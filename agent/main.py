#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import asyncio
import os
from pathlib import Path
import sys

from .args import parse_args
from .learn import run_library_learn
from .synth import run_synthesis_tasks
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
        latest_results = asyncio.run(
            run_synthesis_tasks(tasks, round_idx, library, args, api_key)
        )
        if round_idx < num_rounds:
            library = run_library_learn(
                version=round_idx + 1,
                previous_library=library,
                synthesis_results=latest_results,
                args=args,
                api_key=api_key,
            )

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
    args = parse_args()

    api_key = get_api_key()

    tasks = [
        SynthesisTask(op_file=op_file, op_name=extract_op_name(op_file))
        for op_file in args.op_file
    ]
    initial_library = load_initial_library(args.library)

    final_library, latest_results = run_library_learning_loop(
        tasks, args.rounds, initial_library, args, api_key
    )
    print(
        f"Library learning complete: version={args.rounds}, "
        f"latest_results={len(latest_results)}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
