import json

from agents.items import (
    ItemHelpers,
    MessageOutputItem,
    ReasoningItem,
    ToolCallItem,
    ToolCallOutputItem,
)

from .util import summarize_token_usage

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
            f"{k}:\n{(v if isinstance(v, str) else str(v))}" for k, v in args.items()
        ]
        return "\n\n".join(parts)
    return args if isinstance(args, str) else str(args)


def format_agent_run_dump(result, model: str | None = None) -> str:
    """Format a RunResult into a readable dump of the full agent run (messages, tool calls, outputs)."""
    token_summary = summarize_token_usage(result, model=model)
    lines: list[str] = [
        "=== Agent run dump ===",
        "",
        str(token_summary),
        "",
    ]

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
