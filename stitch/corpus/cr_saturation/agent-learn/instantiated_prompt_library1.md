## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions in MLIR. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## Synthesized transfer functions (inputs)


"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    // lower = avgceils(lhs_lower, rhs_lower) = (a | b) - ((a ^ b) >>s 1)
    %lower_or = "transfer.or"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_xor = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_ashr = "transfer.ashr"(%lower_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_lower = "transfer.sub"(%lower_or, %lower_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // upper = avgceils(lhs_upper, rhs_upper) = (a | b) - ((a ^ b) >>s 1)
    %upper_or = "transfer.or"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_xor = "transfer.xor"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_ashr = "transfer.ashr"(%upper_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_upper = "transfer.sub"(%upper_or, %upper_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res_lower, %res_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_avgceils", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.ashr"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.sub"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @fn_0(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %sign_minus_1 = "transfer.lshr"(%all_ones, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Partition each unsigned input interval into signed nonnegative and signed negative pieces.
    %lhs_nonneg_exists = "transfer.cmp"(%lhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_upper = "transfer.umin"(%lhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.umin"(%rhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%sign_bit, %lhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%sign_bit, %rhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_lower = "transfer.umax"(%lhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.umax"(%rhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case A: lhs >= 0, rhs >= 0 (signed).
    %a_exists = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %a_min_or = "transfer.or"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min_xor = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min_ashr = "transfer.ashr"(%a_min_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min = "transfer.sub"(%a_min_or, %a_min_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_or = "transfer.or"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_xor = "transfer.xor"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_ashr = "transfer.ashr"(%a_max_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max = "transfer.sub"(%a_max_or, %a_max_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case B: lhs < 0, rhs < 0 (signed).
    %b_exists = "arith.andi"(%lhs_neg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %b_min_or = "transfer.or"(%lhs_neg_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min_xor = "transfer.xor"(%lhs_neg_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min_ashr = "transfer.ashr"(%b_min_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min = "transfer.sub"(%b_min_or, %b_min_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_or = "transfer.or"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_xor = "transfer.xor"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_ashr = "transfer.ashr"(%b_max_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max = "transfer.sub"(%b_max_or, %b_max_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case C: lhs >= 0, rhs < 0 (signed).
    %c_exists = "arith.andi"(%lhs_nonneg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %c_min_signed_or = "transfer.or"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed_xor = "transfer.xor"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed_ashr = "transfer.ashr"(%c_min_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed = "transfer.sub"(%c_min_signed_or, %c_min_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_or = "transfer.or"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_xor = "transfer.xor"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_ashr = "transfer.ashr"(%c_max_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed = "transfer.sub"(%c_max_signed_or, %c_max_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_is_neg = "transfer.cmp"(%sign_bit, %c_min_signed) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_max_is_nonneg = "transfer.cmp"(%c_max_signed, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_crosses_sign = "arith.andi"(%c_min_is_neg, %c_max_is_nonneg) : (i1, i1) -> i1
    %c_min = "transfer.select"(%c_crosses_sign, %const0, %c_min_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max = "transfer.select"(%c_crosses_sign, %all_ones, %c_max_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Case D: lhs < 0, rhs >= 0 (signed).
    %d_exists = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %d_min_signed_or = "transfer.or"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed_xor = "transfer.xor"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed_ashr = "transfer.ashr"(%d_min_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed = "transfer.sub"(%d_min_signed_or, %d_min_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_or = "transfer.or"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_xor = "transfer.xor"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_ashr = "transfer.ashr"(%d_max_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed = "transfer.sub"(%d_max_signed_or, %d_max_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_is_neg = "transfer.cmp"(%sign_bit, %d_min_signed) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d_max_is_nonneg = "transfer.cmp"(%d_max_signed, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d_crosses_sign = "arith.andi"(%d_min_is_neg, %d_max_is_nonneg) : (i1, i1) -> i1
    %d_min = "transfer.select"(%d_crosses_sign, %const0, %d_min_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max = "transfer.select"(%d_crosses_sign, %all_ones, %d_max_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Join all present case ranges in unsigned order (start from bottom [max, 0]).
    %ret_lower_0 = "transfer.add"(%all_ones, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_0 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_a = "transfer.umin"(%ret_lower_0, %a_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_a = "transfer.umax"(%ret_upper_0, %a_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%a_exists, %ret_lower_a, %ret_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%a_exists, %ret_upper_a, %ret_upper_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_b = "transfer.umin"(%ret_lower_1, %b_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_b = "transfer.umax"(%ret_upper_1, %b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%b_exists, %ret_lower_b, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%b_exists, %ret_upper_b, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_c = "transfer.umin"(%ret_lower_2, %c_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_c = "transfer.umax"(%ret_upper_2, %c_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_3 = "transfer.select"(%c_exists, %ret_lower_c, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_3 = "transfer.select"(%c_exists, %ret_upper_c, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_d = "transfer.umin"(%ret_lower_3, %d_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_d = "transfer.umax"(%ret_upper_3, %d_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%d_exists, %ret_lower_d, %ret_lower_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%d_exists, %ret_upper_d, %ret_upper_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_avgceils", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()


## Existing library (do not duplicate)

The library already contains the following helpers. Do not re-emit functions that are already present or are trivially equivalent to them:

```mlir
builtin.module {}
```

## Available primitives

Library functions must use only these building blocks:

### Constructor and Deconstructor

- transfer.get : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
- transfer.make : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

### Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

### Integer Operations

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


## What to extract

A good library function:
1. **Encodes a meaningful semantic concept** — e.g., "extract the maybe-zero mask", "compute the carry-propagate bits", "get the minimum possible concrete value of a KnownBits". Prefer names that describe what the function *means*, not how it is computed.
2. **Appears across multiple transfer functions**, or is a large, self-contained sub-computation that would reduce duplication if future transfer functions were refactored to use it.
3. **Is non-trivial** — it should be at least 3 operations long. Do not extract single-op wrappers.
4. **Is general** — parameters should be abstract values or integers; do not hard-code bitwidth-specific constants unless the concept is inherently about a specific constant.

Do **not** extract the transfer functions themselves (e.g. `@kb_add`). Only extract helper functions that could be called from within transfer functions.

## Output format

Output a single `builtin.module` containing only the new library functions you are adding. Do not include the transfer functions from the input. Use `func.func` with:
- SSA form only
- One allowed operation per line
- Descriptive `snake_case` function names
- A brief `//` comment on the first line of each function body explaining its purpose
- Arguments typed as `!transfer.integer` or `!transfer.abs_value<[!transfer.integer, !transfer.integer]>` as appropriate

Example output shape (illustrative, do not copy verbatim):

```mlir
builtin.module {
  func.func @maybe_zero(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Returns the mask of bits that might be 0: complement of known-one.
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known1) : (!transfer.integer) -> !transfer.integer
    %res = "transfer.xor"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }
}
```

## Required workflow

1. Read each synthesized transfer function carefully. For each one, annotate (mentally) which sub-sequences of operations compute a semantically coherent intermediate result.
2. Look for sub-computations that appear in more than one function, or that are large enough to deserve a name on their own.
3. For each candidate, decide on a precise semantic description and a clear name.
4. Write the MLIR for each helper function. Verify it uses only allowed primitives and is in valid SSA form.
5. Output **only** the `builtin.module` containing the new helper functions — no explanation, no transfer functions, no markdown fences around the final answer.