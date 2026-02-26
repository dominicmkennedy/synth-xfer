#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM.

Supports direct_llm (direct prompting) and agent_sdk (OpenAI Agent API).
"""

import argparse
import os
from pathlib import Path
import sys

from synth_xfer._util.domain import AbstractDomain

from .agent_sdk import format_agent_run_dump, run_agent_synthesis
from .direct_llm import call_llm
from .shared import (
    clean_llm_output,
    extract_op_name,
    instantiate_prompt,
    read_op_file,
    read_prompt_template,
    save_instantiated_prompt,
    save_transformer,
)
from .util import eval_transformer


def run_eval(op_file_path: str, transformer_file: Path, op_name: str) -> str:
    """Evaluate the transformer via eval_transformer (no subprocess)."""
    print("\nRunning eval (Python)...")
    return eval_transformer(
        solution_path=transformer_file,
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


def main():
    """Synthesize transformer using selected method."""
    parser = argparse.ArgumentParser(description="Synthesize transfer functions")
    parser.add_argument(
        "op_file", help="Operation MLIR file (e.g., mlir/Operations/Add.mlir)"
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument("--skip-eval", action="store_true", help="Skip eval-final")
    parser.add_argument("--model", default="gpt-4", help="OpenAI model")
    parser.add_argument(
        "--method",
        choices=["direct_llm", "agent_sdk"],
        default="direct_llm",
        help="Synthesis method (direct_llm or agent_sdk)",
    )
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir (agent_sdk only)",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=20,
        help="Max iterations for agent (default: 20, use 2-3 for fast dev)",
    )

    args = parser.parse_args()
    api_key = get_api_key()

    op_name = extract_op_name(args.op_file)
    print(f"Synthesizing: {op_name} (method: {args.method})")

    prompt = instantiate_prompt(
        read_prompt_template(), op_name, read_op_file(args.op_file)
    )

    output_dir = Path(args.output)
    print(f"Prompt saved to: {save_instantiated_prompt(prompt, output_dir, op_name)}")

    # Run synthesis
    print(f"Using model: {args.model}")
    if args.method == "direct_llm":
        llm_output, usage = call_llm(prompt, api_key, args.model)
        # Print token usage
        inp, out, reason = (
            usage["input_tokens"],
            usage["output_tokens"],
            usage.get("reasoning_tokens", 0),
        )
        total = inp + out + reason
        token_str = f"{inp:,} input, {out:,} output" + (
            f", {reason:,} reasoning" if reason else ""
        )
        print(f"Tokens: {token_str} ({total:,} total)")
    else:  # agent_sdk
        llm_output, run_result = run_agent_synthesis(
            prompt, args.op_file, op_name, api_key, args.model, args.max_turns
        )
        # Token usage (aggregate across all turns)
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
        if getattr(args, "dump_agent_run", False):
            dump_path = output_dir / f"agent_run_{op_name.lower()}.txt"
            dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
            print(f"Agent run dump: {dump_path}")

    # Save outputs
    (output_dir / f"llm_output_{op_name.lower()}.txt").write_text(llm_output)
    transformer_file = save_transformer(clean_llm_output(llm_output), output_dir, op_name)
    print(f"Transformer: {transformer_file}")

    # Evaluate unless skipped
    if not args.skip_eval:
        result = run_eval(args.op_file, transformer_file, op_name)
        print(f"Eval result:\n{result}")
        eval_file = output_dir / f"eval_{op_name.lower()}.txt"
        eval_file.write_text(result)
        print(f"Eval result saved: {eval_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
