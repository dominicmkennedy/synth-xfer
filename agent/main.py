#!/usr/bin/env python3
"""Agent for synthesizing transfer functions using LLM."""

import argparse
import os
from pathlib import Path
import subprocess
import sys

from openai import OpenAI


def extract_op_name(op_file_path: str) -> str:
    """Extract operation name from file path.

    Example: mlir/Operations/Add.mlir -> Add
    """
    return Path(op_file_path).stem


def read_prompt_template() -> str:
    """Read the prompt template file, filtering out commented sections.

    Comments are defined as blocks wrapped in <!-- --> and will not be included
    in the final prompt sent to the LLM.
    """
    prompt_file = Path(__file__).parent / "prompt.md"
    with open(prompt_file, "r") as f:
        content = f.read()

    # Remove comments wrapped in <!-- -->
    import re

    filtered_content = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL)

    return filtered_content.strip()


def read_op_file(op_file_path: str) -> str:
    """Read the operation MLIR file."""
    with open(op_file_path, "r") as f:
        return f.read()


def read_example_files() -> str:
    """Read example transfer function files for reference."""
    examples_dir = Path(__file__).parent / "examples"
    examples = []

    for example_file in sorted(examples_dir.glob("*.mlir")):
        with open(example_file, "r") as f:
            content = f.read()
            examples.append(f"Example from {example_file.name}:\n```mlir\n{content}```")

    return "\n\n".join(examples)


def read_ops_json() -> str:
    """Read the operations documentation file."""
    ops_file = Path(__file__).parent / "ops.md"
    with open(ops_file, "r") as f:
        return f.read()


def read_template_mlir() -> str:
    """Read the MLIR template file."""
    template_file = Path(__file__).parent / "template.mlir"
    with open(template_file, "r") as f:
        return f.read()


def instantiate_prompt(template: str, op_name: str, op_content: str) -> str:
    """Instantiate the prompt template with the operation details."""
    # Replace <OP> with the actual operation name
    prompt = template.replace("<OP>", op_name.lower())
    prompt = prompt.replace("<Op>", op_name)

    # Add operations documentation for reference
    ops_docs = read_ops_json()
    prompt += f"\n\nAvailable operations:\n{ops_docs}"

    # Add example files for reference
    examples = read_example_files()
    if examples:
        prompt += f"\n\nHere are example KnownBits transfer functions for reference:\n\n{examples}"

    # Append the operation definition
    prompt += f"\n\nOperation definition from mlir/Operations/{op_name}.mlir:\n```mlir\n{op_content}\n```"

    # Add MLIR template with TODO instructions
    mlir_template = read_template_mlir()
    prompt += f"\n\nUse the following MLIR template and only fill in the parts marked as 'todo':\n```mlir\n{mlir_template}```"
    prompt += f"\n\nGenerate kb_{op_name.lower()}.mlir by filling in only the TODO parts."

    return prompt


def _use_responses_api(model: str) -> bool:
    """True if this model uses the Responses API (v1/responses) rather than Chat Completions.

    Includes: GPT-5.x, Codex (e.g. gpt-5.2-codex), and o-series reasoning (o1, o3, o4).
    """
    m = model.lower()
    return (
        "-codex" in m
        or m.startswith("gpt-5")
        or m.startswith("o1")
        or m.startswith("o3")
        or m.startswith("o4")
    )


def call_llm(prompt: str, api_key: str, model: str = "gpt-4") -> tuple[str, dict]:
    """Call OpenAI API to generate the transformer. Returns (content, usage_dict)."""
    client = OpenAI(api_key=api_key)
    system_msg = (
        "You are an expert in MLIR and abstract interpretation. Your task is to "
        "generate sound and highly precise abstract transformers for the given operation. "
        "Generate only the requested MLIR code without any explanation or markdown formatting."
    )

    if _use_responses_api(model):
        # Responses API: required for Codex/GPT-5/o-series
        # Need to bump max tokens here so that it is able to do reasoning
        response = client.responses.create(
            model=model,
            instructions=system_msg,
            input=[
                {
                    "role": "user",
                    "content": [{"type": "input_text", "text": prompt}],
                }
            ],
            max_output_tokens=64000,
        )
        content = response.output_text
        u = response.usage
        usage = {
            "input_tokens": u.input_tokens if u else 0,
            "output_tokens": u.output_tokens if u else 0,
            "reasoning_tokens": (
                u.output_tokens_details.reasoning_tokens
                if u
                and u.output_tokens_details
                and hasattr(u.output_tokens_details, "reasoning_tokens")
                else 0
            ),
        }
    else:
        # Chat Completions API
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
            max_tokens=5000,
        )
        content = response.choices[0].message.content
        u = response.usage
        usage = {
            "input_tokens": u.prompt_tokens if u else 0,
            "output_tokens": u.completion_tokens if u else 0,
            "reasoning_tokens": 0,
        }

    if not content:
        raise ValueError("LLM response content is None or empty")

    return content.strip(), usage


