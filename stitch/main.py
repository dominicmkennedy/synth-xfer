import sys
import argparse

def main():
    """ Perform library learning with Stitch"""

    parser = argparse.ArgumentParser(description="Learn library functions with Stitch")
    parser.add_argument(
        "library_files", 
        nargs='+', 
        help="one or more MLIR files to learn from (e.g., mlir/Add.mlir mlir/Sub.mlir)"
    )
    parser.add_argument(
        "-o", "--output", default="outputs/learned/llm/", help="output directory"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=3,
        help="number of Stitch iterations (default: 3)",
    )
    parser.add_argument(
        "--max_arity",
        type=int,
        default=3,
        help="max arity of learned functions (default: 3)"
    )

    args = parser.parse_args()

if __name__ == "__main__":
    sys.exit(main())