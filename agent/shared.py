"""Shared utilities for transformer synthesis methods."""


def build_prompt(
    prompt_template: str,
    op_name: str,
    op_content: str,
    template_mlir: str,
    examples: str,
    ops_md: str,
    library_functions: str = "TODO",
) -> str:
    """Instantiate prompt template with operation details."""
    # Replace operation name placeholders
    op_lower = op_name.lower()
    prompt = prompt_template.replace("<OP>", op_name)
    prompt = prompt.replace("<op>", op_lower)

    # Replace content placeholders
    prompt = prompt.replace("<CONCRETE_OPERATION>", op_content)
    prompt = prompt.replace("<PROGRAM_TEMPLATES>", template_mlir)
    prompt = prompt.replace("<TRANSFORMER_EXAMPLES>", examples)
    prompt = prompt.replace("<PRIMITIVE_OPERATORS>", ops_md)
    prompt = prompt.replace("<LIBRARY_FUNCTIONS>", library_functions)

    return prompt

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