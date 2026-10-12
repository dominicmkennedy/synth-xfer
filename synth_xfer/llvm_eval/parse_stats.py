from argparse import ArgumentParser
from dataclasses import dataclass
import json
from pathlib import Path
import sys

from synth_xfer._util.domain import AbstractDomain

RELATIVE_REDUCED_SCALE = 1000
CONST_RANGE_BITS_SCALE = 10_000_000


@dataclass(frozen=True, slots=True)
class StatKeys:
    num_queries: str
    bits_added: str
    vanilla_bits: str
    bits_scale: int
    relative_reduced: str
    improved_queries: str


STAT_KEYS: dict[AbstractDomain, StatKeys] = {
    AbstractDomain.KnownBits: StatKeys(
        num_queries="value-tracking.NumKBTopLevelQueries",
        bits_added="value-tracking.PatternKBBitsAddedTopLevel",
        vanilla_bits="value-tracking.TotalVanillaKnownBitsTopLevelIntNonConstant",
        bits_scale=1,
        relative_reduced="value-tracking.PatternKBRelativeReducedTopLevel",
        improved_queries="value-tracking.NumPatternKBImprovedQueriesTopLevel",
    ),
    AbstractDomain.UConstRange: StatKeys(
        num_queries="value-tracking.NumUCRTopLevelQueries",
        bits_added="value-tracking.PatternUCRPrecisionTenMillionthBitsAddedTopLevel",
        vanilla_bits=(
            "value-tracking.PatternUCRVanillaPrecisionTenMillionthBitsTopLevelNonConstant"
        ),
        bits_scale=CONST_RANGE_BITS_SCALE,
        relative_reduced="value-tracking.PatternUCRRelativeReducedTopLevel",
        improved_queries="value-tracking.NumPatternUCRImprovedQueriesTopLevel",
    ),
    AbstractDomain.SConstRange: StatKeys(
        num_queries="value-tracking.NumSCRTopLevelQueries",
        bits_added="value-tracking.PatternSCRPrecisionTenMillionthBitsAddedTopLevel",
        vanilla_bits=(
            "value-tracking.PatternSCRVanillaPrecisionTenMillionthBitsTopLevelNonConstant"
        ),
        bits_scale=CONST_RANGE_BITS_SCALE,
        relative_reduced="value-tracking.PatternSCRRelativeReducedTopLevel",
        improved_queries="value-tracking.NumPatternSCRImprovedQueriesTopLevel",
    ),
}


def _load_stats(path: Path) -> dict[str, int]:
    with path.open() as f:
        data = json.load(f)
    if not isinstance(data, dict):
        sys.exit(f"error: {path}: expected a JSON object at the top level")
    stats: dict[str, int] = {}
    for key, value in data.items():
        if isinstance(value, bool) or not isinstance(value, int):
            sys.exit(f"error: {path}: value of {key!r} is not an integer: {value!r}")
        stats[str(key)] = value
    return stats


def _ratio(numerator: int | float, denominator: int | float) -> float:
    return numerator / denominator if denominator else float("nan")


def main() -> None:
    p = ArgumentParser(
        description="Summarise one domain's pattern impact from a run_opt_benchmark "
        "--stats JSON"
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(domain) for domain in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    p.add_argument("stats", type=Path, help="stats JSON written by run_opt_benchmark")
    args = p.parse_args()

    domain = AbstractDomain[args.domain]
    if domain not in STAT_KEYS:
        sys.exit(f"error: no value-tracking counters for domain {domain}")
    keys = STAT_KEYS[domain]
    stats = _load_stats(args.stats)

    missing = [
        key
        for key in (
            keys.num_queries,
            keys.bits_added,
            keys.vanilla_bits,
            keys.relative_reduced,
            keys.improved_queries,
        )
        if key not in stats
    ]
    if missing:
        sys.exit(
            f"error: {args.stats}: missing {len(missing)} {domain} key(s):\n  "
            + "\n  ".join(missing)
        )

    bits_added = stats[keys.bits_added] / keys.bits_scale
    vanilla_bits = stats[keys.vanilla_bits] / keys.bits_scale
    improved_queries = stats[keys.improved_queries]
    num_queries = stats[keys.num_queries]
    relative_reduced = stats[keys.relative_reduced] / RELATIVE_REDUCED_SCALE

    bits_text = f"{int(bits_added):,}" if keys.bits_scale == 1 else f"{bits_added:,.2f}"
    rows = [
        ("absolute precision bits gained", bits_text),
        (
            "precision gain over vanilla",
            f"{100 * _ratio(bits_added, vanilla_bits):.3f}%",
        ),
        ("number of queries made more precise", f"{improved_queries:,}"),
        (
            "share of queries made more precise",
            f"{100 * _ratio(improved_queries, num_queries):.3f}%",
        ),
        (
            "mean reduction of improved results",
            f"{100 * _ratio(relative_reduced, improved_queries):.3f}%",
        ),
    ]
    width = max(len(label) for label, _ in rows)
    for label, text in rows:
        print(f"{label:<{width}}  {text}")


if __name__ == "__main__":
    main()
