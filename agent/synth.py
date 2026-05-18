"""Synthesis workflow helpers."""

import asyncio
import json
from pathlib import Path
import time

from pydantic_ai import Agent
from pydantic_ai.exceptions import UsageLimitExceeded
from pydantic_ai.usage import UsageLimits

from agent.agent_solution_set import AgentSolutionSet
from synth_xfer._util.domain import AbstractDomain

from .prompts import DomainFragment, fill_template, load_domain_fragment
from .util import (
    EvalArgs,
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    eval_transformer,
    get_op_output_dir,
    save_file,
    summarize_token_usage,
    verify_transformer,
)


def _make_initial_prompt(task: SynthesisTask, domain: AbstractDomain) -> str:
    return (
        f"Synthesize the {domain.name} transfer function for operation "
        f"{task.op_name} (file: {task.op_file})."
    )


def build_agent_instructions(
    template: str,
    op_name: str,
    op_file: str,
    domain: AbstractDomain,
    fragment: DomainFragment,
) -> str:
    """Instantiate agent_instructions.md template with task and domain values."""
    return fill_template(template, domain, fragment, op_name=op_name, op_file=op_file)


class SynthesisAgent:
    """One persistent agent per synthesis task, reused across library-learning rounds."""

    def __init__(
        self,
        task: SynthesisTask,
        args,
        api_key: str,
        current_lib: LibraryState,
        eval_args: EvalArgs,
    ) -> None:
        self._task = task
        self._args = args
        self._library = current_lib
        self._soln_iters: list[str] = []
        self._current_round: int = 0
        self._eval_call_idx: int = 0
        self._eval_args = eval_args
        self._domain = eval_args.domain
        self._domain_fragment = load_domain_fragment(args.domains_dir, self._domain)
        self._agent = self._build_agent(args, api_key)
        self.solution_set = AgentSolutionSet(current_lib, self._domain)

    def update_library(self, new_lib: LibraryState) -> None:
        """Update the library used by this agent's tools."""
        self._library = new_lib
        self.solution_set.library = new_lib

    def _build_agent(self, args, api_key: str) -> Agent:
        del api_key  # Reserved for future model/provider auth parity.
        task = self._task
        domain = self._domain
        template_path: Path = args.template
        spec_path: Path = args.spec
        examples_dir: Path = args.examples_dir
        domain_examples_dir = examples_dir / domain.name
        shared_examples_dir = examples_dir / "shared"
        instructions_path: Path = (
            args.meet_instructions if args.meet else args.agent_instructions
        )

        def _example_paths() -> list[Path]:
            paths: list[Path] = []
            for d in (domain_examples_dir, shared_examples_dir):
                if d.is_dir():
                    paths.extend(sorted(d.glob("*.mlir")))
            return paths

        def get_task_bundle() -> str:
            """Return JSON with op_name, op_file, and op_content.

            op_content is the MLIR module from op_file and includes:
            - concrete_op: the concrete operator whose transfer function you must synthesize.
            - op_constraint (optional): a predicate over concrete inputs; concretizations that violate it are out of scope.
            """
            print(f"[{task.op_name.upper()}] [TOOL] get_task_bundle", flush=True)
            op_path = Path(task.op_file)
            if not op_path.is_file():
                return f"Error: op file {str(op_path)!r} does not exist."
            bundle = {
                "op_name": task.op_name,
                "op_file": str(op_path),
                "op_content": op_path.read_text(encoding="utf-8"),
            }
            return json.dumps(bundle)

        def get_program_templates() -> str:
            """Return the MLIR output templates (agent/template.mlir)."""
            print(f"[{task.op_name.upper()}] [TOOL] get_program_templates", flush=True)
            if not template_path.is_file():
                return f"Error: template file {str(template_path)!r} does not exist."
            return template_path.read_text(encoding="utf-8")

        def get_dialect_spec() -> str:
            """Return the transfer dialect specification (types, allowed operators, and semantics). Use only operators listed here; do not introduce unsupported constructs (for example, loops)."""
            print(f"[{task.op_name.upper()}] [TOOL] get_dialect_spec", flush=True)
            if not spec_path.is_file():
                return f"Error: spec file {str(spec_path)!r} does not exist."
            return spec_path.read_text(encoding="utf-8")

        def list_library_functions() -> str:
            """List available library functions as JSON dictionary of func names and docstrings"""
            print(f"[{task.op_name.upper()}] [TOOL] list_library_functions", flush=True)
            funcs = {
                func.function_name: func.docstring for func in self._library.functions
            }
            return json.dumps(funcs)

        def get_library_function(name: str) -> str:
            """Return the source of a function by its name"""
            print(
                f"[{task.op_name.upper()}] [TOOL] get_library_function: {name!r}",
                flush=True,
            )
            for func in self._library.functions:
                if func.function_name == name:
                    return func.source

            return f"Error: function {name!r} does not exist in the library. Call list_library_functions() to see available functions."

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

        def list_examples() -> str:
            """List available example transformer files as JSON array of filenames.

            Filenames are prefixed with their subdirectory ("<DomainName>/foo.mlir"
            or "shared/bar.mlir"); pass the same prefixed name back to get_example.
            """
            print(f"[{task.op_name.upper()}] [TOOL] list_examples", flush=True)
            names = [f"{p.parent.name}/{p.name}" for p in _example_paths()]
            return json.dumps(names)

        def get_example(name: str) -> str:
            """Return the contents of one example transformer file by name.

            Use the "<subdir>/<file>.mlir" form returned by list_examples (e.g.
            "{DOMAIN}/top.mlir" or "shared/ex_0_827_109.mlir"). For backward
            compatibility, a bare filename is also resolved against the
            domain-specific and shared subdirs in that order.
            """
            print(f"[{task.op_name.upper()}] [TOOL] get_example: {name!r}", flush=True)
            ex_dir = examples_dir.resolve()
            candidate = (examples_dir / name).resolve()
            if "/" not in name:
                for d in (domain_examples_dir, shared_examples_dir):
                    fallback = (d / name).resolve()
                    if fallback.is_file():
                        candidate = fallback
                        break
            if ex_dir != candidate and ex_dir not in candidate.parents:
                return "Error: example name must refer to a file under the examples directory"
            if candidate.suffix != ".mlir":
                return "Error: example must be a .mlir file"
            if not candidate.is_file():
                return f"Error: example {name!r} does not exist. Call list_examples() to see available files."
            return candidate.read_text(encoding="utf-8")

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
            for p in _example_paths():
                if not p.is_file():
                    continue
                text = p.read_text(encoding="utf-8", errors="replace")
                idx = text.lower().find(q.lower())
                if idx == -1:
                    continue
                start = max(0, idx - 200)
                end = min(len(text), idx + 200)
                matches.append(
                    {
                        "name": f"{p.parent.name}/{p.name}",
                        "start": start,
                        "end": end,
                        "snippet": text[start:end],
                    }
                )
                if len(matches) >= top_k:
                    break
            return json.dumps(matches)

        def run_eval_tool(transformer_mlir: str) -> str:
            """Evaluate the generated transformer MLIR for the current operation (named @<DomainName>_<op>). Pass the raw MLIR code as a string. Uses `--exact-bw` bitwidths from the CLI (default 8).

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

        def run_verify_tool(transformer_mlir: str) -> str:
            """SMT-verify the candidate transformer at bitwidths 4, 8, 16, 32, 64.

            Returns one line per bitwidth, plus an overall verdict on the first line:
            - VERIFIED sound at all checked bitwidths
            - UNSOUND or TIMEOUT at one or more bitwidths
            - error: ... (parse / setup failure)

            Each per-bw line is one of:
            - bw=<n>: VERIFIED sound
            - bw=<n>: UNSOUND, counterexample: ...
            - bw=<n>: TIMEOUT

            Use this AFTER `run_eval_tool` reports 100% sound to confirm soundness symbolically.
            """
            print(f"[{task.op_name.upper()}] [TOOL] run_verify_tool", flush=True)
            summary, _ = verify_transformer(
                transformer_mlir,
                self._eval_args,
                lib=[func.source for func in self._library.functions],
            )
            print(
                f"[{task.op_name.upper()}] [TOOL] run_verify_tool result:\n{summary}",
                flush=True,
            )
            return summary

        def get_existing_solutions() -> str:
            """Return the MLIR source of all solutions currently in the solution set. Each solution will be combined with your candidate via meet when eval_improve is called. Use this to understand what cases are already covered before writing a new candidate."""
            print(f"[{task.op_name.upper()}] [TOOL] get_existing_solutions", flush=True)
            if not self.solution_set.solutions:
                return "No solutions in the solution set yet."
            return "\n\n".join(self.solution_set.solutions)

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
            call_tag = f"{self._eval_call_idx}"
            self._eval_call_idx += 1
            op_output_dir = get_op_output_dir(Path(self._args.output), task.op_name)
            _ = save_file(
                transformer_mlir,
                op_output_dir,
                f"{round_tag}_{task.op_name}_{call_tag}_xfer.mlir",
            )
            _ = save_file(
                summary, op_output_dir, f"{round_tag}_{task.op_name}_{call_tag}_eval.txt"
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
                domain,
                self._domain_fragment,
            ),
            tools=[
                get_task_bundle,
                get_program_templates,
                get_dialect_spec,
                list_examples,
                get_example,
                search_examples,
                list_library_functions,
                get_library_function,
                run_verify_tool,
                *(
                    [get_existing_solutions, run_eval_improve]
                    if args.meet
                    else [run_eval_tool]
                ),
            ],
            model=args.synth_model,
        )

    async def run(self, round_num: int) -> tuple[object, list[str]]:
        """Run one synthesis round. Returns (final_output, run_result, inp, evalled_transformers)."""
        self._soln_iters = []
        self._current_round = round_num
        self._eval_call_idx = 0
        if round_num <= 0:
            user_content = f"{_make_initial_prompt(self._task, self._domain)}\n"
        else:
            user_content = (
                f"The library has been updated for round {round_num}. "
                "Call list_library_functions()/search_library_functions()/"
                "get_library_function() to search and retrieve the new helper "
                "functions, then revise your solution to reuse them where "
                "applicable."
            )
        soft_limit = self._args.max_turns - 2
        user_content += f"\nYou have at most {soft_limit} iterations to complete this task. If you are about to exceed this limit, stop and return the MLIR solution you have generated so far."
        try:
            result = await self._agent.run(
                user_content,
                usage_limits=UsageLimits(request_limit=self._args.max_turns),
            )
        except UsageLimitExceeded as e:
            print(
                f"[{self._task.op_name.upper()}] Request limit hit ({e}); "
                f"returning {len(self._soln_iters)} solution(s) collected so far."
            )
            result = None
        return result, list(self._soln_iters)


async def run_single_synthesis_task(
    synth_agent: SynthesisAgent,
    round_num: int,
    args,
) -> SynthesisResult:
    """Run one synthesis task with the persistent agent."""
    tag = f"[{synth_agent._task.op_name.upper()}]"
    print(f"{tag} Synthesizing: round={round_num}, op={synth_agent._task.op_name}")

    output_dir = Path(args.output)
    op_output_dir = get_op_output_dir(output_dir, synth_agent._task.op_name)

    run_result = None
    synthesis_time = 0.0
    if args.mock_synth:
        mock_path = Path(args.examples_dir) / synth_agent._domain.name / "top.mlir"
        soln_iters = [mock_path.read_text()]
    else:
        print(f"{tag} Using model: {args.synth_model}")
        t0 = time.monotonic()
        run_result, soln_iters = await synth_agent.run(round_num)
        synthesis_time = time.monotonic() - t0

    if not args.mock_synth and run_result is not None:
        print(f"{tag} {summarize_token_usage(run_result)}")

    if soln_iters == []:
        print(f"{tag} No valid transformer generated by the agent.")
        return SynthesisResult(synth_agent._task, [], False, "")

    transformer_file = save_file(
        soln_iters[-1],
        op_output_dir,
        f"r{round_num}_{synth_agent._task.op_name}_xfer.mlir",
    )
    print(f"{tag} Transformer: {transformer_file}")

    print(f"{tag} Evaluating transformer...")
    eval_t0 = time.monotonic()
    if args.meet:
        eval_summary, eval_result = synth_agent.solution_set.eval_improve(
            soln_iters[-1],
            synth_agent._eval_args,
            no_previous=True,
        )
    else:
        eval_summary, eval_result = eval_transformer(
            [soln_iters[-1]],
            synth_agent._eval_args,
            lib=[func.source for func in synth_agent._library.functions],
        )
    eval_time = time.monotonic() - eval_t0
    print(f"{tag} Eval result: {eval_summary}")
    save_file(
        f"synthesis_time: {synthesis_time:.2f}s\neval_time: {eval_time:.2f}s\n\n{eval_summary}",
        op_output_dir,
        f"r{round_num}_{synth_agent._task.op_name}_eval.txt",
    )

    verify_summary, problems = verify_transformer(
        soln_iters[-1],
        synth_agent._eval_args,
        lib=[func.source for func in synth_agent._library.functions],
    )
    print(f"{tag} Verify result: {verify_summary}")
    is_sound = problems is not None and not problems

    return SynthesisResult(
        task=synth_agent._task,
        solution_iters=soln_iters,
        is_sound=is_sound,
        eval_summary=eval_summary,
        eval_result=eval_result,
    )


async def run_synthesis_tasks(
    synth_agents: dict[str, SynthesisAgent],
    tasks: list[SynthesisTask],
    round_num: int,
    args,
) -> list[SynthesisResult]:
    """Run synthesis tasks either in parallel or sequentially based on args.parallel."""
    if args.parallel:
        return list(
            await asyncio.gather(
                *[
                    run_single_synthesis_task(synth_agents[t.op_name], round_num, args)
                    for t in tasks
                ]
            )
        )
    results = []
    for task in tasks:
        results.append(
            await run_single_synthesis_task(synth_agents[task.op_name], round_num, args)
        )
    return results
