from enum import Enum
import re


class AbstractDomain(Enum):
    KnownBits = "KnownBits", 2, None
    UConstRange = "UConstRange", 2, None
    SConstRange = "SConstRange", 2, None
    Mod3 = "Mod3", 1, 3
    Mod5 = "Mod5", 1, 5
    Mod7 = "Mod7", 1, 7
    Mod11 = "Mod11", 1, 11
    Mod13 = "Mod13", 1, 13

    vec_size: int
    const_bw: int | None

    def __new__(
        cls,
        value: str,
        vec_size: int,
        const_bw: int | None,
    ):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.vec_size = vec_size
        obj.const_bw = const_bw
        return obj

    def __str__(self) -> str:
        return self.name


def get_bvs_from_abst(
    arg: str, domain: AbstractDomain, bw: int
) -> tuple[int, int] | None:
    if arg == "(bottom)":
        return None

    def kb_str_to_vals(arg: str) -> tuple[int, int]:
        known_z, known_o = 0, 0

        for ch in arg:
            if ch == "0":
                known_z |= 1
            elif ch == "1":
                known_o |= 1
            known_z <<= 1
            known_o <<= 1

        known_z >>= 1
        known_o >>= 1
        return known_z, known_o

    if domain == AbstractDomain.KnownBits:
        if len(arg) != bw:
            raise ValueError(f"arg len: {len(arg)} != bitwidth: {bw}")

        return kb_str_to_vals(arg)
    if domain == AbstractDomain.UConstRange:
        m = re.match(r"^\[(\d+), (\d+)\]$", arg)
        if not m or not m.group(1).isnumeric() or not m.group(2).isnumeric():
            raise ValueError(f"arg: {arg} is malformed")
        else:
            lb, ub = int(m.group(1)), int(m.group(2))
            if lb < 0 or lb >= 2**bw or ub < 0 or ub >= 2**bw or lb > ub:
                raise ValueError(f"arg: {arg} out of range")

        return lb, ub
    if domain == AbstractDomain.SConstRange:
        imin = -(2**bw // 2)
        imax = (2**bw // 2) - 1
        m = re.match(r"^\[(-?\d+), (-?\d+)\]$", arg)
        if not m:
            raise ValueError(f"arg: {arg} is malformed")
        else:
            lb, ub = int(m.group(1)), int(m.group(2))
            if lb < imin or lb > imax or ub < imin or ub > imax or lb > ub:
                raise ValueError(f"arg: {arg} out of range")
        return lb, ub

    raise NotImplementedError(f"Max precise not implemented for {domain} yet")


def is_top(s: str, domain: AbstractDomain, bw: int) -> bool:
    if domain == AbstractDomain.KnownBits:
        return s == "?" * bw
    elif domain == AbstractDomain.UConstRange:
        res = get_bvs_from_abst(s, domain, bw)
        if res is None:
            return False
        return res[0] == 0 and res[1] == (2**bw) - 1
    elif domain == AbstractDomain.SConstRange:
        res = get_bvs_from_abst(s, domain, bw)
        if res is None:
            return False
        return res[0] == (-(2**bw // 2)) and res[1] == ((2**bw // 2) - 1)
    else:
        raise NotImplementedError()
