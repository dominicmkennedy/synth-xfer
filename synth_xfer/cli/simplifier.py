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

from synth_xfer._util.domain import AbstractDomain
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
        "--domain",
        type=lambda s: AbstractDomain[s],
        choices=list(AbstractDomain),
        required=True,
        help="abstract domain whose axioms apply during rewriting",
    )
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
        exprs, cmp_predicates = rewrite_single_function_to_exprs(
            parsed, domain=args.domain, quiet=args.quiet
        )
        rewritten_func = ExprToMLIR(parsed, cmp_predicates=cmp_predicates).convert(exprs)
        if not args.quiet:
            print("Rewritten MLIR:")
        print(_format_mlir(rewritten_func))
        all_ret_exprs = [exprs]
        meet_num_args = len(parsed.body.blocks[0].args)
    elif isinstance(parsed, ModuleOp):
        xfer_funcs = list(get_fns(parsed).values())
        rewritten_pairs = rewrite_solutions(
            xfer_funcs, domain=args.domain, quiet=args.quiet
        )
        if not args.quiet:
            print("Rewritten MLIR:")
        for rewritten_func, _ in rewritten_pairs:
            print(_format_mlir(rewritten_func))
        all_ret_exprs = [exprs for _, exprs in rewritten_pairs]
        meet_num_args = (
            len(xfer_funcs[0].body.blocks[0].args) if xfer_funcs else 0
        )
    else:
        raise ValueError(
            f"mlir in '{args.transfer_functions}' is not a FuncOp or ModuleOp"
        )
    if args.rewrite_meet:
        rewrite_meet_of_all_functions(
            all_ret_exprs,
            domain=args.domain,
            num_args=meet_num_args,
            quiet=args.quiet,
        )


if __name__ == "__main__":
    main()
