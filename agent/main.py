#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import argparse
import os
from pathlib import Path
import re
import sys

from synth_xfer._util.domain import AbstractDomain

from .agent_sdk import format_agent_run_dump, run_agent_synthesis, run_agent_learn
from .library_learning import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    load_initial_library,
    run_library_learning_loop,
)
from .shared import build_library_learn_prompt
from .util import (
    clean_llm_output,
    eval_transformer,
    extract_op_name,
    save_instantiated_prompt,
    merge_library_text,
    save_transformer,
    save_library,
)


def run_eval(
    op_file_path: str,
    transformer: SynthesisResult, 
    library: LibraryState,
    op_name: str
) -> str:
    """Evaluate the transformer via eval_transformer (no subprocess)."""
    print("\nRunning eval (Python)...")

    cleaned_mlir = clean_llm_output(transformer.solution_text)
    full_soln = merge_library_text(
        library.functions_text,
        cleaned_mlir,
    )

    return eval_transformer(
        solution_path=full_soln,
        op_path=Path(op_file_path),
        domain=AbstractDomain.KnownBits,
        xfer_name=f"kb_{op_name.lower()}",
    )


def get_api_key() -> str:
    """Get API key from env var or file."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_file = Path(__file__).parent / "api_key.txt"
        if api_file.exists():
            api_key = api_file.read_text().strip()
    if not api_key:
        raise ValueError(
            "API key not found. Set OPENAI_API_KEY or create agent/api_key.txt"
        )
    return api_key


def print_token_usage(run_result) -> None:
    """Print aggregated token usage from agent run."""
    inp = out = reason = 0
    for resp in getattr(run_result, "raw_responses", []):
        u = getattr(resp, "usage", None)
        if u is None:
            continue
        inp += getattr(u, "input_tokens", 0) or 0
        out += getattr(u, "output_tokens", 0) or 0
        od = getattr(u, "output_tokens_details", None)
        if od is not None:
            reason += getattr(od, "reasoning_tokens", 0) or 0
    total = inp + out + reason
    token_str = f"{inp:,} input, {out:,} output" + (
        f", {reason:,} reasoning" if reason else ""
    )
    print(f"Tokens: {token_str} ({total:,} total)")


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
    print(
        f"Prompt saved to: {save_instantiated_prompt(prompt, output_dir, task.op_name)}"
    )

    print(f"Using model: {args.model}")
    llm_output, run_result = run_agent_synthesis(
        prompt,
        task.op_file,
        task.op_name,
        api_key,
        library,
        args.model,
        args.max_turns
    )

    print_token_usage(run_result)

    if args.dump_agent_run:
        dump_path = output_dir / f"agent_run_{task.op_name.lower()}.txt"
        dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
        print(f"Agent run dump: {dump_path}")

    (output_dir / f"llm_output_{task.op_name.lower()}.txt").write_text(llm_output)
    transformer_file = save_transformer(
        clean_llm_output(llm_output), output_dir, task.op_name
    )
    print(f"Transformer: {transformer_file}")

    result = SynthesisResult(
        task=task,
        solution_text=llm_output,
        transformer_path=transformer_file,
        eval_summary=None,
    )

    eval_summary: str | None = None
    if not args.skip_eval:
        eval_summary = run_eval(task.op_file,
                                result,
                                library,
                                task.op_name
        )
        print(f"Eval result:\n{eval_summary}")
        eval_file = output_dir / f"eval_{task.op_name.lower()}.txt"
        eval_file.write_text(eval_summary)
        print(f"Eval result saved: {eval_file}")

    return SynthesisResult(
        task=task,
        solution_text=llm_output,
        transformer_path=transformer_file,
        eval_summary=eval_summary,
    )

def run_library_learn(
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    args,
    api_key: str,
) -> LibraryState:
    version = previous_library.version + 1

    print(f"\nLearning library version {version}")

    # Read all files
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
        f"Prompt saved to: {save_instantiated_prompt(prompt, output_dir, f"library{version}")}"
    )

    print(f"Using model: {args.model}")
    llm_output, run_result = run_agent_learn(
        prompt=prompt,
        model=args.model
    )
    
    print_token_usage(run_result)

    if args.dump_agent_run:
        dump_path = output_dir / f"library_run_{version}.txt"
        dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
        print(f"Agent run dump: {dump_path}")

    (output_dir / f"library_output_{version}.txt").write_text(llm_output)
    lib_text = merge_library_text(
        previous_library.functions_text,
        clean_llm_output(llm_output)
    )
    library_file = save_library(
        lib_text, output_dir, version
    )
    print(f"Library: {library_file}")

    return LibraryState(
        version,
        lib_text,
    )

def main():
    """Synthesize transformer using selected method."""
    parser = argparse.ArgumentParser(description="Synthesize transfer functions")
    parser.add_argument(
        "op_file",
        nargs="+",
        help="Operation MLIR file(s) (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument("--skip-eval", action="store_true", help="Skip eval-final")
    parser.add_argument("--model", default="gpt-4", help="OpenAI model")
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=20,
        help="Max iterations for agent (default: 20, use 2-3 for fast dev)",
    )
    parser.add_argument(
        "--synth-prompt",
        type=Path,
        default=Path(__file__).parent / "prompt.md",
        help="Path to synthesis prompt template (default: agent/prompt.md)",
    )
    parser.add_argument(
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "library_prompt.md",
        help="Path to library learning prompt template (default: agent/library_prompt.md",
    )
    parser.add_argument(
        "--examples-dir",
        type=Path,
        default=Path(__file__).parent / "examples",
        help="Path to examples directory (default: agent/examples)",
    )
    parser.add_argument(
        "--ops",
        type=Path,
        default=Path(__file__).parent / "ops.md",
        help="Path to ops.md file (default: agent/ops.md)",
    )
    parser.add_argument(
        "--template",
        type=Path,
        default=Path(__file__).parent / "template.mlir",
        help="Path to template.mlir file (default: agent/template.mlir)",
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
        default=0,
        help="Number of library-update rounds; 0 = synthesis-only pass (default: 2)",
    )

    args = parser.parse_args()
    api_key = get_api_key()

    tasks = [
        SynthesisTask(op_file=op_file, op_name=extract_op_name(op_file))
        for op_file in args.op_file
    ]
    initial_library = load_initial_library(args.library)

    def _run_task(task: SynthesisTask, library: LibraryState) -> SynthesisResult:
        return run_single_synthesis_task(
            task=task,
            library=library,
            args=args,
            api_key=api_key,
        )

    def _library_learn(
            previous_library: LibraryState,
            synthesis_results: list[SynthesisResult],
    ) -> LibraryState:
        return run_library_learn(
            previous_library=previous_library,
            synthesis_results=synthesis_results,
            args=args,
            api_key=api_key
        )

    final_library, latest_results = run_library_learning_loop(
        tasks=tasks,
        num_rounds=args.rounds,
        initial_library=initial_library,
        run_single_task=_run_task,
        run_library_learn=_library_learn,
    )
    print(
        f"Library learning complete: version={final_library.version}, "
        f"latest_results={len(latest_results)}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
