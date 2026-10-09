from argparse import ArgumentParser
import csv
from dataclasses import dataclass
import multiprocessing as mp
import os
from pathlib import Path
import sys

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import RefinementKind, allows_root_split, refine_pattern
from synth_xfer._util.pattern_dsl import PatternDag


@dataclass(frozen=True, slots=True)
class PatternCounts:
    counts: dict[str, int]
    rows: int
    merged: int
    capped: int


@dataclass(frozen=True, slots=True)
class PatternStats:
    unique: int
    weighted: int


@dataclass(frozen=True, slots=True)
class MergeStats:
    added: int
    collided: int


@dataclass(frozen=True, slots=True)
class ProcessResult:
    refined: dict[str, int]
    input: PatternStats
    complete: PatternStats
    unchanged: PatternStats
    producer_cut: PatternStats
    root_split: PatternStats
    middle_split: PatternStats
    producer_cut_merge: MergeStats
    split_merge: MergeStats
    split_leaves_dropped: int


def read_pattern_counts(path: Path, node_cap: int | None = None) -> PatternCounts:
    """Read <count, pattern> rows, summing counts of canonically-equal patterns.

    node_cap drops any pattern with >= node_cap operation nodes. refine_pattern
    cost explodes on large DAGs (a 50+ node pattern can take minutes each), so these
    rare giants otherwise dominate the wall time.
    """
    counts: dict[str, int] = {}
    rows = merged = capped = 0

    with path.open(newline="") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            rows += 1
            dag = PatternDag(row["pattern"])
            if node_cap is not None and len(dag.nodes) >= node_cap:
                capped += 1
                continue
            pattern = str(dag)
            if pattern in counts:
                merged += 1
            counts[pattern] = counts.get(pattern, 0) + int(row["count"])

    if capped:
        print(f"  {path}: dropped {capped} patterns with >= {node_cap} nodes")
    return PatternCounts(counts, rows, merged, capped)


@dataclass(frozen=True, slots=True)
class _Refined:
    source: str
    count: int
    kind: RefinementKind
    kept: tuple[str, ...]
    dropped: int


def _refine_one(source: str, count: int, domain: AbstractDomain) -> _Refined:
    refinement = refine_pattern(PatternDag(source), domain)
    return _Refined(
        source,
        count,
        refinement.kind,
        tuple(str(leaf) for leaf in refinement.kept),
        len(refinement.dropped),
    )


# Worker state, populated in the parent before the pool forks and inherited by
# each worker (avoids pickling the full input to every process).
_WORKER_ITEMS: list[tuple[str, int]] = []
_WORKER_DOMAIN: AbstractDomain | None = None


def _worker_setup() -> None:
    sys.setrecursionlimit(100000)


def _worker_refine(rng: tuple[int, int]) -> list[_Refined]:
    assert _WORKER_DOMAIN is not None
    return [
        _refine_one(source, count, _WORKER_DOMAIN)
        for source, count in _WORKER_ITEMS[rng[0] : rng[1]]
    ]


