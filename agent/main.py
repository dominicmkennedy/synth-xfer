#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM via OpenAI Agent API."""

import argparse
import os
import re
import sys
from pathlib import Path

from .agent_sdk import format_agent_run_dump, run_agent_learn
from .shared import LibraryState, CorpusFile, build_library_learn_prompt
from .util import (
    clean_llm_output,
    save_instantiated_prompt,
    merge_library_text,
    save_library,
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


def run_library_learn(
    previous_library: LibraryState,
    corpus: list[CorpusFile],
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

    prompt = build_library_learn_prompt(
        prompt_template=prompt_template,
        corpus=corpus,
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
    """Perform library learning over MLIR files"""
    parser = argparse.ArgumentParser(description="Learn library functions")
    parser.add_argument(
        "input_files",
        nargs="+",
        help="one or more MLIR files to learn from (e.g., mlir/Add.mlir mlir/Sub.mlir)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="agent/output/",
        help="output directory"
    )
    parser.add_argument("--model", default="gpt-4", help="OpenAI model")
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "library_prompt.md",
        help="Path to library learning prompt template (default: agent/library_prompt.md",
    )
    parser.add_argument(
        "--ops",
        type=Path,
        default=Path(__file__).parent / "ops.md",
        help="Path to ops.md file (default: agent/ops.md)",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=0,
        help="Number of library-update rounds; 0 = synthesis-only pass (default: 2)",
    )

    args = parser.parse_args()
    api_key = get_api_key()

    corpus = []
    for file in args.input_files:
        filepath = Path(file)
        corpus.append(CorpusFile(
            filename=filepath.name,
            text=filepath.read_text()
        ))

    lib_state = LibraryState(version=0, functions_text="builtin.module {}")
    for i in range(args.rounds):
        lib_state = run_library_learn(
            previous_library=lib_state,
            corpus=corpus,
            args=args,
            api_key=api_key, 
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
