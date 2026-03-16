"""Library learning workflow helpers."""

from pathlib import Path
import re

from agents import Agent, Runner, function_tool

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    merge_library_text,
    print_token_usage,
    save_file,
)

def run_agent_learn(
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

def run_library_learn(
    version: int,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    args,
    api_key: str,
) -> LibraryState:
    """Learn a new library version from synthesized task results."""
    del api_key  # Reserved for future model/provider auth parity.

    print(f"\nLearning library version {version}")

    prompt = args.library_prompt.read_text()

    output_dir = Path(args.output)
    print(f"Using model: {args.model}")

    llm_output, run_result = run_agent_learn(
        prompt=prompt,
        api_key=api_key,
        previous_library=previous_library,
        synthesis_results=synthesis_results,
        model=args.model,
        ops_path=args.ops,
        instructions_path=args.learn_instructions,
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
    library_file = save_file(lib_text, output_dir, f"library_v{version}.mlir")
    print(f"Library: {library_file}")

    return LibraryState(lib_text)
