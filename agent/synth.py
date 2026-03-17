"""Synthesis workflow helpers."""

import asyncio
import json
from pathlib import Path
import time
from typing import Any

from agents import Agent, Runner, function_tool

from synth_xfer._util.domain import AbstractDomain

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    clean_llm_output,
    eval_transformer,
    merge_library_text,
    print_token_usage,
    save_file,
)


def _make_initial_prompt(task: SynthesisTask) -> str:
    return f"Synthesize the KnownBits transfer function for operation {task.op_name} (file: {task.op_file})."


def build_agent_instructions(
    template: str,
    op_name: str,
    op_file: str,
) -> str:
    """Instantiate agent_instructions.md template with task-specific values."""
    instructions = template.replace("<OP>", op_name)
    instructions = instructions.replace("<op>", op_name.lower())
    instructions = instructions.replace("<OP_FILE>", op_file)
    return instructions


class SynthesisAgent:
    """One persistent agent per synthesis task, reused across library-learning rounds."""

    def __init__(
        self,
        task: SynthesisTask,
        args,
        api_key: str,
        current_lib_path: Path,
    ) -> None:
        self._task = task
        self._args = args
        self._history: list[Any] | None = None
        self._agent = self._build_agent(args, api_key, current_lib_path)

    def _build_agent(self, args, api_key: str, current_lib_path: Path) -> Agent:
        del api_key  # Reserved for future model/provider auth parity.
        task = self._task
        template_path: Path = args.template
        ops_path: Path = args.ops
        examples_dir: Path = args.examples_dir
        instructions_path: Path = args.agent_instructions

        @function_tool
        def get_task_bundle() -> str:
            """Return the concrete operation/task bundle as JSON (op_name, op_file, and op_content)."""
            op_path = Path(task.op_file)
            bundle = {
                "op_name": task.op_name,
                "op_file": str(op_path),
                "op_content": op_path.read_text(encoding="utf-8"),
            }
            return json.dumps(bundle)

        @function_tool
        def get_program_templates() -> str:
            """Return the MLIR output templates (agent/template.mlir)."""
            return template_path.read_text(encoding="utf-8")

        @function_tool
        def get_available_primitives() -> str:
            """Return the allowed primitive operators documentation (agent/ops.md)."""
            return ops_path.read_text(encoding="utf-8")

        @function_tool
        def get_library_text() -> str:
            """Return the library (in MLIR) containing reusable helper functions mined from previous synthesis rounds. Prefer calling these functions in your solution to keep the program short."""
            return current_lib_path.read_text(encoding="utf-8")

        @function_tool
        def list_examples() -> str:
            """List available example transformer files as JSON array of filenames."""
            names = (
                [p.name for p in sorted(examples_dir.glob("*.mlir"))]
                if examples_dir.exists()
                else []
            )
            return json.dumps(names)

        @function_tool
        def get_example(name: str) -> str:
            """Return the contents of one example transformer file by filename (e.g. 'kb_xor.mlir')."""
            p = (examples_dir / name).resolve()
            ex_dir = examples_dir.resolve()
            if ex_dir not in p.parents:
                raise ValueError(
                    "example name must refer to a file under the examples directory"
                )
            if p.suffix != ".mlir":
                raise ValueError("example must be a .mlir file")
            return p.read_text(encoding="utf-8")

        @function_tool
        def search_examples(query: str, top_k: int = 3) -> str:
            """Search example transformer files by substring. Returns JSON array of matches with filename and snippet."""
            if top_k <= 0:
                return "[]"
            q = query.strip()
            if not q:
                return "[]"
            matches: list[dict] = []
            for p in sorted(examples_dir.glob("*.mlir")) if examples_dir.exists() else []:
                text = p.read_text(encoding="utf-8", errors="replace")
                idx = text.lower().find(q.lower())
                if idx == -1:
                    continue
                start = max(0, idx - 200)
                end = min(len(text), idx + 200)
                matches.append(
                    {
                        "name": p.name,
                        "start": start,
                        "end": end,
                        "snippet": text[start:end],
                    }
                )
                if len(matches) >= top_k:
                    break
            return json.dumps(matches)

        @function_tool
        def run_eval_tool(transformer_mlir: str) -> str:
            """Evaluate the generated transformer MLIR for the current operation (e.g. kb_<op>). Pass the raw MLIR code as a string. Evaluate on a low bitwidth (default: 4), and a high bitwidth (default: 64). Returns a short summary:
            - Sound %: the percentage of inputs for which the output abstract value is sound
            - Exact %: the percentage of inputs for which the output abstract value is exactly the same the optimal transfer function (perfect precision)
            - Norm: ignore for now
            """
            lib_text = current_lib_path.read_text(encoding="utf-8")
            full_soln = merge_library_text(lib_text, transformer_mlir)
            return eval_transformer(
                solution_path=full_soln,
                op_path=Path(task.op_file),
                domain=AbstractDomain.KnownBits,
                xfer_name=f"kb_{task.op_name.lower()}",
            )

        return Agent(
            name="TransformerSynthesizer",
            instructions=build_agent_instructions(
                instructions_path.read_text(encoding="utf-8").strip(),
                task.op_name,
                task.op_file,
            ),
            tools=[
                get_task_bundle,
                get_program_templates,
                get_available_primitives,
                get_library_text,
                list_examples,
                get_example,
                search_examples,
                run_eval_tool,
            ],
            model=args.model,
        )

    async def run(self, round_num: int) -> tuple[str, object, Any]:
        """Run one synthesis round. Returns (final_output, run_result, inp)."""
        if self._history is None:
            user_content = f"{_make_initial_prompt(self._task)}\n"
        else:
            user_content = (
                f"The library has been updated for round {round_num}. "
                "Call get_library_text() to see the new helper functions, "
                "then revise your solution to reuse them where applicable."
            )
        user_content += f"\nYou have a maximum of {self._args.max_turns} iterations to complete this task, If you are going to exceed the limit, return the current MLIR you have generated."
        inp: list[Any] = (self._history or []) + [
            {"role": "user", "content": user_content}
        ]
        result = await Runner.run(self._agent, inp, max_turns=self._args.max_turns)
        self._history = result.to_input_list()
        return result.final_output, result, inp


