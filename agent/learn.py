"""Library learning workflow helpers."""

import argparse
from pathlib import Path

from agents import Agent, Runner, function_tool

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    clean_llm_output,
    extract_op_name,
    get_api_key,
    load_initial_library,
    merge_library_text,
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
) -> tuple[str, object]:
    """Run agent to learn library functions. Returns (final_output, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    @function_tool
    def get_corpus_functions() -> str:
        """Return the corpus MLIR programs to learn library funcs from"""
        corpus = "\n".join([result.solution_text for result in synthesis_results])

        return corpus

    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")

    @function_tool
    def get_library_text() -> str:
        """Return the library (in MLIR) containing reusable helper functions mined from previous synthesis rounds. Prefer calling these functions in your solution to keep the program short."""
        return previous_library.functions_text

    agent = Agent(
        name="LibraryFunctionLearner",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_corpus_functions,
            get_available_primitives,
            get_library_text,
        ],
        model=model,
    )

    result = Runner.run_sync(agent, prompt)

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
    )

    print_token_usage(run_result)

    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"learn_agent_{version}.log",
        )
        print(f"Agent run dump: {dump_path}")

    lib_text = merge_library_text(
        previous_library.functions_text,
        clean_llm_output(llm_output),
    )
    save_file(lib_text, output_dir, "library_current.mlir")
    library_file = save_file(lib_text, output_dir, f"library_v{version}.mlir")
    print(f"Library: {library_file}")

    return LibraryState(lib_text)


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
        "--library",
        type=Path,
        default=None,
        help="Optional initial library file for library-learning workflow",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="Number of library-learn rounds to run (default: 1)",
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

    if args.library is not None and not args.library.exists():
        parser.error(f"--library: path does not exist: {args.library}")

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
    lib = load_initial_library(args.library)

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
