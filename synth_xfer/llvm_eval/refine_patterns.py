from argparse import ArgumentParser
import csv
from dataclasses import dataclass
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import refine_pattern
from synth_xfer._util.pattern_dsl import PatternDag


@dataclass(frozen=True, slots=True)
class LoadedPatterns:
    counts: dict[str, int]
    rows: int
    canonical_collisions: int
    canonical_collision_count_delta: int


def _read_patterns(path: Path) -> LoadedPatterns:
    patterns: dict[str, int] = {}
    rows = 0
    canonical_collisions = 0
    canonical_collision_count_delta = 0
    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        fieldnames = set(reader.fieldnames or ())
        required = {"count", "pattern"}
        missing = sorted(required - fieldnames)
        if missing:
            raise ValueError(f"{path}: missing required columns: {', '.join(missing)}")

        for row in reader:
            pattern = str(PatternDag(row["pattern"]))
            count = int(row["count"])
            rows += 1
            if pattern in patterns:
                canonical_collisions += 1
                canonical_collision_count_delta += count
                patterns[pattern] += count
            else:
                patterns[pattern] = count

    return LoadedPatterns(
        patterns,
        rows,
        canonical_collisions,
        canonical_collision_count_delta,
    )


def _write_patterns(path: Path, patterns: dict[str, int]) -> None:
    rows = sorted(patterns.items(), key=lambda item: (-item[1], item[0]))
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["count", "pattern"], delimiter="\t")
        writer.writeheader()
        for pattern, count in rows:
            writer.writerow({"count": count, "pattern": pattern})


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("-i", "--input", type=Path, required=True)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(domain) for domain in AbstractDomain],
        required=True,
    )
    args = parser.parse_args()

    domain = AbstractDomain[args.domain]
    pattern_input = _read_patterns(args.input)
    pattern_counts = pattern_input.counts
    refined_counts: dict[str, int] = {}
    added_patterns: set[str] = set()
    existing_refined_patterns: set[str] = set()
    total_refinement_results = 0
    unchanged_refinement_results = 0
    changed_refinement_results = 0
    sources_with_changed_refinements = 0
    sources_with_no_output = 0

    for pattern_text, count in pattern_counts.items():
        pattern = PatternDag(pattern_text)
        refined_patterns = refine_pattern(pattern, domain)
        if not refined_patterns:
            sources_with_no_output += 1

        source_changed = False

        for refined_pattern in refined_patterns:
            total_refinement_results += 1
            refined_text = str(refined_pattern)
            if refined_text == pattern_text:
                unchanged_refinement_results += 1
            else:
                changed_refinement_results += 1
                source_changed = True

            if refined_text not in pattern_counts:
                refined_count = count
                if refined_text not in added_patterns:
                    added_patterns.add(refined_text)
            else:
                existing_refined_patterns.add(refined_text)
                refined_count = max(count, pattern_counts[refined_text])

            refined_counts[refined_text] = max(
                refined_counts.get(refined_text, 0),
                refined_count,
            )

        if source_changed:
            sources_with_changed_refinements += 1

    _write_patterns(args.output, refined_counts)
    print("Stats:")
    print(f"  Input rows: {pattern_input.rows}")
    print(f"  Canonical input patterns: {len(pattern_counts)}")
    print(f"  Canonical input collisions: {pattern_input.canonical_collisions}")
    print(
        "  Counts added by canonical input collisions: "
        f"{pattern_input.canonical_collision_count_delta}"
    )
    print(f"  Output patterns: {len(refined_counts)}")
    print(f"  Total refinement results: {total_refinement_results}")
    print(f"  Changed refinement results: {changed_refinement_results}")
    print(f"  Unchanged refinement results: {unchanged_refinement_results}")
    print(f"  Sources with changed refinements: {sources_with_changed_refinements}")
    print(f"  Sources dropped by refinement: {sources_with_no_output}")
    print(f"  Refined patterns already in input: {len(existing_refined_patterns)}")
    print(f"  Refined patterns added: {len(added_patterns)}")
    print(f"  Wrote: {args.output}")


if __name__ == "__main__":
    main()
