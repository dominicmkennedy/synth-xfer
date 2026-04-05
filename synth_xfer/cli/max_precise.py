from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    Namespace,
)
from dataclasses import replace
from multiprocessing import Pool
from pathlib import Path

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.max_precise import RowTask, compute_max_precise, process_row
from synth_xfer._util.tsv import EnumData


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("--op", type=Path, help="path to op or pattern")
    p.add_argument("-i", "--input", type=Path, help="path to enum TSV")
    p.add_argument("-o", "--output", type=Path, help="output TSV path")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )
    p.add_argument("--args", type=str, help="The abstract arguments")
    p.add_argument("--bw", type=int, help="Bitwidth")
    p.add_argument("--timeout", type=int, help="z3 timeout", default=10)

    args = p.parse_args()
    if args.input is not None:
        invalid_flags: list[str] = []
        if args.op is not None:
            invalid_flags.append("--op")
        if args.domain is not None:
            invalid_flags.append("--domain")
        if args.args is not None:
            invalid_flags.append("--args")
        if args.bw is not None:
            invalid_flags.append("--bw")
        if invalid_flags:
            p.error(f"{', '.join(invalid_flags)} cannot be used with --input")
        return args

    missing_flags: list[str] = []
    if args.op is None:
        missing_flags.append("--op")
    if args.domain is None:
        missing_flags.append("--domain")
    if args.args is None:
        missing_flags.append("--args")
    if args.bw is None:
        missing_flags.append("--bw")
    if missing_flags:
        p.error(f"missing required arguments: {', '.join(missing_flags)}")
    if args.output is not None:
        p.error("--output can only be used with --input")
    return args


def _resolve_metadata_op(op: str) -> Path:
    if op.startswith("pattern_"):
        return Path("mlir") / "Patterns" / f"{op.removeprefix('pattern_')}.mlir"
    return Path("mlir") / "Operations" / f"{op}.mlir"


def _comment_row(row: pd.Series, columns: list[str]) -> str:
    return "# " + "\t".join(str(row[column]) for column in columns)


def _fill_hbw_rows(data: EnumData, timeout: int) -> tuple[EnumData, list[str]]:
    op_path = _resolve_metadata_op(data.metadata.op)
    hbw_bws = {bw for bw, _, _ in data.metadata.hbw}
    arg_cols = [f"arg_{i}" for i in range(data.metadata.arity)]
    tasks = [
        RowTask(
            index=int(index),  # type: ignore
            op_path=op_path,
            domain=data.metadata.domain,
            bw=int(row["bw"]),  # type: ignore
            args_str=",".join(str(row[col]) for col in arg_cols),
            timeout=timeout,
        )
        for index, row in data.enumdata.iterrows()
        if int(row["bw"]) in hbw_bws  # type: ignore
    ]

    if not tasks:
        return data, []

    with Pool() as pool:
        results = pool.map(process_row, tasks)

    df = data.enumdata.copy()
    columns = list(df.columns)
    commented_rows: list[str] = []
    timed_out_indexes: list[int] = []

    for result in results:
        if result.timed_out:
            row = df.loc[result.index]
            print(
                f"timeout: row={result.index + 2} bw={row['bw']} args="
                + ",".join(str(row[col]) for col in arg_cols)
            )
            commented_rows.append(_comment_row(row, columns))
            timed_out_indexes.append(result.index)
            continue

        assert result.ideal is not None
        df.at[result.index, "ideal"] = result.ideal

    if timed_out_indexes:
        df = df.drop(index=timed_out_indexes).reset_index(drop=True)

    completed_hbw = sorted(hbw_bws)
    preserved_mbw = [entry for entry in data.metadata.mbw if entry[0] not in hbw_bws]
    generated_mbw = [(bw, int((df["bw"] == bw).sum())) for bw in completed_hbw]
    metadata = replace(
        data.metadata,
        mbw=preserved_mbw + generated_mbw,
        hbw=[],
    )

    return EnumData(metadata, df), commented_rows


def _run_input_mode(args: Namespace) -> None:
    assert args.input is not None
    with args.input.open() as f:
        data = EnumData.read_tsv(f)

    updated, commented_rows = _fill_hbw_rows(data, args.timeout)
    output_path = args.input if args.output is None else args.output
    updated.write_tsv_with_comments(output_path, commented_rows)


def _run_single_mode(args: Namespace) -> None:
    assert args.op is not None
    assert args.domain is not None
    assert args.args is not None
    assert args.bw is not None
    print(
        compute_max_precise(
            args.op,
            AbstractDomain[args.domain],
            args.bw,
            tuple(args.args.split(",")),
            args.timeout,
        )
    )


def main() -> None:
    args = _get_args()
    if args.input is not None:
        _run_input_mode(args)
    else:
        _run_single_mode(args)


if __name__ == "__main__":
    main()
