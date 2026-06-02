from ctypes import CFUNCTYPE, c_uint64
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs, parse_mlir_func
from synth_xfer._util.pattern_dsl import PatternDag

DATA_DIR = Path(__file__).parent.parent / "tests" / "data"


def test_xfer_lowering():
    kb_and_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "kb_and.mlir")
    kb_or_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "kb_or.mlir")
    kb_xor_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "kb_xor.mlir")
    cr_add_mlir = parse_mlir_func(DATA_DIR / "ideal_xfers" / "ucr_add.mlir")

    lowerer = LowerToLLVM([4, 8, 64])
    lowerer.add_fn(kb_and_mlir, shim=True)
    lowerer.add_fn(kb_or_mlir, shim=True)
    lowerer.add_fn(kb_xor_mlir, shim=True)
    lowerer.add_fn(cr_add_mlir, shim=True)
    assert str(lowerer) == (DATA_DIR / "xfer_lowering.ll").read_text()


def test_conc_lowering():
    lowerer = LowerToLLVM([4, 8, 64])
    and_kb_helpers = HelperFuncs(PatternDag("And"), AbstractDomain.KnownBits)
    lowerer.add_fn(and_kb_helpers.meet_func)
    lowerer.add_fn(and_kb_helpers.get_top_func)
    lowerer.add_fn(and_kb_helpers.crt_func, shim=True)
    assert str(lowerer) == (DATA_DIR / "kb_and_conc.ll").read_text()

    lowerer = LowerToLLVM([4, 8, 64])
    add_ucr_helpers = HelperFuncs(PatternDag("Add"), AbstractDomain.UConstRange)
    lowerer.add_fn(add_ucr_helpers.meet_func)
    lowerer.add_fn(add_ucr_helpers.get_top_func)
    lowerer.add_fn(add_ucr_helpers.crt_func, shim=True)
    assert str(lowerer) == (DATA_DIR / "ucr_add_conc.ll").read_text()


def test_saturated_binary_ops_lower_and_run():
    cases = [
        ("UaddSat", 15, 1, 15),
        ("UaddSat", 2, 3, 5),
        ("SaddSat", 7, 1, 7),
        ("SaddSat", 8, 15, 8),
        ("UsubSat", 0, 1, 0),
        ("UsubSat", 5, 3, 2),
        ("SsubSat", 7, 15, 7),
        ("SsubSat", 8, 1, 8),
        ("UmulSat", 8, 2, 15),
        ("UmulSat", 3, 4, 12),
        ("SmulSat", 4, 2, 7),
        ("SmulSat", 12, 2, 8),
        ("SmulSat", 4, 14, 8),
        ("UshlSat", 8, 1, 15),
        ("UshlSat", 3, 1, 6),
        ("SshlSat", 4, 1, 7),
        ("SshlSat", 12, 1, 8),
    ]

    for op_name, lhs, rhs, expected in cases:
        helpers = HelperFuncs(PatternDag(op_name), AbstractDomain.UConstRange)
        lowerer = LowerToLLVM([4])
        lowerer.add_fn(helpers.crt_func, shim=True)
        if helpers.op_constraint_func is not None:
            lowerer.add_fn(helpers.op_constraint_func, shim=True)

        with Jit() as jit:
            jit.add_mod(lowerer)
            fn = CFUNCTYPE(c_uint64, c_uint64, c_uint64)(
                jit.get_fn_ptr("concrete_op_4_shim").addr
            )
            assert fn(lhs, rhs) == expected

            if op_name in ("SshlSat", "UshlSat"):
                constraint = CFUNCTYPE(c_uint64, c_uint64, c_uint64)(
                    jit.get_fn_ptr("op_constraint_4_shim").addr
                )
                assert constraint(lhs, 3) == 1
                assert constraint(lhs, 4) == 0
            else:
                assert helpers.op_constraint_func is None
