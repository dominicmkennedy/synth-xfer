from __future__ import annotations

from typing import Callable

from egglog import Expr, StringLike, birewrite, i64Like, method, rewrite, ruleset, vars_
from xdsl.dialects.arith import AndIOp, OrIOp, XOrIOp
from xdsl.ir import Operation
from xdsl_smt.dialects.transfer import (
    AddOp,
    AndOp,
    AShrOp,
    ClearHighBitsOp,
    ClearLowBitsOp,
    ClearSignBitOp,
    CountLOneOp,
    CountLZeroOp,
    CountROneOp,
    CountRZeroOp,
    GetBitWidthOp,
    LShrOp,
    MulOp,
    NegOp,
    OrOp,
    PopCountOp,
    SDivOp,
    SelectOp,
    SetHighBitsOp,
    SetLowBitsOp,
    SetSignBitOp,
    ShlOp,
    SMaxOp,
    SMinOp,
    SRemOp,
    SubOp,
    UDivOp,
    UMaxOp,
    UMinOp,
    URemOp,
    XorOp,
)

from synth_xfer._util.domain import AbstractDomain


class BV(Expr):
    @method(cost=0)
    def __init__(self, value: i64Like) -> None: ...

    @method(cost=0)
    @classmethod
    def var(cls, name: StringLike) -> BV: ...

    # For some reason, the override for __or__ does not work
    # def __or__(self, other: Num) -> Num: ...

    @classmethod
    def Or(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def Neg(cls, operand: BV) -> BV: ...

    def __add__(self, other: BV) -> BV: ...

    def __mul__(self, other: BV) -> BV: ...

    def __sub__(self, other: BV) -> BV: ...

    def __and__(self, other: BV) -> BV: ...

    def __xor__(self, other: BV) -> BV: ...

    @classmethod
    def udiv(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def sdiv(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def urem(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def srem(cls, lhs: BV, rhs: BV) -> BV: ...

    def __lshift__(self, other: BV) -> BV: ...

    @classmethod
    def ashr(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def lshr(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def umin(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def smin(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def umax(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def smax(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def set_high_bits(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def set_low_bits(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def clear_high_bits(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def clear_low_bits(cls, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def set_sign_bit(cls, op: BV) -> BV: ...

    @classmethod
    def clear_sign_bit(cls, op: BV) -> BV: ...

    @classmethod
    def countl_one(cls, op: BV) -> BV: ...

    @classmethod
    def countl_zero(cls, op: BV) -> BV: ...

    @classmethod
    def countr_one(cls, op: BV) -> BV: ...

    @classmethod
    def countr_zero(cls, op: BV) -> BV: ...

    @classmethod
    def ite(cls, cond: Bool, lhs: BV, rhs: BV) -> BV: ...

    @classmethod
    def get_bitwidth(cls, op: BV) -> BV: ...

    @classmethod
    def pop_count(cls, op: BV) -> BV: ...


class Bool(Expr):
    @method(cost=0)
    @classmethod
    def var(cls, name: StringLike) -> Bool: ...

    @method(cost=0)
    @classmethod
    def true(cls) -> Bool: ...

    @method(cost=0)
    @classmethod
    def false(cls) -> Bool: ...

    @classmethod
    def And(cls, lhs: Bool, rhs: Bool) -> Bool: ...

    @classmethod
    def Or(cls, lhs: Bool, rhs: Bool) -> Bool: ...

    @classmethod
    def Xor(cls, lhs: Bool, rhs: Bool) -> Bool: ...

    @classmethod
    def eq(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def ne(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def slt(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def sle(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def sgt(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def sge(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def ult(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def ule(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def ugt(cls, lhs: BV, rhs: BV) -> Bool: ...

    @classmethod
    def uge(cls, lhs: BV, rhs: BV) -> Bool: ...


class AbsValue(Expr):
    """Joint representation of a transfer.abs_value tuple, one constructor per arity."""

    @classmethod
    def make1(cls, x0: BV) -> AbsValue: ...

    @classmethod
    def make2(cls, x0: BV, x1: BV) -> AbsValue: ...


def make_absvalue(*fields: Expr) -> AbsValue:
    # The underlying AbsValue.makeN constructors are typed (BV, ...) -> AbsValue;
    # egglog enforces field types at saturation time. Python signature is loose
    # here because op_to_expr stores Expr (BV in practice for MakeOp operands).
    if len(fields) == 1:
        return AbsValue.make1(fields[0])  # type: ignore[arg-type]
    if len(fields) == 2:
        return AbsValue.make2(fields[0], fields[1])  # type: ignore[arg-type]
    raise ValueError(f"Unsupported AbsValue arity: {len(fields)}")


cmp_predicate_to_fn: dict[int, Callable[..., Bool]] = {
    0: Bool.eq,  # eq
    1: Bool.ne,  # ne
    2: Bool.slt,
    3: Bool.sle,
    4: Bool.sgt,
    5: Bool.sge,
    6: Bool.ult,
    7: Bool.ule,
    8: Bool.ugt,
    9: Bool.uge,
}

mlir_op_to_egraph_op: dict[type[Operation], Callable[..., Expr]] = {
    AddOp: BV.__add__,
    SubOp: BV.__sub__,
    AndOp: BV.__and__,
    OrOp: BV.Or,
    XorOp: BV.__xor__,
    AndIOp: Bool.And,
    OrIOp: Bool.Or,
    XOrIOp: Bool.Xor,
    NegOp: BV.Neg,
    MulOp: BV.__mul__,
    UDivOp: BV.udiv,
    SDivOp: BV.sdiv,
    URemOp: BV.urem,
    SRemOp: BV.srem,
    ShlOp: BV.__lshift__,
    AShrOp: BV.ashr,
    LShrOp: BV.lshr,
    UMaxOp: BV.umax,
    SMaxOp: BV.smax,
    UMinOp: BV.umin,
    SMinOp: BV.smin,
    SetHighBitsOp: BV.set_high_bits,
    SetLowBitsOp: BV.set_low_bits,
    ClearHighBitsOp: BV.clear_high_bits,
    ClearLowBitsOp: BV.clear_low_bits,
    SetSignBitOp: BV.set_sign_bit,
    ClearSignBitOp: BV.clear_sign_bit,
    CountLOneOp: BV.countl_one,
    CountLZeroOp: BV.countl_zero,
    CountROneOp: BV.countr_one,
    CountRZeroOp: BV.countr_zero,
    SelectOp: BV.ite,
    GetBitWidthOp: BV.get_bitwidth,
    PopCountOp: BV.pop_count,
}


def _knownbits_rules(num_args: int):
    rules = []
    for i in range(num_args):
        kz = BV.var(f"arg{i}_0")  # knownZeros
        ko = BV.var(f"arg{i}_1")  # knownOnes
        # KnownBits invariant: a bit cannot be both known-zero and known-one.
        rules.append(rewrite(kz & ko).to(BV(0)))
        # Disjoint bitsets: addition equals bitwise-or.
        rules.append(birewrite(kz + ko).to(BV.Or(kz, ko)))
    return rules


def gen_ruleset(domain: AbstractDomain, num_args: int):
    x, y, z = vars_("x y z", BV)
    b, c, d = vars_("b c d", Bool)

    domain_rules = []
    if domain == AbstractDomain.KnownBits:
        domain_rules = _knownbits_rules(num_args)

    return ruleset(
        *domain_rules,
        # Bitvector Algebra - Idempotent laws
        rewrite(x & x).to(x),
        rewrite(BV.Or(x, x)).to(x),
        rewrite(x ^ x).to(BV(0)),
        # Commutativity
        rewrite(x + y).to(y + x),
        rewrite(x & y).to(y & x),
        rewrite(BV.Or(x, y)).to(BV.Or(y, x)),
        rewrite(x ^ y).to(y ^ x),
        rewrite(x * y).to(y * x),
        # Identity elements
        rewrite(x + BV(0)).to(x),
        rewrite(x * BV(1)).to(x),
        rewrite(x & BV(-1)).to(x),  # x & all_ones = x
        birewrite(BV(0) - x).to(x * BV(-1)),  # -x = x * -1
        rewrite(BV.Or(x, BV(0))).to(x),
        rewrite(x ^ BV(0)).to(x),
        # Absorbing elements
        rewrite(x * BV(0)).to(BV(0)),
        rewrite(x & BV(0)).to(BV(0)),
        rewrite(BV.Or(x, BV(-1))).to(BV(-1)),  # x | all_ones = all_ones
        # Associativity (useful for normalization)
        birewrite((x + y) + z).to(x + (y + z)),
        birewrite((x * y) * z).to(x * (y * z)),
        birewrite((x & y) & z).to(x & (y & z)),
        birewrite(BV.Or(BV.Or(x, y), z)).to(BV.Or(x, BV.Or(y, z))),
        birewrite((x ^ y) ^ z).to(x ^ (y ^ z)),
        # Distributivity
        birewrite((x & y) ^ (x & z)).to(x & (y ^ z)),
        birewrite(BV.Or(x, y) & BV.Or(x, z)).to(BV.Or(x, (y & z))),
        birewrite(BV.Or(x & z, y & z)).to(BV.Or(x, y) & z),
        # AND/OR relationships
        rewrite(x & BV.Or(x, y)).to(x),  # absorption law
        rewrite(BV.Or(x, (x & y))).to(x),  # absorption law
        # Subtraction properties
        rewrite(x - x).to(BV(0)),
        rewrite(x - BV(0)).to(x),
        birewrite(BV(-1) - x).to(BV.Neg(x)),
        birewrite(x ^ BV(-1)).to(BV.Neg(x)),  # x ^ all_ones = ~x
        # Negation properties (arithmetic negation)
        rewrite(BV.Neg(BV.Neg(x))).to(x),  # double negation
        rewrite(x + BV.Neg(x)).to(BV(-1)),  # x + (~x) = all_ones
        rewrite(x & BV.Neg(x)).to(BV(0)),  # x & (~x) = 0
        rewrite(x ^ BV.Neg(x)).to(BV(-1)),  # x ^ (~x) = all_ones
        # Advanced patterns
        rewrite((x + y) - y).to(x),  # (x + y) - y = x (when no overflow)
        rewrite((x - y) + y).to(x),  # (x - y) + y = x (when no overflow)
        # Multiplication rules
        # distributivity (when no overflow)
        rewrite((x * y) + (x * z)).to(x * (y + z)),
        # distributivity (when no overflow)
        rewrite((y * x) + (z * x)).to((y + z) * x),
        # Division rules - unsigned division (udiv)
        rewrite(BV.udiv(x, BV(1))).to(x),  # x / 1 = x
        rewrite(BV.udiv(x, x)).to(BV(1)),  # x / x = 1 (when x != 0)
        rewrite(BV.udiv(BV(0), x)).to(BV(0)),  # 0 / x = 0 (when x != 0)
        # Division rules - signed division (sdiv)
        rewrite(BV.sdiv(x, BV(1))).to(x),  # x / 1 = x
        rewrite(BV.sdiv(x, x)).to(BV(1)),  # x / x = 1 (when x != 0)
        rewrite(BV.sdiv(BV(0), x)).to(BV(0)),  # 0 / x = 0 (when x != 0)
        rewrite(BV.sdiv(x, BV(-1))).to(BV(0) - x),  # x / -1 = -x
        # Remainder rules - unsigned remainder (urem)
        rewrite(BV.urem(x, BV(1))).to(BV(0)),  # x % 1 = 0
        rewrite(BV.urem(BV(0), x)).to(BV(0)),  # 0 % x = 0 (when x != 0)
        rewrite(BV.urem(x, x)).to(BV(0)),  # x % x = 0 (when x != 0)
        # Remainder rules - signed remainder (srem)
        rewrite(BV.srem(x, BV(1))).to(BV(0)),  # x % 1 = 0
        rewrite(BV.srem(BV(0), x)).to(BV(0)),  # 0 % x = 0 (when x != 0)
        rewrite(BV.srem(x, x)).to(BV(0)),  # x % x = 0 (when x != 0)
        rewrite(BV.srem(x, BV(-1))).to(BV(0)),  # x % -1 = 0
        # Division and remainder relationships
        # For unsigned: x = (x / y) * y + (x % y)
        rewrite(BV.udiv(x, y) * y + BV.urem(x, y)).to(x),  # division theorem
        rewrite((BV.udiv(x, y) * y) + BV.urem(x, y)).to(
            x
        ),  # division theorem (explicit parens)
        # For signed: x = (x / y) * y + (x % y)
        rewrite(BV.sdiv(x, y) * y + BV.srem(x, y)).to(x),  # division theorem
        rewrite((BV.sdiv(x, y) * y) + BV.srem(x, y)).to(
            x
        ),  # division theorem (explicit parens)
        # Additional patterns for multiplication
        birewrite((x * y) * z).to(x * (y * z)),  # associativity
        # Shift rules - Left shift (shl)
        rewrite(x << BV(0)).to(x),  # x << 0 = x
        rewrite(BV(0) << y).to(BV(0)),  # 0 << y = 0
        rewrite(x + x).to(x << BV(1)),  # x + x = x << 1 (x * 2)
        # Shift rules - Logical right shift (lshr)
        rewrite(BV.lshr(x, BV(0))).to(x),  # x >> 0 = x
        rewrite(BV.lshr(BV(0), y)).to(BV(0)),  # 0 >> y = 0
        # Shift rules - Arithmetic right shift (ashr)
        rewrite(BV.ashr(x, BV(0))).to(x),  # x >>> 0 = x
        rewrite(BV.ashr(BV(0), y)).to(BV(0)),  # 0 >>> y = 0
        # Shift cancellation rules
        # (x << y) >> y = x (when no bits lost)
        rewrite(BV.lshr(x << y, y)).to(x),
        rewrite(BV.ashr(x << y, y)).to(
            x
        ),  # (x << y) >>> y = x (when no bits lost, preserves sign)
        # Shift and bitwise operation interactions
        rewrite((x << z) & (y << z)).to(
            (x & y) << z
        ),  # (x << z) & (y << z) = (x & y) << z
        rewrite(BV.Or(x << z, y << z)).to(
            BV.Or(x, y) << z
        ),  # (x << z) | (y << z) = (x | y) << z
        rewrite((x << z) ^ (y << z)).to(
            (x ^ y) << z
        ),  # (x << z) ^ (y << z) = (x ^ y) << z
        # Logical right shift and bitwise operations
        rewrite(BV.lshr(x, z) & BV.lshr(y, z)).to(
            BV.lshr(x & y, z)
        ),  # (x >> z) & (y >> z) = (x & y) >> z
        rewrite(BV.Or(BV.lshr(x, z), BV.lshr(y, z))).to(
            BV.lshr(BV.Or(x, y), z)
        ),  # (x >> z) | (y >> z) = (x | y) >> z
        rewrite(BV.lshr(x, z) ^ BV.lshr(y, z)).to(
            BV.lshr(x ^ y, z)
        ),  # (x >> z) ^ (y >> z) = (x ^ y) >> z
        # Min/Max rules - unsigned min (umin)
        rewrite(BV.umin(x, x)).to(x),  # umin(x, x) = x
        rewrite(BV.umin(x, BV(0))).to(BV(0)),  # umin(x, 0) = 0
        rewrite(BV.umin(x, BV(-1))).to(
            x
        ),  # umin(x, all_ones) = x (all_ones is max unsigned)
        # Min/Max rules - unsigned max (umax)
        rewrite(BV.umax(x, x)).to(x),  # umax(x, x) = x
        rewrite(BV.umax(x, BV(0))).to(x),  # umax(x, 0) = x
        rewrite(BV.umax(x, BV(-1))).to(BV(-1)),  # umax(x, all_ones) = all_ones
        # Min/Max rules - signed min (smin)
        rewrite(BV.smin(x, x)).to(x),  # smin(x, x) = x
        # Note: For signed, -2^(n-1) is the minimum and 2^(n-1)-1 is the maximum
        # We can't easily express these without knowing bit width, so we omit them
        # Min/Max rules - signed max (smax)
        rewrite(BV.smax(x, x)).to(x),  # smax(x, x) = x
        # Min/Max commutativity (already handled by birewrite, but explicit for clarity)
        birewrite(BV.umin(x, y)).to(BV.umin(y, x)),  # umin is commutative
        birewrite(BV.umax(x, y)).to(BV.umax(y, x)),  # umax is commutative
        birewrite(BV.smin(x, y)).to(BV.smin(y, x)),  # smin is commutative
        birewrite(BV.smax(x, y)).to(BV.smax(y, x)),  # smax is commutative
        # Min/Max associativity
        birewrite(BV.umin(BV.umin(x, y), z)).to(
            BV.umin(x, BV.umin(y, z))
        ),  # umin associativity
        birewrite(BV.umax(BV.umax(x, y), z)).to(
            BV.umax(x, BV.umax(y, z))
        ),  # umax associativity
        birewrite(BV.smin(BV.smin(x, y), z)).to(
            BV.smin(x, BV.smin(y, z))
        ),  # smin associativity
        birewrite(BV.smax(BV.smax(x, y), z)).to(
            BV.smax(x, BV.smax(y, z))
        ),  # smax associativity
        # Min/Max absorption laws
        rewrite(BV.umin(x, BV.umax(x, y))).to(x),  # umin(x, umax(x, y)) = x
        rewrite(BV.umax(x, BV.umin(x, y))).to(x),  # umax(x, umin(x, y)) = x
        rewrite(BV.smin(x, BV.smax(x, y))).to(x),  # smin(x, smax(x, y)) = x
        rewrite(BV.smax(x, BV.smin(x, y))).to(x),  # smax(x, smin(x, y)) = x
        # Min/Max idempotency (already covered above, but completing the pattern)
        rewrite(BV.umin(BV.umin(x, y), x)).to(
            BV.umin(x, y)
        ),  # umin(umin(x, y), x) = umin(x, y)
        rewrite(BV.umax(BV.umax(x, y), x)).to(
            BV.umax(x, y)
        ),  # umax(umax(x, y), x) = umax(x, y)
        rewrite(BV.smin(BV.smin(x, y), x)).to(
            BV.smin(x, y)
        ),  # smin(smin(x, y), x) = smin(x, y)
        rewrite(BV.smax(BV.smax(x, y), x)).to(
            BV.smax(x, y)
        ),  # smax(smax(x, y), x) = smax(x, y)y)
        # Bit manipulation rules - set_high_bits
        rewrite(BV.set_high_bits(x, BV(0))).to(
            x
        ),  # set_high_bits(x, 0) = x (set 0 high bits = no change)
        rewrite(BV.set_high_bits(BV(-1), y)).to(
            BV(-1)
        ),  # set_high_bits(all_ones, y) = all_ones
        # Bit manipulation rules - set_low_bits
        rewrite(BV.set_low_bits(x, BV(0))).to(
            x
        ),  # set_low_bits(x, 0) = x (set 0 low bits = no change)
        birewrite(BV.set_low_bits(BV(0), x)).to(
            (BV(1) << x) - BV(1)
        ),  # set_low_bits(0, y) = mask with y low bits set
        rewrite(BV.set_low_bits(BV(-1), y)).to(
            BV(-1)
        ),  # set_low_bits(all_ones, y) = all_ones
        # Bit manipulation rules - clear_high_bits
        rewrite(BV.clear_high_bits(x, BV(0))).to(
            x
        ),  # clear_high_bits(x, 0) = x (clear 0 high bits = no change)
        birewrite(BV.clear_high_bits(BV(-1), x)).to(
            BV.lshr(BV(-1), x)
        ),  # clear_high_bits(all_ones, y) = logical right shift
        rewrite(BV.clear_high_bits(BV(0), y)).to(BV(0)),  # clear_high_bits(0, y) = 0
        # Bit manipulation rules - clear_low_bits
        rewrite(BV.clear_low_bits(x, BV(0))).to(
            x
        ),  # clear_low_bits(x, 0) = x (clear 0 low bits = no change)
        birewrite(BV.clear_low_bits(BV(-1), x)).to(
            BV(-1) << x
        ),  # clear_low_bits(all_ones, y) = left shift
        rewrite(BV.clear_low_bits(BV(0), y)).to(BV(0)),  # clear_low_bits(0, y) = 0
        # Bit manipulation rules - set_sign_bit
        rewrite(BV.set_sign_bit(BV.set_sign_bit(x))).to(
            BV.set_sign_bit(x)
        ),  # idempotent: set_sign_bit(set_sign_bit(x)) = set_sign_bit(x)
        # set_sign_bit(0) = sign bit set
        rewrite(BV.set_sign_bit(BV(-1))).to(BV(-1)),
        # Bit manipulation rules - clear_sign_bit
        rewrite(BV.clear_sign_bit(BV.clear_sign_bit(x))).to(
            BV.clear_sign_bit(x)
        ),  # idempotent: clear_sign_bit(clear_sign_bit(x)) = clear_sign_bit(x)
        rewrite(BV.clear_sign_bit(BV(0))).to(BV(0)),  # clear_sign_bit(0) = 0
        # Sign bit interactions
        rewrite(BV.clear_sign_bit(BV.set_sign_bit(x))).to(
            BV.clear_sign_bit(x)
        ),  # clear after set = just clear
        rewrite(BV.set_sign_bit(BV.clear_sign_bit(x))).to(
            BV.set_sign_bit(x)
        ),  # set after clear = just set
        # Bit manipulation composition rules
        birewrite(BV.set_high_bits(BV.set_high_bits(x, y), z)).to(
            BV.set_high_bits(x, BV.umax(y, z))
        ),  # set_high_bits composition
        birewrite(BV.set_low_bits(BV.set_low_bits(x, y), z)).to(
            BV.set_low_bits(x, BV.umax(y, z))
        ),  # set_low_bits composition
        birewrite(BV.clear_high_bits(BV.clear_high_bits(x, y), z)).to(
            BV.clear_high_bits(x, BV.umax(y, z))
        ),  # clear_high_bits composition
        birewrite(BV.clear_low_bits(BV.clear_low_bits(x, y), z)).to(
            BV.clear_low_bits(x, BV.umax(y, z))
        ),  # clear_low_bits composition
        # Bit manipulation with constants - high bits
        rewrite(BV.set_high_bits(x, BV(1))).to(
            BV.Or(x, BV.set_sign_bit(BV(0)))
        ),  # set 1 high bit = set sign bit
        rewrite(BV.clear_high_bits(x, BV(1))).to(
            BV.clear_sign_bit(x)
        ),  # clear 1 high bit = clear sign bit
        # Bit manipulation contradictions
        rewrite(BV.clear_high_bits(BV.set_high_bits(x, y), y)).to(
            BV.clear_high_bits(x, y)
        ),  # clear what was just set
        rewrite(BV.clear_low_bits(BV.set_low_bits(x, y), y)).to(
            BV.clear_low_bits(x, y)
        ),  # clear what was just set
        # Bit manipulation with bitwise operations
        rewrite(BV.set_high_bits(x, y) & BV.clear_high_bits(z, y)).to(
            BV.clear_high_bits(z, y)
        ),  # AND with complementary masks
        rewrite(BV.set_low_bits(x, y) & BV.clear_low_bits(z, y)).to(
            BV.clear_low_bits(z, y)
        ),  # AND with complementary masks
        rewrite(BV.Or(BV.set_high_bits(x, y), BV.clear_high_bits(z, y))).to(
            BV.set_high_bits(BV.Or(x, z), y)
        ),  # OR with masks
        # Constant folding
        rewrite(BV(1) + BV(-1)).to(BV(0)),
        # Boolean algebra (arith.andi / arith.ori / arith.xori)
        # Idempotent
        rewrite(Bool.And(b, b)).to(b),
        rewrite(Bool.Or(b, b)).to(b),
        # Commutativity
        rewrite(Bool.And(b, c)).to(Bool.And(c, b)),
        rewrite(Bool.Or(b, c)).to(Bool.Or(c, b)),
        rewrite(Bool.Xor(b, c)).to(Bool.Xor(c, b)),
        # Associativity
        birewrite(Bool.And(Bool.And(b, c), d)).to(Bool.And(b, Bool.And(c, d))),
        birewrite(Bool.Or(Bool.Or(b, c), d)).to(Bool.Or(b, Bool.Or(c, d))),
        birewrite(Bool.Xor(Bool.Xor(b, c), d)).to(Bool.Xor(b, Bool.Xor(c, d))),
        # Absorption
        rewrite(Bool.And(b, Bool.Or(b, c))).to(b),
        rewrite(Bool.Or(b, Bool.And(b, c))).to(b),
        # Distributivity
        birewrite(Bool.And(b, Bool.Or(c, d))).to(Bool.Or(Bool.And(b, c), Bool.And(b, d))),
        birewrite(Bool.Or(b, Bool.And(c, d))).to(Bool.And(Bool.Or(b, c), Bool.Or(b, d))),
        # Comparison predicates (transfer.cmp) -- only the symmetric ones
        rewrite(Bool.eq(x, y)).to(Bool.eq(y, x)),
        rewrite(Bool.ne(x, y)).to(Bool.ne(y, x)),
        # Select (transfer.select)
        rewrite(BV.ite(b, x, x)).to(x),  # both branches identical
        rewrite(BV.ite(Bool.true(), x, y)).to(x),  # guard known true
        rewrite(BV.ite(Bool.false(), x, y)).to(y),  # guard known false
        # Comparison reflexivity -- produce Bool.true / Bool.false
        rewrite(Bool.eq(x, x)).to(Bool.true()),
        rewrite(Bool.sle(x, x)).to(Bool.true()),
        rewrite(Bool.sge(x, x)).to(Bool.true()),
        rewrite(Bool.ule(x, x)).to(Bool.true()),
        rewrite(Bool.uge(x, x)).to(Bool.true()),
        rewrite(Bool.ne(x, x)).to(Bool.false()),
        rewrite(Bool.slt(x, x)).to(Bool.false()),
        rewrite(Bool.sgt(x, x)).to(Bool.false()),
        rewrite(Bool.ult(x, x)).to(Bool.false()),
        rewrite(Bool.ugt(x, x)).to(Bool.false()),
        name="my_ruleset",
    )
