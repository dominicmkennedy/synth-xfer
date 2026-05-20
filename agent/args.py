"""Argument parsing for the synthesis agent."""

import argparse
from pathlib import Path

import yaml

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.tsv import EnumData


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


def _load_ops_from_bench(bench_path: Path, domain: AbstractDomain) -> list[str]:
    """Parse bench.yaml and return list of MLIR op file paths for `domain`."""
    with bench_path.open() as f:
        data = yaml.safe_load(f)
    if domain.name not in data:
        raise ValueError(
            f"bench.yaml has no top-level key '{domain.name}'. "
            f"Available keys: {sorted(data.keys())}"
        )
    cfg = data[domain.name] or {}
    return [
        str(Path("mlir/Operations") / f"{op_name}.mlir")
        for op_name in cfg.get("concrete_ops", [])
    ]


def _validate_args(parser: argparse.ArgumentParser, args: argparse.Namespace) -> None:
    for name, path in [
        ("--agent-instructions", args.agent_instructions),
        ("--meet-instructions", args.meet_instructions),
        ("--library-instructions", args.library_instructions),
        ("--autodoc-instructions", args.autodoc_instructions),
        ("--library-prompt", args.library_prompt),
        ("--spec", args.spec),
        ("--template", args.template),
    ]:
        if not path.exists():
            parser.error(f"{name}: path does not exist: {path}")

    if not args.examples_dir.is_dir():
        parser.error(f"--examples-dir: not a directory: {args.examples_dir}")

    if not args.domains_dir.is_dir():
        parser.error(f"--domains-dir: not a directory: {args.domains_dir}")

    if args.library_dir is not None and not args.library_dir.is_dir():
        parser.error(f"--library-dir: not a directory: {args.library_dir}")

    has_input = bool(args.input)
    has_benchmark = args.benchmark is not None
    has_op_file = bool(args.op_file)

    args.domain_enum = AbstractDomain[args.domain] if args.domain is not None else None

    if bool(args.collective_learn):
        if bool(args.stitch):
            parser.error("--stitch and --collective-learn are mutually exclusive")
        if bool(args.no_learn):
            parser.error("--no-learn and --collective-learn are mutually exclusive")

    if has_input:
        if has_benchmark:
            parser.error("--input and --benchmark are mutually exclusive")
        if has_op_file:
            parser.error("--input and op_file are mutually exclusive")
        for input_path in args.input:
            if not input_path.exists():
                parser.error(f"--input: path does not exist: {input_path}")

            try:
                with input_path.open(encoding="utf-8") as f:
                    EnumData.read_tsv(f)
            except Exception as e:
                parser.error(f"--input: failed to parse EnumData TSV '{input_path}': {e}")

        invalid_bw_flags: list[str] = []
        if args.lbw != [4]:
            invalid_bw_flags.append("--lbw")
        if args.mbw != [(8, 10000)]:
            invalid_bw_flags.append("--mbw")
        if args.hbw != []:
            invalid_bw_flags.append("--hbw")
        if invalid_bw_flags:
            parser.error(
                f"{', '.join(invalid_bw_flags)} cannot be used with --input; bitwidths come from dataset metadata"
            )
    else:
        if has_benchmark and has_op_file:
            parser.error("op_file and --benchmark are mutually exclusive")
        if not has_benchmark and not has_op_file:
            parser.error("provide op_file, --benchmark, or --input")
        if args.domain is None:
            parser.error(
                "--domain is required when using op_file or --benchmark "
                "(it is inferred from dataset metadata only with --input)"
            )

    if has_benchmark:
        if not args.benchmark.exists():
            parser.error(f"--benchmark: path does not exist: {args.benchmark}")
        assert args.domain_enum is not None
        try:
            args.op_file = _load_ops_from_bench(args.benchmark, args.domain_enum)
        except ValueError as e:
            parser.error(str(e))

    if args.compress is not None:
        if not args.compress_instructions.exists():
            parser.error(
                f"--compress-instructions: path does not exist: {args.compress_instructions}"
            )
        if not args.compress_prompt.exists():
            parser.error(
                f"--compress-prompt: path does not exist: {args.compress_prompt}"
            )

    for op_file in args.op_file:
        if not Path(op_file).exists():
            parser.error(f"op_file: path does not exist: {op_file}")

    if args.max_turns <= 0:
        parser.error("--max-turns: must be greater than 0")

    if args.domain_enum is not None:
        domain_examples_dir = args.examples_dir / args.domain_enum.name
        if not domain_examples_dir.is_dir():
            parser.error(
                f"--examples-dir: missing per-domain subdirectory "
                f"{domain_examples_dir} for domain {args.domain_enum.name}"
            )
        domain_fragment = args.domains_dir / f"{args.domain_enum.name}.md"
        if not domain_fragment.is_file():
            parser.error(
                f"--domains-dir: missing fragment file {domain_fragment} "
                f"for domain {args.domain_enum.name}"
            )


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
        "-i",
        "--input",
        type=Path,
        nargs="+",
        default=None,
        help="EnumData TSV input(s) used as evaluation dataset (one per op)",
    )
    parser.add_argument(
        "-d",
        "--domain",
        choices=[d.name for d in AbstractDomain],
        default=None,
        help=(
            "Abstract domain (e.g. KnownBits, UConstRange, SConstRange). "
            "Required with op_file or --benchmark; inferred from --input "
            "metadata (validated against this flag if also given)."
        ),
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument(
        "--synth-model",
        default="openai-responses:gpt-5.2-codex",
        help="Pydantic AI model string for synthesis (e.g. 'openai-responses:gpt-5.1-codex-mini', 'openai:gpt-4o', 'anthropic:claude-sonnet-4-5')",
    )
    parser.add_argument(
        "--library-model",
        default="openai-responses:gpt-5.1-codex-mini",
        help="Pydantic AI model string for library learning (same format as --synth-model)",
    )
    parser.add_argument(
        "--stitch",
        action="store_true",
        help="Run library learning with Stitch",
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
        "--autodoc-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "autodoc_instructions.md",
        help="Path to autodoc agent instructions file (default: agent/md/autodoc_instructions.md)",
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
        help=(
            "Path to examples root directory (default: agent/examples). "
            "Expected layout: <examples-dir>/<DomainName>/*.mlir for "
            "per-domain examples, plus <examples-dir>/shared/*.mlir for "
            "domain-agnostic operator-usage corpus."
        ),
    )
    parser.add_argument(
        "--domains-dir",
        type=Path,
        default=Path(__file__).parent / "md" / "domains",
        help=(
            "Path to per-domain prompt fragments directory "
            "(default: agent/md/domains). Each domain needs <DomainName>.md."
        ),
    )
    parser.add_argument(
        "--spec",
        type=Path,
        default=Path(__file__).parent / "md" / "spec.md",
        help="Path to spec.md file (default: agent/md/spec.md)",
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
        "--compress",
        action="store_true",
        help="Run a compress step after synthesis (default: compress is disabled)",
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
        "--collective-learn",
        action="store_true",
        help="Instead of library learning, just pass in previous round of transformers",
    )
    parser.add_argument(
        "--mock-synth",
        action="store_true",
        help=(
            "Skip synthesis agent; return the canonical top transformer "
            "from examples_dir/<DomainName>/top.mlir for fast pipeline testing."
        ),
    )
    parser.add_argument(
        "--no-learn",
        action="store_true",
        help="Skip the library learning step after each synthesis round",
    )
    args = parser.parse_args()
    _validate_args(parser, args)
    return args
