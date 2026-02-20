from pathlib import Path

from synth_xfer._eval_engine import (
    enum_low_knownbits_4_4,
    enum_low_knownbits_4_4_4,
    enum_low_knownbits_8_8,
    enum_low_mod3_8_8,
    enum_low_mod5_8_8,
    enum_low_mod7_8_8,
    enum_low_mod11_16_16,
    enum_low_mod13_16_16,
    enum_low_sconstrange_4_4,
    enum_low_uconstrange_4_4,
    eval_knownbits_4_4,
    eval_mod3_8_8,
    eval_mod5_8_8,
    eval_mod7_8_8,
    eval_mod11_16_16,
    eval_mod13_16_16,
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

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_knownbits_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "kb_lattice_4.txt").read_text().strip()

        raw_res = eval_knownbits_4_4(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
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

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_uconstrange_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "ucr_lattice_4.txt").read_text().strip()

        raw_res = eval_uconstrange_4_4(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
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

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_4_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_4_shim")

        to_eval = enum_low_sconstrange_4_4(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "scr_lattice_4.txt").read_text().strip()

        raw_res = eval_sconstrange_4_4(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
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

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_4_addr = jit.get_fn_ptr("concrete_op_4_shim")
        conc_op_8_addr = jit.get_fn_ptr("concrete_op_8_shim")

        to_eval_4 = enum_low_knownbits_4_4_4(conc_op_4_addr.addr, None)
        to_eval_8 = enum_low_knownbits_8_8(conc_op_8_addr.addr, None)
        assert len(to_eval_4) == len(to_eval_8)


def test_mod3_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([8])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod3)
    xfer_mlir = parse_mlir_func(DATA_DIR / "mod3_xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_8_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_8_shim")

        to_eval = enum_low_mod3_8_8(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "mod3_lattice.txt").read_text().strip()

        raw_res = eval_mod3_8_8(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 8  all: 7     s: 7     e: 7     uall: 6     ue: 6     dis: 0       bdis: 4.5     sdis: 0"
        )


def test_mod5_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([8])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod5)
    xfer_mlir = parse_mlir_func(DATA_DIR / "mod5_xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_8_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_8_shim")

        to_eval = enum_low_mod5_8_8(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "mod5_lattice.txt").read_text().strip()

        raw_res = eval_mod5_8_8(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 8  all: 31    s: 31    e: 31    uall: 30    ue: 30    dis: 0       bdis: 18.75   sdis: 0"
        )


def test_mod7_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([8])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod7)
    xfer_mlir = parse_mlir_func(DATA_DIR / "mod7_xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_8_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_8_shim")

        to_eval = enum_low_mod7_8_8(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "mod7_lattice.txt").read_text().strip()

        raw_res = eval_mod7_8_8(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 8  all: 127   s: 127   e: 127   uall: 126   ue: 126   dis: 0       bdis: 73.5    sdis: 0"
        )


def test_mod11_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod11)
    xfer_mlir = parse_mlir_func(DATA_DIR / "mod11_xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_16_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_16_shim")

        to_eval = enum_low_mod11_16_16(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "mod11_lattice.txt").read_text().strip()

        raw_res = eval_mod11_16_16(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 16 all: 2047  s: 2047  e: 2047  uall: 2046  ue: 2046  dis: 0       bdis: 1125.3  sdis: 0"
        )


def test_mod13_lattice():
    conc_nop_f = PROJ_DIR / "mlir" / "Operations" / "Nop.mlir"

    lowerer = LowerToLLVM([16])
    helpers = get_helper_funcs(conc_nop_f, AbstractDomain.Mod13)
    xfer_mlir = parse_mlir_func(DATA_DIR / "mod13_xfer_nop.mlir")
    lowerer.add_fn(xfer_mlir, shim=True)
    lowerer.add_fn(helpers.crt_func, shim=True)

    with Jit() as jit:
        jit.add_mod(str(lowerer))
        conc_op_addr = jit.get_fn_ptr("concrete_op_16_shim")
        xfer_fn_addr = jit.get_fn_ptr("xfer_nop_16_shim")

        to_eval = enum_low_mod13_16_16(conc_op_addr.addr, None)
        lattice_str = "\n".join(str(x) for (x,), _ in to_eval).strip()
        assert lattice_str == (DATA_DIR / "mod13_lattice.txt").read_text().strip()

        raw_res = eval_mod13_16_16(to_eval, [xfer_fn_addr.addr], [])
        for (x,), y in to_eval:
            assert str(x) == str(y)
        res = get_per_bit(raw_res)[0]
        assert (
            str(res).strip()
            == "bw: 16 all: 8191  s: 8191  e: 8191  uall: 8190  ue: 8190  dis: 0       bdis: 4436.25 sdis: 0"
        )
