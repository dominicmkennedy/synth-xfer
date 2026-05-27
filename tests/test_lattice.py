from pathlib import Path

from synth_xfer._eval_engine import (
    enum_low_knownbits_4_4,
    # enum_low_knownbits_4_4_4,
    # enum_low_knownbits_8_8,
    # enum_low_mod3_8_8,
    enum_low_sconstrange_4_4,
    enum_low_uconstrange_4_4,
    eval_knownbits_4_4,
    # eval_mod3_8_8,
    eval_sconstrange_4_4,
    eval_uconstrange_4_4,
)
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import get_per_bit
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs, parse_mlir_func
from synth_xfer._util.pattern_dsl import PatternDag

DATA_DIR = Path(__file__).parent.parent / "tests" / "data"


def test_kb_lattice():
    lowerer = LowerToLLVM([4])
    helpers = HelperFuncs(PatternDag("PopCount"), AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_knownbits_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "kb_lattice_4.txt").read_text().strip()

        raw_res = eval_knownbits_4_4(to_eval, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 4  all: 81    s: 7     e: 4     uall: 81    ue: 4     dis: 5.4     bdis: 39.0    sdis: 36"
        )


def test_ucr_lattice():
    lowerer = LowerToLLVM([4])
    helpers = HelperFuncs(PatternDag("PopCount"), AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_uconstrange_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "ucr_lattice_4.txt").read_text().strip()

        raw_res = eval_uconstrange_4_4(to_eval, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 4  all: 136   s: 31    e: 3     uall: 136   ue: 3     dis: -12.5576bdis: 93.1639 sdis: 83.2889"
        )


def test_scr_lattice():
    lowerer = LowerToLLVM([4])
    helpers = HelperFuncs(PatternDag("PopCount"), AbstractDomain.SConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_sconstrange_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "scr_lattice_4.txt").read_text().strip()

        raw_res = eval_sconstrange_4_4(to_eval, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 4  all: 136   s: 47    e: 3     uall: 136   ue: 3     dis: 1.39462 bdis: 83.0093 sdis: 70.2545"
        )
