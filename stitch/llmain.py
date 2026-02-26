import sys
import argparse

def main():
    """ Perform library learning with an LLM """

    parser = argparse.ArgumentParser(description="Learn library functions with an LLM")
    parser.add_argument(
        "library_files", 
        nargs='+', 
        help="one or more MLIR files to learn from (e.g., mlir/Add.mlir mlir/Sub.mlir)"
    )
    parser.add_argument(
        "-o", "--output", default="outputs/learned/llm/", help="output directory"
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

if __name__ == "__main__":
    sys.exit(main())