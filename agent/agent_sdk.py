"""OpenAI Agent SDK method for transformer synthesis."""

from pathlib import Path

from agents import Agent, Runner, function_tool
from agents.items import (
    ItemHelpers,
    MessageOutputItem,
    ReasoningItem,
    ToolCallItem,
    ToolCallOutputItem,
)

from synth_xfer._util.domain import AbstractDomain

from .util import eval_transformer

# System Instructions
AGENT_INSTRUCTIONS = """You synthesize KnownBits transfer functions in MLIR. You have an eval tool that evaluates your transformer.
- Before writing any MLIR: reason step-by-step about the operation semantics and how each output bit should update known-zero and known-one. Aim for a sound and precise transfer, not just the first candidate that passes eval.
- You must call the eval tool with your MLIR before returning. If it returns an error (e.g. parse error), fix the MLIR and call again.
- If eval returns unsound (Sound %% < 100), you had to fix the soundness and should not return yet.
- If eval returns sound but low precison (Sound %% = 100 and Exact %% is low), reason about why (e.g. missing cases, wrong bit propagation) and try a better design before submitting the next candidate; do not only make minimal syntax fixes.
- Only when the tool returns sound (Sound %% = 100) and you are satisfied with the precision (Exact %% is high), return that MLIR as your final answer. Prefer a well-reasoned, precise implementation over stopping at the first passing candidate.
- In your final message return only the MLIR code, no explanation.
- Each line of MLIR must be exactly one operation from the allowed ops; do not write %x = %y (use the value directly in the next op or in transfer.make)."""

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


def run_agent_synthesis(
    prompt: str,
    op_file: str,
    op_name: str,
    api_key: str,
    model: str = "gpt-4",
    max_turns: int = 20,
) -> tuple[str, object]:
    """Run agent to synthesize transformer. Returns (final_output, run_result)."""

    @function_tool
    def run_eval_tool(transformer_mlir: str) -> str:
        """Evaluate the generated transformer MLIR for the current operation (e.g. kb_<op>). Pass the raw MLIR code as a string. Evaluate on a low bitwidth (default: 4), and a high bitwidth (default: 64). Returns a short summary:
        - Sound %: the percentage of inputs for which the output abstract value is sound
        - Exact %: the percentage of inputs for which the output abstract value is exactly the same the optimal transfer function (perfect precision)
        - Norm: ignore for now
        """
        # Xuanyu: let agent understand simple metrics first for now. Use Norm later.
        return eval_transformer(
            solution_path=transformer_mlir,
            op_path=Path(op_file),
            domain=AbstractDomain.KnownBits,
            xfer_name=f"kb_{op_name.lower()}",
        )

    agent = Agent(
        name="TransformerSynthesizer",
        instructions=AGENT_INSTRUCTIONS,
        tools=[run_eval_tool],
        model=model,
    )

    # Full task as user message
    MAX_TURN_MESSAGE = f"You have a maximum of {max_turns} iterations to complete this task.  Do not exceed this limit."
    user_message = prompt + "\n" + MAX_TURN_MESSAGE
    result = Runner.run_sync(agent, user_message, max_turns=max_turns)

    return (result.final_output, result)


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