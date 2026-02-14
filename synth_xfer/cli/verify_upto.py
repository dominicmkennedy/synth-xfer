from time import perf_counter

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_fns, get_helper_funcs, parse_mlir_mod
from synth_xfer.cli.eval_final import resolve_xfer_name
from synth_xfer.cli.verify import _register_parser, verify_function


def _target_bitwidth(bws: list[int]) -> int:
    target = max(bws)
    if target < 1:
        raise ValueError("Target bitwidth must be at least 1 for verify-upto")
    return target


def main() -> None:
    args = _register_parser()
    target_bw = _target_bitwidth(args.bw)

    domain = AbstractDomain[args.domain]
    xfer_fns = get_fns(parse_mlir_mod(args.xfer_file))
    xfer_name = resolve_xfer_name(xfer_fns, args.xfer_name)

    xfer_fn = xfer_fns[xfer_name]
    del xfer_fns[xfer_name]
    helper_funcs = get_helper_funcs(args.op, domain)

    for bw in range(1, target_bw + 1):
        start_time = perf_counter()
        is_sound, model = verify_function(
            bw, xfer_fn, list(xfer_fns.values()), helper_funcs, args.timeout
        )
        run_time = perf_counter() - start_time

        if is_sound is None:
            print(f"{bw:<2} bits | timeout | took {run_time:.4f}s", flush=True)
            break
        elif is_sound:
            print(f"{bw:<2} bits | sound   | took {run_time:.4f}s", flush=True)
        else:
            print(f"{bw:<2} bits | unsound | took {run_time:.4f}s", flush=True)
            print("counterexample:", flush=True)
            print(model, flush=True)


if __name__ == "__main__":
    main()
