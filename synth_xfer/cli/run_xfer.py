from argparse import ArgumentParser, Namespace
from contextlib import nullcontext
from io import StringIO
from pathlib import Path
from sys import stdin, stdout
from typing import Any

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import (
    eval_transfer_func,
    parse_to_eval_inputs,
    parse_to_run_inputs,
    run_xfer_fn,
)
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer._util.tsv import EnumData
from synth_xfer.cli.eval_final import resolve_xfer_name


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument("--bw", type=int, help="Bitwidth")

    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )

    p.add_argument("--xfer-file", type=Path, required=True, help="Transformer file")
    p.add_argument("--xfer-name", type=str, help="Transformer to verify")
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument("--eval", action="store_true", help="Eval")
    args = p.parse_args()

    has_input = args.input is not None
    has_bw = args.bw is not None
    has_domain = args.domain is not None

    if has_input:
        if has_bw or has_domain:
            p.error("--input cannot be used with --bw, --domain or --eval")
    elif not (has_bw and has_domain):
        p.error("both --bw and --domain are required with no --input")
    elif args.eval:
        p.error("need --input to use --eval")

    return args


def parse_enum_df(df: pd.DataFrame, domain: AbstractDomain, arity: int, bw: int):
    if all(f"arg_{i}" in df.columns for i in range(arity)):
        df = df[[f"arg_{i}" for i in range(arity)]]  # type: ignore
    else:
        raise ValueError(f"Input header missing columns, for {arity}-ary transformer")

    in_strs = [tuple(x) for x in df.astype(str).itertuples(index=False, name=None)]

    return parse_to_run_inputs(domain, bw, arity, in_strs)


def parse_eval_df(df: pd.DataFrame, domain: AbstractDomain, arity: int, bw: int):
    if all(f"arg_{i}" in df.columns for i in range(arity)) and "ideal" in df.columns:
        args = (
            df[[f"arg_{i}" for i in range(arity)]]
            .astype(str)
            .itertuples(index=False, name=None)
        )
        ret = df[["ideal"]].astype(str).itertuples(index=False, name=None)
    else:
        raise ValueError(f"Input header missing columns, for {arity}-ary transformer")

    in_strs = [(tuple(x), y[0]) for x, y in zip(args, ret)]

    return parse_to_eval_inputs(domain, bw, arity, in_strs)


def _parse_inputs(args: Namespace, arity: int):
    if args.input:
        with open(args.input, "r") as f:
            data = EnumData.read_tsv(f)
            df = data.enumdata

        domain = data.metadata.domain
        parse_fn = parse_eval_df if args.eval else parse_enum_df
        to_eval: dict[int, Any] = {
            bw: parse_fn(v, domain, data.metadata.arity, bw)  # type: ignore
            for bw, v in df.groupby("bw")
        }
    else:
        domain = args.domain
        df = pd.read_csv(StringIO(stdin.read()), sep="\t")
        in_strs = [tuple(x) for x in df.astype(str).itertuples(index=False, name=None)]
        to_eval = {args.bw: parse_to_run_inputs(args.domain, args.bw, arity, in_strs)}

    return domain, to_eval, df


def _run_eval(to_eval: dict[int, Any], mlir_mod: Any, xfer_name: str) -> str:
    lowerer = LowerToLLVM(list(to_eval.keys()))
    lowerer.add_mod(mlir_mod, [xfer_name])
    with Jit() as jit:
        jit.add_mod(lowerer)
        x = {
            bw: (v, [jit.get_fn_ptr(f"{xfer_name}_{bw}_shim")], [])
            for bw, v in to_eval.items()
        }

        return str(eval_transfer_func(x)[0])


def _run_enum(
    to_eval: dict[int, Any],
    domain: AbstractDomain,
    mlir_mod: Any,
    xfer_name: str,
    df: pd.DataFrame,
    output: Path | None,
) -> None:
    outputs = []
    for bw, inputs in to_eval.items():
        outputs.extend(run_xfer_fn(domain, bw, inputs, mlir_mod, xfer_name))

    df["output"] = outputs
    df["size"] = [x.size() for x in outputs]

    out_ctx = nullcontext(stdout) if output is None else output.open("w")
    with out_ctx as out_f:
        if output is None:
            with pd.option_context("display.max_rows", None, "display.max_columns", None):
                print(df.to_string(index=False), file=out_f)
        else:
            df.to_csv(out_f, sep="\t", index=False)


def main() -> None:
    args = _register_parser()
    mlir_mod = parse_mlir_mod(args.xfer_file)
    xfer_name = resolve_xfer_name(get_fns(mlir_mod), args.xfer_name)
    xfer_fn = get_fns(mlir_mod)[xfer_name]
    arity = len(xfer_fn.args)

    domain, to_eval, df = _parse_inputs(args, arity)

    if args.eval:
        r = _run_eval(to_eval, mlir_mod, xfer_name)
        print(r)
    else:
        _run_enum(to_eval, domain, mlir_mod, xfer_name, df, args.output)


if __name__ == "__main__":
    main()
