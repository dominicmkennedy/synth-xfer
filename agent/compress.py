"""File compression workflow helpers."""

import json
from pathlib import Path
import re

from agents import Agent, Runner, function_tool

from synth_xfer._util.domain import AbstractDomain

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    eval_transformer,
    merge_library_text,
    print_token_usage,
    save_file,
)


def _run_agent_compress(
    prompt: str,
    api_key: str,
    target: SynthesisResult,
    library: LibraryState,
    model: str,
    ops_path: Path,
    instructions_path: Path,
    max_turns: int,
    lbw: list[int],
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
    def list_library_functions() -> str:
        """List available library functions as JSON dictionary of func names and docstrings"""
        funcs = {func.function_name: func.docstring for func in library.functions}
        return json.dumps(funcs)

    @function_tool
    def get_library_function(name: str) -> str:
        """Return the source of a function by its name"""
        for func in library.functions:
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
        for func in library.functions:
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
    def verify_correctness(transformer_mlir: str) -> str:
        """Confirm that the compressed transformer has the same eval results as uncompressed transformer"""
        pattern = r"Sound %:\s*(?P<sound>[\d.]+),\s*Exact %:\s*(?P<exact>[\d.]+)"

        # Get eval of current transformer
        if not target.eval_summary:
            full_soln = merge_library_text(library.functions_text, target.solution_text)
            curr_eval_summary = eval_transformer(
                solution=full_soln,
                op_path=Path(target.task.op_file),
                domain=AbstractDomain.KnownBits,
                xfer_name=f"kb_{target.task.op_name.lower()}",
                lbw=lbw,
            )
            match = re.search(pattern, curr_eval_summary)
            if match is None:
                return (
                    "Problem in eval of original file. Proceed with compression.\n"
                    f"{curr_eval_summary}"
                )

            curr_sound = float(match.group("sound"))
            curr_exact = float(match.group("exact"))
        else:
            match = re.search(pattern, target.eval_summary)
            if match is None:
                return (
                    "Problem in eval of original file. Proceed with compression.\n"
                    f"{target.eval_summary}"
                )

            curr_sound = float(match.group("sound"))
            curr_exact = float(match.group("exact"))

        # Get eval of new transformer
        full_soln = merge_library_text(library.functions_text, transformer_mlir)
        compressed_eval_summary = eval_transformer(
            solution=full_soln,
            op_path=Path(target.task.op_file),
            domain=AbstractDomain.KnownBits,
            xfer_name=f"kb_{target.task.op_name.lower()}",
            lbw=lbw,
        )
        match = re.search(pattern, compressed_eval_summary)
        if match is None:
            return compressed_eval_summary
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
            list_library_functions,
            get_library_function,
            search_library_functions,
            verify_correctness,
        ],
        model=model,
    )

    result = Runner.run_sync(agent, prompt, max_turns=max_turns)

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
        max_turns=args.max_turns,
        lbw=args.exact_bw,
    )
    print_token_usage(run_result)

    target_text = clean_llm_output(llm_output)

    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"compress_run{round_num}_{op_name}.log",
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
        solution_iters=target.solution_iters,
        transformer_path=target.transformer_path,
        eval_summary=target.eval_summary,
    )