def run_eval(
    op_file_path: str,
    transformer: SynthesisResult,
    library: LibraryState,
    op_name: str,
) -> str:
    """Evaluate the transformer via eval_transformer (no subprocess)."""
    cleaned_mlir = clean_llm_output(transformer.solution_text)
    full_soln = merge_library_text(library.functions_text, cleaned_mlir)

    return eval_transformer(
        full_soln, Path(op_file_path), AbstractDomain.KnownBits, f"kb_{op_name.lower()}"
    )


async def run_single_synthesis_task(
    synth_agent: SynthesisAgent,
    task: SynthesisTask,
    round_num: int,
    library: LibraryState,
    args,
) -> SynthesisResult:
    """Run one synthesis task with the persistent agent."""
    tag = f"[{task.op_name.upper()}]"
    print(f"{tag} Synthesizing: round={round_num}, op={task.op_name}")

    output_dir = Path(args.output)
    print(f"{tag} Using model: {args.model}")
    t0 = time.monotonic()
    llm_output, run_result, agent_input = await synth_agent.run(round_num)
    synthesis_time = time.monotonic() - t0

    if args.dump_agent_run:
        input_dump = (
            agent_input
            if isinstance(agent_input, str)
            else json.dumps(agent_input, indent=2)
        )
        input_path = save_file(
            input_dump,
            output_dir,
            f"synth_input_r{round_num}_{task.op_name.lower()}.json",
        )
        print(f"{tag} Agent input dump: {input_path}")
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"synth_agent_r{round_num}_{task.op_name.lower()}.log",
        )
        print(f"{tag} Agent run dump: {dump_path}")

    print_token_usage(run_result)
    transformer_file = save_file(
        clean_llm_output(llm_output),
        output_dir,
        f"kb_r{round_num}_{task.op_name.lower()}.mlir",
    )
    print(f"{tag} Transformer: {transformer_file}")

    result = SynthesisResult(task, llm_output, transformer_file, None)

    eval_summary: str | None = None
    if not args.skip_eval:
        print(f"{tag} Evaluating transformer...")
        eval_summary = run_eval(task.op_file, result, library, task.op_name)
        print(f"{tag} Eval result: {eval_summary}")
        save_file(
            f"synthesis_time: {synthesis_time:.2f}s\n\n{eval_summary}",
            output_dir,
            f"eval_r{round_num}_{task.op_name.lower()}.txt",
        )

    return SynthesisResult(task, llm_output, transformer_file, eval_summary)


async def run_synthesis_tasks(
    synth_agents: dict[str, SynthesisAgent],
    tasks: list[SynthesisTask],
    round_num: int,
    library: LibraryState,
    args,
) -> list[SynthesisResult]:
    """Run synthesis tasks either in parallel or sequentially based on args.parallel."""
    if args.parallel:
        return list(
            await asyncio.gather(
                *[
                    run_single_synthesis_task(
                        synth_agents[t.op_name], t, round_num, library, args
                    )
                    for t in tasks
                ]
            )
        )
    results = []
    for task in tasks:
        results.append(
            await run_single_synthesis_task(
                synth_agents[task.op_name], task, round_num, library, args
            )
        )
    return results
