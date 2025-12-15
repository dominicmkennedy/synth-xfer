from pathlib import Path

from synth_xfer._eval_engine import (
    enum_low_knownbits_4_4,
    enum_low_knownbits_4_4_4,
    enum_low_knownbits_8_8,
    enum_low_sconstrange_4_4,
    enum_low_uconstrange_4_4,
    eval_knownbits_4_4,
    eval_sconstrange_4_4,
    eval_uconstrange_4_4,
)
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import get_per_bit
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_func

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


def test_kb_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([4])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    jit = Jit()
    jit.add_mod(str(lowerer))
    conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
    xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

    to_eval = enum_low_knownbits_4_4(conc_op_addr, None)
    lattice_str = "\n".join(str(x[0]) for x in to_eval).strip()
    assert lattice_str == (DATA_DIR / "kb_lattice_4.txt").read_text().strip()

    raw_res = eval_knownbits_4_4(to_eval, [xfer_fn_addr], [])
    for x in to_eval:
        assert str(x[0]) == str(x[1])
    res = get_per_bit(raw_res)[0]
    assert (
        str(res).strip()
        == "bw: 4  all: 81    s: 81    e: 81    uall: 80    ue: 80    dis: 0       bdis: 54.0    sdis: 0"
    )


def test_ucr_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([4])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    jit = Jit()
    jit.add_mod(str(lowerer))
    conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
    xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

    to_eval = enum_low_uconstrange_4_4(conc_op_addr, None)
    lattice_str = "\n".join(str(x[0]) for x in to_eval).strip()
    assert lattice_str == (DATA_DIR / "ucr_lattice_4.txt").read_text().strip()

    raw_res = eval_uconstrange_4_4(to_eval, [xfer_fn_addr], [])
    for x in to_eval:
        assert str(x[0]) == str(x[1])
    res = get_per_bit(raw_res)[0]
    assert (
        str(res).strip()
        == "bw: 4  all: 136   s: 136   e: 136   uall: 135   ue: 135   dis: 0       bdis: 90.6667 sdis: 0"
    )


def test_scr_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([4])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    jit = Jit()
    jit.add_mod(str(lowerer))
    conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
    xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

    to_eval = enum_low_sconstrange_4_4(conc_op_addr, None)
    lattice_str = "\n".join(str(x[0]) for x in to_eval).strip()
    assert lattice_str == (DATA_DIR / "scr_lattice_4.txt").read_text().strip()

    raw_res = eval_sconstrange_4_4(to_eval, [xfer_fn_addr], [])
    for x in to_eval:
        assert str(x[0]) == str(x[1])
    res = get_per_bit(raw_res)[0]
    assert (
        str(res).strip()
        == "bw: 4  all: 136   s: 136   e: 136   uall: 135   ue: 135   dis: 0       bdis: 90.6667 sdis: 0"
    )


def test_kb_n_ary_kb_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.KnownBits)

    lowerer = LowerToLLVM([4, 8])
    lowerer.add_fn(helpers.crt_func, shim=True)

    jit = Jit()
    jit.add_mod(str(lowerer))
    conc_op_4_addr = jit.get_fn_ptr("concrete_op_4_shim")
    conc_op_8_addr = jit.get_fn_ptr("concrete_op_8_shim")

    to_eval_4 = enum_low_knownbits_4_4_4(conc_op_4_addr, None)
    to_eval_8 = enum_low_knownbits_8_8(conc_op_8_addr, None)
    assert len(to_eval_4) == len(to_eval_8)
