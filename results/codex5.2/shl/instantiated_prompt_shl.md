## Task

Implement or improve a KnownBits transfer function for operation `shl` in this repo

## Key Clarification

- CI integration is NOT required for this task.
- The important tools are `verify` and `eval-final`.
- The width list below is a suggestion only; choose widths freely to maximize useful signal.

## Reasoning (before implementing)

- Reason about the operation semantics and how KnownBits (known-zero, known-one) should be updated for each output before writing MLIR.
- Aim for **sound** and **precise** transfers; prefer a well-reasoned design over the first implementation that passes eval.
- If a candidate gets low metrics or errors, analyze why (e.g. wrong propagation, missing cases) and improve the design, not only fix syntax.

## Requirements

1. Implement `kb_<op>.mlir` in the same MLIR style as the examples I provided to you.
2. Function signature must be:
   ```
   (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
   ```
   with symbol name `kb_<op>`.

3. KnownBits encoding:
   - index 0 = known-zero mask
   - index 1 = known-one mask

4. Transfer must be **sound** and as **precise** as possible.

5. Keep code bitwidth-agnostic:
   - no special cases for specific bitwidths (e.g., no "if bw==…" logic).

6. Use existing primitive (`transfer.and`,  `transfer.add`, `transfer.sub`, `transfer.shl`, `transfer.lshr`, `transfer.constant`, `transfer.get_all_ones`, etc.) included in `ops.md`, which aligned with the LLVM APInt semantics.

7. The program should be in SSA (Single Static Assigment) form. **Each line only has 1 operation** from `ops.md`. Do not write `%x = %y` (that is invalid MLIR); every definition must be an operation call; use SSA values directly in the next operation or in `transfer.make`.

Available operations:
# Available Operations

## Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

## Integer Operations

- transfer.neg: (!transfer.integer) -> !transfer.integer
- transfer.and: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.or: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.xor: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.add: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sub: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.select: (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.mul: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.lshr: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.shl: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.udiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sdiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.urem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.srem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.countl_one: (!transfer.integer) -> !transfer.integer
- transfer.countl_zero: (!transfer.integer) -> !transfer.integer
- transfer.countr_one: (!transfer.integer) -> !transfer.integer
- transfer.countr_zero: (!transfer.integer) -> !transfer.integer

## Utility Operations

- transfer.constant: (!transfer.integer) -> !transfer.integer
    - example: `%const0 = "transfer.constant"(%arg){value=42:index} : (!transfer.integer) -> !transfer.integer` provides constant 42.
    - the argument `%arg` is to decide bitwidth
- transfer.get_all_ones: (!transfer.integer) -> !transfer.integer
    - the argument is to decide bitwidth
- transfer.get_bit_width: (!transfer.integer) -> !transfer.integer


KnownBits examples:

Example from kb_or.mlir:
```mlir
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %res0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_or", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
```

Example from kb_xor.mlir:
```mlir
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %and0s = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and1s = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and01 = "transfer.and"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and10 = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%and0s, %and1s) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%and01, %and10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_xor", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
```

Operation: mlir/Operations/Shl.mlir
```mlir
"builtin.module"() ({
  "func.func"() ({
  ^bb0(%arg0: !transfer.integer, %arg1: !transfer.integer):
    %result = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) ->!transfer.integer
    "func.return"(%result) : (!transfer.integer) -> ()
  }) {function_type = (!transfer.integer,!transfer.integer) -> !transfer.integer, sym_name = "concrete_op"} : () -> ()

  "func.func"() ({
  ^bb0(%arg0: !transfer.integer, %arg1: !transfer.integer):
    %const0 = "transfer.constant"(%arg1) {value=0:index}:(!transfer.integer)->!transfer.integer
    %bitwidth = "transfer.get_bit_width"(%arg0): (!transfer.integer) -> !transfer.integer
    %arg1_ge_0 = "transfer.cmp"(%arg1, %const0) {predicate=9:i64}: (!transfer.integer, !transfer.integer) -> i1
    %arg1_le_bitwidth = "transfer.cmp"(%arg1, %bitwidth) {predicate=7:i64}: (!transfer.integer, !transfer.integer) -> i1
    %check = "arith.andi"(%arg1_ge_0, %arg1_le_bitwidth) : (i1, i1) -> i1
    "func.return"(%check) : (i1) -> ()
  }) {function_type = (!transfer.integer, !transfer.integer) -> i1, sym_name = "op_constraint"} : () -> ()

}) : () -> ()

```

MLIR template (fill only TODOs):
```mlir
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    // TODO (multiple lines)
    // use %lhs0, %lhs1, %rhs0, %rhs1 to compute the result
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "TODO", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
```

Generate kb_shl.mlir by filling in only the TODO parts.