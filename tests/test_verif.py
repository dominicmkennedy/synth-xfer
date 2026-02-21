import importlib.util
from pathlib import Path
import re

import pytest

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_func
from synth_xfer.cli.verify import _parse_counter_example, verify_function

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"
HAS_CVC5 = importlib.util.find_spec("cvc5") is not None


def test_verif_kb_and():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3)
        assert res is True


def test_verif_ucr_add():
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Add.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "cr_add.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3)
        assert res is True


def test_verif_kb_nop():
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3)
        assert res is True


def test_verif_ucr_nop():
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3)
        assert res is True


def test_verif_scr_nop():
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.SConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3)
        assert res is True


def test_verif_unsound_counterexample_parse_ucr():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    bw = 4

    res, model = verify_function(bw, xfer_mlir, [], helpers, 3)

    assert res is False
    assert model is not None

    conc_args, abst_args = _parse_counter_example(
        model, AbstractDomain.UConstRange, bw, len(helpers.crt_func.args)
    )
    assert len(conc_args) == len(helpers.crt_func.args)
    assert len(abst_args) == len(helpers.crt_func.args)
    assert all(0 <= x < (1 << bw) for x in conc_args)
    assert all(re.fullmatch(r"\[\d+, \d+\]", s) for s in abst_args)


@pytest.mark.skipif(not HAS_CVC5, reason="cvc5 backend not installed")
def test_verif_kb_and_cvc5():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    for bw in range(1, 9):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, "cvc5")
        assert res is True


@pytest.mark.skipif(not HAS_CVC5, reason="cvc5 backend not installed")
def test_verif_unsound_counterexample_parse_ucr_cvc5():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    bw = 4

    res, model = verify_function(bw, xfer_mlir, [], helpers, 3, "cvc5")
    assert res is False
    assert model is not None

    conc_args, abst_args = _parse_counter_example(
        model, AbstractDomain.UConstRange, bw, len(helpers.crt_func.args)
    )
    assert len(conc_args) == len(helpers.crt_func.args)
    assert len(abst_args) == len(helpers.crt_func.args)
    assert all(0 <= x < (1 << bw) for x in conc_args)
    assert all(re.fullmatch(r"\[\d+, \d+\]", s) for s in abst_args)
