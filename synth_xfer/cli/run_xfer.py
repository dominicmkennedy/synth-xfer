from argparse import ArgumentParser, Namespace
from contextlib import nullcontext
from io import StringIO
from pathlib import Path
from sys import stdin, stdout

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import RunInputMap, parse_to_run_inputs, run_xfer_fns
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.xfer_data import (
    enumdata_to_run_inputs,
    load_file_candidates,
)
from synth_xfer.cli.args import PreparedCandidates


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
    p.add_argument("--bw", type=int, help="Bitwidth for stdin apply mode")

    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )

    args = p.parse_args()
    _validate_args(args, p)
    return args


def _validate_args(args: Namespace, p: ArgumentParser) -> None:
    for f in args.xfer_file:
        if not f.is_file():
            p.error(f"--xfer-file expects files, got: {f}")

    using_input = args.input is not None
    using_stdin = args.input is None

    if using_input:
        if args.bw is not None:
            p.error("--bw cannot be used with --input")
    elif using_stdin:
        if args.bw is None or args.domain is None:
            p.error("stdin apply mode requires both --bw and --domain")


def _run_apply(
    prepared: PreparedCandidates,
    domain: AbstractDomain,
    to_eval: RunInputMap,
    df: pd.DataFrame,
    output: Path | None,
) -> None:
    run_outputs = run_xfer_fns(
        domain,
        to_eval,
        prepared.merged_mod,
        prepared.xfer_names,
    )

    out_df = df.copy()
    if len(prepared.labels) == 1:
        outputs = run_outputs[0]
        out_df["output"] = outputs
        out_df["size"] = [x.size() for x in outputs]
    else:
        for i, key in enumerate(prepared.labels):
            outputs = run_outputs[i]
            out_df[f"{key}_output"] = outputs
            out_df[f"{key}_size"] = [x.size() for x in outputs]

    out_ctx = nullcontext(stdout) if output is None else output.open("w")
    with out_ctx as out_f:
        if output is None:
            with pd.option_context("display.max_rows", None, "display.max_columns", None):
                print(out_df.to_string(index=False), file=out_f)
        else:
            out_df.to_csv(out_f, sep="\t", index=False)


def _parse_stdin_inputs(
    args: Namespace, arity: int
) -> tuple[AbstractDomain, RunInputMap, pd.DataFrame]:
    assert args.bw is not None
    assert args.domain is not None
    domain = AbstractDomain[args.domain]
    df = pd.read_csv(StringIO(stdin.read()), sep="\t")
    in_strs = [tuple(x) for x in df.astype(str).itertuples(index=False, name=None)]
    to_eval: RunInputMap = {args.bw: parse_to_run_inputs(domain, args.bw, arity, in_strs)}
    return domain, to_eval, df


def main() -> None:
    args = _register_parser()
    candidates = load_file_candidates(
        args.xfer_file,
        args.xfer_name,
    )
    prepared = PreparedCandidates.from_candidates(candidates)

    if args.input is not None:
        with args.input.open("r", encoding="utf-8") as f:
            data = EnumData.read_tsv(f)
        if prepared.arity != data.metadata.arity:
            raise ValueError(
                f"Candidate arity {prepared.arity} does not match dataset arity {data.metadata.arity}"
            )
        domain = data.metadata.domain
        to_eval = enumdata_to_run_inputs(data)
        df = data.enumdata
    else:
        domain, to_eval, df = _parse_stdin_inputs(args, prepared.arity)

    _run_apply(prepared, domain, to_eval, df, args.output)


if __name__ == "__main__":
    main()
