from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_func

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


def test_xfer_lowering():
    kb_and_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    kb_or_mlir = parse_mlir_func(DATA_DIR / "kb_or.mlir")
    kb_xor_mlir = parse_mlir_func(DATA_DIR / "kb_xor.mlir")
    ucr_add_mlir = parse_mlir_func(DATA_DIR / "ucr_add.mlir")

    lowerer = LowerToLLVM([4, 8, 64])
    lowerer.add_fn(kb_and_mlir, shim=True)
    lowerer.add_fn(kb_or_mlir, shim=True)
    lowerer.add_fn(kb_xor_mlir, shim=True)
    lowerer.add_fn(ucr_add_mlir, shim=True)
    assert str(lowerer) == (DATA_DIR / "xfer_lowering.ll").read_text()


def test_conc_lowering():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Add.mlir"

    lowerer = LowerToLLVM([4, 8, 64])
    and_kb_helpers = get_helper_funcs(conc_and_f, AbstractDomain.KnownBits)
    lowerer.add_fn(and_kb_helpers.meet_func)
    lowerer.add_fn(and_kb_helpers.get_top_func)
    lowerer.add_fn(and_kb_helpers.crt_func, shim=True)
    assert str(lowerer) == (DATA_DIR / "kb_and_conc.ll").read_text()

    lowerer = LowerToLLVM([4, 8, 64])
    add_ucr_helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    lowerer.add_fn(add_ucr_helpers.meet_func)
    lowerer.add_fn(add_ucr_helpers.get_top_func)
    lowerer.add_fn(add_ucr_helpers.crt_func, shim=True)
    assert str(lowerer) == (DATA_DIR / "ucr_add_conc.ll").read_text()


    lowerer = LowerToLLVM([4, 8, 64])
    add_scr_helpers = get_helper_funcs(conc_add_f, AbstractDomain.SConstRange)
    lowerer.add_fn(add_scr_helpers.meet_func)
    lowerer.add_fn(add_scr_helpers.get_top_func)
    lowerer.add_fn(add_scr_helpers.crt_func, shim=True)
    assert str(lowerer) == (DATA_DIR / "scr_add_conc.ll").read_text()
