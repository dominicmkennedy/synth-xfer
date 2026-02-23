"""OpenAI Agent SDK method for transformer synthesis."""

from pathlib import Path

from agents import Agent, Runner, function_tool


def run_agent_synthesis(
    prompt: str,
    op_file: str,
    op_name: str,
    api_key: str,
    model: str = "gpt-4",
) -> str:
    """Run agent to synthesize transformer."""

    @function_tool
    def run_eval_tool(transformer_mlir: str) -> str:
        """Tool for agent to run evaluation on generated transformer."""
        from agent.main import run_eval

        return run_eval(op_file, Path(transformer_mlir), op_name)

    agent = Agent(
        name="TransformerSynthesizer",
        instructions=prompt,  ## Xuanyu: insert the whole prompt as instructions is stupid, improve later
        tools=[run_eval_tool],
    )

    result = Runner.run_sync(
        agent, "only return MLIR code in the final output"
    )  ## Xuanyu: this task description also needs improvement

    # Xuanyu: Figure out a way to tell agent use the tool

    # Xuanyu: Find a way to import the python eval function instead of using command line tool.

    return result.final_output


def process_tool_call(tool_name: str, tool_input: dict) -> str:
    raise NotImplementedError(f"TODO: Implement handler for tool: {tool_name}")
