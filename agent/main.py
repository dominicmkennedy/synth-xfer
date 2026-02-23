#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM.

Supports direct_llm (direct prompting) and agent_sdk (OpenAI Agent API).
"""

import argparse
import os
from pathlib import Path
import subprocess
import sys

from .agent_sdk import run_agent_synthesis
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


def run_eval(op_file_path: str, transformer_file: Path, op_name: str) -> str:
    """Run eval-final to evaluate the transformer."""
    cmd = [
        "eval-final",
        str(transformer_file),
        "-d",
        "KnownBits",
        "--op",
        op_file_path,
        "--xfer-name",
        f"kb_{op_name.lower()}",
        "--exact-bw",
        "4",
    ]
    print(f"\nRunning: {' '.join(cmd)}")
    # return subprocess.run(cmd, capture_output=False).returncode
    # capture the output and return
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Eval failed with code {result.returncode}:\n{result.stderr}")
    else:
        return result.stdout


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
        llm_output = run_agent_synthesis(prompt, args.op_file, api_key, args.model)

    # Save outputs
    (output_dir / f"llm_output_{op_name.lower()}.txt").write_text(llm_output)
    transformer_file = save_transformer(clean_llm_output(llm_output), output_dir, op_name)
    print(f"Transformer: {transformer_file}")

    # Evaluate if requested
    result = run_eval(args.op_file, transformer_file, op_name)
    print(f"Eval result:\n{result}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
