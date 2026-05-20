from __future__ import annotations

from agent.stitch.util import DAG, Opcode, Vertex, iter_vertices


def _is_leaf(v: Vertex) -> bool:
    return v.opcode == Opcode.leaf()


def _match_vertex(
    prog_v: Vertex,
    pattern_v: Vertex,
    bindings: dict[int, Vertex],
) -> bool:
    pid = id(pattern_v)
    bound = bindings.get(pid)
    if bound is not None:
        return bound is prog_v

    if _is_leaf(pattern_v):
        bindings[pid] = prog_v
        return True

    if prog_v.opcode != pattern_v.opcode:
        return False

    if len(prog_v.args) != len(pattern_v.args):
        return False

    bindings[pid] = prog_v
    for prog_arg, pattern_arg in zip(prog_v.args, pattern_v.args, strict=True):
        if not _match_vertex(prog_arg, pattern_arg, bindings):
            return False

    return True


def match(prog: DAG, pattern: DAG) -> list[Vertex]:
    """Return all vertices in `prog` that match `pattern`.

    Pattern special case:
    - opcode == "leaf": matches any subtree.
    """
    matches: list[Vertex] = []

    for candidate in iter_vertices(prog.root):
        if _match_vertex(candidate, pattern.root, {}):
            matches.append(candidate)

    return matches


def match_with_bindings(prog: DAG, pattern: DAG) -> list[dict[int, Vertex]]:
    """Return one bindings dict per match.

    Each dict maps id(pattern_vertex) -> program_vertex for every non-leaf
    pattern vertex, i.e. the program ops directly involved in the match.
    """
    pattern_vertices = iter_vertices(pattern.root)
    non_leaf_ids = {id(v) for v in pattern_vertices if not _is_leaf(v)}

    result: list[dict[int, Vertex]] = []
    for candidate in iter_vertices(prog.root):
        bindings: dict[int, Vertex] = {}
        if _match_vertex(candidate, pattern.root, bindings):
            result.append({k: v for k, v in bindings.items() if k in non_leaf_ids})

    return result


def match_with_all_bindings(prog: DAG, pattern: DAG) -> list[dict[int, Vertex]]:
    """Return one bindings dict per match, including leaf bindings.

    Each dict maps id(pattern_vertex) -> program_vertex for every pattern vertex
    (both leaves and non-leaves). Used by match-guided expansion to know which
    program vertex each leaf was bound to.
    """
    result: list[dict[int, Vertex]] = []
    for candidate in iter_vertices(prog.root):
        bindings: dict[int, Vertex] = {}
        if _match_vertex(candidate, pattern.root, bindings):
            result.append(bindings)
    return result
