from argparse import ArgumentParser, Namespace
from pathlib import Path

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import RunInputMap, parse_to_run_inputs, run_xfer_fns
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.xfer_data import (
    PreparedCandidates,
    enumdata_to_run_inputs,
    load_file_candidates,
    prepare_exec_module,
)


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument(
        "--xfer-file",
        type=Path,
        nargs="+",
        required=True,
        help="Transformer MLIR file(s)",
    )
    p.add_argument("--xfer-name", type=str, help="Transformer to evaluate")
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument("--args", type=str, help="The abstract arguments for args apply mode")
    p.add_argument("--bw", type=int, help="Bitwidth for args apply mode")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain for args apply mode",
    )

    args = p.parse_args()
    _validate_args(args, p)
    return args


def _validate_args(args: Namespace, p: ArgumentParser) -> None:
    for f in args.xfer_file:
        if not f.is_file():
            p.error(f"--xfer-file expects files, got: {f}")

    if args.input is not None:
        if args.bw is not None:
            p.error("--bw cannot be used with --input")
        if args.domain is not None:
            p.error("--domain cannot be used with --input")
        if args.args is not None:
            p.error("--args cannot be used with --input")
    else:
        if args.bw is None or args.domain is None or args.args is None:
            p.error("args apply mode requires --bw, --args, and --domain")


def _run_apply(
    prepared: PreparedCandidates,
    helper_funcs,
    domain: AbstractDomain,
    to_eval: RunInputMap,
    df: pd.DataFrame,
    output: Path | None,
) -> None:
    run_outputs = run_xfer_fns(
        domain,
        to_eval,
        prepare_exec_module(prepared.merged_mod.clone(), helper_funcs),
        prepared.xfer_names,
    )

    out_df = df.copy()
    if len(prepared.labels) == 1:
        outputs = run_outputs[0]
        out_df["output"] = outputs
        out_df["norm"] = [x.norm() for x in outputs]
    else:
        for i, key in enumerate(prepared.labels):
            outputs = run_outputs[i]
            out_df[f"{key}_output"] = outputs
            out_df[f"{key}_norm"] = [x.norm() for x in outputs]

    if output is None:
        with pd.option_context("display.max_rows", None, "display.max_columns", None):
            print(out_df.to_string(index=False))
    else:
        with output.open("w") as f:
            out_df.to_csv(f, sep="\t", index=False)


def main() -> None:
    args = _register_parser()
    candidates = load_file_candidates(args.xfer_file, args.xfer_name)
    prepared = PreparedCandidates.from_candidates(candidates)
    data: EnumData | None = None

    if args.input is not None:
        with args.input.open("r", encoding="utf-8") as f:
            data = EnumData.read_tsv(f)
        if prepared.arity != data.metadata.arity:
            raise ValueError(
                f"Candidate arity {prepared.arity} does not match dataset arity {data.metadata.arity}"
            )

        domain, df = data.metadata.domain, data.enumdata
        to_eval = enumdata_to_run_inputs(data)
    else:
        domain = AbstractDomain[args.domain]
        fn_args = [tuple(x.strip() for x in args.args.split(";"))]
        to_eval: RunInputMap = {
            args.bw: parse_to_run_inputs(domain, args.bw, prepared.arity, fn_args)
        }
        df = pd.DataFrame({f"arg_{n}": [x] for n, x in enumerate(fn_args[0])})

    helper_funcs = get_helper_funcs(args.op, domain)
    _run_apply(prepared, helper_funcs, domain, to_eval, df, args.output)


if __name__ == "__main__":
    main()
