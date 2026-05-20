"""Agent utilities."""

from dataclasses import dataclass, field
import os
from pathlib import Path
import re

from pydantic import BaseModel
from xdsl.dialects.func import FuncOp
from xdsl.utils.exceptions import ParseError

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import enum, eval_transfer_func
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import (
    get_helper_funcs,
    parse_mlir_func,
    parse_mlir_mod,
    top_as_xfer,
)
from synth_xfer._util.random import Random, Sampler
from synth_xfer._util.smt_solver import Model, SolverKind
from synth_xfer.cli.verify import format_counterexample, verify_function


@dataclass
class EvalArgs:
    """Arguments for evaluating a transfer function."""

    op_path: Path
    domain: AbstractDomain
    lbw: list[int]
    mbw: list[tuple[int, int]] = field(default_factory=list)
    hbw: list[tuple[int, int, int]] = field(default_factory=list)
    unsound_ex: int = 0
    imprecise_ex: int = 0
    to_eval: dict | None = field(default=None, repr=False)


@dataclass
class SynthesisTask:
    """Concrete synthesis task for one operator/program file."""

    op_file: str
    op_name: str


@dataclass
class SynthesisResult:
    """High-level synthesis output for one task."""

    task: SynthesisTask
    solution_iters: list[str]
    is_sound: bool
    eval_summary: str | None
    eval_result: EvalResult | None = None

    @property
    def solution_text(self) -> str | None:
        """Return the latest synthesized solution, if available."""
        return self.solution_iters[-1] if self.solution_iters else None


class LibraryFunction(BaseModel):
    """A single library function"""

    function_name: str
    docstring: str
    source: str


class FunctionDocumentation(BaseModel):
    """Name and docstring of a function"""

    function_name: str
    docstring: str


class LibraryState(BaseModel):
    """Current learned library state passed to synthesis prompts."""

    functions: list[LibraryFunction]

    @property
    def functions_text(self) -> str:
        """Render all functions as a builtin.module MLIR string."""
        if not self.functions:
            return ""
        body = "\n\n".join(f.source for f in self.functions)
        indented = "\n".join(
            "  " + line if line.strip() else "" for line in body.splitlines()
        )
        return f"builtin.module {{\n{indented}\n}}"


def validate_library_functions(
    funcs: list[LibraryFunction],
) -> list[LibraryFunction]:
    """Drop functions whose source fails to parse as a func.func."""
    valid: list[LibraryFunction] = []
    for f in funcs:
        try:
            parse_mlir_func(f.source)
        except (ParseError, ValueError) as e:
            print(f"[LIBRARY] Dropping invalid function {f.function_name!r}: {e}")
            continue
        valid.append(f)
    return valid


@dataclass
class CollectiveLibrary:
    """Previously generated transformers collected into a library"""

    results: dict[str, SynthesisResult]

    def to_library_state(self, mask: list[str] = []) -> LibraryState:
        funcs: list[LibraryFunction] = []
        for op_name, result in self.results.items():
            if op_name not in mask and result.solution_text:
                funcs.append(
                    LibraryFunction(
                        function_name=op_name,
                        docstring=result.task.op_file,
                        source=result.solution_text,
                    )
                )
        return LibraryState(functions=funcs)

    def update(self, results: list[SynthesisResult]) -> None:
        """add new results and update ones with greater exactness"""
        for result in results:
            if result.is_sound and result.eval_result is not None:
                op_name = result.task.op_name
                new_exact = result.eval_result.get_exact_prop()
                if op_name not in self.results:
                    self.results[op_name] = result
                else:
                    existing_eval = self.results[op_name].eval_result
                    if (
                        existing_eval is not None
                        and new_exact > existing_eval.get_exact_prop()
                    ):
                        self.results[op_name] = result


@dataclass
class TokenUsageSummary:
    input_tokens: int
    cached_input_tokens: int
    output_tokens: int

    def __str__(self) -> str:
        return (
            f"Token usage: input={self.input_tokens:,}, "
            f"cached_input={self.cached_input_tokens:,}, "
            f"output={self.output_tokens:,}"
        )


