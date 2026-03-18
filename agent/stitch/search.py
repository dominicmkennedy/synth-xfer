from __future__ import annotations

from dataclasses import dataclass
import heapq
import itertools
from pathlib import Path

from xdsl_smt.dialects.transfer import GetOp, MakeOp

from agent.stitch.converter import mlir_program_to_dags
from agent.stitch.matcher import match
from agent.stitch.util import DAG, Opcode, Vertex, iter_vertices


@dataclass
class PatternHit:
    pattern: DAG
    pattern_key: str
    total_matches: int
    matched_functions: dict[str, int]
    utility: int  # inst_count * total_matches


@dataclass
class SearchResult:
    op_sigs: list[Opcode]
    hits: list[PatternHit]


def _pattern_key(root: Vertex) -> str:
    """Canonical string key for a DAG pattern, handling shared nodes."""
    vertices = iter_vertices(root)
    index = {id(v): i for i, v in enumerate(vertices)}
    parts = []
    for i, v in enumerate(vertices):
        if v.opcode == Opcode.leaf():
            parts.append(f"{i}=leaf")
        else:
            args_str = ",".join(str(index[id(a)]) for a in v.args)
            parts.append(f"{i}={v.opcode.key}({args_str})")
    return "|".join(parts)


def _ancestors_of(root: Vertex, target: Vertex) -> set[int]:
    """Return IDs of all vertices from which `target` is reachable, including `target` itself."""
    target_id = id(target)
    ancestors: set[int] = set()

    def dfs(v: Vertex) -> bool:
        if id(v) == target_id:
            ancestors.add(id(v))
            return True
        for arg in v.args:
            if dfs(arg):
                ancestors.add(id(v))
                return True
        return False

    dfs(root)
    return ancestors


def _expand_pattern(pattern: DAG, op_sigs: list[Opcode]) -> list[DAG]:
    """Expand pattern by replacing each leaf with a new instruction.

    Each arg of the new instruction can be:
    - a fresh wildcard leaf node, OR
    - any existing node in the pattern that is not an ancestor of the replaced leaf
      (adding a back-edge to an ancestor would create a cycle).
    """
    results: list[DAG] = []
    leaves = [v for v in iter_vertices(pattern.root) if v.opcode == Opcode.leaf()]

    for leaf in leaves:
        ancestors = _ancestors_of(pattern.root, leaf)
        candidates = [v for v in iter_vertices(pattern.root) if id(v) not in ancestors]

        for opcode in op_sigs:
            k = opcode.arity
            # None sentinel = fresh leaf wildcard
            arg_choices: list[Vertex | None] = [None, *candidates]
            for combo in itertools.product(arg_choices, repeat=k):
                new_args = [
                    Vertex(opcode=Opcode.leaf()) if a is None else a for a in combo
                ]
                new_vertex = Vertex(opcode=opcode, args=new_args)
                results.append(pattern.clone_with_substitution(leaf, new_vertex))

    return results


def _collect_program_dags(paths: list[Path]) -> dict[str, DAG]:
    dags: dict[str, DAG] = {}
    for path in paths:
        for fn, dag in mlir_program_to_dags(path).items():
            dags[f"{path.name}:{fn}"] = dag
    return dags


def _collect_opcode_signatures(program_dags: dict[str, DAG]) -> list[Opcode]:
    seen: set[Opcode] = set()
    for dag in program_dags.values():
        for v in iter_vertices(dag.root):
            if v.opcode in (Opcode.leaf(), Opcode("block_argument", 0)):
                continue
            if isinstance(v.mlir_op, (GetOp, MakeOp)):
                continue
            seen.add(v.opcode)
    return sorted(seen, key=lambda s: (s.key, s.arity))


def _precompute_reachable_sizes(
    program_dags: dict[str, DAG],
) -> dict[str, dict[int, int]]:
    """For each program DAG, map vertex id → number of vertices reachable from it."""
    result: dict[str, dict[int, int]] = {}
    for fn_name, dag in program_dags.items():
        sizes: dict[int, int] = {}
        for v in iter_vertices(dag.root):
            sizes[id(v)] = len(iter_vertices(v))
        result[fn_name] = sizes
    return result


