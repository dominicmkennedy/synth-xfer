"""File compression workflow helpers."""

import json
from pathlib import Path
import re

from pydantic_ai import Agent
from pydantic_ai.usage import UsageLimits

from synth_xfer._util.domain import AbstractDomain

from .prompts import DomainFragment, fill_template, load_domain_fragment
from .util import (
    EvalArgs,
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    eval_transformer,
    get_op_output_dir,
    save_file,
    summarize_token_usage,
)


def _run_agent_compress(
    prompt: str,
    api_key: str,
    target: SynthesisResult,
    library: LibraryState,
    model: str,
    spec_path: Path,
    instructions_path: Path,
    max_turns: int,
    eval_args: EvalArgs,
    domain: AbstractDomain,
    fragment: DomainFragment,
) -> tuple[str, object]:
    """Run agent to compress a target file. Returns (final_output, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    def get_target_file() -> str:
        """Get the MLIR code of the file to compress"""
        if target.solution_text is None:
            raise ValueError("target solution text is unavailable")
        return target.solution_text

    def get_dialect_spec() -> str:
        """Return the transfer dialect specification (types, allowed operators, and semantics)."""
        return spec_path.read_text(encoding="utf-8")

    def list_library_functions() -> str:
        """List available library functions as JSON dictionary of func names and docstrings"""
        funcs = {func.function_name: func.docstring for func in library.functions}
        return json.dumps(funcs)

    def get_library_function(name: str) -> str:
        """Return the source of a function by its name"""
        for func in library.functions:
            if func.function_name == name:
                return func.source

        raise ValueError("name must refer to a function in the library")

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

    def verify_correctness(transformer_mlir: str) -> str:
        """Confirm that the compressed transformer has the same eval results as uncompressed transformer"""
        pattern = r"Sound %:\s*(?P<sound>[\d.]+),\s*Exact %:\s*(?P<exact>[\d.]+)"

        # Xuanyu: target.eval_summary are guaranteed to exist, check text equivalence should be enough
        assert target.eval_summary is not None
        match = re.search(pattern, target.eval_summary)
        if match is None:
            return (
                "Problem in eval of original file. Proceed with compression.\n"
                f"{target.eval_summary}"
            )

        # Get eval of new transformer
        compressed_eval_summary, compressed_eval_result = eval_transformer(
            [transformer_mlir],
            eval_args,
            lib=[func.source for func in library.functions],
        )
        if target.eval_summary != compressed_eval_summary:
            return (
                "Correctness check failed.\n"
                f"Original eval summary: {target.eval_summary}\n"
                f"Compressed eval summary: {compressed_eval_summary}"
            )
        return "Correctness check successful! Compression is valid."

    instructions_text = fill_template(
        instructions_path.read_text(encoding="utf-8").strip(), domain, fragment
    )
    agent = Agent(
        name="TargetFileCompressor",
        instructions=instructions_text,
        tools=[
            get_target_file,
            get_dialect_spec,
            list_library_functions,
            get_library_function,
            search_library_functions,
            verify_correctness,
        ],
        model=model,
    )

    filled_prompt = fill_template(prompt, domain, fragment)
    result = agent.run_sync(
        filled_prompt, usage_limits=UsageLimits(request_limit=max_turns)
    )

    return (result.output, result)


def run_compress_task(
    target: SynthesisResult,
    library: LibraryState,
    round_num: int,
    args,
    api_key,
    eval_args: EvalArgs,
) -> SynthesisResult:
    """Run compression on a synthesis result"""
    op_name = target.task.op_name

    print(f"\nRunning compression on {op_name}")

    # Read prompt
    prompt = args.compress_prompt.read_text()
    domain = eval_args.domain
    fragment = load_domain_fragment(args.domains_dir, domain)

    output_dir = Path(args.output)
    op_output_dir = get_op_output_dir(output_dir, op_name)
    print(f"Using model: {args.library_model}")

    llm_output, run_result = _run_agent_compress(
        prompt=prompt,
        api_key=api_key,
        target=target,
        library=library,
        model=args.library_model,
        spec_path=args.spec,
        instructions_path=args.compress_instructions,
        max_turns=args.max_turns,
        eval_args=eval_args,
        domain=domain,
        fragment=fragment,
    )
    summary = summarize_token_usage(run_result)
    print(summary)

    target_text = clean_llm_output(llm_output)

    transformer_file = save_file(
        target_text,
        op_output_dir,
        f"{domain.name}_r{round_num}_{op_name}_compressed.mlir",
    )
    print(f"Transformer: {transformer_file}")

    return SynthesisResult(
        task=target.task,
        solution_iters=[*target.solution_iters, target_text],
        is_sound=target.is_sound,
        eval_summary=target.eval_summary,
    )
