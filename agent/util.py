"""Agent utilities."""

from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.random import Sampler
from synth_xfer.cli.eval_final import _parse_bw_args, run


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
