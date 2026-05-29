from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser
from io import StringIO
from pathlib import Path
from random import Random, SystemRandom

from xdsl.printer import Printer

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.input_generation import generate_pattern_inputs
from synth_xfer._util.parse_mlir import lower_pattern_to_mlir
from synth_xfer._util.pattern import analyze_pattern, eval_pattern
from synth_xfer._util.pattern_dsl import PatternDag
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.tsv import EnumData
from synth_xfer.cli.args import int_tuple


def _gen_args(p: ArgumentParser):
    p.add_argument("--op", type=PatternDag, required=True, help="pattern expression")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    p.add_argument(
        "--mbw",
        nargs="*",
        type=int_tuple,
        default=[],
        help="Bitwidth specs as 'bw,samples' with ideal computation",
    )
    p.add_argument(
        "--hbw",
        nargs="*",
        type=int_tuple,
        default=[],
        help="Bitwidth specs as 'bw,samples' without ideal computation",
    )
    p.add_argument("-o", "--output", type=Path, required=True, help="Output TSV path")
    p.add_argument(
        "--data-dir",
        type=Path,
        default="input_data",
        help="Directory containing per-domain input TSVs",
    )
    p.add_argument(
        "--seed",
        type=int,
        help="Sampling seed used only for random input selection",
    )
    p.add_argument(
        "--sampling-alpha",
        type=float,
        default=0.7,
        help="Exponent applied to per-row counts before sampling",
    )
    p.add_argument(
        "--weight-beta",
        type=float,
        default=0.15,
        help="Exponent applied to the proposal probability when emitting row weights",
    )
    p.add_argument(
        "--timeout",
        type=int,
        default=10,
        help="Timeout in seconds for ideal computation",
    )
    p.add_argument(
        "--solver",
        type=SolverKind,
        choices=list(SolverKind),
        default=SolverKind.bitwuzla,
        help="SMT solver backend for ideal computation",
    )
    p.add_argument(
        "--max-failures",
        type=int,
        default=1000,
        help="Maximum consecutive duplicate/timeout rejections before failing",
    )
    p.add_argument(
        "--enforce-abs-op-constraint",
        action="store_true",
        help="Reject sampled inputs that do not satisfy the pattern's "
        "abs_op_constraint (rejection sampling). No-op if the pattern has none.",
    )


def main() -> None:
    p = ArgumentParser(
        prog="pattern",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    sub = p.add_subparsers(dest="command", required=True)

    analyze_parser = sub.add_parser(
        "analyze",
        formatter_class=ArgumentDefaultsHelpFormatter,
        help="Analyze forward/backward completeness of a pattern expression",
    )
    analyze_parser.add_argument(
        "--op", type=PatternDag, required=True, help="pattern expression"
    )
    analyze_parser.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain to evaluate",
    )

    _gen_args(
        sub.add_parser(
            "generate-input",
            formatter_class=ArgumentDefaultsHelpFormatter,
            help="Generate abstract inputs for a pattern expression",
        )
    )

    eval_parser = sub.add_parser(
        "eval",
        formatter_class=ArgumentDefaultsHelpFormatter,
        help="Evaluate a pattern transformer compared to LLVM",
    )
    eval_parser.add_argument("--composite-xfer", type=Path, help="Composite MLIR file")
    eval_parser.add_argument("--xfer-name", type=str, help="Name of composite function")
    eval_parser.add_argument(
        "-i",
        "--input",
        type=Path,
        required=True,
        help="path to enum TSV (use `pattern generate-input` to make this)",
    )
    eval_parser.add_argument("--bw", type=int, default=8, help="BW to use for eval")

    lift_parser = sub.add_parser(
        "lift",
        formatter_class=ArgumentDefaultsHelpFormatter,
        help="Lift a pattern expression to MLIR",
    )
    lift_parser.add_argument(
        "--op", type=PatternDag, required=True, help="pattern expression"
    )
    lift_parser.add_argument("-o", "--output", type=Path, help="Output MLIR path")

    args = p.parse_args()
    if args.command == "analyze":
        print(analyze_pattern(args.op, AbstractDomain[args.domain]))

    if args.command == "generate-input":
        rng = Random(SystemRandom().randrange(2**32) if args.seed is None else args.seed)
        generated_inputs, timeouts = generate_pattern_inputs(
            args.op,
            AbstractDomain[args.domain],
            args.mbw,
            args.hbw,
            data_dir=args.data_dir,
            rng=rng,
            sampling_alpha=args.sampling_alpha,
            weight_beta=args.weight_beta,
            timeout=args.timeout,
            max_failures=args.max_failures,
            solver_kind=args.solver,
            enforce_abs_op_constraint=args.enforce_abs_op_constraint,
        )
        generated_inputs.write_tsv(args.output)
        for bw, timeout in timeouts.items():
            if timeout:
                print(f"bw {bw} had {timeout} max-precise timeouts")

    if args.command == "eval":
        with args.input.open("r") as f:
            data = EnumData.read_tsv(f)

        (
            seq_sound,
            comp_sound,
            seq_exact,
            comp_exact,
            seq_dist,
            comp_dist,
            seq_norm,
            comp_norm,
        ) = eval_pattern(
            data.metadata.op,
            args.composite_xfer,
            args.xfer_name,
            data,
            args.bw,
        )

        # Dist is only meaningful when `best` is the true optimal, i.e. for
        # exhaustively-enumerated (mbw) bitwidths. hbw samples concretizations
        # and computes no ideal, so omit the column there.
        hbw_bws = {b for b, _, _ in data.metadata.hbw}
        if args.bw not in hbw_bws:

            def _dist_cell(sound: float, dist: float) -> str:
                # Dist is a clean imprecision measure only for a fully sound
                # result; for an unsound one it conflates imprecision with
                # unsoundness, so don't report a number.
                if sound >= 100.0 - 1e-9:
                    return f"{dist:.5f}"
                return "unsound"

            print(f"Type       | Sound % | Exact % |  Norm   |   Dist  (bw={args.bw})")
            print("-----------|---------|---------|---------|---------")
            print(
                f"LLVM Seq   | {seq_sound:6.2f}% | {seq_exact:6.2f}% | {seq_norm:7.5f} | {_dist_cell(seq_sound, seq_dist):>7}"
            )
            if args.composite_xfer:
                print(
                    f"Composite  | {comp_sound:6.2f}% | {comp_exact:6.2f}% | {comp_norm:7.5f} | {_dist_cell(comp_sound, comp_dist):>7}"
                )
        else:
            print(f"Type       | Sound % | Exact % |  Norm    (bw={args.bw})")
            print("-----------|---------|---------|---------")
            print(f"LLVM Seq   | {seq_sound:6.2f}% | {seq_exact:6.2f}% | {seq_norm:7.5f}")
            if args.composite_xfer:
                print(
                    f"Composite  | {comp_sound:6.2f}% | {comp_exact:6.2f}% | {comp_norm:7.5f}"
                )
    if args.command == "lift":
        stream = StringIO()
        Printer(stream=stream).print_op(lower_pattern_to_mlir(args.op))
        if args.output:
            args.output.write_text(stream.getvalue())
            args.output.write_text("\n")
        else:
            print(stream.getvalue())


if __name__ == "__main__":
    main()
