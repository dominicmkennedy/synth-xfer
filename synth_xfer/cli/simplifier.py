from pathlib import Path

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import Func, FuncOp
from xdsl.parser import Parser
from xdsl_smt.dialects.transfer import Transfer

from synth_xfer.cli.args import build_parser


def get_funcs(ctx: Context, p: Path) -> tuple[ModuleOp, list[FuncOp]]:
    with open(p, "r") as f:
        module = Parser(ctx, f.read(), p.name).parse_op()
        assert isinstance(module, ModuleOp)

    fns = {x.sym_name.data: x for x in module.ops if isinstance(x, FuncOp)}
    return module, list(fns.values())


def run(
    transfer_functions: Path,
    rewrite_meet: bool,
):
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    _, xfer_funcs = get_funcs(ctx, transfer_functions)

    # Import the rewriter module
    from synth_xfer.egraph_rewriter.rewriter import (
        rewrite_meet_of_all_functions,
        rewrite_transfer_functions,
    )

    # Rewrite the transfer functions
    all_ret_exprs = rewrite_transfer_functions(xfer_funcs)
    if rewrite_meet:
        rewrite_meet_of_all_functions(all_ret_exprs)


def main() -> None:
    args = build_parser("egraph_rewriter")
    run(transfer_functions=args.transfer_functions, rewrite_meet=args.rewrite_meet)


if __name__ == "__main__":
    main()
