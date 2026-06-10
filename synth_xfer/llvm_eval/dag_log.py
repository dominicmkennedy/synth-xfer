"""Parsing for the truncated-DAG logs produced by ``run_opt_benchmark --slice-kb``.

A `.dag` log is a stream of records emitted on stderr by
`opt -enable-knownbits-dag-logging`. Each record is one truncated DAG seen at a
`computeKnownBits` visit, written on a single line in the root-first SSA form
that :meth:`PatternDag.from_ssa` accepts:

    %0 = Select(%1, arg0, arg1); %1 = ICmpUlt(arg0, arg1)

``%0`` is the result; every operand references a higher ``%K`` (an earlier op)
or a boundary input ``argJ``. :meth:`PatternDag.from_ssa` validates op names,
arities, operand types, contiguous args, and acyclicity, and restores interior
sharing exactly (a ``%K`` used twice is one shared node).

The DAG's identity downstream is its canonical ``str(dag)`` -- which also
normalizes commutative operand order and swapped icmp predicates, so variants
the C++ serializer leaves distinct collapse here.
"""

from synth_xfer._util.pattern_dsl import PatternDag


def parse_record(line: str) -> PatternDag | None:
    """Parse one SSA-line record into a PatternDag, or None if malformed."""
    try:
        return PatternDag.from_ssa(line)
    except ValueError:
        return None


def count_blocks(path: str) -> dict[str, int]:
    """Count records in one .dag file by their raw line text. Pure string ops --
    no parsing or validation, which is deferred to the few distinct lines. Lines
    that are not records (stray debug / stderr noise) are skipped. Top-level so
    it pickles."""
    counts: dict[str, int] = {}
    try:
        with open(path, "r", errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.startswith("%0"):
                    counts[line] = counts.get(line, 0) + 1
    except OSError:
        return counts
    return counts
