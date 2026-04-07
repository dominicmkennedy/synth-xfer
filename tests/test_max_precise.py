from ctypes import CFUNCTYPE, c_bool, c_int64
from functools import lru_cache
from itertools import product
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.max_precise import compute_max_precise
from synth_xfer._util.parse_mlir import get_helper_funcs

PROJ_DIR = Path(__file__).parent.parent
OPS_DIR = PROJ_DIR / "mlir" / "Operations"
BW = 4


KB_CASES = [
    ("And", "1?0?", "?10?"),
    ("Or", "?0?0", "1?11"),
    ("Xor", "10?1", "?1?1"),
    ("OrDisjoint", "?010", "10?0"),
    ("Modu", "11??", "0?1?"),
    ("Modu", "?111", "001?"),
    ("Mods", "10??", "0?11"),
    ("Mods", "?101", "001?"),
    ("Udiv", "11?0", "0?1?"),
    ("Udiv", "?110", "001?"),
    ("Sdiv", "10?1", "0?1?"),
    ("Sdiv", "?101", "001?"),
    ("Shl", "0?11", "00??"),
    ("Shl", "1?01", "000?"),
    ("Lshr", "11?0", "00??"),
    ("Lshr", "?111", "000?"),
    ("Ashr", "10?1", "00??"),
    ("Ashr", "1?10", "000?"),
]

UCR_CASES = [
    ("Add", "[1, 3]", "[4, 6]"),
    ("AddNuw", "[2, 4]", "[1, 3]"),
    ("AddNuw", "[15, 15]", "[1, 1]"),
    ("SubNuw", "[6, 10]", "[2, 4]"),
    ("SubNuw", "[0, 0]", "[1, 1]"),
    ("Mul", "[2, 4]", "[1, 3]"),
    ("MulNuw", "[2, 3]", "[2, 4]"),
    ("MulNuw", "[8, 15]", "[2, 2]"),
    ("Modu", "[5, 14]", "[2, 6]"),
    ("Modu", "[3, 7]", "[0, 0]"),
    ("Udiv", "[8, 15]", "[2, 4]"),
    ("Udiv", "[3, 7]", "[0, 0]"),
    ("Shl", "[1, 5]", "[0, 3]"),
    ("ShlNuw", "[1, 3]", "[0, 2]"),
    ("ShlNuw", "[8, 15]", "[1, 2]"),
    ("Lshr", "[8, 15]", "[1, 3]"),
    ("And", "[3, 12]", "[5, 10]"),
    ("Xor", "[1, 9]", "[2, 14]"),
]

SCR_CASES = [
    ("Add", "[-3, 1]", "[2, 4]"),
    ("AddNsw", "[-2, 3]", "[-1, 2]"),
    ("AddNsw", "[7, 7]", "[1, 1]"),
    ("SubNsw", "[1, 5]", "[-2, 1]"),
    ("SubNsw", "[-8, -8]", "[1, 1]"),
    ("Mul", "[-3, -1]", "[1, 3]"),
    ("MulNsw", "[-2, 2]", "[-2, 2]"),
    ("MulNsw", "[-8, -8]", "[-1, -1]"),
    ("Mods", "[-7, 7]", "[2, 3]"),
    ("Mods", "[-3, 3]", "[0, 0]"),
    ("Sdiv", "[-7, 7]", "[2, 3]"),
    ("Sdiv", "[-3, 3]", "[0, 0]"),
    ("Ashr", "[-8, -1]", "[1, 3]"),
    ("Shl", "[-3, 3]", "[0, 2]"),
    ("ShlNsw", "[-2, 2]", "[0, 1]"),
    ("ShlNsw", "[4, 7]", "[1, 2]"),
    ("And", "[-8, 7]", "[-3, 5]"),
    ("Xor", "[-6, 6]", "[-5, 5]"),
]


def _signed_to_raw(x: int, bw: int) -> int:
    return x % (2**bw)


def _raw_to_signed(x: int, bw: int) -> int:
    sign_bit = 1 << (bw - 1)
    return x - (1 << bw) if x & sign_bit else x


def _kb_values(arg: str) -> list[int]:
    vals = [0]
    for ch in arg:
        next_vals: list[int] = []
        for val in vals:
            if ch == "?":
                next_vals.extend([(val << 1), (val << 1) | 1])
            else:
                next_vals.append((val << 1) | int(ch))
        vals = next_vals
    return vals


