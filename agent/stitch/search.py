from __future__ import annotations

from dataclasses import dataclass
import heapq
import itertools
from pathlib import Path

from xdsl_smt.dialects.transfer import GetOp, MakeOp

from agent.stitch.converter import mlir_program_to_dags
from agent.stitch.matcher import match, match_with_all_bindings
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
    patterns_considered: int


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


def _expand_pattern_guided(
    pattern: DAG,
    bindings_by_fn: dict[str, list[dict[int, Vertex]]],
) -> list[DAG]:
    """Expand pattern guided by actual match bindings.

    Instead of enumerating all (N+1)^k argument combinations for each opcode,
    only generates expansions for (opcode, arg-combo) tuples that actually appear
    in the current match data. This is complete: any child with non-zero matches
    must correspond to some match where the leaf was bound to a vertex with that
    opcode, so no valid children are missed.

    For each match binding, the leaf's bound program vertex determines the opcode.
    Arguments are set to existing pattern nodes where the program's children are
    already bound, and to fresh wildcards otherwise. All 2^(shared-args)
    generalizations are generated and deduplicated across matches.
    """
    pattern_vertices = iter_vertices(pattern.root)
    pattern_by_id = {id(v): v for v in pattern_vertices}
    leaves = [v for v in pattern_vertices if v.opcode == Opcode.leaf()]

    results: list[DAG] = []
    seen_combos: set[tuple] = set()

    for leaf in leaves:
        ancestors = _ancestors_of(pattern.root, leaf)
        non_ancestor_ids = {id(v) for v in pattern_vertices if id(v) not in ancestors}

        for bindings_list in bindings_by_fn.values():
            for bindings in bindings_list:
                prog_v = bindings.get(id(leaf))
                if prog_v is None or _is_excluded_vertex(prog_v):
                    continue

                opcode = prog_v.opcode

                # Reverse map: id(program_vertex) -> pattern_vertex
                prog_to_pattern: dict[int, Vertex] = {}
                for pid, pv_prog in bindings.items():
                    prog_to_pattern[id(pv_prog)] = pattern_by_id[pid]

                # For each arg of prog_v, use the matching pattern node if it's a
                # non-ancestor; otherwise fall back to a fresh wildcard (None).
                base_args: list[Vertex | None] = []
                for child in prog_v.args:
                    pat_v = prog_to_pattern.get(id(child))
                    if pat_v is not None and id(pat_v) in non_ancestor_ids:
                        base_args.append(pat_v)
                    else:
                        base_args.append(None)

                # Generate all generalizations: replace some specific-node args
                # with fresh wildcards to produce less-constrained patterns.
                specific_positions = [i for i, a in enumerate(base_args) if a is not None]
                for mask in range(1 << len(specific_positions)):
                    combo = list(base_args)
                    for j, pos in enumerate(specific_positions):
                        if not (mask >> j & 1):
                            combo[pos] = None

                    combo_key = (
                        id(leaf),
                        opcode,
                        tuple(id(a) if a is not None else -1 for a in combo),
                    )
                    if combo_key in seen_combos:
                        continue
                    seen_combos.add(combo_key)

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


# Ops excluded from pattern search — edit this tuple to add/remove exclusions
EXCLUDED_OP_TYPES: tuple[type, ...] = (GetOp, MakeOp)


def _is_excluded_vertex(v: Vertex) -> bool:
    if v.opcode in (Opcode.leaf(), Opcode("block_argument", 0)):
        return True
    if isinstance(v.mlir_op, EXCLUDED_OP_TYPES):
        return True
    return False


def _reachable_inst_count(root: Vertex) -> int:
    """Count non-excluded vertices reachable from root, stopping traversal at excluded nodes."""
    seen: set[int] = set()
    count = 0

    def dfs(v: Vertex) -> None:
        nonlocal count
        if id(v) in seen:
            return
        seen.add(id(v))
        if _is_excluded_vertex(v):
            return
        count += 1
        for arg in v.args:
            dfs(arg)

    dfs(root)
    return count


def _collect_opcode_signatures(program_dags: dict[str, DAG]) -> list[Opcode]:
    seen: set[Opcode] = set()
    for dag in program_dags.values():
        for v in iter_vertices(dag.root):
            if _is_excluded_vertex(v):
                continue
            seen.add(v.opcode)
    return sorted(seen, key=lambda s: (s.key, s.arity))


def _precompute_reachable_sizes(
    program_dags: dict[str, DAG],
) -> dict[str, dict[int, int]]:
    """For each program DAG, map vertex id → non-excluded inst count reachable from it."""
    result: dict[str, dict[int, int]] = {}
    for fn_name, dag in program_dags.items():
        sizes: dict[int, int] = {}
        for v in iter_vertices(dag.root):
            sizes[id(v)] = _reachable_inst_count(v)
        result[fn_name] = sizes
    return result


def _get_matches(
    pattern: DAG, program_dags: dict[str, DAG]
) -> tuple[
    int, dict[str, int], dict[str, list[Vertex]], dict[str, list[dict[int, Vertex]]]
]:
    """Return (total_matches, per_fn_counts, match_roots_by_fn, bindings_by_fn)."""
    total = 0
    per_fn: dict[str, int] = {}
    roots_by_fn: dict[str, list[Vertex]] = {}
    bindings_by_fn: dict[str, list[dict[int, Vertex]]] = {}
    for fn_name, prog in program_dags.items():
        matched = match(prog, pattern)
        if matched:
            per_fn[fn_name] = len(matched)
            roots_by_fn[fn_name] = matched
            bindings_by_fn[fn_name] = match_with_all_bindings(prog, pattern)
            total += len(matched)
    return total, per_fn, roots_by_fn, bindings_by_fn


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

    ptn_cnt = 0
    while heap:
        neg_ub, _, pattern = heapq.heappop(heap)
        ub = -neg_ub
        if ub <= threshold():
            break  # heap property: all remaining entries have ub <= this

        key = _pattern_key(pattern.root)
        if key in seen:
            continue
        seen.add(key)
        ptn_cnt += 1

        total, per_fn, roots_by_fn, bindings_by_fn = _get_matches(pattern, program_dags)
        if total == 0:
            continue

        utility = (pattern.inst_count - 1) * total
        # print(f"[debug] {pattern} ")
        # print(f"[debug] total_matches={total} utility={utility} ub={ub} threshold={threshold()}")
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

        for child in _expand_pattern_guided(pattern, bindings_by_fn):
            heapq.heappush(heap, (-child_ub, next(counter), child))

    hits = sorted([h for _, _, h in top_hits], key=lambda h: (-h.utility, h.pattern_key))
    return SearchResult(op_sigs=op_sigs, hits=hits, patterns_considered=ptn_cnt)
