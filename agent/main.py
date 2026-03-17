#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import asyncio
from pathlib import Path
import sys

from .args import parse_args
from .compress import run_compress_task
from .learn import run_library_learn_task
from .synth import SynthesisAgent, run_synthesis_tasks
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    extract_op_name,
    get_api_key,
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

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write initial library to disk so get_library_text() has a file on round 0.
    current_lib_path = output_dir / "library_current.mlir"
    current_lib_path.write_text(library.functions_text, encoding="utf-8")

    # Create one persistent agent per task (agent + tools built once).
    synth_agents = {
        task.op_name: SynthesisAgent(task, args, api_key, current_lib_path)
        for task in tasks
    }

    # Round 0 is synthesis-only (single-shot equivalent).
    for round_idx in range(num_rounds + 1):
        latest_results = asyncio.run(
            run_synthesis_tasks(synth_agents, tasks, round_idx, library, args)
        )
        if round_idx < num_rounds:
            library = run_library_learn_task(
                version=round_idx + 1,
                previous_library=library,
                synthesis_results=latest_results,
                args=args,
                api_key=api_key,
            )
        if not args.no_compress:
            new_results: list[SynthesisResult] = []
            for result in latest_results:
                new_result = run_compress_task(result, library, round_idx, args, api_key)
                new_results.append(new_result)
            latest_results = new_results
    return library, latest_results


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
