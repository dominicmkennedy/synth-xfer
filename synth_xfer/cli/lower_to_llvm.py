from argparse import ArgumentParser, Namespace
from pathlib import Path
from sys import stdin, stdout

from xdsl.dialects.builtin import ModuleOp
from xdsl.dialects.func import FuncOp

from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import parse_mlir


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument("--bw", type=int, required=True, help="Bitwidth")
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)

    return p.parse_args()


class _StdinReadable:
    @property
    def name(self) -> str:
        return "<stdin>"

    def read_text(self) -> str:
        return stdin.read()


def main() -> None:
    args = _register_parser()

    in_f = _StdinReadable() if args.input is None else args.input
    out_f = stdout if args.output is None else args.output.open("w")

    mlir = parse_mlir(in_f)
    lowerer = LowerToLLVM([args.bw])

    if isinstance(mlir, ModuleOp):
        lowerer.add_mod(mlir)
    elif isinstance(mlir, FuncOp):
        lowerer.add_fn(mlir)
    else:
        raise ValueError(f"Not a FuncOp or a ModuleOp: {mlir}")

    out_f.write(str(lowerer))


if __name__ == "__main__":
    main()
