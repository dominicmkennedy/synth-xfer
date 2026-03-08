"""Agent utilities."""

from dataclasses import dataclass
from pathlib import Path
import re

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.random import Sampler
from synth_xfer.cli.eval_final import _parse_bw_args, run


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


@dataclass
class LibraryState:
    """Current learned library state passed to synthesis prompts."""

    functions_text: str


def extract_op_name(op_file_path: str) -> str:
    """Extract operation name from file path (e.g., mlir/Operations/Add.mlir -> Add)."""
    return Path(op_file_path).stem


def load_initial_library(library_file: Path | None) -> LibraryState:
    """Load initial library text for round 0."""
    if library_file is None:
        return LibraryState("builtin.module {}")
    return LibraryState(library_file.read_text())


def read_prompt_template() -> str:
    """Read prompt template, removing HTML comments (<!-- -->)."""
    content = (Path(__file__).parent / "prompt.md").read_text()
    return re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL).strip()


def read_op_file(op_file_path: str) -> str:
    """Read operation MLIR file."""
    return Path(op_file_path).read_text()


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
    solution_path: Path | str,
    op_path: Path,
    domain: AbstractDomain,
    xfer_name: str,
    *,
    exact_bw: tuple[int, ...] = (8,),
    norm_bw: tuple[int, ...] = (64, 2500, 50000),
    random_seed: int | None = None,
) -> str:
    """Run eval on a transformer (file path or MLIR string) and return a summary string.

    For use by the agent and by main.run_eval(). On failure returns 'error: ...'.
    """
    try:
        lbw, mbw, hbw = _parse_bw_args(exact_bw, norm_bw)
        sampler = Sampler.uniform()
        top_r, synth_r = run(
            domain=domain,
            lbw=lbw,
            mbw=mbw,
            hbw=hbw,
            op_path=op_path,
            solution_path=solution_path,
            xfer_name=xfer_name,
            random_seed=random_seed,
            sampler=sampler,
        )
        exact_bw_val = exact_bw[0]
        norm_bw_val = norm_bw[0]
        top_exact = next(x for x in top_r.per_bit_res if x.bitwidth == exact_bw_val)
        synth_exact = next(x for x in synth_r.per_bit_res if x.bitwidth == exact_bw_val)
        top_norm = next(x for x in top_r.per_bit_res if x.bitwidth == norm_bw_val)
        synth_norm = next(x for x in synth_r.per_bit_res if x.bitwidth == norm_bw_val)
        return (
            f"Sound %: {synth_exact.get_sound_prop() * 100:.2f}, Exact %: {synth_exact.get_exact_prop() * 100:.2f}, Norm: {synth_norm.dist:.4f} "
            # f"(top Exact %: {top_exact.get_exact_prop() * 100:.2f}, top Norm: {top_norm.dist:.4f})"
        )
    except Exception as e:
        msg = str(e).strip() or repr(e) or type(e).__name__
        # Single line, truncated, so the agent reliably sees parse/location info
        msg_flat = " ".join(msg.splitlines())[:1500]
        return f"error: {msg_flat}"
