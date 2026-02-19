from argparse import ArgumentParser, Namespace
from contextlib import nullcontext
from csv import reader, writer
from pathlib import Path
from sys import stdin, stdout

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
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument("--size", action="store_true", help="Show abstract value sizes")
    p.add_argument(
        "--show-inputs", action="store_true", help="Show abstract value inputs"
    )

    return p.parse_args()


def main() -> None:
    args = _register_parser()
    domain = AbstractDomain[args.domain]
    bw: int = args.bw

    in_ctx = nullcontext(stdin) if args.input is None else args.input.open("r")
    with in_ctx as in_f:
        input_text = list(tuple(x) for x in reader(in_f, delimiter="\t"))

    arity = len(input_text[0])
    input_args = parse_to_run_inputs(domain, bw, arity, input_text)
    mlir_mod = parse_mlir_mod(args.xfer_file)
    xfer_name = resolve_xfer_name(get_fns(mlir_mod), args.xfer_name)

    lowerer = LowerToLLVM([bw])
    lowerer.add_mod(mlir_mod, [xfer_name])

    with Jit() as jit:
        jit.add_mod(lowerer)
        fn_ptr = jit.get_fn_ptr(f"{xfer_name}_{bw}_shim")
        outputs = eval_to_run(domain, bw, arity, input_args, fn_ptr)

    out_ctx = nullcontext(stdout) if args.output is None else args.output.open("w")
    with out_ctx as out_f:
        csv_w = writer(out_f, delimiter="\t")
        input_rows = [f"arg_{x}" for x in range(arity)] if args.show_inputs else []

        csv_w.writerow(input_rows + ["Output"] + (["Size"] if args.size else []))
        for input, output in zip(input_args, outputs):  # type: ignore
            in_row = [f"{x}" for x in input] if args.show_inputs else []
            size_row = [str(output.size())] if args.size else []
            csv_w.writerow(in_row + [str(output)] + size_row)


if __name__ == "__main__":
    main()
