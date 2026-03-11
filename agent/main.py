#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import argparse
import os
from pathlib import Path
import sys

from .learn import run_library_learn
from .synth import run_single_synthesis_task
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    extract_op_name,
    load_initial_library,
)


def run_library_learning_loop(
    tasks: list[SynthesisTask],
    num_rounds: int,
    initial_library: LibraryState,
    args,
    api_key: str,
) -> tuple[LibraryState, list[SynthesisResult]]:
    """Top-level loop: synthesize tasks, then improve library."""
    library = initial_library
    latest_results: list[SynthesisResult] = []

    # Round 0 is synthesis-only (single-shot equivalent).
    for round_idx in range(num_rounds + 1):
        latest_results = []
        for task in tasks:
            result = run_single_synthesis_task(task, library, args, api_key)
            latest_results.append(result)
        if round_idx < num_rounds:
            library = run_library_learn(library, latest_results, args, api_key)

    return library, latest_results


def get_api_key() -> str:
    """Get API key from env var or file."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_file = Path(__file__).parent / "api_key.txt"
        if api_file.exists():
            api_key = api_file.read_text().strip()
    if not api_key:
        raise ValueError(
            "API key not found. Set OPENAI_API_KEY or create agent/api_key.txt"
        )
    return api_key


def main():
    """Synthesize transformer using selected method."""
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
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "md" / "library_prompt.md",
        help="Path to library learning prompt template (default: agent/md/library_prompt.md)",
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

    args = parser.parse_args()
    api_key = get_api_key()

    tasks = [SynthesisTask(op_file, extract_op_name(op_file)) for op_file in args.op_file]
    initial_library = load_initial_library(args.library)

    final_library, latest_results = run_library_learning_loop(
        tasks, args.rounds, initial_library, args, api_key
    )
    print(
        f"Library learning complete: version={final_library.version}, "
        f"latest_results={len(latest_results)}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