def _refine_all(
    input_counts: dict[str, int],
    domain: AbstractDomain,
    jobs: int,
) -> list[_Refined]:
    items = list(input_counts.items())
    if jobs <= 1 or len(items) < 2 * jobs:
        return [_refine_one(source, count, domain) for source, count in items]

    global _WORKER_ITEMS, _WORKER_DOMAIN
    _WORKER_ITEMS = items
    _WORKER_DOMAIN = domain
    n = len(items)
    step = -(-n // (jobs * 4))  # ceil; ~4 tasks per worker for load balance
    ranges = [(i, min(i + step, n)) for i in range(0, n, step)]
    try:
        ctx = mp.get_context("fork")
        with ctx.Pool(jobs, initializer=_worker_setup) as pool:
            parts = pool.map(_worker_refine, ranges)
    finally:
        _WORKER_ITEMS = []
        _WORKER_DOMAIN = None
    return [record for part in parts for record in part]


def _max_insert(counts: dict[str, int], text: str, count: int) -> None:
    counts[text] = max(counts.get(text, 0), count)


def _stats(records: list[_Refined]) -> PatternStats:
    return PatternStats(len(records), sum(record.count for record in records))


def process_pattern_counts(
    input_counts: dict[str, int],
    domain: AbstractDomain,
    jobs: int = 1,
) -> ProcessResult:
    records = _refine_all(input_counts, domain, jobs)
    by_kind: dict[RefinementKind, list[_Refined]] = {
        "complete": [],
        "unchanged": [],
        "producer_cut": [],
        "root_split": [],
        "middle_split": [],
    }
    for record in records:
        by_kind[record.kind].append(record)

    # Unchanged inputs seed the output; refinement results then merge in by max.
    # Collisions are counted against everything seeded before that stage.
    refined: dict[str, int] = {}
    for record in by_kind["unchanged"]:
        refined[record.source] = record.count
    seeded = set(refined)

    cut_texts: set[str] = set()
    for record in by_kind["producer_cut"]:
        (text,) = record.kept
        _max_insert(refined, text, record.count)
        cut_texts.add(text)
    cut_added = len(cut_texts - seeded)
    producer_cut_merge = MergeStats(cut_added, len(by_kind["producer_cut"]) - cut_added)
    seeded |= cut_texts

    leaf_texts: set[str] = set()
    leaves = dropped = 0
    for record in by_kind["root_split"] + by_kind["middle_split"]:
        dropped += record.dropped
        for text in record.kept:
            leaves += 1
            _max_insert(refined, text, record.count)
            leaf_texts.add(text)
    leaf_added = len(leaf_texts - seeded)
    split_merge = MergeStats(leaf_added, leaves - leaf_added)

    return ProcessResult(
        refined,
        PatternStats(len(input_counts), sum(input_counts.values())),
        _stats(by_kind["complete"]),
        _stats(by_kind["unchanged"]),
        _stats(by_kind["producer_cut"]),
        _stats(by_kind["root_split"]),
        _stats(by_kind["middle_split"]),
        producer_cut_merge,
        split_merge,
        dropped,
    )


def write_pattern_counts(
    path: Path,
    counts: dict[str, int],
    top: int | None,
) -> int:
    rows = sorted(counts.items(), key=lambda item: (-item[1], item[0]))
    if top is not None:
        rows = rows[:top]

    with path.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["count", "pattern"],
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        for pattern, count in rows:
            writer.writerow({"count": count, "pattern": pattern})

    return len(rows)


def _format_stats(label: str, stats: PatternStats, denominator: PatternStats) -> str:
    unique_percent = (
        0.0 if denominator.unique == 0 else 100.0 * stats.unique / denominator.unique
    )
    weighted_percent = (
        0.0
        if denominator.weighted == 0
        else 100.0 * stats.weighted / denominator.weighted
    )
    return (
        f"  {label}: {stats.unique} unique ({unique_percent:.2f}%), "
        f"{stats.weighted} weighted ({weighted_percent:.2f}%)"
    )


def main() -> None:
    p = ArgumentParser(description=__doc__)
    p.add_argument(
        "-i", "--input", type=Path, required=True, help="mined <count, pattern> TSV"
    )
    p.add_argument(
        "-o", "--output", type=Path, required=True, help="refined <count, pattern> TSV"
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(domain) for domain in AbstractDomain],
        required=True,
        help="abstract domain: selects the completeness table and whether a leaf "
        "may drop the root (KnownBits only)",
    )
    p.add_argument(
        "--top", type=int, default=None, help="keep only the N highest-count rows"
    )
    p.add_argument(
        "--jobs",
        type=int,
        default=os.cpu_count() or 1,
        help="parallel worker processes for refinement (default: all cores)",
    )
    args = p.parse_args()

    sys.setrecursionlimit(100000)
    domain = AbstractDomain[args.domain]

    inputs = read_pattern_counts(args.input)
    result = process_pattern_counts(inputs.counts, domain, jobs=args.jobs)
    written = write_pattern_counts(args.output, result.refined, args.top)
    output = PatternStats(len(result.refined), sum(result.refined.values()))
    cuts = result.producer_cut_merge
    splits = result.split_merge

    print("Stats:")
    print(f"  Input rows: {inputs.rows} ({inputs.merged} merged as canonical duplicates)")
    print(
        f"  Canonical inputs: {result.input.unique} unique, "
        f"{result.input.weighted} weighted"
    )
    print(_format_stats("Fully complete / dropped", result.complete, result.input))
    print(_format_stats("Unchanged incomplete", result.unchanged, result.input))
    print(_format_stats("Producer cut", result.producer_cut, result.input))
    print(f"    results: {cuts.added} added to output, {cuts.collided} collided")
    print(_format_stats("Root split", result.root_split, result.input))
    print(_format_stats("Middle split", result.middle_split, result.input))
    print(
        f"    leaves: {splits.added + splits.collided} kept "
        f"({splits.added} added, {splits.collided} collided), "
        f"{result.split_leaves_dropped} complete pieces dropped"
    )
    if not allows_root_split(domain):
        print("    (splits that drop the root are disabled for this domain)")
    print(f"  Output: {output.unique} unique, {output.weighted} weighted")
    print(f"  Wrote: {args.output} ({written} rows)")


if __name__ == "__main__":
    main()
