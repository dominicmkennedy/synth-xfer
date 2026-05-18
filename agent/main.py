#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import asyncio
from pathlib import Path
import sys

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.tsv import EnumData, resolve_dataset_op_path
from synth_xfer._util.xfer_data import enumdata_to_eval_inputs

from .args import parse_args
from .compress import run_compress_task
from .learn import run_library_learn_task, run_stitch_learn
from .synth import SynthesisAgent, run_synthesis_tasks
from .util import (
    CollectiveLibrary,
    EvalArgs,
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    extract_op_name,
    get_api_key,
    get_op_output_dir,
    load_initial_library,
)


def run_library_learning_loop(
    tasks: list[SynthesisTask],
    num_rounds: int,
    initial_library: LibraryState,
    args,
    api_key: str,
    eval_args_by_op: dict[str, EvalArgs],
) -> tuple[LibraryState, list[SynthesisResult]]:
    """Top-level loop: synthesize tasks, then improve library."""
    library = initial_library
    collective_library = CollectiveLibrary(results={})
    latest_results: list[SynthesisResult] = []

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Create one persistent agent per task (agent + tools built once).
    synth_agents = {
        task.op_name: SynthesisAgent(
            task,
            args,
            api_key,
            library,
            eval_args=eval_args_by_op[task.op_name],
        )
        for task in tasks
    }

    perfect_ops: set[str] = set()

    # Round 0 is synthesis-only (single-shot equivalent).
    for round_idx in range(num_rounds + 1):
        sep = "=" * 60
        print(f"\n{sep}\n ROUND {round_idx}\n")

        tasks_to_run = [t for t in tasks if t.op_name not in perfect_ops]
        for op_name in perfect_ops:
            print(f"[{op_name.upper()}] Skipping round {round_idx}: already perfect")
        latest_results = asyncio.run(
            run_synthesis_tasks(synth_agents, tasks_to_run, round_idx, args)
        )

        for r in latest_results:
            if r.is_sound and r.eval_result is not None and r.eval_result.is_perfect():
                perfect_ops.add(r.task.op_name)

        if args.meet:
            for result in latest_results:
                if result.solution_text is not None and result.is_sound:
                    synth_agents[result.task.op_name].solution_set.upd_solution(
                        result.solution_text
                    )
        else:
            for result in latest_results:
                if result.solution_text is not None:
                    solution_set = synth_agents[result.task.op_name].solution_set
                    solution_set.solutions = [result.solution_text]
                    solution_set._base_result_cache = None

        # Xuanyu: maybe when meet is enabled, not only the latest solution but the entire solution set should be sent to the library learning.
        if round_idx < num_rounds and not args.no_learn:
            if args.collective_learn:
                collective_library.update(latest_results)
            else:
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
                if args.collective_learn:
                    agent.update_library(
                        collective_library.to_library_state(mask=[agent._task.op_name])
                    )
                else:
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
            op_output_dir = get_op_output_dir(output_dir, op_name)
            final_solution_path = op_output_dir / "solution.mlir"
            final_solution_path.write_text(final_solution)
            print(f"[{op_name.upper()}] Final solution: {final_solution_path}")
        except Exception as e:
            print(f"[{op_name.upper()}] Failed to build final solution: {e}")

    return library, latest_results


def build_tasks_and_eval_args(
    args,
) -> tuple[list[SynthesisTask], dict[str, EvalArgs]]:
    """Build synthesis tasks and per-task EvalArgs from CLI args."""
    if not args.input:
        domain: AbstractDomain = args.domain_enum
        tasks: list[SynthesisTask] = []
        eval_args_by_op: dict[str, EvalArgs] = {}
        for op_file in args.op_file:
            op_name = extract_op_name(op_file)
            tasks.append(SynthesisTask(op_file=op_file, op_name=op_name))
            eval_args_by_op[op_name] = EvalArgs(
                op_path=Path(op_file),
                domain=domain,
                lbw=args.lbw,
                mbw=args.mbw,
                hbw=args.hbw,
                unsound_ex=5,
                imprecise_ex=5,
            )
        return tasks, eval_args_by_op

    tasks: list[SynthesisTask] = []
    eval_args_by_op: dict[str, EvalArgs] = {}
    seen_domain: AbstractDomain | None = None
    for input_path in args.input:
        with input_path.open("r", encoding="utf-8") as f:
            data = EnumData.read_tsv(f)

        if args.domain_enum is not None and data.metadata.domain != args.domain_enum:
            raise ValueError(
                f"--domain={args.domain_enum.name} does not match dataset "
                f"'{input_path}' metadata domain={data.metadata.domain.name}"
            )
        if seen_domain is None:
            seen_domain = data.metadata.domain
        elif data.metadata.domain != seen_domain:
            raise ValueError(
                f"--input datasets mix domains: {seen_domain.name} and "
                f"{data.metadata.domain.name} (from '{input_path}'). "
                "All --input TSVs in a single run must share one domain."
            )

        op_path = resolve_dataset_op_path(data.metadata.op)
        op_name = extract_op_name(str(op_path))
        if op_name in eval_args_by_op:
            raise ValueError(
                f"Duplicate op '{op_name}' inferred from --input datasets; each input TSV must target a distinct op"
            )

        task = SynthesisTask(op_file=str(op_path), op_name=op_name)
        eval_args = EvalArgs(
            op_path=op_path,
            domain=data.metadata.domain,
            lbw=data.metadata.lbw,
            mbw=data.metadata.mbw,
            hbw=data.metadata.hbw,
            unsound_ex=5,
            imprecise_ex=5,
            to_eval=enumdata_to_eval_inputs(data),
        )
        tasks.append(task)
        eval_args_by_op[op_name] = eval_args
    if seen_domain is not None:
        args.domain_enum = seen_domain
        args.domain = seen_domain.name
    return tasks, eval_args_by_op


def main():
    """Synthesize transformer using selected method."""
    args = parse_args()

    api_key = get_api_key()

    tasks, eval_args_by_op = build_tasks_and_eval_args(args)

    domain: AbstractDomain = args.domain_enum
    domain_examples_dir = args.examples_dir / domain.name
    if not domain_examples_dir.is_dir():
        raise ValueError(
            f"--examples-dir: missing per-domain subdirectory "
            f"{domain_examples_dir} for domain {domain.name}"
        )
    domain_fragment_path = args.domains_dir / f"{domain.name}.md"
    if not domain_fragment_path.is_file():
        raise ValueError(
            f"--domains-dir: missing fragment file {domain_fragment_path} "
            f"for domain {domain.name}"
        )

    initial_library = load_initial_library(args.library_dir, domain)

    final_library, latest_results = run_library_learning_loop(
        tasks,
        args.rounds,
        initial_library,
        args,
        api_key,
        eval_args_by_op,
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
