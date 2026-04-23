"""Synthesis workflow helpers."""

import asyncio
import json
from pathlib import Path
import time
from typing import Any

from agents import Agent, Runner, function_tool

from agent.agent_solution_set import AgentSolutionSet
from synth_xfer._util.domain import AbstractDomain

from .agent_helper import format_agent_run_dump
from .util import (
    EvalArgs,
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    clean_llm_output,
    eval_transformer,
    get_op_output_dir,
    save_file,
    summarize_token_usage,
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
    instructions = instructions.replace("<op>", op_name)
    instructions = instructions.replace("<OP_FILE>", op_file)
    return instructions


class SynthesisAgent:
    """One persistent agent per synthesis task, reused across library-learning rounds."""

    def __init__(
        self,
        task: SynthesisTask,
        args,
        api_key: str,
        current_lib: LibraryState,
        eval_args_override: EvalArgs | None = None,
    ) -> None:
        self._task = task
        self._args = args
        self._library = current_lib
        self._soln_iters: list[str] = []
        self._current_round: int = 0
        self._eval_call_idx: int = 0
        self._eval_args = eval_args_override or EvalArgs(
            op_path=Path(task.op_file),
            domain=AbstractDomain.KnownBits,
            lbw=args.lbw,
            mbw=args.mbw,
            hbw=args.hbw,
            unsound_ex=5,
            imprecise_ex=5,
        )
        self._agent = self._build_agent(args, api_key)
        self.solution_set = AgentSolutionSet(current_lib)

    def update_library(self, new_lib: LibraryState) -> None:
        """Update the library used by this agent's tools."""
        self._library = new_lib
        self.solution_set.library = new_lib

    def _build_agent(self, args, api_key: str) -> Agent:
        del api_key  # Reserved for future model/provider auth parity.
        task = self._task
        template_path: Path = args.template
        ops_path: Path = args.ops
        examples_dir: Path = args.examples_dir
        instructions_path: Path = (
            args.meet_instructions if args.meet else args.agent_instructions
        )

        @function_tool
        def get_task_bundle() -> str:
            """Return JSON with op_name, op_file, and op_content.

            op_content is the MLIR module from op_file and includes:
            - concrete_op: the concrete operator whose KnownBits transformer you must synthesize.
            - op_constraint (optional): a predicate over concrete inputs; concretizations that violate it are out of scope.
            """
            print(f"[{task.op_name.upper()}] [TOOL] get_task_bundle", flush=True)
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
            print(f"[{task.op_name.upper()}] [TOOL] get_program_templates", flush=True)
            return template_path.read_text(encoding="utf-8")

        @function_tool
        def get_available_primitives() -> str:
            """Return the allowed primitive operators documentation (agent/ops.md)."""
            print(f"[{task.op_name.upper()}] [TOOL] get_available_primitives", flush=True)
            return ops_path.read_text(encoding="utf-8")

        @function_tool
        def list_library_functions() -> str:
            """List available library functions as JSON dictionary of func names and docstrings"""
            print(f"[{task.op_name.upper()}] [TOOL] list_library_functions", flush=True)
            funcs = {
                func.function_name: func.docstring for func in self._library.functions
            }
            return json.dumps(funcs)

        @function_tool
        def get_library_function(name: str) -> str:
            """Return the source of a function by its name"""
            print(
                f"[{task.op_name.upper()}] [TOOL] get_library_function: {name!r}",
                flush=True,
            )
            for func in self._library.functions:
                if func.function_name == name:
                    return func.source

            raise ValueError("name must refer to a function in the library")

        @function_tool
        def search_library_functions(query: str, top_k: int = 3) -> str:
            """Search inside library functions by substring 'query' to understand how specific operators are used. Returns JSON array of matches with function name and docstring."""
            # Xuanyu: I am not sure whether this tool is actually useful, since search_examples show usage of operators.
            print(
                f"[{task.op_name.upper()}] [TOOL] search_library_functions: {query!r}",
                flush=True,
            )
            if top_k <= 0:
                return "[]"
            q = query.strip()
            if not q:
                return "[]"
            matches: list[dict] = []
            for func in self._library.functions:
                searchable = f"{func.function_name}\n{func.docstring}\n{func.source}"
                if searchable.lower().find(q.lower()) == -1:
                    continue
                matches.append(
                    {
                        "function_name": func.function_name,
                        "docstring": func.docstring,
                    }
                )
                if len(matches) >= top_k:
                    break
            return json.dumps(matches)

        @function_tool
        def list_examples() -> str:
            """List available example transformer files as JSON array of filenames."""
            print(f"[{task.op_name.upper()}] [TOOL] list_examples", flush=True)
            names = (
                [p.name for p in sorted(examples_dir.glob("*.mlir"))]
                if examples_dir.exists()
                else []
            )
            return json.dumps(names)

        @function_tool
        def get_example(name: str) -> str:
            """Return the contents of one example transformer file by filename (e.g. 'kb_xor.mlir')."""
            print(f"[{task.op_name.upper()}] [TOOL] get_example: {name!r}", flush=True)
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
            """Search inside reference implementations by substring 'query' to understand the usage of operators. Returns JSON array of matches with filename and snippet."""
            print(
                f"[{task.op_name.upper()}] [TOOL] search_examples: {query!r}", flush=True
            )
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
            """Evaluate the generated transformer MLIR for the current operation (e.g. kb_<op>). Pass the raw MLIR code as a string. Uses `--exact-bw` bitwidths from the CLI (default 8).

            First line is always a short summary:
            - Sound %: fraction of inputs where the abstract output is sound
            - Exact %: fraction where the result matches the optimal transfer (full precision)
            - Dist: sound-distance metric for this eval

            If the transformer is not fully sound or not fully exact, following lines may include a short legend and up to a few concrete counterexamples per bitwidth (unsound vs imprecise), labeled with bw=..., so you can see inputs, your abstract output, and the optimal abstract output.
            """
            print(f"[{task.op_name.upper()}] [TOOL] run_eval_tool", flush=True)
            summary, eval_result = eval_transformer(
                [transformer_mlir],
                self._eval_args,
                lib=[func.source for func in self._library.functions],
            )
            print(
                f"[{task.op_name.upper()}] [TOOL] run_eval_tool result:\n{summary}",
                flush=True,
            )
            if eval_result and eval_result.is_sound():
                self._soln_iters.append(transformer_mlir)
            return summary

        @function_tool
        def get_existing_solutions() -> str:
            """Return the MLIR source of all solutions currently in the solution set. Each solution will be combined with your candidate via meet when eval_improve is called. Use this to understand what cases are already covered before writing a new candidate."""
            print(f"[{task.op_name.upper()}] [TOOL] get_existing_solutions", flush=True)
            if not self.solution_set.solutions:
                return "No solutions in the solution set yet."
            return "\n\n".join(self.solution_set.solutions)

        @function_tool
        def run_eval_improve(transformer_mlir: str) -> str:
            """Evaluate the transformer MLIR combined with all previously accepted solutions via meet. Returns two summary lines so you can compare before and after:

            Previous: Sound/Exact/Dist of the existing solution set alone
            Updated:  Sound/Exact/Dist after adding your candidate via meet

            Each line has the format: Sound %: ..., Exact %: ..., Dist: ...
            - Sound %: fraction of inputs where the abstract output is sound
            - Exact %: fraction where the result matches the optimal transfer (full precision)
            - Dist: sound-distance metric for this eval
            An improvement shows higher Exact % or lower Dist on the Updated line.

            If the combined transformer is not fully sound or not fully precise, following lines may includeshort legend and up to a few concrete counterexamples per bitwidth (unsound vs imprecise labeled with bw=..., so you can see inputs, your abstract output, and the optimal abstract output.
            """

            print(f"[{task.op_name.upper()}] [TOOL] run_eval_improve:", flush=True)
            summary, eval_result = self.solution_set.eval_improve(
                transformer_mlir,
                self._eval_args,
            )
            print(
                f"[{task.op_name.upper()}] [TOOL] run_eval_improve result:\n{summary}",
                flush=True,
            )

            round_tag = f"r{self._current_round}"
            call_tag = f"{self._eval_call_idx:03d}"
            self._eval_call_idx += 1
            op_output_dir = get_op_output_dir(Path(self._args.output), task.op_name)
            _ = save_file(
                transformer_mlir,
                op_output_dir,
                f"xfer_{round_tag}_{task.op_name}_{call_tag}.mlir",
            )
            _ = save_file(
                summary, op_output_dir, f"eval_{round_tag}_{task.op_name}_{call_tag}.txt"
            )
            if eval_result and eval_result.is_sound():
                self._soln_iters.append(transformer_mlir)

            return summary

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
                list_examples,
                get_example,
                search_examples,
                list_library_functions,
                get_library_function,
                *(
                    [get_existing_solutions, run_eval_improve]
                    if args.meet
                    else [run_eval_tool]
                ),
            ],
            model=args.synth_model,
        )

    async def run(self, round_num: int) -> tuple[str, object, Any, list[str]]:
        """Run one synthesis round. Returns (final_output, run_result, inp, evalled_transformers)."""
        self._soln_iters = []
        self._current_round = round_num
        self._eval_call_idx = 0
        if round_num <= 0:
            user_content = f"{_make_initial_prompt(self._task)}\n"
        else:
            user_content = (
                f"The library has been updated for round {round_num}. "
                "Call list_library_functions()/search_library_functions()/"
                "get_library_function() to search and retrieve the new helper "
                "functions, then revise your solution to reuse them where "
                "applicable."
            )
        user_content += f"\nYou have a maximum of {self._args.max_turns} iterations to complete this task, If you are going to exceed the limit, return the current MLIR you have generated."
        inp: list[Any] = [{"role": "user", "content": user_content}]
        result = await Runner.run(self._agent, inp, max_turns=self._args.max_turns)
        return result.final_output, result, inp, list(self._soln_iters)


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
    op_output_dir = get_op_output_dir(output_dir, task.op_name)

    run_result = None
    agent_input = None
    soln_iters: list[str] = []
    synthesis_time = 0.0
    if args.mock_synth:
        llm_output = (Path(__file__).parent / "examples" / "kb_top.mlir").read_text()
    else:
        print(f"{tag} Using model: {args.synth_model}")
        t0 = time.monotonic()
        llm_output, run_result, agent_input, soln_iters = await synth_agent.run(round_num)
        synthesis_time = time.monotonic() - t0

    if not args.mock_synth:
        if args.dump_agent_run:
            dump_path = save_file(
                format_agent_run_dump(run_result, args.synth_model),
                op_output_dir,
                f"synth_agent_r{round_num}_{task.op_name}.log",
            )
            print(f"{tag} Agent run dump: {dump_path}")

        print(f"{tag} Token usage: {summarize_token_usage(run_result, args.synth_model)}")

    transformer_file = save_file(
        clean_llm_output(llm_output),
        op_output_dir,
        f"xfer_r{round_num}_{task.op_name}.mlir",
    )
    print(f"{tag} Transformer: {transformer_file}")

    solution_text = clean_llm_output(llm_output)

    print(f"{tag} Evaluating transformer...")
    eval_t0 = time.monotonic()
    if args.meet:
        eval_summary, _ = synth_agent.solution_set.eval_improve(
            solution_text,
            synth_agent._eval_args,
            no_previous=True,
        )
    else:
        eval_summary, _ = eval_transformer(
            [solution_text],
            synth_agent._eval_args,
            lib=[func.source for func in library.functions],
        )
    eval_time = time.monotonic() - eval_t0
    print(f"{tag} Eval result: {eval_summary}")
    save_file(
        f"synthesis_time: {synthesis_time:.2f}s\neval_time: {eval_time:.2f}s\n\n{eval_summary}",
        op_output_dir,
        f"eval_r{round_num}_{task.op_name}.txt",
    )

    return SynthesisResult(
        task=task,
        solution_text=solution_text,
        solution_iters=soln_iters,
        transformer_path=transformer_file,
        eval_summary=eval_summary,
    )


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
