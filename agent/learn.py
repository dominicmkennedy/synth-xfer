"""Library learning workflow helpers."""

import argparse
import json
from pathlib import Path

from agents import Agent, Runner, function_tool

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    dump_library,
    extract_op_name,
    get_api_key,
    load_initial_library,
    print_token_usage,
    save_file,
)


def _run_agent_learn(
    prompt: str,
    api_key: str,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    model: str,
    ops_path: Path,
    instructions_path: Path,
    max_turns: int,
) -> tuple[LibraryState, object]:
    """Run agent to learn library functions. Returns (LibraryState, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    @function_tool
    def get_corpus_functions() -> str:
        """Return the corpus MLIR programs to learn library funcs from"""
        text = ""
        for result in synthesis_results:
            for soln in result.solution_iters:
                text += f"{soln}\n"

        return text

    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")

    @function_tool
    def list_library_functions() -> str:
        """List available library functions as JSON dictionary of func names and docstrings"""
        funcs = {
            func.function_name: func.docstring for func in previous_library.functions
        }
        return json.dumps(funcs)

    @function_tool
    def get_library_function(name: str) -> str:
        """Return the source of a function by its name"""
        for func in previous_library.functions:
            if func.function_name == name:
                return func.source

        raise ValueError("name must refer to a function in the library")

    @function_tool
    def search_library_functions(query: str, top_k: int = 3) -> str:
        """Search library functions by substring. Returns JSON array of matches with function name and docstring."""
        if top_k <= 0:
            return "[]"
        q = query.strip()
        if not q:
            return "[]"
        matches: list[dict] = []
        for func in previous_library.functions:
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

    agent = Agent(
        name="LibraryFunctionLearner",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_corpus_functions,
            get_available_primitives,
            list_library_functions,
            get_library_function,
            search_library_functions,
        ],
        model=model,
        output_type=LibraryState,
    )

    result = Runner.run_sync(agent, prompt, max_turns=max_turns)

    return (result.final_output, result)


def run_library_learn_task(
    version: int,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    args,
    api_key: str,
) -> LibraryState:
    """Learn a new library version from synthesized task results."""

    print(f"\nLearning library version {version}")

    prompt = args.library_prompt.read_text()

    output_dir = Path(args.output)
    print(f"Using model: {args.model}")

    llm_output, run_result = _run_agent_learn(
        prompt=prompt,
        api_key=api_key,
        previous_library=previous_library,
        synthesis_results=synthesis_results,
        model=args.model,
        ops_path=args.ops,
        instructions_path=args.library_instructions,
        max_turns=args.max_turns,
    )

    print_token_usage(run_result)

    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"learn_agent_{version}.log",
        )
        print(f"Agent run dump: {dump_path}")

    existing_names = {f.function_name for f in previous_library.functions}
    new_functions = [
        f for f in llm_output.functions if f.function_name not in existing_names
    ]
    merged = LibraryState(functions=previous_library.functions + new_functions)

    lib_dir = output_dir / f"library{version}"
    dump_library(merged, lib_dir)
    print(f"Library: {lib_dir}")

    return merged


def main():
    parser = argparse.ArgumentParser(description="Learn library functions")
    parser.add_argument(
        "input_files",
        nargs="+",
        help="MLIR files to learn from (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument("--model", default="gpt-5.1-codex-mini", help="OpenAI model")
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--library-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "library_instructions.md",
        help="Path to library agent instructions file (default: agent/md/library_instructions.md)",
    )
    parser.add_argument(
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "md" / "library_prompt.md",
        help="Path to library learning prompt template (default: agent/md/library_prompt.md)",
    )
    parser.add_argument(
        "--ops",
        type=Path,
        default=Path(__file__).parent / "md" / "ops.md",
        help="Path to ops.md file (default: agent/ops.md)",
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
        default=1,
        help="Number of library-learn rounds to run (default: 1)",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=20,
        help="Max iterations for agent (default: 20, use 2-3 for fast dev)",
    )

    args = parser.parse_args()

    # Validate arguments
    if len(args.input_files) < 2:
        parser.error("input_file: need at least two files to learn from")

    for input_file in args.input_files:
        if not Path(input_file).exists():
            parser.error(f"input_file: path does not exist: {input_file}")

    for name, path in [
        ("--library-instructions", args.library_instructions),
        ("--library-prompt", args.library_prompt),
        ("--ops", args.ops),
    ]:
        if not path.exists():
            parser.error(f"{name}: path does not exist: {path}")

    if args.library_dir is not None and not args.library_dir.is_dir():
        parser.error(f"--library-dir: not a directory: {args.library_dir}")

    if args.max_turns <= 0:
        parser.error("--max-turns: must be greater than 0")

    # Parse input files
    corpus = []
    for input_file in args.input_files:
        task = SynthesisTask("", extract_op_name(input_file))
        result = SynthesisResult(
            task=task,
            solution_text=Path(input_file).read_text(),
            transformer_path=None,
            eval_summary=None,
        )
        corpus.append(result)

    api_key = get_api_key()
    lib = load_initial_library(args.library_dir)

    for rnd in range(args.rounds):
        lib = run_library_learn_task(
            version=rnd,
            previous_library=lib,
            synthesis_results=corpus,
            args=args,
            api_key=api_key,
        )

    print("Library learning complete")

    return 0
