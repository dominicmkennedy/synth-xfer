from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


def test_mod3_lowering():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16, 64])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod3)
    lowerer.add_fn(helpers.get_top_func, shim=True)
    lowerer.add_fn(helpers.meet_func, shim=True)
    lowerer.add_fn(helpers.transfer_func, shim=True)

    assert str(lowerer) == (DATA_DIR / "mod3_lowering.ll").read_text()


def test_mod5_lowering():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16, 64])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod5)
    lowerer.add_fn(helpers.get_top_func, shim=True)
    lowerer.add_fn(helpers.meet_func, shim=True)
    lowerer.add_fn(helpers.transfer_func, shim=True)

    assert str(lowerer) == (DATA_DIR / "mod5_lowering.ll").read_text()


def test_mod7_lowering():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16, 64])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod7)
    lowerer.add_fn(helpers.get_top_func, shim=True)
    lowerer.add_fn(helpers.meet_func, shim=True)
    lowerer.add_fn(helpers.transfer_func, shim=True)

    assert str(lowerer) == (DATA_DIR / "mod7_lowering.ll").read_text()


def test_mod11_lowering():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16, 64])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod11)
    lowerer.add_fn(helpers.get_top_func, shim=True)
    lowerer.add_fn(helpers.meet_func, shim=True)
    lowerer.add_fn(helpers.transfer_func, shim=True)

    assert str(lowerer) == (DATA_DIR / "mod11_lowering.ll").read_text()


def test_mod13_lowering():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16, 64])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod13)
    lowerer.add_fn(helpers.get_top_func, shim=True)
    lowerer.add_fn(helpers.meet_func, shim=True)
    lowerer.add_fn(helpers.transfer_func, shim=True)

    assert str(lowerer) == (DATA_DIR / "mod13_lowering.ll").read_text()
