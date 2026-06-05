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
from synth_xfer._util.max_precise import (
    RowProcessor,
    RowTask,
    SequentialMaxPreciseAnalysis,
    compute_max_precise,
    sequential_max_precise,
)
from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternRef,
    format_pattern_ref,
)
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.tsv import EnumData


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("--op", type=PatternDag, help="op or pattern expression")
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
    p.add_argument(
        "--sequential",
        action="store_true",
        help="compute the most precise result from sequential evaluation",
    )
    p.add_argument("--timeout", type=int, help="solver timeout", default=10)
    p.add_argument(
        "--solver",
        type=SolverKind,
        choices=list(SolverKind),
        default=SolverKind.bitwuzla,
        help="SMT solver backend",
    )

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
        if args.sequential:
            invalid_flags.append("--sequential")
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


def _comment_row(row: pd.Series, columns: list[str]) -> str:
    return "# " + "\t".join(str(row[column]) for column in columns)


def _format_node(
    pattern: PatternDag,
    analysis: SequentialMaxPreciseAnalysis,
    node_index: int,
) -> str:
    node = pattern.nodes[node_index]
    operands = ", ".join(format_pattern_ref(operand) for operand in node.operands)
    ref = NodeRef(node_index)
    return (
        f"n{node_index} = {node.op.value}({operands}) "
        f"comp={analysis.comp_values[ref]} seq={analysis.seq_values[ref]}"
    )


def _format_ref_expr(pattern: PatternDag, ref: PatternRef) -> str:
    if isinstance(ref, ArgRef):
        return format_pattern_ref(ref)

    assert isinstance(ref, NodeRef)
    node = pattern.nodes[ref.index]
    operands = ", ".join(_format_ref_expr(pattern, operand) for operand in node.operands)
    return f"{node.op.value}({operands})"


def _format_seq_analysis(
    pattern: PatternDag,
    analysis: SequentialMaxPreciseAnalysis,
) -> str:
    def cut_value(label: str, comp: str, seq: str) -> str:
        if comp == seq:
            return f"{label}={comp}"
        return f"{label}={comp}/{seq}"

    lines = [
        f"composite:  {analysis.composite}",
        f"sequential: {analysis.sequential}",
        "",
        "Edge Analysis:",
    ]

    edges_by_dest = {i: [] for i, _ in enumerate(pattern.nodes)}
    for edge in analysis.edges:
        edges_by_dest[edge.dest.index].append(edge)
    source_width = max(
        (len(format_pattern_ref(edge.source)) for edge in analysis.edges),
        default=0,
    )
    dest_width = max(
        (
            len(cut_value("dest", edge.dest_cut_comp, edge.dest_cut_seq))
            for edge in analysis.edges
        ),
        default=0,
    )

    for node_index, edges in edges_by_dest.items():
        if node_index:
            lines.append("")
        lines.append(f"    {_format_node(pattern, analysis, node_index)}")
        for edge in edges:
            source = format_pattern_ref(edge.source)
            dest = cut_value("dest", edge.dest_cut_comp, edge.dest_cut_seq)
            root = cut_value("root", edge.root_cut_comp, edge.root_cut_seq)
            lines.append(
                f"      {source:<{source_width}} : {edge.local_kind.value:<13} "
                f"{dest:<{dest_width}} {root}"
            )

    lines.extend(["", "Smallest Divergent Patterns:"])
    if not analysis.minimal_divergences:
        lines.append("  (none)")
    for divergence in analysis.minimal_divergences:
        lines.append(
            f"  {format_pattern_ref(divergence.ref)} = "
            f"{_format_ref_expr(pattern, divergence.ref)}"
        )
        lines.append(f"    composite:  {divergence.composite}")
        lines.append(f"    sequential: {divergence.sequential}")

    return "\n".join(lines)


def _fill_hbw_rows(
    data: EnumData,
    timeout: int,
    solver_kind: SolverKind,
) -> tuple[EnumData, list[str]]:
    hbw_bws = {bw for bw, _, _ in data.metadata.hbw}
    arg_cols = [f"arg_{i}" for i in range(data.metadata.arity)]
    tasks = [
        RowTask(
            index=int(index),  # type: ignore
            bw=int(row["bw"]),  # type: ignore
            args=tuple(str(row[col]) for col in arg_cols),
        )
        for index, row in data.enumdata.iterrows()
        if int(row["bw"]) in hbw_bws  # type: ignore
    ]

    with Pool() as pool:
        results = pool.map(
            RowProcessor(data.metadata.op, data.metadata.domain, timeout, solver_kind),
            tasks,
        )

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


def main() -> None:
    args = _get_args()
    if args.input is not None:
        with args.input.open() as f:
            data = EnumData.read_tsv(f)

        updated, commented_rows = _fill_hbw_rows(data, args.timeout, args.solver)
        output_path = args.input if args.output is None else args.output
        updated.write_tsv_with_comments(output_path, commented_rows)
    else:
        fn_args: tuple[str, ...] = tuple(x.strip() for x in args.args.split(";"))
        domain = AbstractDomain[args.domain]
        if args.sequential:
            seq_analysis = sequential_max_precise(
                args.op,
                domain,
                args.bw,
                fn_args,
                args.timeout,
                args.solver,
            )
            print(_format_seq_analysis(args.op, seq_analysis))
        else:
            max_prec = compute_max_precise(
                args.op,
                domain,
                args.bw,
                fn_args,
                args.timeout,
                args.solver,
            )
            print(max_prec)


if __name__ == "__main__":
    main()