def _get_matches(
    pattern: DAG, program_dags: dict[str, DAG]
) -> tuple[int, dict[str, int], dict[str, list[Vertex]]]:
    """Return (total_matches, per_fn_counts, match_roots_by_fn)."""
    total = 0
    per_fn: dict[str, int] = {}
    roots_by_fn: dict[str, list[Vertex]] = {}
    for fn_name, prog in program_dags.items():
        matched = match(prog, pattern)
        if matched:
            per_fn[fn_name] = len(matched)
            roots_by_fn[fn_name] = matched
            total += len(matched)
    return total, per_fn, roots_by_fn


def _upper_bound(
    roots_by_fn: dict[str, list[Vertex]],
    reachable_sizes: dict[str, dict[int, int]],
) -> int:
    """UB on utility for any extension: sum of reachable-set sizes over all match roots."""
    return sum(
        reachable_sizes[fn][id(r)] for fn, roots in roots_by_fn.items() for r in roots
    )


def search_patterns(
    paths: list[Path], max_instructions: int = 3, top_k: int | None = None
) -> SearchResult:
    """Branch-and-bound search for high-utility DAG patterns.

    Utility = inst_count * total_matches.
    Upper bound for any extension of pattern P:
        UB(P) = sum_{r in match_roots(P)} |reachable_vertices(r)|
    Branches are pruned when UB <= k-th best utility seen so far.
    """
    program_dags = _collect_program_dags(paths)
    op_sigs = _collect_opcode_signatures(program_dags)
    reachable_sizes = _precompute_reachable_sizes(program_dags)

    global_ub = sum(sum(sizes.values()) for sizes in reachable_sizes.values())

    initial_patterns = [
        DAG(
            root=Vertex(
                opcode=sig, args=[Vertex(opcode=Opcode.leaf()) for _ in range(sig.arity)]
            )
        )
        for sig in op_sigs
    ]

    # search heap entries: (-ub, tie_break, pattern)
    counter = itertools.count()
    heap: list[tuple[int, int, DAG]] = [
        (-global_ub, next(counter), pat) for pat in initial_patterns
    ]
    heapq.heapify(heap)

    # top-k hits tracked as a min-heap of (utility, tie_break, hit)
    top_hits: list[tuple[int, int, PatternHit]] = []
    hit_counter = itertools.count()
    seen: set[str] = set()

    def threshold() -> int:
        """Pruning threshold: min utility among top-k (0 if fewer than k hits)."""
        if top_k is not None and len(top_hits) >= top_k:
            return top_hits[0][0]
        return 0

    while heap:
        neg_ub, _, pattern = heapq.heappop(heap)
        ub = -neg_ub
        if ub <= threshold():
            break  # heap property: all remaining entries have ub <= this

        key = _pattern_key(pattern.root)
        if key in seen:
            continue
        seen.add(key)

        total, per_fn, roots_by_fn = _get_matches(pattern, program_dags)
        if total == 0:
            continue

        utility = (pattern.inst_count - 1) * total
        hit = PatternHit(
            pattern=pattern,
            pattern_key=key,
            total_matches=total,
            matched_functions=per_fn,
            utility=utility,
        )
        entry = (utility, next(hit_counter), hit)
        if top_k is None:
            heapq.heappush(top_hits, entry)
        elif len(top_hits) < top_k:
            heapq.heappush(top_hits, entry)
        elif utility > top_hits[0][0]:
            heapq.heapreplace(top_hits, entry)

        if pattern.inst_count >= max_instructions:
            continue

        child_ub = _upper_bound(roots_by_fn, reachable_sizes)
        if child_ub <= threshold():
            continue

        for child in _expand_pattern(pattern, op_sigs):
            heapq.heappush(heap, (-child_ub, next(counter), child))

    hits = sorted([h for _, _, h in top_hits], key=lambda h: (-h.utility, h.pattern_key))
    return SearchResult(op_sigs=op_sigs, hits=hits)
