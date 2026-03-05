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
    existing_lib: str,
    ops_md: str,
) -> str:
    """Instantiate library learning prompt"""

    synth_functions = "\n".join([file.text for file in corpus])

    prompt = prompt_template.replace("<SYNTHESIZED_FUNCTIONS>", synth_functions)
    prompt = prompt.replace("<EXISTING_LIBRARY>", existing_lib)
    prompt = prompt.replace("<PRIMITIVE_OPERATORS>", ops_md)

    return prompt