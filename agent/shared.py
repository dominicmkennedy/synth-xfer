"""Shared utilities for transformer synthesis methods."""

def build_library_learn_prompt(
    prompt_template: str,
    synth_functions: str,
    existing_lib: str,
    ops_md: str,
) -> str:
    """Instantiate library learning prompt"""

    prompt = prompt_template.replace("<SYNTHESIZED_FUNCTIONS>", synth_functions)
    prompt = prompt.replace("<EXISTING_LIBRARY>", existing_lib)
    prompt = prompt.replace("<PRIMITIVE_OPERATORS>", ops_md)

    return prompt