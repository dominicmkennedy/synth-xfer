"""Synthesis workflow helpers."""

from pathlib import Path

from synth_xfer._util.domain import AbstractDomain

from .agent_sdk import format_agent_run_dump, run_agent_synthesis
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    clean_llm_output,
    eval_transformer,
    merge_library_text,
    print_token_usage,
    save_transformer,
)


def run_eval(
    op_file_path: str,
    transformer: SynthesisResult,
    library: LibraryState,
    op_name: str,
) -> str:
    """Evaluate the transformer via eval_transformer (no subprocess)."""
    print("\nRunning eval (Python)...")

    cleaned_mlir = clean_llm_output(transformer.solution_text)
    full_soln = merge_library_text(library.functions_text, cleaned_mlir)

    return eval_transformer(
        full_soln, Path(op_file_path), AbstractDomain.KnownBits, f"kb_{op_name.lower()}"
    )


def run_single_synthesis_task(
    task: SynthesisTask,
    library: LibraryState,
    args,
    api_key: str,
) -> SynthesisResult:
    """Run one synthesis task with current library context."""
    print(f"Synthesizing: {task.op_name}")

    op_lower = task.op_name.lower()
    prompt = (
        "Task: Synthesize a KnownBits transfer function in MLIR.\n"
        f"- Operation name: {task.op_name}\n"
        f"- Operation file: {task.op_file}\n"
        "\n"
        "Use tools to fetch all materials; do not assume they are in this message:\n"
        "- get_task_bundle(): concrete op MLIR\n"
        "- get_program_templates(): output templates\n"
        "- get_available_primitives(): allowed operators\n"
        "- get_library_text(): available helper functions\n"
        "- list_examples()/search_examples()/get_example(): reference implementations\n"
        "- run_eval_tool(mlir): evaluate your candidate\n"
        "\n"
        "Output contract:\n"
        f"- Return ONLY MLIR (builtin.module) defining func.func @kb_{op_lower}\n"
        "- One operation per line; SSA form; no explanations.\n"
    )

    output_dir = Path(args.output)
    print(f"Using model: {args.model}")
    llm_output, run_result = run_agent_synthesis(
        prompt,
        task.op_file,
        task.op_name,
        api_key,
        library,
        args.model,
        args.max_turns,
    )
    print_token_usage(run_result)
    if args.dump_agent_run:
        dump_path = output_dir / f"agent_run_{task.op_name.lower()}.txt"
        dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
        print(f"Agent run dump: {dump_path}")

    transformer_file = save_transformer(
        clean_llm_output(llm_output), output_dir, task.op_name
    )
    print(f"Transformer: {transformer_file}")

    result = SynthesisResult(task, llm_output, transformer_file, None)

    eval_summary: str | None = None
    if not args.skip_eval:
        eval_summary = run_eval(task.op_file, result, library, task.op_name)
        print(f"Eval result:\n{eval_summary}")
        eval_file = output_dir / f"eval_{task.op_name.lower()}.txt"
        eval_file.write_text(eval_summary)
        print(f"Eval result saved: {eval_file}")

    return SynthesisResult(task, llm_output, transformer_file, eval_summary)