def clean_llm_output(output: str) -> str:
    """Clean the LLM output to extract just the MLIR code."""
    # Remove markdown code blocks if present
    if "```mlir" in output:
        start = output.find("```mlir") + 7
        end = output.find("```", start)
        if end != -1:
            output = output[start:end].strip()
    elif "```" in output:
        start = output.find("```") + 3
        end = output.find("```", start)
        if end != -1:
            output = output[start:end].strip()

    return output


def save_transformer(output: str, output_dir: Path, op_name: str) -> Path:
    """Save the generated transformer to a file."""
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / f"kb_{op_name.lower()}.mlir"

    with open(output_file, "w") as f:
        f.write(output)

    return output_file


def save_instantiated_prompt(prompt: str, output_dir: Path, op_name: str) -> Path:
    """Save the instantiated prompt to a .md file."""
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / f"instantiated_prompt_{op_name.lower()}.md"

    with open(output_file, "w") as f:
        f.write(prompt)

    return output_file


def run_eval(op_file_path: str, transformer_file: Path, op_name: str) -> int:
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

    print(f"\nRunning evaluation: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=False)
    return result.returncode


def main():
    """Main entry point for the agent."""
    parser = argparse.ArgumentParser(
        description="Synthesize transfer functions using LLM",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "op_file",
        type=str,
        help="Path to the operation MLIR file (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        default="outputs/agent",
        help="Output directory for generated transformers",
    )
    parser.add_argument(
        "--skip-eval",
        action="store_true",
        help="Skip running eval-final after generation",
    )
    parser.add_argument(
        "--model",
        type=str,
        default="gpt-4",
        help="OpenAI model to use (e.g., gpt-4, gpt-3.5-turbo)",
    )

    args = parser.parse_args()

    # Prefer OPENAI_API_KEY env var; fall back to agent/api_key.txt
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_key_file = Path(__file__).parent / "api_key.txt"
        if api_key_file.exists():
            api_key = api_key_file.read_text().strip()
    if not api_key:
        print(
            "Error: No API key found. Set OPENAI_API_KEY or create agent/api_key.txt",
            file=sys.stderr,
        )
        return 1

    # Extract operation name
    op_name = extract_op_name(args.op_file)
    print(f"Synthesizing transformer for operation: {op_name}")

    # Read files
    print("Reading prompt template and operation file...")
    prompt_template = read_prompt_template()
    op_content = read_op_file(args.op_file)

    # Instantiate prompt
    prompt = instantiate_prompt(prompt_template, op_name, op_content)

    # Save instantiated prompt as .md
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    instantiated_prompt_file = save_instantiated_prompt(prompt, output_dir, op_name)
    print(f"Instantiated prompt saved to: {instantiated_prompt_file}")

    # Call LLM
    print("Calling OpenAI API...")
    llm_output, usage = call_llm(prompt, api_key, args.model)
    inp = usage["input_tokens"]
    out = usage["output_tokens"]
    reasoning = usage.get("reasoning_tokens") or 0
    total = inp + out + reasoning
    if reasoning:
        print(
            f"Tokens used: {inp:,} input, {out:,} output, {reasoning:,} reasoning ({total:,} total)"
        )
    else:
        print(f"Tokens used: {inp:,} input, {out:,} output ({total:,} total)")

    # Save raw LLM output for debugging
    llm_output_file = output_dir / f"llm_output_{op_name.lower()}.txt"
    with open(llm_output_file, "w") as f:
        f.write(llm_output)
    print(f"Raw LLM output saved to: {llm_output_file}")

    # Clean output
    clean_output = clean_llm_output(llm_output)

    # Save transformer
    transformer_file = save_transformer(clean_output, output_dir, op_name)
    print(f"Transformer saved to: {transformer_file}")

    # Run evaluation
    if not args.skip_eval:
        print("\nEvaluating transformer...")
        return_code = run_eval(args.op_file, transformer_file, op_name)
        if return_code == 0:
            print("Evaluation completed successfully!")
        else:
            print(f"Evaluation failed with return code {return_code}")
            return return_code

    print("\nAgent synthesis completed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
