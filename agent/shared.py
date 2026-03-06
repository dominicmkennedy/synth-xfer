"""Shared utilities for transformer synthesis methods."""
from dataclasses import dataclass

@dataclass
class LibraryState:
    """Current learned library state passed to synthesis prompts."""

    version: int
    functions_text: str


@dataclass
class CorpusFile:
    filename: str
    text: str


def build_library_learn_prompt(
    prompt_template: str,
    corpus: list[CorpusFile],
    existing_lib: LibraryState,
    ops_md: str,
) -> str:
    """Instantiate library learning prompt"""

    synth_functions = ""
    for file in corpus:
        synth_functions += f"// {file.filename}\n"
        synth_functions += f"{file.text}\n"

    prompt = prompt_template.replace("<SYNTHESIZED_FUNCTIONS>", synth_functions)
    prompt = prompt.replace("<EXISTING_LIBRARY>", existing_lib.functions_text)
    prompt = prompt.replace("<PRIMITIVE_OPERATORS>", ops_md)

    return prompt


def build_compression_prompt(
    prompt_template: str,
    target: CorpusFile,
    lib: LibraryState,
) -> str:
    """Instantiate compression prompt"""

    prompt = prompt_template.replace("<LIBRARY>", lib.functions_text)
    prompt = prompt.replace("<TARGET>", target.text)

    return prompt