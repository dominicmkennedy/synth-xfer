from pathlib import Path

import pytest

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_func
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer.cli.verify import verify_function

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_kb_and(solver_kind: SolverKind):
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "kb_and.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_ucr_add(solver_kind: SolverKind):
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Add.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "ucr_add.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_kb_nop(solver_kind: SolverKind):
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_ucr_nop(solver_kind: SolverKind):
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_scr_nop(solver_kind: SolverKind):
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.SConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True
