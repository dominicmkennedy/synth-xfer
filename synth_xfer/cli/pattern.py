from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser, ArgumentTypeError
from pathlib import Path
from random import Random, SystemRandom

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import (
    eval_pattern_exact,
    eval_pattern_norm,
)
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer._util.pattern import (
    CompletenessReport,
    analyze_pattern,
    construct_pattern_solution,
    generate_inputs,
)
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.xfer_data import (
    enumdata_to_eval_inputs,
    enumdata_to_run_inputs,
    namespace_module,
    resolve_xfer_name,
)


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


def _analyze_args(p: ArgumentParser):
    p.add_argument(
        "--pattern", type=Path, required=True, help="Pattern MLIR file to analyze"
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain to evaluate",
    )


def _seq_args(p: ArgumentParser):
    p.add_argument(
        "--pattern", type=Path, required=True, help="Pattern MLIR file to analyze"
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    p.add_argument(
        "--xfer-dir",
        type=Path,
        required=True,
        help="Directory containing component op solutions",
    )
    p.add_argument("-o", "--output", type=Path, help="Output mlir function")


def _gen_args(p: ArgumentParser):
    p.add_argument(
        "--pattern", type=Path, required=True, help="Pattern MLIR file to analyze"
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    p.add_argument(
        "--bw",
        nargs="+",
        type=_parse_bw_spec,
        required=True,
        help="Bitwidth specs as 'bw' or 'bw,samples'",
    )
    p.add_argument("-o", "--output", type=Path, required=True, help="Output TSV path")
    p.add_argument(
        "--data-dir",
        type=Path,
        required=True,
        help="Directory containing per-domain input TSVs",
    )
    p.add_argument(
        "--seed",
        type=int,
        help="Sampling seed used only for random input selection",
    )


def _eval_args(p: ArgumentParser):
    p.add_argument(
        "--sequential-xfer",
        type=Path,
        required=True,
        help="Sequential MLIR file (use `pattern make-sequential` to generate this)",
    )
    p.add_argument(
        "--composite-xfer", type=Path, required=True, help="Composite MLIR file"
    )
    p.add_argument("--xfer-name", type=str, help="Name of composite function")
    p.add_argument(
        "-i",
        "--input",
        type=Path,
        required=True,
        help="path to enum TSV (use `pattern generate-input` to make this)",
    )
    p.add_argument("--exact-bw", type=int, default=8, help="BW to use for exact eval")
    p.add_argument("--norm-bw", type=int, default=64, help="BW to use for norm eval")


def main() -> None:
    p = ArgumentParser(
        prog="pattern",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    sub = p.add_subparsers(dest="command", required=True)

    analyze_parser = sub.add_parser(
        "analyze", formatter_class=ArgumentDefaultsHelpFormatter
    )
    _analyze_args(analyze_parser)

    seq_parser = sub.add_parser(
        "make-sequential", formatter_class=ArgumentDefaultsHelpFormatter
    )
    _seq_args(seq_parser)

    gen_parser = sub.add_parser(
        "generate-input", formatter_class=ArgumentDefaultsHelpFormatter
    )
    _gen_args(gen_parser)

    eval_parser = sub.add_parser(
        "eval",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    _eval_args(eval_parser)

    args = p.parse_args()
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

    if args.command == "make-sequential":
        fn = construct_pattern_solution(
            args.pattern, args.xfer_dir, AbstractDomain[args.domain]
        )
        if args.output:
            args.output.write_text(str(fn))
        else:
            print(fn)
    if args.command == "eval":
        raw_seq_mod = parse_mlir_mod(args.sequential_xfer)
        seq_mod = namespace_module(raw_seq_mod, "seq")
        seq_xfer_name = "seq_solution"
        comp_mod = parse_mlir_mod(args.composite_xfer)
        comp_xfer_name = resolve_xfer_name(get_fns(comp_mod), args.xfer_name)

        with args.input.open("r") as f:
            data = EnumData.read_tsv(f)

        if args.exact_bw not in [x[0] for x in data.metadata.mbw + data.metadata.hbw]:
            raise ValueError(f"Exact BW {args.exact_bw} not in Enum TSV")
        if args.norm_bw not in [x[0] for x in data.metadata.mbw + data.metadata.hbw]:
            raise ValueError(f"Norm BW {args.norm_bw} not in Enum TSV")

        exact_to_eval = enumdata_to_eval_inputs(data)[args.exact_bw]
        tmp_weights = [1 for _ in range(len(exact_to_eval))]
        norm_to_eval = enumdata_to_run_inputs(data)[args.norm_bw]
        lowerer = LowerToLLVM(sorted({args.exact_bw, args.norm_bw}))
        lowerer.add_mod(seq_mod, [seq_xfer_name])
        lowerer.add_mod(comp_mod, [comp_xfer_name])

        with Jit() as jit:
            jit.add_mod(lowerer)
            seq_exact, comp_exact = eval_pattern_exact(
                exact_to_eval,
                tmp_weights,
                jit.get_fn_ptr(f"{seq_xfer_name}_{args.exact_bw}_shim"),
                jit.get_fn_ptr(f"{comp_xfer_name}_{args.exact_bw}_shim"),
            )

            seq_norm, comp_norm = eval_pattern_norm(
                norm_to_eval,
                tmp_weights,
                jit.get_fn_ptr(f"{seq_xfer_name}_{args.norm_bw}_shim"),
                jit.get_fn_ptr(f"{comp_xfer_name}_{args.norm_bw}_shim"),
            )

        print("Type       | Exact % | Norm Score")
        print("-----------|---------|-------------")
        print(f"Sequential | {seq_exact}% | {seq_norm}")
        print(f"Composite  | {comp_exact}% | {comp_norm}")


if __name__ == "__main__":
    main()
