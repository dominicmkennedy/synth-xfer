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
from xdsl.ir import Operation
from xdsl.printer import Printer

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_fns, parse_mlir
from synth_xfer.egraph_rewriter.rewriter import (
    rewrite_single_function,
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
        "-o",
        "--output",
        type=Path,
        default=None,
        help="write the rewritten module to this file instead of stdout",
    )
    p.add_argument(
        "--max-iterations",
        type=int,
        default=6,
        help="hard upper bound on egraph saturation passes per function",
    )
    p.add_argument(
        "--step-time-limit",
        type=float,
        default=1.0,
        help="per-iteration wall-clock cap in seconds; after any iteration "
        "exceeds this budget no further iterations are started",
    )
    p.add_argument(
        "-q",
        "--quiet",
        action=BooleanOptionalAction,
        default=True,
        help="Suppress console output from the optimizer",
    )

    return p.parse_args()


def _format_mlir(op: Operation) -> str:
    buf = StringIO()
    Printer(stream=buf).print_op(op)
    return buf.getvalue()


def main() -> None:
    args = _get_args()

    parsed = parse_mlir(args.transfer_functions)
    if isinstance(parsed, FuncOp):
        rewritten_funcs = [
            rewrite_single_function(
                parsed,
                domain=args.domain,
                quiet=args.quiet,
                max_iterations=args.max_iterations,
                step_time_limit_seconds=args.step_time_limit,
            )
        ]
    elif isinstance(parsed, ModuleOp):
        xfer_funcs = list(get_fns(parsed).values())
        rewritten_funcs = rewrite_solutions(
            xfer_funcs,
            domain=args.domain,
            quiet=args.quiet,
            max_iterations=args.max_iterations,
            step_time_limit_seconds=args.step_time_limit,
        )
    else:
        raise ValueError(
            f"mlir in '{args.transfer_functions}' is not a FuncOp or ModuleOp"
        )

    rewritten_module = ModuleOp(list[Operation](rewritten_funcs))
    formatted = _format_mlir(rewritten_module)

    if args.output is not None:
        args.output.write_text(formatted + "\n")
        if not args.quiet:
            print(f"Wrote rewritten module to {args.output}")
    else:
        if not args.quiet:
            print("Rewritten MLIR:")
        print(formatted)


if __name__ == "__main__":
    main()