def get_api_key() -> str:
    """Get API key from env var or file."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_file = Path(__file__).parent / "api_key.txt"
        if api_file.exists():
            api_key = api_file.read_text().strip()
    if not api_key:
        raise ValueError(
            "API key not found. Set OPENAI_API_KEY or create agent/api_key.txt"
        )
    return api_key


def extract_op_name(op_file_path: str) -> str:
    """Extract operation name from file path (e.g., mlir/Operations/Add.mlir -> Add)."""
    return Path(op_file_path).stem


def _parse_library_function(text: str) -> LibraryFunction | None:
    """Parse a single func.func definition from text. Returns None if not found."""
    func_pattern = re.compile(r"func\.func\s+@(\w+)\s*\(")
    match = func_pattern.search(text)
    if not match:
        return None

    func_name = match.group(1)

    brace_pos = text.find("{", match.end())
    if brace_pos == -1:
        raise ValueError(f"Ill-formed MLIR: no opening brace for function '{func_name}'")

    depth = 1
    i = brace_pos + 1
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1

    if depth != 0:
        raise ValueError(f"Ill-formed MLIR: unmatched braces in function '{func_name}'")

    source = text[match.start() : i].strip()

    docstring = ""
    body = text[brace_pos + 1 : i - 1]
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("//"):
            docstring = stripped[2:].strip()
            break

    return LibraryFunction(function_name=func_name, docstring=docstring, source=source)


def load_initial_library(
    library_dir: Path | None, domain: AbstractDomain
) -> LibraryState:
    """Load initial library text for round 0 from `library_dir/<domain>/`.

    `library_dir` is the root that contains per-domain subdirectories
    (e.g. `agent/library/KnownBits/`). Returns an empty library if
    `library_dir` is None or the per-domain subdir does not exist.
    """

    if library_dir is None:
        return LibraryState(functions=[])

    domain_dir = library_dir / domain.name
    if not domain_dir.is_dir():
        return LibraryState(functions=[])

    functions = []
    for entry in sorted(domain_dir.iterdir()):
        if not entry.is_file():
            continue
        func = _parse_library_function(entry.read_text())
        if func is not None:
            functions.append(func)

    return LibraryState(functions=functions)


def clean_llm_output(output: str) -> str:
    """Extract MLIR code from LLM output, removing markdown blocks."""
    for fence in ["```mlir", "```"]:
        if fence in output:
            start = output.find(fence) + len(fence)
            end = output.find("```", start)
            if end != -1:
                output = output[start:end].strip()
                break
    output = output.replace(r"\n", "\n").replace(r"\t", "\t")
    return output


def make_output_dir(output_dir: Path):
    """Create the output directory and the output/log directory"""
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "log").mkdir(exist_ok=True)


def summarize_token_usage(run_result) -> TokenUsageSummary:
    """Aggregate input/cached-input/output tokens from the run result."""
    u = run_result.usage()
    return TokenUsageSummary(
        input_tokens=u.input_tokens or 0,
        cached_input_tokens=u.cache_read_tokens or 0,
        output_tokens=u.output_tokens or 0,
    )


def save_file(content: str, dir: Path, file_name: str) -> Path:
    """Save content to dir/file_name and return the full path."""
    path = Path(dir) / file_name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


def get_op_output_dir(base_output: Path, op_name: str) -> Path:
    """Return and create the per-operator output directory."""
    op_dir = Path(base_output) / op_name
    op_dir.mkdir(parents=True, exist_ok=True)
    return op_dir


def dump_library(lib: LibraryState, out_dir: Path) -> Path:
    """Save library funcs to library directory"""
    for func in lib.functions:
        save_file(func.source, out_dir, f"{func.function_name}.mlir")

    return out_dir


def _extract_module_body(mlir: str) -> str:
    """Extract content inside the outermost builtin.module { } block, dedented by 2 spaces."""
    if "builtin.module" not in mlir:
        return mlir
    start = mlir.index("{") + 1
    depth = 1
    i = start
    while i < len(mlir) and depth > 0:
        if mlir[i] == "{":
            depth += 1
        elif mlir[i] == "}":
            depth -= 1
        i += 1
    inner = mlir[start : i - 1]
    lines = [line[2:] if line.startswith("  ") else line for line in inner.splitlines()]
    return "\n".join(lines).strip()


def merge_library_text(mod1: str, mod2: str) -> str:
    """Merge 2 sets of functions into a single builtin.module."""
    body1 = _extract_module_body(mod1)
    body2 = _extract_module_body(mod2)
    combined = "\n".join(part for part in [body1, body2] if part)
    # Re-indent each non-blank line by 2 spaces
    indented = "\n".join(
        "  " + line if line.strip() else "" for line in combined.splitlines()
    )
    return f"builtin.module {{\n{indented}\n}}"


def _format_eval_examples_for_agent(
    eval_result: EvalResult, domain: AbstractDomain
) -> str:
    """Optional multi-line suffix: legend plus unsound/imprecise CaseExample lines per bitwidth."""
    if not any(
        res.unsound_examples or res.imprecise_examples for res in eval_result.per_bit_res
    ):
        return ""

    lines: list[str] = [
        "",
        "Counterexamples:",
        "How to read each example line:",
        "  • The `( ... )` before `->` lists abstract inputs in MLIR argument order: first = %0, then %1, and so on.",
        "  • After `->`: your abstract output in this eval; `best` is the optimal abstract output for that input.",
    ]
    if domain == AbstractDomain.KnownBits:
        lines.extend(
            [
                "  • KnownBits: each input/output is one string of length = bw above; bits are MSB→LSB (left to right). "
                "`0` and `1` are known; `?` is unknown.",
            ]
        )
    elif domain == AbstractDomain.UConstRange:
        lines.extend(
            [
                "  • UConstRange: each input/output is `[lo, hi]` an unsigned interval "
                "(0 ≤ lo ≤ hi ≤ 2^bw - 1, inclusive). `(bottom)` denotes the empty / "
                "infeasible interval.",
            ]
        )
    elif domain == AbstractDomain.SConstRange:
        lines.extend(
            [
                "  • SConstRange: each input/output is `[lo, hi]` a signed interval "
                "(-2^(bw-1) ≤ lo ≤ hi ≤ 2^(bw-1) - 1, inclusive). `(bottom)` denotes "
                "the empty / infeasible interval.",
            ]
        )
    else:
        raise ValueError(f"Domain {domain} not supported in example formatting yet")
    lines.extend(
        [
            "",
            "Unsound: the abstract output does not soundly cover the true concrete result; "
            "`best` is the optimal abstract output for that input.",
            "Imprecise: still sound but less precise than optimal; `dist` is precision loss vs "
            "optimal (0 = exact).",
            "",
        ]
    )
    unsound_lines: list[str] = []
    imprecise_lines: list[str] = []
    for res in eval_result.per_bit_res:
        for ex in res.unsound_examples:
            unsound_lines.append(f"  bw={res.bitwidth}: {ex.to_str(show_dist=False)}")
        for ex in res.imprecise_examples:
            imprecise_lines.append(f"  bw={res.bitwidth}: {ex.to_str()}")
    if unsound_lines:
        lines.append("Unsound examples (per bitwidth):")
        lines.extend(unsound_lines)
        lines.append("")
    if imprecise_lines:
        lines.append("Imprecise examples (per bitwidth):")
        lines.extend(imprecise_lines)
    return "\n".join(lines).rstrip("\n")


def _get_xfer_name(solution: str) -> str:
    """Extract the first func.func name from an MLIR solution string."""
    match = re.search(r"func\.func\s+@(\w+)\s*\(", solution)
    if not match:
        raise ValueError("No func.func definition found in solution")
    return match.group(1)


def rename_xfer(solution: str, new_name: str) -> str:
    """Rename the transfer function in an MLIR solution string."""
    old_name = _get_xfer_name(solution)
    return re.sub(rf"@{re.escape(old_name)}\b", f"@{new_name}", solution)


def _check_undefined_calls(xfer: list[str], combined: str, helpers) -> None:
    """Raise ValueError if xfer calls any function not defined in combined or helpers."""
    called: set[str] = set()
    for src in xfer:
        called.update(re.findall(r"func\.call\s+@(\w+)", src))
    if not called:
        return
    defined: set[str] = set(re.findall(r"func\.func\s+@(\w+)", combined))
    defined.add(helpers.meet_func.sym_name.data)
    defined.add(helpers.get_top_func.sym_name.data)
    undefined = called - defined
    if undefined:
        names = ", ".join(f"@{n}" for n in sorted(undefined))
        raise ValueError(
            f"Transformer calls undefined function(s): {names}. "
            "Call list_library_functions() to see what is available."
        )


def _run_eval(
    xfer: list[str],
    base: list[str],
    lib: list[str],
    eval_args: EvalArgs,
) -> EvalResult:
    """Core eval logic shared by eval_transformer and AgentSolutionSet.

    xfer: candidate transfer function(s); empty list uses top as candidate.
    base: existing solutions combined via meet for comparison.
    lib:  library helper functions.
    """
    lbw, mbw, hbw = eval_args.lbw, eval_args.mbw, eval_args.hbw
    all_bws = list(set(lbw) | set(x[0] for x in mbw) | set(x[0] for x in hbw))
    low_and_med_bw = set(lbw) | set(x[0] for x in mbw)
    sampler = Sampler.uniform()

    base_names = [_get_xfer_name(s) for s in base]
    helpers = get_helper_funcs(eval_args.op_path, eval_args.domain)

    combined = ""
    for p in lib + base + xfer:
        if p.strip():
            combined = merge_library_text(combined, p)

    if xfer:
        _check_undefined_calls(xfer, combined, helpers)

    lowerer = LowerToLLVM(all_bws)
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)

    if xfer:
        xfer_name = _get_xfer_name(xfer[0])
        lowerer.add_mod(parse_mlir_mod(combined), [xfer_name] + base_names)
        cand_shim_names = {bw: f"{xfer_name}_{bw}_shim" for bw in all_bws}
    else:
        top_bw_fns = lowerer.add_fn(top_as_xfer(helpers.transfer_func), shim=True)
        cand_shim_names = {bw: fn.name for bw, fn in top_bw_fns.items()}
        if combined:
            lowerer.add_mod(parse_mlir_mod(combined), base_names)

    if eval_args.to_eval is None:
        seed = Random(None).randint(0, 1_000_000)
        eval_args.to_eval = enum(lbw, mbw, hbw, seed, helpers, sampler)
    to_eval = eval_args.to_eval
    with Jit() as jit:
        jit.add_mod(lowerer)
        eval_input = {
            bw: (
                to_eval[bw],
                [jit.get_fn_ptr(cand_shim_names[bw])],
                [jit.get_fn_ptr(f"{bn}_{bw}_shim") for bn in base_names],
            )
            for bw in all_bws
        }
        (result,) = eval_transfer_func(
            eval_input, low_and_med_bw, eval_args.unsound_ex, eval_args.imprecise_ex
        )

    return result


def format_result(result: EvalResult) -> str:
    """Format EvalResult summary metrics for agent-facing output."""
    return (
        f"Sound %: {result.get_sound_prop() * 100:.2f}, "
        f"Exact %: {result.get_exact_prop() * 100:.2f}, "
        f"Dist: {result.sound_dist:.4f}"
    )


VERIFY_BITWIDTHS: tuple[int, ...] = (4, 8, 16, 32, 64)


def verify_transformer(
    xfer: str,
    eval_args: EvalArgs,
    *,
    lib: list[str] = [],
    timeout: int = 60,
    solver_kind: SolverKind = SolverKind.bitwuzla,
) -> tuple[str, dict[int, Model | None] | None]:
    """SMT-verify a transformer (MLIR string) at bitwidths 4, 8, 16, 32, 64.

    Returns (summary, problems):
      summary: an LLM-friendly string. If all bitwidths are sound, a single line.
        Otherwise a verdict line plus one line per problematic bitwidth.
      problems: dict from problematic bitwidth to (model | None).
        - bw -> Model: unsound at bw, model carries the counterexample
        - bw -> None:  solver timed out at bw
        - empty dict:  sound at every checked bitwidth
        - None:        parse / setup failure (summary is `error: ...`)
    """
    try:
        func = parse_mlir_func(xfer)
        xfer_helpers: list[FuncOp | None] = [parse_mlir_func(s) for s in lib]
        helpers = get_helper_funcs(eval_args.op_path, eval_args.domain)
        problems: dict[int, Model | None] = {}
        for bw in VERIFY_BITWIDTHS:
            is_sound, model = verify_function(
                bw, func, list(xfer_helpers), helpers, timeout, solver_kind
            )
            if is_sound is None:
                problems[bw] = None
            elif not is_sound:
                problems[bw] = model
    except Exception as e:
        return (f"error: {str(e)}", None)

    if not problems:
        return ("VERIFIED sound at all checked bitwidths", problems)

    xfer_name = func.sym_name.data
    op_name = eval_args.op_path.stem
    mlir_mod = None
    if any(m is not None for m in problems.values()):
        combined = ""
        for s in lib + [xfer]:
            combined = merge_library_text(combined, s)
        mlir_mod = parse_mlir_mod(combined)

    lines = ["UNSOUND or TIMEOUT at one or more bitwidths"]
    for bw, model in problems.items():
        if model is None:
            lines.append(f"bw={bw}: TIMEOUT")
        else:
            assert mlir_mod is not None
            cx = format_counterexample(
                op_name, model, bw, eval_args.domain, mlir_mod, xfer_name, helpers, False
            )
            lines.append(f"bw={bw}: UNSOUND")
            lines.append(cx)
    return ("\n".join(lines), problems)


def eval_transformer(
    xfer: list[str],
    eval_args: EvalArgs,
    *,
    lib: list[str] = [],
) -> tuple[str, EvalResult | None]:
    """Run eval on a transformer (MLIR string) and return (summary, eval_result).

    For use by the agent and by main.run_eval(). On failure returns 'error: ...'.
    """
    try:
        result = _run_eval(xfer, [], lib, eval_args)
        summary = format_result(result)
        return (
            summary + _format_eval_examples_for_agent(result, eval_args.domain),
            result,
        )

    except Exception as e:
        return (f"error: {str(e)}", None)
