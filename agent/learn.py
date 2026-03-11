"""Library learning workflow helpers."""

from pathlib import Path
import re

from .agent_sdk import format_agent_run_dump, run_agent_learn
from .shared import build_library_learn_prompt
from .util import (
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    merge_library_text,
    print_token_usage,
    save_instantiated_prompt,
    save_library,
)


def run_library_learn(
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    args,
    api_key: str,
) -> LibraryState:
    """Learn a new library version from synthesized task results."""
    del api_key  # Reserved for future model/provider auth parity.

    version = previous_library.version + 1

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
        f"Prompt saved to: {save_instantiated_prompt(prompt, output_dir, f'library{version}')}"
    )

    print(f"Using model: {args.model}")
    llm_output, run_result = run_agent_learn(prompt=prompt, model=args.model)

    print_token_usage(run_result)

    if args.dump_agent_run:
        dump_path = output_dir / f"library_run_{version}.txt"
        dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
        print(f"Agent run dump: {dump_path}")

    (output_dir / f"library_output_{version}.txt").write_text(llm_output)
    lib_text = merge_library_text(
        previous_library.functions_text,
        clean_llm_output(llm_output),
    )
    library_file = save_library(lib_text, output_dir, version)
    print(f"Library: {library_file}")

    return LibraryState(
        version,
        lib_text,
    )
