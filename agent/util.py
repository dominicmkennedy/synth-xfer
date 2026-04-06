"""Agent utilities."""

from dataclasses import dataclass
import os
from pathlib import Path
import re

from pydantic import BaseModel

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import enum, eval_transfer_func
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_mod
from synth_xfer._util.random import Random, Sampler


@dataclass
class SynthesisTask:
    """Concrete synthesis task for one operator/program file."""

    op_file: str
    op_name: str


@dataclass
class SynthesisResult:
    """High-level synthesis output for one task."""

    task: SynthesisTask
    solution_text: str
    transformer_path: Path
    eval_summary: str | None = None


class LibraryFunction(BaseModel):
    """A single library function"""

    function_name: str
    docstring: str
    source: str


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


def load_initial_library(library_dir: Path | None) -> LibraryState:
    """Load initial library text for round 0."""

    if library_dir is None:
        return LibraryState(functions=[])

    functions = []
    for entry in sorted(library_dir.iterdir()):
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


def print_token_usage(run_result) -> None:
    """Print aggregated token usage from agent run."""
    inp = out = reason = 0
    for resp in getattr(run_result, "raw_responses", []):
        u = getattr(resp, "usage", None)
        if u is None:
            continue
        inp += getattr(u, "input_tokens", 0) or 0
        out += getattr(u, "output_tokens", 0) or 0
        od = getattr(u, "output_tokens_details", None)
        if od is not None:
            reason += getattr(od, "reasoning_tokens", 0) or 0
    total = inp + out + reason
    token_str = f"{inp:,} input, {out:,} output" + (
        f", {reason:,} reasoning" if reason else ""
    )
    print(f"Tokens: {token_str} ({total:,} total)")


def save_file(content: str, dir: Path, file_name: str) -> Path:
    """Save content to dir/file_name and return the full path."""
    path = Path(dir) / file_name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


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


def eval_transformer(
    solution: str,
    op_path: Path,
    domain: AbstractDomain,
    xfer_name: str,
    *,
    lbw: list[int],
    mbw: list[tuple[int, int]] = [],
    hbw: list[tuple[int, int, int]] = [],
    random_seed: int | None = None,
) -> str:
    """Run eval on a transformer (MLIR string) and return a summary string.

    For use by the agent and by main.run_eval(). On failure returns 'error: ...'.
    """
    try:
        all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]
        EvalResult.init_bw_settings(
            set(lbw), set(x[0] for x in mbw), set(x[0] for x in hbw)
        )
        sampler = Sampler.uniform()

        helpers = get_helper_funcs(op_path, domain)
        sol_module = parse_mlir_mod(solution)
        seed = (
            Random(random_seed).randint(0, 1_000_000)
            if random_seed is None
            else random_seed
        )

        lowerer = LowerToLLVM(all_bws)
        lowerer.add_fn(helpers.meet_func)
        lowerer.add_fn(helpers.get_top_func)
        lowerer.add_mod(sol_module, [xfer_name])

        to_eval = enum(lbw, mbw, hbw, seed, helpers, sampler)
        with Jit() as jit:
            jit.add_mod(lowerer)
            eval_input = {
                bw: (to_eval[bw], [jit.get_fn_ptr(f"{xfer_name}_{bw}_shim")], [])
                for bw in all_bws
            }
            (synth_r,) = eval_transfer_func(eval_input)

        return f"Sound %: {synth_r.get_sound_prop() * 100:.2f}, Exact %: {synth_r.get_exact_prop() * 100:.2f}, Dist: {synth_r.sound_dist:.4f}"
    except Exception as e:
        msg = str(e).strip() or repr(e) or type(e).__name__
        # Single line, truncated, so the agent reliably sees parse/location info
        msg_flat = " ".join(msg.splitlines())[:1500]
        return f"error: {msg_flat}"
