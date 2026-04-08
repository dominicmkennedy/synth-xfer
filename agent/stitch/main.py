from __future__ import annotations

import argparse
from pathlib import Path

from agent.stitch.search import search_patterns


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Top-down DAG pattern search over MLIR files")
    p.add_argument(
        "mlir_files",
        nargs="+",
        help="One or more MLIR files (for example corpus/llm/llm_add.mlir)",
    )
    p.add_argument(
        "--max-instructions",
        type=int,
        default=3,
        help="Maximum number of non-leaf instructions in a pattern",
    )
    p.add_argument(
        "--top-k",
        type=int,
        default=1,
        help="Number of top patterns to find by utility (inst_count * matches)",
    )
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    paths = [Path(p).resolve() for p in args.mlir_files]
    result = search_patterns(
        paths, max_instructions=args.max_instructions, top_k=args.top_k
    )

    hits = [h for h in result.hits if h.pattern.inst_count >= 2]

    for hit in hits:
        print(
            f"=== utility={hit.utility} | size = {hit.pattern.inst_count} | {hit.total_matches} matches ==="
        )
        print(hit.pattern)
        print()

    print(f"patterns considered: {result.patterns_considered}")


if __name__ == "__main__":
    main()
