"""Argument parsing for the synthesis agent."""

import argparse
from pathlib import Path

import yaml


def _parse_bw_pair(s: str) -> tuple[int, int]:
    parts = [int(x.strip()) for x in s.split(",")]
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(f"Expected 'bw,samples', got: {s!r}")
    return (parts[0], parts[1])


def _parse_bw_triple(s: str) -> tuple[int, int, int]:
    parts = [int(x.strip()) for x in s.split(",")]
    if len(parts) != 3:
        raise argparse.ArgumentTypeError(f"Expected 'bw,lo,hi', got: {s!r}")
    return (parts[0], parts[1], parts[2])


def _load_ops_from_bench(bench_path: Path) -> list[str]:
    """Parse bench.yaml and return list of MLIR op file paths."""
    with bench_path.open() as f:
        data = yaml.safe_load(f)
    ops = []
    for _domain, cfg in data.items():
        for op_name in cfg.get("concrete_ops", []):
            ops.append(str(Path("mlir/Operations") / f"{op_name}.mlir"))
    return ops


def _validate_args(parser: argparse.ArgumentParser, args: argparse.Namespace) -> None:
    for name, path in [
        ("--agent-instructions", args.agent_instructions),
        ("--meet-instructions", args.meet_instructions),
        ("--library-instructions", args.library_instructions),
        ("--compress-instructions", args.compress_instructions),
        ("--library-prompt", args.library_prompt),
        ("--compress-prompt", args.compress_prompt),
        ("--ops", args.ops),
        ("--template", args.template),
    ]:
        if not path.exists():
            parser.error(f"{name}: path does not exist: {path}")

    if not args.examples_dir.is_dir():
        parser.error(f"--examples-dir: not a directory: {args.examples_dir}")

    if args.library_dir is not None and not args.library_dir.is_dir():
        parser.error(f"--library-dir: not a directory: {args.library_dir}")

    if args.benchmark is not None and args.op_file:
        parser.error("op_file and --benchmark are mutually exclusive")
    if args.benchmark is None and not args.op_file:
        parser.error("provide op_file or --benchmark")

    if args.benchmark is not None:
        if not args.benchmark.exists():
            parser.error(f"--benchmark: path does not exist: {args.benchmark}")
        args.op_file = _load_ops_from_bench(args.benchmark)

    for op_file in args.op_file:
        if not Path(op_file).exists():
            parser.error(f"op_file: path does not exist: {op_file}")

    if args.max_turns <= 0:
        parser.error("--max-turns: must be greater than 0")


def parse_args() -> argparse.Namespace:
    """Parse and validate command-line arguments."""
    parser = argparse.ArgumentParser(description="Synthesize transfer functions")
    parser.add_argument(
        "op_file",
        nargs="*",
        help="Operation MLIR file(s) (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "--benchmark",
        type=Path,
        default=None,
        metavar="YAML",
        help="Path to bench.yaml specifying ops per domain (mutually exclusive with op_file)",
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument("--skip-eval", action="store_true", help="Skip eval-final")
    parser.add_argument("--model", default="gpt-4", help="OpenAI model")
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=20,
        help="Max iterations for agent (default: 20, use 2-3 for fast dev)",
    )
    parser.add_argument(
        "--agent-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "agent_instructions.md",
        help="Path to agent instructions file (default: agent/md/agent_instructions.md)",
    )
    parser.add_argument(
        "--meet-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "meet_instructions.md",
        help="Path to agent instructions for meet mode (default: agent/md/meet_instructions.md)",
    )
    parser.add_argument(
        "--library-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "library_instructions.md",
        help="Path to library agent instructions file (default: agent/md/library_instructions.md)",
    )
    parser.add_argument(
        "--compress-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "compress_instructions.md",
        help="Path to compress agent instructions file (default: agent/md/compress_instructions.md)",
    )
    parser.add_argument(
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "md" / "library_prompt.md",
        help="Path to library learning prompt (default: agent/md/library_prompt.md)",
    )
    parser.add_argument(
        "--compress-prompt",
        type=Path,
        default=Path(__file__).parent / "md" / "compress_prompt.md",
        help="Path to compression prompt (default: agent/md/compress_prompt.md)",
    )
    parser.add_argument(
        "--examples-dir",
        type=Path,
        default=Path(__file__).parent / "examples",
        help="Path to examples directory (default: agent/examples)",
    )
    parser.add_argument(
        "--ops",
        type=Path,
        default=Path(__file__).parent / "md" / "ops.md",
        help="Path to ops.md file (default: agent/ops.md)",
    )
    parser.add_argument(
        "--template",
        type=Path,
        default=Path(__file__).parent / "template" / "template.mlir",
        help="Path to template.mlir file (default: agent/template.mlir)",
    )
    parser.add_argument(
        "--library-dir",
        type=Path,
        default=None,
        help="Optional initial library directory for library-learning workflow",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=0,
        help="Number of library-update rounds; 0 = synthesis-only pass (default: 2)",
    )
    parser.add_argument(
        "--no-parallel",
        dest="parallel",
        action="store_false",
        help="Run synthesis tasks sequentially within each round (default: parallel)",
    )
    parser.set_defaults(parallel=True)
    parser.add_argument(
        "--no-compress",
        action="store_true",
        help="Skip the compress step after synthesis (default: compress is enabled)",
    )
    parser.add_argument(
        "--lbw",
        type=int,
        nargs="*",
        default=[4],
        metavar="BW",
        help="Low (exact) bitwidth(s) for eval (default: 4)",
    )
    parser.add_argument(
        "--mbw",
        type=_parse_bw_pair,
        nargs="*",
        default=[(8, 10000)],
        metavar="BW,SAMPLES",
        help="Medium bitwidth(s) for eval as 'bw,samples' (default: 8,10000)",
    )
    parser.add_argument(
        "--hbw",
        type=_parse_bw_triple,
        nargs="*",
        default=[],
        metavar="BW,LO,HI",
        help="High bitwidth(s) for eval as 'bw,lo,hi' (default: none)",
    )
    parser.add_argument(
        "--meet",
        action="store_true",
        help="Accumulate solutions into a SolutionSet and combine via meet",
    )
    parser.add_argument(
        "--mock-synth",
        action="store_true",
        help="Skip synthesis agent; return a random example from examples_dir for fast pipeline testing",
    )
    parser.add_argument(
        "--no-learn",
        action="store_true",
        help="Skip the library learning step after each synthesis round",
    )
    args = parser.parse_args()
    _validate_args(parser, args)
    return args
