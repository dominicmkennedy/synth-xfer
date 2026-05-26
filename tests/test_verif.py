from pathlib import Path

import pytest

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import HelperFuncs, parse_mlir_func
from synth_xfer._util.pattern_dsl import PatternDag
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer.cli.verify import verify_function

DATA_DIR = Path(__file__).parent.parent / "tests" / "data"


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_kb_and(solver_kind: SolverKind):
    helpers = HelperFuncs(PatternDag("And"), AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "kb_and.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True


@pytest.mark.parametrize("solver_kind", list(SolverKind))
def test_verif_ucr_add(solver_kind: SolverKind):
    helpers = HelperFuncs(PatternDag("Add"), AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "ucr_add.mlir")
    for bw in range(1, 17):
        res, _ = verify_function(bw, xfer_mlir, [], helpers, 3, solver_kind)
        assert res is True
