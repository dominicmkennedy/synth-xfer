#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import asyncio
from pathlib import Path
import re
import sys

from .args import parse_args
from .compress import run_compress_task
from .learn import run_library_learn_task, run_stitch_learn
from .synth import SynthesisAgent, run_synthesis_tasks
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    extract_op_name,
    get_api_key,
    load_initial_library,
)


def _is_fully_sound(eval_summary: str | None) -> bool:
    """Return True if eval_summary reports Sound % = 100."""
    if not eval_summary:
        return False
    m = re.search(r"Sound %:\s*([\d.]+)", eval_summary)
    return m is not None and float(m.group(1)) == 100.0


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

    # Create one persistent agent per task (agent + tools built once).
    synth_agents = {
        task.op_name: SynthesisAgent(task, args, api_key, library) for task in tasks
    }

    # Round 0 is synthesis-only (single-shot equivalent).
    for round_idx in range(num_rounds + 1):
        sep = "=" * 60
        print(f"\n{sep}\n ROUND {round_idx}\n")

        tasks_to_run: list[SynthesisTask] = []
        for task in tasks:
            agent = synth_agents[task.op_name]
            # Xuanyu's TODO: skip if the solution set is already perfect
            tasks_to_run.append(task)
        latest_results = asyncio.run(
            run_synthesis_tasks(synth_agents, tasks_to_run, round_idx, library, args)
        )

        if args.meet:
            for result in latest_results:
                if result.solution_text != "NO_IMPROVEMENT" and _is_fully_sound(
                    result.eval_summary
                ):
                    synth_agents[result.task.op_name].solution_set.upd_solution(
                        result.solution_text
                    )
        else:
            for result in latest_results:
                solution_set = synth_agents[result.task.op_name].solution_set
                solution_set.solutions = [result.solution_text]
                solution_set._base_result_cache = None

        # Xuanyu: maybe when meet is enabled, not only the latest solution but the entire solution set should be sent to the library learning.
        if round_idx < num_rounds and not args.no_learn:
            if args.stitch:
                library = run_stitch_learn(
                    version=round_idx + 1,
                    previous_library=library,
                    synthesis_results=latest_results,
                    max_instructions=5,
                    top_k=5,
                    args=args,
                    api_key=api_key,
                )
            else:
                library = run_library_learn_task(
                    version=round_idx + 1,
                    previous_library=library,
                    synthesis_results=latest_results,
                    args=args,
                    api_key=api_key,
                )
            for agent in synth_agents.values():
                agent.update_library(library)
            if args.compress:
                new_results: list[SynthesisResult] = []
                for result in latest_results:
                    new_result = run_compress_task(
                        result,
                        library,
                        round_idx,
                        args,
                        api_key,
                        eval_args=synth_agents[result.task.op_name]._eval_args,
                    )
                    new_results.append(new_result)
                latest_results = new_results

    for op_name, agent in synth_agents.items():
        try:
            final_solution = agent.solution_set.build_final_solution()
            final_solution_path = output_dir / f"final_solution_{op_name.lower()}.mlir"
            final_solution_path.write_text(final_solution)
            print(f"[{op_name.upper()}] Final solution: {final_solution_path}")
        except Exception as e:
            print(f"[{op_name.upper()}] Failed to build final solution: {e}")

    return library, latest_results


def main():
    """Synthesize transformer using selected method."""
    args = parse_args()

    api_key = get_api_key()

    tasks = [
        SynthesisTask(op_file=op_file, op_name=extract_op_name(op_file))
        for op_file in args.op_file
    ]
    initial_library = load_initial_library(args.library_dir)

    final_library, latest_results = run_library_learning_loop(
        tasks, args.rounds, initial_library, args, api_key
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
