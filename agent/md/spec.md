# Transfer Dialect Spec

## 1. Purpose and Model

The `transfer` dialect models integer transfer functions over `!transfer.integer` values and structural containers of those values.
`!transfer.integer` represents an integer at an arbitrary bitwidth; concrete bitwidths are instantiated later during lowering.

## 2. Global Semantic Rules

- All ops are total: no UB, no poison, no partial functions.
- Division/remainder ops (`sdiv`, `udiv`, `srem`, `urem`) follow SMT-LIB semantics on divide-by-zero.
- Shift ops return `0` when the shift amount is greater than or equal to bitwidth.
- High/low bit-mask ops (`set_high_bits`, `set_low_bits`, `clear_high_bits`, `clear_low_bits`) are total as well.
- Concise syntax is used throughout, modeled after arith-style syntax.

## 3. Types

- `i1`: bool type
- `!transfer.integer`: arbitrary-bitwidth integer placeholder.
- `!transfer.abs_value<[!transfer.integer, ...]>`: homogeneous container of transfer integers.

### 3.1 Concise syntax convention

Most `transfer` ops print a single type after `:`. **That type is the operand element type, not the result type.** This mirrors `arith` (e.g. `arith.cmpi ult, %x, %y : i32` — `i32` is the operand type; the result is implicitly `i1`).

```mlir
%r = transfer.op %x[, %y, ...] : !transfer.integer
```

The result type is fixed by the op definition and not written in the concise form:

- **Arithmetic / bitwise ops** (§5.1, §5.2): result is `!transfer.integer` — same as the printed type.
- **Predicate ops** (§4 `transfer.cmp`, `transfer.is_negative`; §5.3 `*_overflow`): result is `i1`, even though the type after `:` is `!transfer.integer`.
- **`transfer.select %cond, %t, %f : !transfer.integer`**: `%cond` is implicitly `i1`; the printed type is the type of `%t`, `%f`, and the result.

Ops whose signature can't be recovered from one type spell out the full functional form explicitly:

- `transfer.make`: `(operand-types) -> result-type`
- `transfer.get`: `operand-type -> result-type`

When reading a concise-form op, derive the result type from the op's signature in §4 / §5, not from the `:` annotation.

## 4. Special Ops

These ops have special structure and do not fit simple unary/binary families.

| Op | Signature | Canonical syntax | Semantics |
|---|---|---|---|
| `transfer.cmp` | `(!transfer.integer, !transfer.integer) -> i1` | `%c = transfer.cmp ugt, %x, %y : !transfer.integer` | Predicate compare. Predicates: `eq ne slt sle sgt sge ult ule ugt uge`. |
| `transfer.is_negative` | `(!transfer.integer) -> i1` | `%c = transfer.is_negative %x : !transfer.integer` | True iff value is negative under signed interpretation. |
| `transfer.make` | `(!transfer.integer, ..., !transfer.integer) -> !transfer.abs_value<[!transfer.integer, ...]>` | `%r = transfer.make %a, %b : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>` | Constructs an abstract value from transfer-integer fields. |
| `transfer.get` | `(!transfer.abs_value<[!transfer.integer, ...]>) -> !transfer.integer` | `%f = transfer.get %v[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer` | Projects field `index` from abstract value; verifies index bounds/type. |
| `transfer.select` | `(i1, !transfer.integer, !transfer.integer) -> !transfer.integer` | `%r = transfer.select %cond, %t, %f : !transfer.integer` | Value select on boolean condition. |

## 5. Ops by Signature Family

## 5.1 `(!transfer.integer) -> !transfer.integer`

