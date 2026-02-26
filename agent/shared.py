"""Shared utilities for transformer synthesis methods."""

from pathlib import Path
import re


def extract_op_name(op_file_path: str) -> str:
    """Extract operation name from file path (e.g., mlir/Operations/Add.mlir -> Add)."""
    return Path(op_file_path).stem


def _read_file(path: Path) -> str:
    """Helper to read file content."""
    return path.read_text()


def read_prompt_template() -> str:
    """Read prompt template, removing HTML comments (<!-- -->)."""
    content = _read_file(Path(__file__).parent / "prompt.md")
    return re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL).strip()


def read_op_file(op_file_path: str) -> str:
    """Read operation MLIR file."""
    return _read_file(Path(op_file_path))


def read_example_files() -> str:
    """Read all example .mlir files from examples directory."""
    examples_dir = Path(__file__).parent / "examples"
    examples = [
        f"Example from {f.name}:\n```mlir\n{_read_file(f)}```"
        for f in sorted(examples_dir.glob("*.mlir"))
    ]
    return "\n\n".join(examples)


def read_ops_json() -> str:
    """Read operations documentation."""
    return _read_file(Path(__file__).parent / "ops.md")


def read_template_mlir() -> str:
    """Read MLIR template."""
    return _read_file(Path(__file__).parent / "template.mlir")


def instantiate_prompt(template: str, op_name: str, op_content: str) -> str:
    """Instantiate prompt template with operation details."""
    op_lower = op_name.lower()
    prompt = template.replace("<OP>", op_lower).replace("<Op>", op_name)
    prompt += f"\n\nAvailable operations:\n{read_ops_json()}"

    examples = read_example_files()
    if examples:
        prompt += f"\n\nKnownBits examples:\n\n{examples}"

    prompt += f"\n\nOperation: mlir/Operations/{op_name}.mlir\n```mlir\n{op_content}\n```"
    prompt += f"\n\nMLIR template (fill only TODOs):\n```mlir\n{read_template_mlir()}```"
    prompt += f"\n\nGenerate kb_{op_lower}.mlir by filling in only the TODO parts."
    return prompt


def clean_llm_output(output: str) -> str:
    """Extract MLIR code from LLM output, removing markdown blocks."""
    for fence in ["```mlir", "```"]:
        if fence in output:
            start = output.find(fence) + len(fence)
            end = output.find("```", start)
            if end != -1:
                return output[start:end].strip()
    return output


def _save_file(content: str, path: Path) -> Path:
    """Helper to save file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


def save_transformer(output: str, output_dir: Path, op_name: str) -> Path:
    """Save generated transformer to kb_{op_name}.mlir."""
    return _save_file(output, Path(output_dir) / f"kb_{op_name.lower()}.mlir")


def save_instantiated_prompt(prompt: str, output_dir: Path, op_name: str) -> Path:
    """Save instantiated prompt to instantiated_prompt_{op_name}.md."""
    return _save_file(
        prompt, Path(output_dir) / f"instantiated_prompt_{op_name.lower()}.md"
    )