def _ucr_values(arg: str) -> list[int]:
    low, high = map(int, arg[1:-1].split(", "))
    return list(range(low, high + 1))


def _scr_values(arg: str, bw: int) -> list[int]:
    low, high = map(int, arg[1:-1].split(", "))
    return [_signed_to_raw(x, bw) for x in range(low, high + 1)]


def _kb_expected(outputs: list[int], bw: int) -> str:
    if not outputs:
        return "(bottom)"
    bits = []
    for shift in range(bw - 1, -1, -1):
        bit_vals = {(out >> shift) & 1 for out in outputs}
        bits.append("?" if len(bit_vals) > 1 else str(next(iter(bit_vals))))
    return "".join(bits)


def _ucr_expected(outputs: list[int]) -> str:
    if not outputs:
        return "(bottom)"
    return f"[{min(outputs)}, {max(outputs)}]"


def _scr_expected(outputs: list[int], bw: int) -> str:
    if not outputs:
        return "(bottom)"
    signed = [_raw_to_signed(x, bw) for x in outputs]
    return f"[{min(signed)}, {max(signed)}]"


@lru_cache(maxsize=None)
def _truth_table(
    op_name: str, domain: AbstractDomain, bw: int
) -> dict[tuple[int, int], int | None]:
    helpers = get_helper_funcs(OPS_DIR / f"{op_name}.mlir", domain)
    lowerer = LowerToLLVM([bw])
    crt = lowerer.add_fn(helpers.crt_func, shim=True)
    op_constraint = (
        lowerer.add_fn(helpers.op_constraint_func, shim=True)
        if helpers.op_constraint_func
        else None
    )
    conc_fn_t = CFUNCTYPE(c_int64, c_int64, c_int64)
    op_con_fn_t = CFUNCTYPE(c_bool, c_int64, c_int64)
    table: dict[tuple[int, int], int | None] = {}

    with Jit() as jit:
        jit.add_mod(lowerer)
        conc_fn = conc_fn_t(jit.get_fn_ptr(crt[bw].name).addr)
        op_con_fn = (
            op_con_fn_t(jit.get_fn_ptr(op_constraint[bw].name).addr)
            if op_constraint
            else None
        )
        for a, b in product(range(2**bw), repeat=2):
            if op_con_fn and not op_con_fn(a, b):
                table[(a, b)] = None
            else:
                table[(a, b)] = int(conc_fn(a, b))

    return table


def _expected(
    domain: AbstractDomain, op_name: str, args: tuple[str, str], bw: int
) -> str:
    if domain == AbstractDomain.KnownBits:
        arg_vals = [_kb_values(arg) for arg in args]
    elif domain == AbstractDomain.UConstRange:
        arg_vals = [_ucr_values(arg) for arg in args]
    else:
        arg_vals = [_scr_values(arg, bw) for arg in args]

    outputs: list[int] = []
    table = _truth_table(op_name, domain, bw)
    for concrete_args in product(*arg_vals):
        result = table[concrete_args]  # type: ignore
        if result is not None:
            outputs.append(result)

    if domain == AbstractDomain.KnownBits:
        return _kb_expected(outputs, bw)
    if domain == AbstractDomain.UConstRange:
        return _ucr_expected(outputs)
    return _scr_expected(outputs, bw)


def _check_cases(
    domain: AbstractDomain, cases: list[tuple[str, str, str]], bw: int = BW
) -> None:
    for op_name, arg0, arg1 in cases:
        op_path = OPS_DIR / f"{op_name}.mlir"
        args = (arg0, arg1)
        expected = _expected(domain, op_name, args, bw)
        actual = compute_max_precise(op_path, domain, bw, args, timeout=3)
        assert actual == expected, (
            f"{domain.name} {op_name} {args}: expected {expected}, got {actual}"
        )


def test_max_precise_knownbits():
    _check_cases(AbstractDomain.KnownBits, KB_CASES)


def test_max_precise_ucr():
    _check_cases(AbstractDomain.UConstRange, UCR_CASES)


def test_max_precise_scr():
    _check_cases(AbstractDomain.SConstRange, SCR_CASES)
