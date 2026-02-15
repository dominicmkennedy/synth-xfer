from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    BooleanOptionalAction,
    Namespace,
)
from io import StringIO
from pathlib import Path

from xdsl.dialects.builtin import ModuleOp
from xdsl.dialects.func import FuncOp
from xdsl.printer import Printer

from synth_xfer._util.parse_mlir import get_fns, parse_mlir
from synth_xfer.egraph_rewriter.expr_to_mlir import ExprToMLIR
from synth_xfer.egraph_rewriter.rewriter import (
    rewrite_meet_of_all_functions,
    rewrite_single_function_to_exprs,
    rewrite_solutions,
)


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("transfer_functions", type=Path, help="path to transfer function")
    p.add_argument(
        "--rewrite-meet",
        action="store_true",
        help="rewrite the entire meet instead of individual functions",
    )
    p.add_argument(
        "-q",
        "--quiet",
        action=BooleanOptionalAction,
        default=True,
        help="Suppress console output from the optimizer",
    )

    return p.parse_args()


def _format_mlir(op: FuncOp) -> str:
    buf = StringIO()
    Printer(stream=buf).print_op(op)
    return buf.getvalue()


def main() -> None:
    args = _get_args()

    parsed = parse_mlir(args.transfer_functions)
    if isinstance(parsed, FuncOp):
        exprs, cmp_predicates = rewrite_single_function_to_exprs(parsed, quiet=args.quiet)
        rewritten_func = ExprToMLIR(parsed, cmp_predicates=cmp_predicates).convert(exprs)
        if not args.quiet:
            print("Rewritten MLIR:")
        print(_format_mlir(rewritten_func))
        all_ret_exprs = [exprs]
    elif isinstance(parsed, ModuleOp):
        xfer_funcs = list(get_fns(parsed).values())
        all_ret_exprs = rewrite_solutions(xfer_funcs, quiet=args.quiet)
    else:
        raise ValueError(
            f"mlir in '{args.transfer_functions}' is not a FuncOp or ModuleOp"
        )
    if args.rewrite_meet:
        rewrite_meet_of_all_functions(all_ret_exprs, quiet=args.quiet)


if __name__ == "__main__":
    main()
