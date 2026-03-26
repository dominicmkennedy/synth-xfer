from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser, ArgumentTypeError
from pathlib import Path
from random import Random, SystemRandom

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import CompletenessReport, analyze_pattern, generate_inputs


def _parse_bw_spec(text: str) -> tuple[int, int | None]:
    parts = [part.strip() for part in text.split(",")]
    try:
        if len(parts) == 1:
            return (int(parts[0]), None)
        if len(parts) == 2:
            return (int(parts[0]), int(parts[1]))
    except ValueError as e:
        raise ArgumentTypeError(str(e))
    raise ArgumentTypeError(f"Invalid bw spec '{text}'. Expected 'bw' or 'bw,samples'.")


def _format_report(report: CompletenessReport) -> str:
    lines = [
        f"Pattern:   {report.dag.expression}",
        f"Coincide:  {'True' if report.coincides else 'False'}",
        f"SSA Reuse: {'True' if report.reuse else 'False'}",
        "Complete Edges:",
    ]
    edge_map = dict(report.edges)
    for i, node in enumerate(report.dag.nodes):
        if i:
            lines.append("")
        lines.append(f"  n{i} = {node.operation}({', '.join(node.operands)})")
        for operand in node.operands:
            if not operand.startswith("n"):
                continue
            producer_idx = int(operand.removeprefix("n"))
            producer = report.dag.nodes[producer_idx]
            edge = f"n{producer_idx}({producer.operation}) -> n{i}({node.operation})"
            is_complete = edge_map[edge]
            lines.append(f"    {operand} : {'complete' if is_complete else 'incomplete'}")
    return "\n".join(lines)


def main() -> None:
    parser = ArgumentParser(
        prog="pattern",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    analyze_parser = subparsers.add_parser(
        "analyze",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    analyze_parser.add_argument(
        "--pattern", type=Path, required=True, help="Pattern MLIR file to analyze"
    )
    analyze_parser.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain to evaluate",
    )

    gen_parser = subparsers.add_parser(
        "generate-input",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    gen_parser.add_argument(
        "--pattern", type=Path, required=True, help="Pattern MLIR file to analyze"
    )
    gen_parser.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    gen_parser.add_argument(
        "--bw",
        nargs="+",
        type=_parse_bw_spec,
        required=True,
        help="Bitwidth specs as 'bw' or 'bw,samples'",
    )
    gen_parser.add_argument(
        "-o", "--output", type=Path, required=True, help="Output TSV path"
    )
    gen_parser.add_argument(
        "--data-dir",
        type=Path,
        required=True,
        help="Directory containing per-domain input TSVs",
    )
    gen_parser.add_argument(
        "--seed",
        type=int,
        help="Sampling seed used only for random input selection",
    )

    args = parser.parse_args()
    if args.command == "analyze":
        print(_format_report(analyze_pattern(args.pattern, AbstractDomain[args.domain])))

    if args.command == "generate-input":
        rng = Random(SystemRandom().randrange(2**32) if args.seed is None else args.seed)
        generated_inputs = generate_inputs(
            args.pattern,
            AbstractDomain[args.domain],
            args.bw,
            data_dir=args.data_dir,
            rng=rng,
        )
        generated_inputs.write_tsv(args.output)


if __name__ == "__main__":
    main()
