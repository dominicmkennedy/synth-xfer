import pytest

from synth_xfer._eval_engine import (
    ArgsKnownBits_4_4,
    KnownBits4,
    KnownBits8,
    KnownBits16,
    KnownBits32,
    KnownBits64,
    Mod34,
    SConstRange4,
    SConstRange8,
    SConstRange16,
    SConstRange32,
    SConstRange64,
    ToEvalKnownBits_4_4_4,
    ToEvalKnownBits_4_4_4_4,
    UConstRange4,
    UConstRange8,
    UConstRange16,
    UConstRange32,
    UConstRange64,
)


def test_knownbits_parse():
    bw_4 = "10?0"
    bw_8 = "10?0??01"
    bw_16 = "1100??0110?0??01"
    bw_32 = "?0?111???010???01100??0110?0??01"
    bw_64 = "?0?111???000???01100??0110?0??01?0?111???000???01100??0110?0??01"

    assert str(KnownBits4(bw_4)) == bw_4
    assert str(KnownBits8(bw_8)) == bw_8
    assert str(KnownBits16(bw_16)) == bw_16
    assert str(KnownBits32(bw_32)) == bw_32
    assert str(KnownBits64(bw_64)) == bw_64

    with pytest.raises(ValueError):
        KnownBits4(bw_8)

    with pytest.raises(ValueError):
        KnownBits8(bw_4)

    with pytest.raises(ValueError):
        KnownBits16(bw_32)

    with pytest.raises(ValueError):
        KnownBits32(bw_16)

    with pytest.raises(ValueError):
        KnownBits4(bw_64)

    with pytest.raises(ValueError):
        KnownBits64(bw_4)


def test_ucr_parse():
    bw_4 = "[1, 15]"
    bw_8 = "[1, 200]"
    bw_16 = "[0, 0]"
    bw_32 = "[0, 4000000000]"
    bw_64 = "[4, 18000000000000000000]"

    assert str(UConstRange4(bw_4)) == bw_4
    assert str(UConstRange8(bw_8)) == bw_8
    assert str(UConstRange16(bw_16)) == bw_16
    assert str(UConstRange32(bw_32)) == bw_32
    assert str(UConstRange64(bw_64)) == bw_64

    with pytest.raises(ValueError):
        UConstRange4("[0, 16]")

    with pytest.raises(ValueError):
        UConstRange16("[-10, 100]")

    with pytest.raises(ValueError):
        UConstRange32("[-10, -1]")


def test_scr_parse():
    bw_4 = "[-8, 6]"
    bw_8 = "[-128, -127]"
    bw_16 = "[-32768, -32767]"
    bw_32 = "[-2147483648, 2147483646]"
    bw_64 = "[-9223372036854775807, 9223372036854775807]"

    assert str(SConstRange4(bw_4)) == bw_4
    assert str(SConstRange8(bw_8)) == bw_8
    assert str(SConstRange16(bw_16)) == bw_16
    assert str(SConstRange32(bw_32)) == bw_32
    assert str(SConstRange64(bw_64)) == bw_64

    with pytest.raises(ValueError):
        SConstRange4("[8, 9]")

    with pytest.raises(ValueError):
        SConstRange8("[-256, 255]")


def test_mod3_parse():
    test_str_1 = "{1,2} mod3"
    assert str(Mod34(test_str_1)) == test_str_1

    test_str_2 = "{1} mod3"
    assert str(Mod34(test_str_2)) == test_str_2

    test_str_3 = "{0,2} mod3"
    assert str(Mod34(test_str_3)) == test_str_3


def test_domain_top_bottom():
    assert str(KnownBits8.top()) == "????????"
    assert str(KnownBits8.bottom()) == "(bottom)"

    assert str(UConstRange8.top()) == "[0, 255]"
    assert str(UConstRange8.bottom()) == "(bottom)"

    assert str(SConstRange8.top()) == "[-128, 127]"
    assert str(SConstRange8.bottom()) == "(bottom)"

    assert str(Mod34.top()) == "{0,1,2} mod3"
    assert str(Mod34.bottom()) == "(bottom)"


def test_parse_to_eval():
    rows = [
        (("10?0", "0?1?"), "1??0"),
        (("1???", "0?1?"), "?000"),
        (("1??0", "000?"), "1??0"),
    ]
    to_eval = ToEvalKnownBits_4_4_4(rows)
    assert len(to_eval) == 3

    row_i = iter(to_eval)
    row = next(row_i)
    assert str(row[0][0]) == "10?0"
    assert str(row[0][1]) == "0?1?"
    assert str(row[1]) == "1??0"

    row = next(row_i)
    assert str(row[0][0]) == "1???"
    assert str(row[0][1]) == "0?1?"
    assert str(row[1]) == "?000"

    row = next(row_i)
    assert str(row[0][0]) == "1??0"
    assert str(row[0][1]) == "000?"
    assert str(row[1]) == "1??0"

    with pytest.raises(ValueError):
        ToEvalKnownBits_4_4_4_4(rows)


def test_parse_to_run():
    rows = [
        ("10?0", "0?1?"),
        ("1???", "0?1?"),
        ("1??0", "000?"),
    ]
    to_run = ArgsKnownBits_4_4(rows)
    assert len(to_run) == 3

    row_i = iter(to_run)
    row = next(row_i)
    assert str(row[0]) == "10?0"
    assert str(row[1]) == "0?1?"

    row = next(row_i)
    assert str(row[0]) == "1???"
    assert str(row[1]) == "0?1?"

    row = next(row_i)
    assert str(row[0]) == "1??0"
    assert str(row[1]) == "000?"

    with pytest.raises(ValueError):
        ArgsKnownBits_4_4([("10?0",)])

    with pytest.raises(ValueError):
        ArgsKnownBits_4_4([("10?0", "10?0", "10?0")])
