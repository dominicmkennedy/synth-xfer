"""Argument parsing for the synthesis agent."""

import argparse
from pathlib import Path


def _validate_args(parser: argparse.ArgumentParser, args: argparse.Namespace) -> None:
    for name, path in [
        ("--agent-instructions", args.agent_instructions),
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

    if args.library is not None and not args.library.exists():
        parser.error(f"--library: path does not exist: {args.library}")

    for op_file in args.op_file:
        if not Path(op_file).exists():
            parser.error(f"op_file: path does not exist: {op_file}")


def parse_args() -> argparse.Namespace:
    """Parse and validate command-line arguments."""
    parser = argparse.ArgumentParser(description="Synthesize transfer functions")
    parser.add_argument(
        "op_file",
        nargs="+",
        help="Operation MLIR file(s) (e.g., mlir/Operations/Add.mlir)",
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
        "--library",
        type=Path,
        default=None,
        help="Optional initial library file for library-learning workflow",
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

    args = parser.parse_args()
    _validate_args(parser, args)
    return args
