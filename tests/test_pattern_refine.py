import pytest

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import refine_pattern
from synth_xfer._util.pattern_dsl import PatternDag
from synth_xfer.llvm_eval.process_patterns import MergeStats, process_pattern_counts

KB = AbstractDomain.KnownBits
UCR = AbstractDomain.UConstRange


def canon(text: str) -> str:
    return str(PatternDag(text))


def refined(text: str, domain: AbstractDomain) -> tuple[str, list[str], list[str]]:
    result = refine_pattern(PatternDag(text), domain)
    return (
        result.kind,
        sorted(str(leaf) for leaf in result.kept),
        sorted(str(leaf) for leaf in result.dropped),
    )


@pytest.mark.parametrize(
    "text",
    [
        # Used to flip between two renderings on every pass.
        "Add(Add(Add(arg0, arg1), arg2), Xor(And(Add(Add(Add(arg3, arg4), arg5), "
        "Xor(And(arg6, arg7), arg8)), Xor(arg9, arg10)), arg10))",
        "Xor(And(Add(Add(Add(Add(arg0, arg1), Xor(arg2, arg3)), Add(Add(arg4, arg5), "
        "Xor(arg6, arg7))), arg8), Xor(arg9, arg10)), arg10)",
        "Add(Xor(Add(arg0, arg1), arg2), Xor(Add(arg3, arg4), Or(arg5, arg6)))",
        "Add(arg1, arg0)",
        "ICmpSgt(arg1, arg0)",
        "Sub(arg0, arg0)",
        "Or(Lshr(arg0, arg1), arg0)",
    ],
)
def test_canonical_text_is_a_fixpoint(text: str) -> None:
    once = canon(text)
    assert canon(once) == once


def test_canonical_single_node_shorthand() -> None:
    assert canon("Add(arg1, arg0)") == "Add"
    assert canon("ICmpSgt(arg1, arg0)") == "ICmpSlt"
    assert canon("ICmpSgt(arg0, arg1)") == "ICmpSgt"
    assert canon("Sub(arg0, arg0)") == "Sub(arg0, arg0)"


def test_canonical_text_ignores_arg_numbering() -> None:
    assert canon(
        "Add(Xor(Add(arg3, arg4), Or(arg5, arg6)), Xor(Add(arg0, arg1), arg2))"
    ) == canon("Add(Xor(Add(arg0, arg1), arg2), Xor(Add(arg3, arg4), Or(arg5, arg6)))")


def test_kb_fully_complete_is_dropped() -> None:
    assert refined("And(Add(arg0, arg1), arg2)", KB) == ("complete", [], ["Add", "And"])


def test_kb_incomplete_is_unchanged() -> None:
    kind, kept, _ = refined("Add(Mul(arg0, arg1), arg2)", KB)
    assert kind == "unchanged"
    assert kept == [canon("Add(Mul(arg0, arg1), arg2)")]


def test_kb_producer_cut_keeps_root() -> None:
    assert refined("Add(Mul(arg0, arg1), Xor(arg2, arg3))", KB) == (
        "producer_cut",
        [canon("Add(Mul(arg0, arg1), arg2)")],
        ["Xor"],
    )


def test_kb_root_split_one_leaf() -> None:
    assert refined("And(Add(Mul(arg0, arg1), arg2), arg3)", KB) == (
        "root_split",
        [canon("Add(Mul(arg0, arg1), arg2)")],
        ["And"],
    )


def test_kb_root_split_two_leaves() -> None:
    kind, kept, dropped = refined(
        "And(Add(Mul(arg0, arg1), arg2), Sub(Mul(arg3, arg4), arg5))", KB
    )
    assert kind == "root_split"
    assert kept == sorted(
        [canon("Add(Mul(arg0, arg1), arg2)"), canon("Sub(Mul(arg0, arg1), arg2)")]
    )
    assert dropped == ["And"]


def test_kb_root_split_peels_several_ops() -> None:
    assert refined(
        "Add(ZextBool(ICmpEq(Add(Mul(arg0, arg1), arg2), arg3)), arg4)", KB
    ) == (
        "root_split",
        [canon("ICmpEq(Add(Mul(arg0, arg1), arg2), arg3)")],
        ["Add", "ZextBool"],
    )


def test_kb_root_split_wins_over_producer_cut() -> None:
    assert refined("And(Add(Mul(arg0, arg1), Xor(arg2, arg3)), arg4)", KB) == (
        "root_split",
        [canon("Add(Mul(arg0, arg1), arg2)")],
        ["And", "Xor"],
    )


def test_kb_middle_split_keeps_both_sides() -> None:
    kind, kept, dropped = refined(
        "Add(Select(arg0, Add(Mul(arg1, arg2), arg3), arg4), arg5)", KB
    )
    assert kind == "middle_split"
    assert kept == sorted(
        [
            canon("Add(Mul(arg0, arg1), arg2)"),
            canon("Add(Select(arg0, arg1, arg2), arg3)"),
        ]
    )
    assert dropped == []


def test_kb_shared_arg_blocks_split() -> None:
    assert refined("And(Add(arg0, arg1), Add(arg0, arg2))", KB)[0] == "unchanged"


def test_root_split_only_in_knownbits() -> None:
    text = "Select(arg0, Add(Mul(arg1, arg2), arg3), arg4)"
    assert refined(text, KB) == (
        "root_split",
        [canon("Add(Mul(arg0, arg1), arg2)")],
        ["Select"],
    )
    assert refined(text, UCR)[0] == "unchanged"
    assert refined("Umax(AshrExact(Sub(arg0, arg1), arg2), arg3)", UCR)[0] == "unchanged"


def test_ucr_producer_cut_still_applies() -> None:
    assert refined("Umax(Add(arg0, arg1), Mul(arg2, Sub(arg3, arg4)))", UCR) == (
        "producer_cut",
        [canon("Umax(Mul(Sub(arg0, arg1), arg2), arg3)")],
        ["Add"],
    )


def test_process_pattern_counts_accounting_and_idempotence() -> None:
    inputs = {
        canon(text): count
        for text, count in [
            ("Add(Mul(arg0, arg1), arg2)", 5),  # unchanged
            ("Add(Mul(arg0, arg1), Xor(arg2, arg3))", 3),  # producer cut, collides
            ("And(Add(Mul(arg0, arg1), arg2), arg3)", 9),  # root split, collides
            ("Sub(Mul(arg0, arg1), Xor(arg2, arg3))", 2),  # producer cut, new text
            ("And(Add(arg0, arg1), arg2)", 7),  # fully complete
        ]
    }
    result = process_pattern_counts(inputs, KB, jobs=1)

    assert result.refined == {
        canon("Add(Mul(arg0, arg1), arg2)"): 9,
        canon("Sub(Mul(arg0, arg1), arg2)"): 2,
    }
    assert (result.complete.unique, result.complete.weighted) == (1, 7)
    assert (result.unchanged.unique, result.unchanged.weighted) == (1, 5)
    assert (result.producer_cut.unique, result.producer_cut.weighted) == (2, 5)
    assert result.producer_cut_merge == MergeStats(added=1, collided=1)
    assert (result.root_split.unique, result.root_split.weighted) == (1, 9)
    assert result.middle_split.unique == 0
    assert result.split_merge == MergeStats(added=0, collided=1)
    assert result.split_leaves_dropped == 1

    again = process_pattern_counts(result.refined, KB, jobs=1)
    assert again.refined == result.refined
    assert again.unchanged.unique == len(result.refined)
