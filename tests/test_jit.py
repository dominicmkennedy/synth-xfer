from pathlib import Path

from synth_xfer._eval_engine import (
    enum_low_knownbits_4_4_4,
    enum_low_uconstrange_4_4_4,
    enum_mid_knownbits_8_8_8,
    enum_mid_uconstrange_8_8_8,
    eval_knownbits_4_4_4,
    eval_knownbits_8_8_8,
    eval_uconstrange_4_4_4,
    eval_uconstrange_8_8_8,
)
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import get_per_bit
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_func
from synth_xfer._util.random import Sampler

PROJ_DIR = Path(__file__).parent.parent
DATA_DIR = PROJ_DIR / "tests" / "data"


def test_jit_with_kb_and():
    conc_and_f = PROJ_DIR / "mlir" / "Operations" / "And.mlir"

    lowerer = LowerToLLVM([4, 8])
    helpers = get_helper_funcs(conc_and_f, AbstractDomain.KnownBits)
    xfer_mlir = parse_mlir_func(DATA_DIR / "kb_and.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("kb_and_4_shim")

        to_eval_low = enum_low_knownbits_4_4_4(conc_op_addr.addr, None)
        raw_res = eval_knownbits_4_4_4(to_eval_low, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 4  all: 6561  s: 6561  e: 6561  uall: 6480  ue: 6480  dis: 0       bdis: 4374.0  sdis: 0"
        )

        conc_op_addr = jit.get_fn_ptr("concrete_op_8_shim")
        xfer_fn_addr = jit.get_fn_ptr("kb_and_8_shim")

        NUM_CASES = 5000
        sampler = Sampler.uniform()
        to_eval_mid = enum_mid_knownbits_8_8_8(
            conc_op_addr.addr, None, NUM_CASES, 100, sampler.sampler
        )
        raw_res = eval_knownbits_8_8_8(to_eval_mid, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert res.get_exact_prop() == 1.0
        assert res.all_cases == NUM_CASES
        assert res.bitwidth == 8


def test_jit_with_ucr_add():
    conc_add_f = PROJ_DIR / "mlir" / "Operations" / "Add.mlir"

    lowerer = LowerToLLVM([4, 8])
    helpers = get_helper_funcs(conc_add_f, AbstractDomain.UConstRange)
    xfer_mlir = parse_mlir_func(DATA_DIR / "cr_add.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("cr_add_4_shim")

        to_eval_low = enum_low_uconstrange_4_4_4(conc_op_addr.addr, None)
        raw_res = eval_uconstrange_4_4_4(to_eval_low, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 4  all: 18496 s: 18496 e: 18496 uall: 6920  ue: 6920  dis: 0       bdis: 4243.2  sdis: 0"
        )

        conc_op_addr = jit.get_fn_ptr("concrete_op_8_shim")
        xfer_fn_addr = jit.get_fn_ptr("cr_add_8_shim")

        NUM_CASES = 5000
        sampler = Sampler.uniform()
        to_eval_mid = enum_mid_uconstrange_8_8_8(
            conc_op_addr.addr, None, NUM_CASES, 100, sampler.sampler
        )
        raw_res = eval_uconstrange_8_8_8(to_eval_mid, [xfer_fn_addr.addr], [])
        res = get_per_bit(raw_res)[0]
        assert res.get_exact_prop() == 1.0
        assert res.all_cases == NUM_CASES
        assert res.bitwidth == 8
