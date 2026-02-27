import sys
import argparse
import os
from pathlib import Path

def get_api_key() -> str:
    """Get API key from env var or file."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_file = Path(__file__).parent / "api_key.txt"
        if api_file.exists():
            api_key = api_file.read_text().strip()
    if not api_key:
        raise ValueError(
            "API key not found. Set OPENAI_API_KEY or create agent/api_key.txt"
        )
    return api_key

def main():
    """ Perform library learning with an LLM """

    parser = argparse.ArgumentParser(description="Learn library functions with an LLM")
    parser.add_argument(
        "library_files", 
        nargs='+', 
        help="one or more MLIR files to learn from (e.g., mlir/Add.mlir mlir/Sub.mlir)"
    )
    parser.add_argument(
        "-o", "--output", default="stdout", help="output directory"
    )
    parser.add_argument("--model", default="gpt-4", help="OpenAI model")
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=3,
        help="max iterations for agent (default: 3)",
    )

    args = parser.parse_args()
    api_key = get_api_key()

if __name__ == "__main__":
    sys.exit(main())