from argparse import ArgumentParser, Namespace
from pathlib import Path
from sys import stdout

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_to_run, parse_to_run_inputs
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer.cli.eval_final import resolve_xfer_name


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument(
        "--bw",
        type=int,
        required=True,
        help="Bitwidth",
    )

    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )

    p.add_argument("--xfer-file", type=Path, required=True, help="Transformer file")
    p.add_argument("--xfer-name", type=str, help="Transformer to verify")
    p.add_argument("-i", "--input", nargs="+", required=True)
    p.add_argument("-o", "--output", type=Path, default=None)

    return p.parse_args()


def main() -> None:
    args = _register_parser()
    domain = AbstractDomain[args.domain]
    out_f = stdout if args.output is None else args.output.open("w")

    if len(args.input) == 1 and Path(args.input[0]).is_file():
        text = Path(args.input[0]).read_text().split("\n")[:-1]
        input_text = [tuple(y for y in x.split(" ")) for x in text]
        arity = len(input_text[0])
    else:
        text = tuple(str(x) for x in args.input)
        arity = len(text)
        input_text = [text]

    mlir_mod = parse_mlir_mod(args.xfer_file)
    xfer_name = resolve_xfer_name(get_fns(mlir_mod), args.xfer_name)
    input_args = parse_to_run_inputs(domain, args.bw, arity, input_text)

    lowerer = LowerToLLVM([args.bw])
    lowerer.add_mod(mlir_mod, [xfer_name])

    jit = Jit()
    jit.add_mod(str(lowerer))
    fn_ptr = jit.get_fn_ptr(f"{xfer_name}_{args.bw}_shim")
    outputs = eval_to_run(domain, args.bw, arity, input_args, fn_ptr)

    for output in outputs:  # type: ignore
        out_f.write(f"{output}\n")


if __name__ == "__main__":
    main()
