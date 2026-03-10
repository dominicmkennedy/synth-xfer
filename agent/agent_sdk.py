"""OpenAI Agent SDK method for transformer synthesis."""

import json
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

from .util import eval_transformer, merge_library_text
from .library_learning import LibraryState

# System instructions live as markdown files next to this module.
_AGENT_DIR = Path(__file__).parent


def _read_instruction_file(name: str) -> str:
    text = (_AGENT_DIR / name).read_text(encoding="utf-8")
    return text.strip()


AGENT_INSTRUCTIONS = _read_instruction_file("agent_instructions.md")
LEARN_INSTRUCTIONS = _read_instruction_file("learn_instructions.md")

# Helper stuff for debugging


def _format_tool_call_args(args) -> str:
    """Format tool-call arguments for dump: parse JSON if needed, return string with real newlines."""
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except (json.JSONDecodeError, TypeError):
            return args
    if isinstance(args, dict):
        parts = [
            f"{k}:\n{(v if isinstance(v, str) else str(v))}"
            for k, v in args.items()
        ]
        return "\n\n".join(parts)
    return args if isinstance(args, str) else str(args)


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
                args_str = _format_tool_call_args(args)[:2000].rstrip()
                lines.append("Arguments:")
                lines.extend(args_str.splitlines())
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
    library: LibraryState,
    model: str = "gpt-4",
    max_turns: int = 20,
) -> tuple[str, object]:
    """Run agent to synthesize transformer. Returns (final_output, run_result)."""

    agent_dir = Path(__file__).parent

    @function_tool
    def get_task_bundle() -> str:
        """Return the concrete operation/task bundle as JSON (op_name, op_file, and op_content)."""
        op_path = Path(op_file)
        bundle = {
            "op_name": op_name,
            "op_file": str(op_path),
            "op_content": op_path.read_text(encoding="utf-8"),
        }
        return json.dumps(bundle)

    @function_tool
    def get_program_templates() -> str:
        """Return the MLIR output templates (agent/template.mlir)."""
        return (agent_dir / "template.mlir").read_text(encoding="utf-8")

    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return (agent_dir / "ops.md").read_text(encoding="utf-8")

    @function_tool
    def get_library_text() -> str:
        """Return the current library MLIR (builtin.module text)."""
        return library.functions_text

    @function_tool
    def list_examples() -> str:
        """List available example transformer files as JSON array of filenames."""
        ex_dir = agent_dir / "examples"
        names = [p.name for p in sorted(ex_dir.glob("*.mlir"))] if ex_dir.exists() else []
        return json.dumps(names)

    @function_tool
    def get_example(name: str) -> str:
        """Return the contents of one example transformer file by filename (e.g. 'kb_xor.mlir')."""
        p = (agent_dir / "examples" / name).resolve()
        ex_dir = (agent_dir / "examples").resolve()
        if ex_dir not in p.parents:
            raise ValueError("example name must refer to a file under agent/examples/")
        if p.suffix != ".mlir":
            raise ValueError("example must be a .mlir file")
        return p.read_text(encoding="utf-8")

    @function_tool
    def search_examples(query: str, top_k: int = 3) -> str:
        """Search example transformer files by substring. Returns JSON array of matches with filename and snippet."""
        if top_k <= 0:
            return "[]"
        q = query.strip()
        if not q:
            return "[]"
        ex_dir = agent_dir / "examples"
        matches: list[dict] = []
        for p in sorted(ex_dir.glob("*.mlir")) if ex_dir.exists() else []:
            text = p.read_text(encoding="utf-8", errors="replace")
            idx = text.lower().find(q.lower())
            if idx == -1:
                continue
            start = max(0, idx - 200)
            end = min(len(text), idx + 200)
            matches.append(
                {"name": p.name, "start": start, "end": end, "snippet": text[start:end]}
            )
            if len(matches) >= top_k:
                break
        return json.dumps(matches)

    @function_tool
    def run_eval_tool(transformer_mlir: str) -> str:
        """Evaluate the generated transformer MLIR for the current operation (e.g. kb_<op>). Pass the raw MLIR code as a string. Evaluate on a low bitwidth (default: 4), and a high bitwidth (default: 64). Returns a short summary:
        - Sound %: the percentage of inputs for which the output abstract value is sound
        - Exact %: the percentage of inputs for which the output abstract value is exactly the same the optimal transfer function (perfect precision)
        - Norm: ignore for now
        """
        full_soln = merge_library_text(
            library.functions_text, 
            transformer_mlir
        )

        # Xuanyu: let agent understand simple metrics first for now. Use Norm later.
        return eval_transformer(
            solution_path=full_soln,
            op_path=Path(op_file),
            domain=AbstractDomain.KnownBits,
            xfer_name=f"kb_{op_name.lower()}",
        )

    agent = Agent(
        name="TransformerSynthesizer",
        instructions=AGENT_INSTRUCTIONS,
        tools=[
            get_task_bundle,
            get_program_templates,
            get_available_primitives,
            get_library_text,
            list_examples,
            get_example,
            search_examples,
            run_eval_tool,
        ],
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