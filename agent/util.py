"""Agent utilities."""

from pathlib import Path
import re

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.random import Sampler
from synth_xfer.cli.eval_final import _parse_bw_args, run


def extract_op_name(op_file_path: str) -> str:
    """Extract operation name from file path (e.g., mlir/Operations/Add.mlir -> Add)."""
    return Path(op_file_path).stem


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


def _save_file(content: str, path: Path) -> Path:
    """Helper to save file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


def save_transformer(output: str, output_dir: Path, op_name: str) -> Path:
    """Save generated transformer to kb_{op_name}.mlir."""
    return _save_file(output, Path(output_dir) / f"kb_{op_name.lower()}.mlir")

def save_library(output: str, output_dir: Path, version: int) -> Path:
    """Save learned library to library_v{version}.mlir"""
    return _save_file(output, Path(output_dir) / f"library_v{version}.mlir")

def save_instantiated_prompt(prompt: str, output_dir: Path, op_name: str) -> Path:
    """Save instantiated prompt to instantiated_prompt_{op_name}.md."""
    return _save_file(
        prompt, Path(output_dir) / f"instantiated_prompt_{op_name.lower()}.md"
    )

def _extract_module_body(mlir: str) -> str:
    """Extract content inside the outermost builtin.module { } block, dedented by 2 spaces."""
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
    # Strip the 2-space module-level indentation from each line
    lines = []
    for line in inner.splitlines():
        lines.append(line[2:] if line.startswith("  ") else line)
    return "\n".join(lines).strip()


def merge_library_text(lib1: str, lib2: str) -> str:
    """Merge two builtin.module MLIR strings into one module containing all functions."""
    body1 = _extract_module_body(lib1)
    body2 = _extract_module_body(lib2)
    combined = "\n".join(part for part in [body1, body2] if part)
    # Re-indent each non-blank line by 2 spaces
    indented = "\n".join("  " + line if line.strip() else "" for line in combined.splitlines())
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
