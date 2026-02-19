from argparse import ArgumentParser, Namespace
from pathlib import Path
from time import perf_counter

from xdsl.dialects.func import FuncOp
from z3 import ModelRef

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import (
    HelperFuncs,
    get_fns,
    get_helper_funcs,
    parse_mlir_mod,
)
from synth_xfer._util.verifier import verify_transfer_function
from synth_xfer.cli.args import int_list
from synth_xfer.cli.eval_final import resolve_xfer_name


def verify_function(
    bw: int,
    func: FuncOp,
    xfer_helpers: list[FuncOp | None],
    helper_funcs: HelperFuncs,
    timeout: int,
) -> tuple[bool | None, ModelRef | None]:
    xfer_helpers += [
        helper_funcs.get_top_func,
        helper_funcs.instance_constraint_func,
        helper_funcs.domain_constraint_func,
        helper_funcs.op_constraint_func,
        helper_funcs.meet_func,
    ]
    helpers = [x for x in xfer_helpers if x is not None]

    return verify_transfer_function(func, helper_funcs.crt_func, helpers, bw, timeout)


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument(
        "--bw",
        type=int_list,
        required=True,
        help="Bitwidth range (e.g. `-bw 4`, `-bw 4-64` or `-bw 4,8,16`)",
    )

    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain to evaluate",
    )

    p.add_argument("--op", type=Path, required=True, help="Concrete op")
    p.add_argument("--xfer-file", type=Path, required=True, help="Transformer file")
    p.add_argument("--xfer-name", type=str, help="Transformer to verify")
    p.add_argument("--timeout", type=int, default=30, help="z3 timeout")
    p.add_argument(
        "--continue-unsound",
        action="store_true",
        help="Continue after hitting an unsound bw",
    )
    p.add_argument(
        "--continue-timeout", action="store_true", help="Continue after a timeout"
    )

    return p.parse_args()


def main() -> None:
    args = _register_parser()
    domain = AbstractDomain[args.domain]
    xfer_fns = get_fns(parse_mlir_mod(args.xfer_file))
    xfer_name = resolve_xfer_name(xfer_fns, args.xfer_name)

    xfer_fn = xfer_fns[xfer_name]
    del xfer_fns[xfer_name]
    helper_funcs = get_helper_funcs(args.op, domain)

    for bw in args.bw:
        start_time = perf_counter()
        is_sound, model = verify_function(
            bw, xfer_fn, list(xfer_fns.values()), helper_funcs, args.timeout
        )
        run_time = perf_counter() - start_time

        if is_sound is None:
            if args.continue_timeout:
                print(f"{bw:<2} bits | timeout | took {args.timeout}s")
            else:
                print(
                    f"Verifier TIMEOUT at {bw}-bits.\nTimeout was {args.timeout} second."
                )
                break
        elif is_sound:
            print(f"{bw:<2} bits | sound   | took {run_time:.4f}s")
        else:
            if args.continue_unsound:
                print(f"{bw:<2} bits | unsound | took {run_time:.4f}s")
            else:
                print(f"Verifier UNSOUND at {bw}-bits. Took {run_time:.4f}s.")
                print("Counterexample:")
                print(model)
                break


if __name__ == "__main__":
    main()