| Op | One-line semantics |
|---|---|
| `transfer.constant` | Immediate constant in the same bitwidth context as the input operand. |
| `transfer.get_all_ones` | All-bits-ones value at input bitwidth. |
| `transfer.get_signed_max_value` | Signed max value at input bitwidth. |
| `transfer.get_signed_min_value` | Signed min value at input bitwidth. |
| `transfer.get_bit_width` | Bitwidth query encoded as transfer integer. |
| `transfer.neg` | Arithmetic negation. |
| `transfer.countl_zero` | Count leading zeros. |
| `transfer.countr_zero` | Count trailing zeros. |
| `transfer.countl_one` | Count leading ones. |
| `transfer.countr_one` | Count trailing ones. |
| `transfer.popcount` | Population count. |
| `transfer.set_sign_bit` | Sets sign bit to `1`. |
| `transfer.clear_sign_bit` | Clears sign bit to `0`. |

Canonical syntax shape:
```mlir
%r = transfer.op %x : !transfer.integer
```

For `transfer.constant`:
```mlir
%r = transfer.constant %ctx, 8 : !transfer.integer
```

## 5.2 `(!transfer.integer, !transfer.integer) -> !transfer.integer`

| Op | One-line semantics |
|---|---|
| `transfer.add` | Addition. |
| `transfer.sub` | Subtraction. |
| `transfer.mul` | Multiplication. |
| `transfer.sdiv` | Signed division (SMT-LIB divide-by-zero semantics). |
| `transfer.udiv` | Unsigned division (SMT-LIB divide-by-zero semantics). |
| `transfer.srem` | Signed remainder (SMT-LIB divide-by-zero semantics). |
| `transfer.urem` | Unsigned remainder (SMT-LIB divide-by-zero semantics). |
| `transfer.shl` | Left shift; returns `0` on overshift (`shift >= bitwidth`). |
| `transfer.ashr` | Arithmetic right shift; returns `0` on overshift. |
| `transfer.lshr` | Logical right shift; returns `0` on overshift. |
| `transfer.and` | Bitwise and. |
| `transfer.or` | Bitwise or. |
| `transfer.xor` | Bitwise xor. |
| `transfer.smin` | Signed minimum. |
| `transfer.smax` | Signed maximum. |
| `transfer.umin` | Unsigned minimum. |
| `transfer.umax` | Unsigned maximum. |
| `transfer.set_high_bits` | Sets the high `n` bits to `1`; for `n >= bitwidth`, result is all ones. |
| `transfer.set_low_bits` | Sets the low `n` bits to `1`; for `n >= bitwidth`, result is all ones. |
| `transfer.clear_high_bits` | Clears the high `n` bits to `0`; for `n >= bitwidth`, result is zero. |
| `transfer.clear_low_bits` | Clears the low `n` bits to `0`; for `n >= bitwidth`, result is zero. |

Canonical syntax shape:
```mlir
%r = transfer.op %x, %y : !transfer.integer
```

## 5.3 `(!transfer.integer, !transfer.integer) -> i1`

| Op | One-line semantics |
|---|---|
| `transfer.umul_overflow` | Unsigned multiply overflow predicate. |
| `transfer.smul_overflow` | Signed multiply overflow predicate. |
| `transfer.ushl_overflow` | Unsigned left-shift overflow predicate. |
| `transfer.sshl_overflow` | Signed left-shift overflow predicate. |
| `transfer.uadd_overflow` | Unsigned add overflow predicate. |
| `transfer.sadd_overflow` | Signed add overflow predicate. |
| `transfer.usub_overflow` | Unsigned sub overflow predicate. |
| `transfer.ssub_overflow` | Signed sub overflow predicate. |

Canonical syntax shape:
```mlir
%c = transfer.op %x, %y : !transfer.integer
```

## 6. Function Calls

Examples:
```mlir
%lhsMax = func.call @getMaxValue(%lhs) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
%lhsMin = func.call @getMinValue(%lhs) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
```

## 7. `func.return`

Result types after `:` are a bare, comma-separated list — no parentheses. Examples:

```mlir
func.return %r : !transfer.integer
func.return %a, %b, %c : i1, i1, i1
```

## 8. Logical vs Bitwise

- Use `arith.andi` / `arith.ori` / `arith.xori` for boolean logical composition (the `i1` conditions).
- Use `transfer.and` / `transfer.or` / `transfer.xor` for bitwise operations on `!transfer.integer` values.
