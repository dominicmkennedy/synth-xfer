"""File compression workflow helpers."""

import re
import argparse
from pathlib import Path
from agents import Agent, Runner, function_tool

from .agent_helper import format_agent_run_dump
from synth_xfer._util.domain import AbstractDomain
from .util import (
    LibraryState,
    SynthesisTask,
    SynthesisResult,
    clean_llm_output,
    merge_library_text,
    eval_transformer,
    print_token_usage,
    save_file,
    extract_op_name,
    load_initial_library,
    get_api_key,
)


def _run_agent_compress(
    prompt: str,
    api_key: str,
    target: SynthesisResult,
    library: LibraryState,
    model: str,
    ops_path: Path,
    instructions_path: Path,
) -> tuple[str, object]:
    """Run agent to compress a target file. Returns (final_output, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    @function_tool
    def get_target_file() -> str:
        """Get the MLIR code of the file to compress"""
        return target.solution_text
    
    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")
    
    @function_tool
    def get_library_text() -> str:
        """Return the library (in MLIR) containing reusable helper functions mined from previous synthesis rounds. Prefer calling these functions in your solution to keep the program short."""
        return library.functions_text
    
    @function_tool
    def verify_correctness(transformer_mlir: str) -> str:
        """Confirm that the compressed transformer has the same eval results as uncompressed transformer"""
        pattern = r"Sound %:\s*(?P<sound>[\d.]+),\s*Exact %:\s*(?P<exact>[\d.]+)"

        # Get eval of current transformer
        if not target.eval_summary:
            full_soln = merge_library_text(library.functions_text, target.solution_text)
            curr_eval_summary = eval_transformer(
                solution_path=full_soln,
                op_path=Path(target.task.op_file),
                domain=AbstractDomain.KnownBits,
                xfer_name=f"kb_{target.task.op_name.lower()}",
            )
            match = re.search(pattern, curr_eval_summary)
            curr_sound = float(match.group("sound"))
            curr_exact = float(match.group("exact"))
        else:
            match = re.search(pattern, target.eval_summary)
            curr_sound = float(match.group("sound"))
            curr_exact = float(match.group("exact"))

        # Get eval of new transformer
        full_soln = merge_library_text(library.functions_text, transformer_mlir)
        compressed_eval_summary = eval_transformer(
                solution_path=full_soln,
                op_path=Path(target.task.op_file),
                domain=AbstractDomain.KnownBits,
                xfer_name=f"kb_{target.task.op_name.lower()}",
        
        )
        match = re.search(pattern, compressed_eval_summary)
        compressed_sound = float(match.group("sound"))
        compressed_exact = float(match.group("exact"))

        if abs(compressed_sound - curr_sound) > 0.1:
            return (
                "Correctness check failed.\n"
                f"Soundness before compression: {curr_sound}\n"
                f"Soundness after compression: {compressed_sound}\n"
            )
        if abs(compressed_exact - curr_exact) > 0.1:
            return (
                "Correctness check failed.\n"
                f"Exactness before compression: {curr_exact}\n"
                f"Exactness after compression: {compressed_exact}"
            )

        return "Correctness check successful! Compression is valid."

    agent = Agent(
        name="TargetFileCompressor",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_target_file,
            get_available_primitives,
            get_library_text,
            verify_correctness,
        ],
        model=model,
    )

    result = Runner.run_sync(agent, prompt)

    return (result.final_output, result)


def run_compress_task(
    target: SynthesisResult,
    library: LibraryState,
    round_num: int,
    args,
    api_key,
) -> SynthesisResult:
    """Run compression on a synthesis result"""
    op_name = target.task.op_name

    print(f"\nRunning compression on {op_name}")

    # Read prompt
    prompt = args.compress_prompt.read_text()

    output_dir = Path(args.output)
    print(f"Using model: {args.model}")

    llm_output, run_result = _run_agent_compress(
        prompt=prompt,
        api_key=api_key,
        target=target,
        library=library,
        model=args.model,
        ops_path=args.ops,
        instructions_path=args.compress_instructions,
    )
    print_token_usage(run_result)

    target_text = clean_llm_output(llm_output)

    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"compress_run_{op_name}.log",
        )
        print(f"Agent run dump: {dump_path}")

    transformer_file = save_file(
        target_text,
        output_dir,
        f"kb_r{round_num}_{op_name}_compressed.mlir",
    )
    print(f"Transformer: {transformer_file}")

    return SynthesisResult(
        task=target.task,
        solution_text=target_text,
        transformer_path=target.transformer_path,
        eval_summary=target.eval_summary,
    )


def main():
    parser = argparse.ArgumentParser(description="Compress target files")
    parser.add_argument(
        "input_files",
        nargs="+",
        type=Path,
        help="MLIR files to compress (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "--library",
        type=Path,
        help="Library file to use for compression",
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
        "--compress-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "library_instructions.md",
        help="Path to library agent instructions file (default: agent/md/library_instructions.md)",
    )
    parser.add_argument(
        "--compress-prompt",
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

    args = parser.parse_args()
    
    # Validate arguments
    for input_file in args.input_files:
        if not input_file.exists():
            parser.error(f"input_file: path does not exist: {input_file}")
    
    for lib_file in args.library:
        if not lib_file.exists():
            parser.error(f"library: path does not exist: {lib_file}")
    
    for name, path in [
        ("--compress-instructions", args.compress_instructions),
        ("--compress-prompt", args.compress_prompt),
        ("--ops", args.ops),
    ]:
        if not path.exists():
            parser.error(f"{name}: path does not exist: {path}")
    
    # Parse input files
    corpus = []
    for input_file in args.input_files:
        task = SynthesisTask("", extract_op_name(input_file))
        result = SynthesisResult(
            task=task,
            solution_text=input_file.read_text(),
            transformer_path=None,
            eval_summary=None,
        )
        corpus.append(result)
    
    library = load_initial_library(args.library)
    api_key = get_api_key()

    for target in corpus:
        run_compress_task(
            target=target,
            library=library,
            round_num=0,
            args=args,
            api_key=api_key,
        )
    
    print("Compression complete")
    return 0
    