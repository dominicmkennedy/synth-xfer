"""Library learning workflow helpers."""

from pathlib import Path
import re

from agents import Agent, Runner

from .agent_helper import format_agent_run_dump
from .shared import build_library_learn_prompt
from .util import (
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    merge_library_text,
    print_token_usage,
    save_file,
)

_MD_DIR = Path(__file__).parent / "md"


def _read_instruction_file(name: str) -> str:
    text = (_MD_DIR / name).read_text(encoding="utf-8")
    return text.strip()


LEARN_INSTRUCTIONS = _read_instruction_file("learn_instructions.md")


def run_agent_learn(
    prompt: str,
    model: str = "gpt-4",
) -> tuple[str, object]:
    """Run agent to learn library functions. Returns (final_output, run_result)."""

    agent = Agent(
        name="LibraryFunctionLearner",
        instructions=LEARN_INSTRUCTIONS,
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

    prompt_template_raw = args.library_prompt.read_text()
    prompt_template = re.sub(
        r"<!--.*?-->", "", prompt_template_raw, flags=re.DOTALL
    ).strip()

    ops_md = args.ops.read_text()
    synthesized_functions = [sr.solution_text for sr in synthesis_results]

    prompt = build_library_learn_prompt(
        prompt_template=prompt_template,
        synth_functions="\n".join(synthesized_functions),
        existing_lib=previous_library.functions_text,
        ops_md=ops_md,
    )

    output_dir = Path(args.output)
    print(
        f"Prompt saved to: {save_file(prompt, output_dir, f'instantiated_prompt_library{version}.md')}"
    )

    print(f"Using model: {args.model}")
    llm_output, run_result = run_agent_learn(prompt=prompt, model=args.model)

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
