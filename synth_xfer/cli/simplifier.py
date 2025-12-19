from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    BooleanOptionalAction,
    Namespace,
)
from pathlib import Path

from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer.egraph_rewriter.rewriter import (
    rewrite_meet_of_all_functions,
    rewrite_solutions,
)


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("transfer_functions", type=Path, help="path to transfer function")
    p.add_argument(
        "-rewrite_meet",
        action="store_true",
        help="rewrite the entire meet instead of individual functions",
    )
    p.add_argument(
        "-quiet",
        action=BooleanOptionalAction,
        default=True,
        help="Suppress console output from the optimizer",
    )

    return p.parse_args()


def main() -> None:
    args = _get_args()

    mlir_mod = parse_mlir_mod(args.transfer_functions)
    xfer_funcs = list(get_fns(mlir_mod).values())

    all_ret_exprs = rewrite_solutions(xfer_funcs, quiet=args.quiet)
    if args.rewrite_meet:
        rewrite_meet_of_all_functions(all_ret_exprs, quiet=args.quiet)


if __name__ == "__main__":
    main()
