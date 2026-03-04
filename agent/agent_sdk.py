"""OpenAI Agent SDK method for transformer synthesis."""

from agents import Agent, Runner
from agents.items import (
    ItemHelpers,
    MessageOutputItem,
    ReasoningItem,
    ToolCallItem,
    ToolCallOutputItem,
)

# System Instructions
LEARN_INSTRUCTIONS = """You extract reusable helper functions from KnownBits transfer functions written in MLIR.             
- Before writing any MLIR: read all input transfer functions and identify sub-computations that recur across them or that encode a coherent semantic concept (e.g. "the maybe-zero mask", "carry propagation"). Name the concept before writing the code.
- Only extract non-trivial helpers: a function must be at least 3 operations and must mean something in the KnownBits domain. Do not wrap a single op in a function.
- Do not re-emit the transfer functions themselves, and do not duplicate any function already present in the existing library.
- Each line of MLIR must be exactly one allowed operation; do not write %x = %y.
- In your final message return only the builtin.module containing the new library functions, no explanation."""

# Helper stuff for debugging
def format_agent_run_dump(result) -> str:
    """Format a RunResult into a readable dump of the full agent run (messages, tool calls, outputs)."""
    lines: list[str] = ["=== Agent run dump ===", ""]

    for i, item in enumerate(result.new_items):
        lines.append(
            f"--- Item {i + 1}: {getattr(item, 'type', type(item).__name__)} ---"
        )
        if isinstance(item, MessageOutputItem):
            text = ItemHelpers.text_message_output(item)
            lines.append(text.strip() or "(empty message)")
        elif isinstance(item, ReasoningItem):
            raw = getattr(item, "raw_item", None)
            if raw is not None and hasattr(raw, "content"):
                lines.append(str(raw.content)[:2000])
            else:
                lines.append(str(raw)[:2000] if raw is not None else "(no reasoning)")
        elif isinstance(item, ToolCallItem):
            raw = getattr(item, "raw_item", None)
            name = getattr(raw, "name", None) or (
                raw.get("name") if isinstance(raw, dict) else None
            )
            args = getattr(raw, "arguments", None) or (
                raw.get("arguments") if isinstance(raw, dict) else None
            )
            lines.append(f"Tool call: {name}")
            if args is not None:
                args_str = str(args) if not isinstance(args, str) else args
                lines.append(f"Arguments: {args_str[:1500]}")
        elif isinstance(item, ToolCallOutputItem):
            out = getattr(item, "output", None)
            lines.append(f"Tool output: {str(out)[:2000]}")
        else:
            lines.append(str(item)[:1500])
        lines.append("")

    lines.append("=== Raw responses (summary) ===")
    for j, resp in enumerate(result.raw_responses):
        usage = getattr(resp, "usage", None)
        usage_str = str(usage) if usage else "?"
        lines.append(f"Response {j + 1}: usage={usage_str}")
    return "\n".join(lines)

def run_agent_learn(
    prompt: str,
    model: str = "gpt-4",
) -> tuple[str, object]:
    """Run agent to learn library functions. Returns (final_output, run_result)."""

    agent = Agent(
        name="LibraryFunctionLearner",
        instructions=LEARN_INSTRUCTIONS,
        model=model,
    )

    result = Runner.run_sync(agent, prompt)

    return (result.final_output, result)