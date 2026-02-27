import sys
import argparse
from stitch_core import compress
from .mlir_to_lam import mlir_file_to_lam
from .lam_to_mlir import lamstr_to_mlir
from pathlib import Path

def main():
    """ Perform library learning with Stitch"""

    parser = argparse.ArgumentParser(description="Learn library functions with Stitch")
    parser.add_argument(
        "library_files", 
        nargs='+', 
        help="one or more MLIR files to learn from (e.g., mlir/Add.mlir mlir/Sub.mlir)"
    )
    parser.add_argument(
        "-o", "--output", default="stdout", help="output directory"
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

    programs = []
    for file_path in args.library_files:
        programs += mlir_file_to_lam(Path(file_path))
    
    print(f"Read {len(programs)} functions")

    res = compress(programs, iterations=args.iterations, max_arity=args.max_arity)
    print("Library learning complete")

    if (args.output != 'stdout'):
        with open(args.output, 'w') as file:
            file.write(lamstr_to_mlir(''.join(f'{a}\n' for a in res.abstractions)))
        print(f"Wrote to file {args.output}")
    else:
        print(lamstr_to_mlir(''.join(f'{a}\n' for a in res.abstractions)))

if __name__ == "__main__":
    sys.exit(main())