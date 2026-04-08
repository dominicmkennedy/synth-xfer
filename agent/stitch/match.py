from __future__ import annotations

import argparse
from pathlib import Path

from agent.stitch.converter import mlir_program_to_dags, mlir_program_to_single_dag
from agent.stitch.matcher import match_with_bindings
from agent.stitch.util import Vertex


def _op_line(v: Vertex, source: str) -> str:
    if v.mlir_op is None:
        return "<unknown>"
    op_str = str(v.mlir_op).strip()
    for lineno, line in enumerate(source.splitlines(), 1):
        if op_str in line:
            return f"line {lineno}: {line.strip()}"
    return op_str


def match_pattern_in_program(program_paths: list[Path], pattern_path: Path) -> None:
    pattern_dag = mlir_program_to_single_dag(pattern_path)
    root_id = id(pattern_dag.root)

    for prog_path in program_paths:
        source = prog_path.read_text()
        prog_dags = mlir_program_to_dags(prog_path)

        for func_name, prog_dag in prog_dags.items():
            all_bindings = match_with_bindings(prog_dag, pattern_dag)
            if not all_bindings:
                print(f"=== {prog_path}  @{func_name}: no matches ===")
                continue
            print(f"=== {prog_path}  @{func_name}: {len(all_bindings)} match(es) ===")
            for i, bindings in enumerate(all_bindings, 1):
                root_vertex = bindings[root_id]
                print(f"  Match {i}: {_op_line(root_vertex, source)}")


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Find where a pattern appears in MLIR program files"
    )
    p.add_argument("pattern_file", help="MLIR file defining the pattern function")
    p.add_argument("mlir_files", nargs="+", help="MLIR program files to search")
    return p.parse_args()


def main() -> None:
    args = _parse_args()
    match_pattern_in_program(
        [Path(f).resolve() for f in args.mlir_files],
        Path(args.pattern_file).resolve(),
    )


if __name__ == "__main__":
    main()
