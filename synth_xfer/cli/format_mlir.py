from argparse import ArgumentParser, Namespace
from pathlib import Path

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin
from xdsl.dialects.func import Func
from xdsl.parser import Parser
from xdsl.printer import Printer
from xdsl_smt.dialects.transfer import Transfer


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument("-i", "--input", type=Path, required=True)
    p.add_argument("-o", "--output", type=Path, default=None)

    return p.parse_args()


def main() -> None:
    args = _register_parser()

    ctx = Context()
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Arith)
    ctx.load_dialect(Transfer)

    input_path = Path(args.input)
    source = input_path.read_text()
    op = Parser(ctx, source, str(input_path)).parse_operation()

    if args.output:
        output_path = Path(args.output)
        with output_path.open("w") as f:
            Printer(stream=f).print_op(op)
            f.write("\n")
    else:
        Printer().print_op(op)
        print()


if __name__ == "__main__":
    main()
