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
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %res0 = "transfer.or"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_and", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    // A sufficient feasibility check for op_constraint rhs in [0, bw]:
    // if min(rhs) = known-one mask is already > bw, there is no feasible rhs.
    %rhs_min_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_le_bw) : (i1, i1) -> i1

    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_mask = "transfer.shl"(%const1, %bw_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_clz = "transfer.countl_zero"(%bitwidth) : (!transfer.integer) -> !transfer.integer
    %rhs_bound_low_mask = "transfer.lshr"(%all_ones, %bw_clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_bound_high_zero = "transfer.xor"(%rhs_bound_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_c = "transfer.or"(%rhs0, %rhs_bound_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_c = "transfer.and"(%rhs1, %rhs_bound_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res0 = "transfer.ashr"(%lhs0, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.ashr"(%lhs1, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1_c, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0_c, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_sign_zero = "transfer.and"(%lhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one = "transfer.and"(%lhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg = "transfer.cmp"(%lhs_sign_zero, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_sign_one, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_mlz = "transfer.countl_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_mlo = "transfer.countl_one"(%lhs1) : (!transfer.integer) -> !transfer.integer

    %lz_keep = "transfer.umax"(%lhs_mlz, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_keep = "transfer.umax"(%lhs_mlo, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lz_inv = "transfer.sub"(%bitwidth, %lz_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_inv = "transfer.sub"(%bitwidth, %lo_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.shl"(%all_ones, %lz_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_one_mask = "transfer.shl"(%all_ones, %lo_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0 = "transfer.select"(%lhs_nonneg, %high_zero_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.select"(%lhs_neg, %high_one_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_known_union = "transfer.or"(%rhs0_c, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas2 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas2) : (i1, i1) -> i1

    %alt_res0 = "transfer.ashr"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.ashr"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_2 = "transfer.select"(%rhs_feas2, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_2 = "transfer.select"(%rhs_feas2, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1_c, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1_c, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_res0_1 = "transfer.ashr"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.ashr"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.ashr"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.ashr"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.ashr"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.ashr"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %lhs0_is_zero = "transfer.cmp"(%lhs0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_all_ones = "transfer.cmp"(%lhs1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_all_ones = "arith.andi"(%lhs0_is_zero, %lhs1_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_is_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ashr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    // Exactness requires shifted-out low bits to be zero, so shift amount
    // cannot exceed the maximum possible trailing-zero count of lhs.
    %lhs_max_tz = "transfer.countr_zero"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %rhs_max_shift = "transfer.umin"(%bitwidth, %lhs_max_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min_le_bound = "transfer.cmp"(%rhs1, %rhs_max_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_le_bound) : (i1, i1) -> i1

    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_mask = "transfer.shl"(%const1, %bw_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_clz = "transfer.countl_zero"(%bitwidth) : (!transfer.integer) -> !transfer.integer
    %rhs_bound_low_mask = "transfer.lshr"(%all_ones, %bw_clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_bound_high_zero = "transfer.xor"(%rhs_bound_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_c = "transfer.or"(%rhs0, %rhs_bound_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_c = "transfer.and"(%rhs1, %rhs_bound_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res0 = "transfer.ashr"(%lhs0, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.ashr"(%lhs1, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1_c, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0_c, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_sign_zero = "transfer.and"(%lhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one = "transfer.and"(%lhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg = "transfer.cmp"(%lhs_sign_zero, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_sign_one, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_mlz = "transfer.countl_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_mlo = "transfer.countl_one"(%lhs1) : (!transfer.integer) -> !transfer.integer

    %lz_keep = "transfer.umax"(%lhs_mlz, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_keep = "transfer.umax"(%lhs_mlo, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lz_inv = "transfer.sub"(%bitwidth, %lz_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_inv = "transfer.sub"(%bitwidth, %lo_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.shl"(%all_ones, %lz_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_one_mask = "transfer.shl"(%all_ones, %lo_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0 = "transfer.select"(%lhs_nonneg, %high_zero_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.select"(%lhs_neg, %high_one_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_known_union = "transfer.or"(%rhs0_c, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas2 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas2) : (i1, i1) -> i1

    %alt_res0 = "transfer.ashr"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.ashr"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_2 = "transfer.select"(%rhs_feas2, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_2 = "transfer.select"(%rhs_feas2, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1_c, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1_c, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_res0_1 = "transfer.ashr"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.ashr"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.ashr"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.ashr"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.ashr"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.ashr"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %lhs0_is_zero = "transfer.cmp"(%lhs0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_all_ones = "transfer.cmp"(%lhs1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_all_ones = "arith.andi"(%lhs0_is_zero, %lhs1_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_is_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ashrexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%a : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %b : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %s : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %a0 = "transfer.get"(%a) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %a1 = "transfer.get"(%a) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b0 = "transfer.get"(%b) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b1 = "transfer.get"(%b) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s0 = "transfer.get"(%s) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s1 = "transfer.get"(%s) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%a0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%a0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%a0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %a_conflict = "transfer.and"(%a0, %a1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_conflict = "transfer.and"(%b0, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_conflict = "transfer.and"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_consistent = "transfer.cmp"(%a_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_consistent = "transfer.cmp"(%b_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_consistent = "transfer.cmp"(%s_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ab_consistent = "arith.andi"(%a_consistent, %b_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%ab_consistent, %s_consistent) : (i1, i1) -> i1

    %bitwidth = "transfer.get_bit_width"(%a0) : (!transfer.integer) -> !transfer.integer
    %k = "transfer.urem"(%s1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_shl = "transfer.shl"(%a0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_lshr = "transfer.lshr"(%b0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%a0_shl, %b0_lshr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_shl = "transfer.shl"(%a1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_lshr = "transfer.lshr"(%b1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%a1_shl, %b1_lshr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %s1_not = "transfer.xor"(%s1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_is_const = "transfer.cmp"(%s0, %s1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %s_known_union = "transfer.or"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_mask = "transfer.xor"(%s_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_nonzero = "transfer.cmp"(%s_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_unknown_minus_1 = "transfer.sub"(%s_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_and_minus_1 = "transfer.and"(%s_unknown_mask, %s_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_pow2ish = "transfer.cmp"(%s_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_one_unknown = "arith.andi"(%s_unknown_nonzero, %s_unknown_pow2ish) : (i1, i1) -> i1

    %s_alt = "transfer.add"(%s1, %s_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%s_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0_shl_alt = "transfer.shl"(%a0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_lshr_alt = "transfer.lshr"(%b0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%a0_shl_alt, %b0_lshr_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_shl_alt = "transfer.shl"(%a1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_lshr_alt = "transfer.lshr"(%b1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%a1_shl_alt, %b1_lshr_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%s_one_unknown, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%s_one_unknown, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%s_one_unknown, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%s_one_unknown, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%s_one_unknown, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%s_one_unknown, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%s_is_const, %const_res0, %two_case_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%s_is_const, %const_res1, %two_case_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_all_ones = "transfer.cmp"(%a0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_is_zero = "transfer.cmp"(%a1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_zero = "arith.andi"(%a0_all_ones, %a1_is_zero) : (i1, i1) -> i1
    %b0_all_ones = "transfer.cmp"(%b0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_is_zero = "transfer.cmp"(%b1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_zero = "arith.andi"(%b0_all_ones, %b1_is_zero) : (i1, i1) -> i1
    %both_zero = "arith.andi"(%a_is_zero, %b_is_zero) : (i1, i1) -> i1

    %a0_is_zero = "transfer.cmp"(%a0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_all_ones = "transfer.cmp"(%a1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_all_ones = "arith.andi"(%a0_is_zero, %a1_all_ones) : (i1, i1) -> i1
    %b0_is_zero = "transfer.cmp"(%b0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_all_ones = "transfer.cmp"(%b1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_all_ones = "arith.andi"(%b0_is_zero, %b1_all_ones) : (i1, i1) -> i1
    %both_all_ones = "arith.andi"(%a_is_all_ones, %b_is_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%both_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%both_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%both_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_fshl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%a : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %b : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %s : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %a0 = "transfer.get"(%a) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %a1 = "transfer.get"(%a) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b0 = "transfer.get"(%b) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b1 = "transfer.get"(%b) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s0 = "transfer.get"(%s) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s1 = "transfer.get"(%s) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%a0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%a0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%a0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %a_conflict = "transfer.and"(%a0, %a1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_conflict = "transfer.and"(%b0, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_conflict = "transfer.and"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_consistent = "transfer.cmp"(%a_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_consistent = "transfer.cmp"(%b_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_consistent = "transfer.cmp"(%s_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ab_consistent = "arith.andi"(%a_consistent, %b_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%ab_consistent, %s_consistent) : (i1, i1) -> i1

    %bitwidth = "transfer.get_bit_width"(%a0) : (!transfer.integer) -> !transfer.integer
    %k = "transfer.urem"(%s1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_lshr = "transfer.lshr"(%a0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_shl = "transfer.shl"(%b0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%a0_lshr, %b0_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_lshr = "transfer.lshr"(%a1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_shl = "transfer.shl"(%b1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%a1_lshr, %b1_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %s1_not = "transfer.xor"(%s1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_is_const = "transfer.cmp"(%s0, %s1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %s_known_union = "transfer.or"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_mask = "transfer.xor"(%s_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_nonzero = "transfer.cmp"(%s_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_unknown_minus_1 = "transfer.sub"(%s_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_and_minus_1 = "transfer.and"(%s_unknown_mask, %s_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_pow2ish = "transfer.cmp"(%s_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_one_unknown = "arith.andi"(%s_unknown_nonzero, %s_unknown_pow2ish) : (i1, i1) -> i1

    %s_alt = "transfer.add"(%s1, %s_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%s_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0_lshr_alt = "transfer.lshr"(%a0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_shl_alt = "transfer.shl"(%b0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%a0_lshr_alt, %b0_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_lshr_alt = "transfer.lshr"(%a1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_shl_alt = "transfer.shl"(%b1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%a1_lshr_alt, %b1_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%s_one_unknown, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%s_one_unknown, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%s_one_unknown, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%s_one_unknown, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%s_one_unknown, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%s_one_unknown, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%s_is_const, %const_res0, %two_case_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%s_is_const, %const_res1, %two_case_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_all_ones = "transfer.cmp"(%a0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_is_zero = "transfer.cmp"(%a1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_zero = "arith.andi"(%a0_all_ones, %a1_is_zero) : (i1, i1) -> i1
    %b0_all_ones = "transfer.cmp"(%b0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_is_zero = "transfer.cmp"(%b1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_zero = "arith.andi"(%b0_all_ones, %b1_is_zero) : (i1, i1) -> i1
    %both_zero = "arith.andi"(%a_is_zero, %b_is_zero) : (i1, i1) -> i1

    %a0_is_zero = "transfer.cmp"(%a0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_all_ones = "transfer.cmp"(%a1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_all_ones = "arith.andi"(%a0_is_zero, %a1_all_ones) : (i1, i1) -> i1
    %b0_is_zero = "transfer.cmp"(%b0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_all_ones = "transfer.cmp"(%b1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_all_ones = "arith.andi"(%b0_is_zero, %b1_all_ones) : (i1, i1) -> i1
    %both_all_ones = "arith.andi"(%a_is_all_ones, %b_is_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%both_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%both_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%both_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_fshr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_lt_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_lt_bw) : (i1, i1) -> i1

    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_m1_clz = "transfer.countl_zero"(%bw_minus_1) : (!transfer.integer) -> !transfer.integer
    %rhs_bound_low_mask = "transfer.lshr"(%all_ones, %bw_m1_clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_bound_high_zero = "transfer.xor"(%rhs_bound_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_c = "transfer.or"(%rhs0, %rhs_bound_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_c = "transfer.and"(%rhs1, %rhs_bound_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_shift_res0 = "transfer.lshr"(%lhs0, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.lshr"(%lhs1, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_mask_after_min = "transfer.lshr"(%all_ones, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %intro_zero_mask = "transfer.xor"(%low_mask_after_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%const_shift_res0, %intro_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1_c, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0_c, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0_c, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_u3_rem1_not_pow2 = "arith.xori"(%rhs_u2_rem_pow2, %const_true) : (i1, i1) -> i1
    %rhs_u3_rem2 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_nonzero = "transfer.cmp"(%rhs_u3_rem2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_minus_1 = "transfer.sub"(%rhs_u3_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_and_minus_1 = "transfer.and"(%rhs_u3_rem2, %rhs_u3_rem2_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_pow2ish = "transfer.cmp"(%rhs_u3_rem2_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_pow2 = "arith.andi"(%rhs_u3_rem2_nonzero, %rhs_u3_rem2_pow2ish) : (i1, i1) -> i1
    %rhs_three_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown_1 = "arith.andi"(%rhs_three_unknown_0, %rhs_u3_rem1_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_three_unknown_1, %rhs_u3_rem2_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas1 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas1) : (i1, i1) -> i1

    %alt_shift_res0 = "transfer.lshr"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.lshr"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_low_mask = "transfer.lshr"(%all_ones, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_zero = "transfer.xor"(%alt_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%alt_shift_res0, %alt_intro_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%rhs_feas1, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%rhs_feas1, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1_c, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1_c, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_shift0_1 = "transfer.lshr"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_2 = "transfer.lshr"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_3 = "transfer.lshr"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_1 = "transfer.lshr"(%all_ones, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_2 = "transfer.lshr"(%all_ones, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_3 = "transfer.lshr"(%all_ones, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_1 = "transfer.xor"(%rhs_u2_lowmask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_2 = "transfer.xor"(%rhs_u2_lowmask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_3 = "transfer.xor"(%rhs_u2_lowmask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_1 = "transfer.or"(%rhs_u2_shift0_1, %rhs_u2_intro0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.or"(%rhs_u2_shift0_2, %rhs_u2_intro0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.or"(%rhs_u2_shift0_3, %rhs_u2_intro0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.lshr"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.lshr"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.lshr"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_rem1_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit1 = "transfer.and"(%rhs_unknown_mask, %rhs_u3_rem1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_not = "transfer.xor"(%rhs_u3_rem2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit2 = "transfer.and"(%rhs_u3_rest, %rhs_u3_rem2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit3 = "transfer.xor"(%rhs_u3_rest, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_val1 = "transfer.add"(%rhs1_c, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val2 = "transfer.add"(%rhs1_c, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val3 = "transfer.add"(%rhs1_c, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit12 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit13 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit23 = "transfer.add"(%rhs_u3_bit2, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val4 = "transfer.add"(%rhs1_c, %rhs_u3_bit12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val5 = "transfer.add"(%rhs1_c, %rhs_u3_bit13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val6 = "transfer.add"(%rhs1_c, %rhs_u3_bit23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val7 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_le_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_le_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_le_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_le_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_le_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_le_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_le_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_u3_feas0 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v0_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas1 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v1_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas2 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v2_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas3 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v3_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas4 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v4_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas5 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v5_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas6 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v6_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas7 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v7_le_bw) : (i1, i1) -> i1

    %rhs_u3_any01 = "arith.ori"(%rhs_u3_feas0, %rhs_u3_feas1) : (i1, i1) -> i1
    %rhs_u3_any23 = "arith.ori"(%rhs_u3_feas2, %rhs_u3_feas3) : (i1, i1) -> i1
    %rhs_u3_any45 = "arith.ori"(%rhs_u3_feas4, %rhs_u3_feas5) : (i1, i1) -> i1
    %rhs_u3_any67 = "arith.ori"(%rhs_u3_feas6, %rhs_u3_feas7) : (i1, i1) -> i1
    %rhs_u3_any0123 = "arith.ori"(%rhs_u3_any01, %rhs_u3_any23) : (i1, i1) -> i1
    %rhs_u3_any4567 = "arith.ori"(%rhs_u3_any45, %rhs_u3_any67) : (i1, i1) -> i1
    %rhs_u3_any = "arith.ori"(%rhs_u3_any0123, %rhs_u3_any4567) : (i1, i1) -> i1

    %rhs_u3_shift0_1 = "transfer.lshr"(%lhs0, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_2 = "transfer.lshr"(%lhs0, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_3 = "transfer.lshr"(%lhs0, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_4 = "transfer.lshr"(%lhs0, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_5 = "transfer.lshr"(%lhs0, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_6 = "transfer.lshr"(%lhs0, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_7 = "transfer.lshr"(%lhs0, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_lowmask_1 = "transfer.lshr"(%all_ones, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_2 = "transfer.lshr"(%all_ones, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_3 = "transfer.lshr"(%all_ones, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_4 = "transfer.lshr"(%all_ones, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_5 = "transfer.lshr"(%all_ones, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_6 = "transfer.lshr"(%all_ones, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_7 = "transfer.lshr"(%all_ones, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_intro0_1 = "transfer.xor"(%rhs_u3_lowmask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_2 = "transfer.xor"(%rhs_u3_lowmask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_3 = "transfer.xor"(%rhs_u3_lowmask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_4 = "transfer.xor"(%rhs_u3_lowmask_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_5 = "transfer.xor"(%rhs_u3_lowmask_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_6 = "transfer.xor"(%rhs_u3_lowmask_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_7 = "transfer.xor"(%rhs_u3_lowmask_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res0_1 = "transfer.or"(%rhs_u3_shift0_1, %rhs_u3_intro0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_2 = "transfer.or"(%rhs_u3_shift0_2, %rhs_u3_intro0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_3 = "transfer.or"(%rhs_u3_shift0_3, %rhs_u3_intro0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_4 = "transfer.or"(%rhs_u3_shift0_4, %rhs_u3_intro0_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_5 = "transfer.or"(%rhs_u3_shift0_5, %rhs_u3_intro0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_6 = "transfer.or"(%rhs_u3_shift0_6, %rhs_u3_intro0_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_7 = "transfer.or"(%rhs_u3_shift0_7, %rhs_u3_intro0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel0_0 = "transfer.select"(%rhs_u3_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc0_01 = "transfer.and"(%rhs_u3_sel0_0, %rhs_u3_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_23 = "transfer.and"(%rhs_u3_sel0_2, %rhs_u3_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_45 = "transfer.and"(%rhs_u3_sel0_4, %rhs_u3_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_67 = "transfer.and"(%rhs_u3_sel0_6, %rhs_u3_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_0123 = "transfer.and"(%rhs_u3_acc0_01, %rhs_u3_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_4567 = "transfer.and"(%rhs_u3_acc0_45, %rhs_u3_acc0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0 = "transfer.and"(%rhs_u3_acc0_0123, %rhs_u3_acc0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res0 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res1_1 = "transfer.lshr"(%lhs1, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_2 = "transfer.lshr"(%lhs1, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_3 = "transfer.lshr"(%lhs1, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_4 = "transfer.lshr"(%lhs1, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_5 = "transfer.lshr"(%lhs1, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_6 = "transfer.lshr"(%lhs1, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_7 = "transfer.lshr"(%lhs1, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel1_0 = "transfer.select"(%rhs_u3_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res1_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res1_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res1_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res1_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc1_01 = "transfer.and"(%rhs_u3_sel1_0, %rhs_u3_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_23 = "transfer.and"(%rhs_u3_sel1_2, %rhs_u3_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_45 = "transfer.and"(%rhs_u3_sel1_4, %rhs_u3_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_67 = "transfer.and"(%rhs_u3_sel1_6, %rhs_u3_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_0123 = "transfer.and"(%rhs_u3_acc1_01, %rhs_u3_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_4567 = "transfer.and"(%rhs_u3_acc1_45, %rhs_u3_acc1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1 = "transfer.and"(%rhs_u3_acc1_0123, %rhs_u3_acc1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res1 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0 = "transfer.add"(%intro_zero_mask, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res0, %var_res0_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res1, %var_res1_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %res0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_lshr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    // lshr exact requires all shifted-out low bits to be zero.
    %lhs_max_exact_shift = "transfer.countr_zero"(%lhs1) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_lt_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_exact_ok = "transfer.cmp"(%rhs1, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %rhs_min_ok = "arith.andi"(%rhs_min_lt_bw, %rhs_min_exact_ok) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_ok) : (i1, i1) -> i1

    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_m1_clz = "transfer.countl_zero"(%bw_minus_1) : (!transfer.integer) -> !transfer.integer
    %rhs_bound_low_mask = "transfer.lshr"(%all_ones, %bw_m1_clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_bound_high_zero = "transfer.xor"(%rhs_bound_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_c = "transfer.or"(%rhs0, %rhs_bound_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_c = "transfer.and"(%rhs1, %rhs_bound_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_shift_res0 = "transfer.lshr"(%lhs0, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.lshr"(%lhs1, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_mask_after_min = "transfer.lshr"(%all_ones, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %intro_zero_mask = "transfer.xor"(%low_mask_after_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%const_shift_res0, %intro_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1_c, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0_c, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0_c, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_u3_rem1_not_pow2 = "arith.xori"(%rhs_u2_rem_pow2, %const_true) : (i1, i1) -> i1
    %rhs_u3_rem2 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_nonzero = "transfer.cmp"(%rhs_u3_rem2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_minus_1 = "transfer.sub"(%rhs_u3_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_and_minus_1 = "transfer.and"(%rhs_u3_rem2, %rhs_u3_rem2_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_pow2ish = "transfer.cmp"(%rhs_u3_rem2_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_pow2 = "arith.andi"(%rhs_u3_rem2_nonzero, %rhs_u3_rem2_pow2ish) : (i1, i1) -> i1
    %rhs_three_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown_1 = "arith.andi"(%rhs_three_unknown_0, %rhs_u3_rem1_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_three_unknown_1, %rhs_u3_rem2_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_exact_ok = "transfer.cmp"(%rhs1_c, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_exact_ok = "transfer.cmp"(%rhs_alt, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_ok = "arith.andi"(%rhs_val0_le_bw, %rhs_val0_exact_ok) : (i1, i1) -> i1
    %rhs_alt_ok = "arith.andi"(%rhs_alt_le_bw, %rhs_alt_exact_ok) : (i1, i1) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_ok) : (i1, i1) -> i1
    %rhs_feas1 = "arith.andi"(%rhs_one_unknown, %rhs_alt_ok) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas1) : (i1, i1) -> i1

    %alt_shift_res0 = "transfer.lshr"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.lshr"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_low_mask = "transfer.lshr"(%all_ones, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_zero = "transfer.xor"(%alt_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%alt_shift_res0, %alt_intro_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%rhs_feas1, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%rhs_feas1, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1_c, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1_c, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v0_exact_ok = "transfer.cmp"(%rhs1_c, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_exact_ok = "transfer.cmp"(%rhs_u2_val1, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_exact_ok = "transfer.cmp"(%rhs_u2_val2, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_exact_ok = "transfer.cmp"(%rhs_u2_val3, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v0_ok = "arith.andi"(%rhs_u2_v0_le_bw, %rhs_u2_v0_exact_ok) : (i1, i1) -> i1
    %rhs_u2_v1_ok = "arith.andi"(%rhs_u2_v1_le_bw, %rhs_u2_v1_exact_ok) : (i1, i1) -> i1
    %rhs_u2_v2_ok = "arith.andi"(%rhs_u2_v2_le_bw, %rhs_u2_v2_exact_ok) : (i1, i1) -> i1
    %rhs_u2_v3_ok = "arith.andi"(%rhs_u2_v3_le_bw, %rhs_u2_v3_exact_ok) : (i1, i1) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_ok) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_ok) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_ok) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_ok) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_shift0_1 = "transfer.lshr"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_2 = "transfer.lshr"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_3 = "transfer.lshr"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_1 = "transfer.lshr"(%all_ones, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_2 = "transfer.lshr"(%all_ones, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowmask_3 = "transfer.lshr"(%all_ones, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_1 = "transfer.xor"(%rhs_u2_lowmask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_2 = "transfer.xor"(%rhs_u2_lowmask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro0_3 = "transfer.xor"(%rhs_u2_lowmask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_1 = "transfer.or"(%rhs_u2_shift0_1, %rhs_u2_intro0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.or"(%rhs_u2_shift0_2, %rhs_u2_intro0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.or"(%rhs_u2_shift0_3, %rhs_u2_intro0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.lshr"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.lshr"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.lshr"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_rem1_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit1 = "transfer.and"(%rhs_unknown_mask, %rhs_u3_rem1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_not = "transfer.xor"(%rhs_u3_rem2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit2 = "transfer.and"(%rhs_u3_rest, %rhs_u3_rem2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit3 = "transfer.xor"(%rhs_u3_rest, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_val1 = "transfer.add"(%rhs1_c, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val2 = "transfer.add"(%rhs1_c, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val3 = "transfer.add"(%rhs1_c, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit12 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit13 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit23 = "transfer.add"(%rhs_u3_bit2, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val4 = "transfer.add"(%rhs1_c, %rhs_u3_bit12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val5 = "transfer.add"(%rhs1_c, %rhs_u3_bit13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val6 = "transfer.add"(%rhs1_c, %rhs_u3_bit23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val7 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_le_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_le_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_le_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_le_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_le_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_le_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_le_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_u3_v0_exact_ok = "transfer.cmp"(%rhs1_c, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_exact_ok = "transfer.cmp"(%rhs_u3_val1, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_exact_ok = "transfer.cmp"(%rhs_u3_val2, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_exact_ok = "transfer.cmp"(%rhs_u3_val3, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_exact_ok = "transfer.cmp"(%rhs_u3_val4, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_exact_ok = "transfer.cmp"(%rhs_u3_val5, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_exact_ok = "transfer.cmp"(%rhs_u3_val6, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_exact_ok = "transfer.cmp"(%rhs_u3_val7, %lhs_max_exact_shift) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v0_ok = "arith.andi"(%rhs_u3_v0_le_bw, %rhs_u3_v0_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v1_ok = "arith.andi"(%rhs_u3_v1_le_bw, %rhs_u3_v1_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v2_ok = "arith.andi"(%rhs_u3_v2_le_bw, %rhs_u3_v2_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v3_ok = "arith.andi"(%rhs_u3_v3_le_bw, %rhs_u3_v3_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v4_ok = "arith.andi"(%rhs_u3_v4_le_bw, %rhs_u3_v4_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v5_ok = "arith.andi"(%rhs_u3_v5_le_bw, %rhs_u3_v5_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v6_ok = "arith.andi"(%rhs_u3_v6_le_bw, %rhs_u3_v6_exact_ok) : (i1, i1) -> i1
    %rhs_u3_v7_ok = "arith.andi"(%rhs_u3_v7_le_bw, %rhs_u3_v7_exact_ok) : (i1, i1) -> i1
    %rhs_u3_feas0 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v0_ok) : (i1, i1) -> i1
    %rhs_u3_feas1 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v1_ok) : (i1, i1) -> i1
    %rhs_u3_feas2 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v2_ok) : (i1, i1) -> i1
    %rhs_u3_feas3 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v3_ok) : (i1, i1) -> i1
    %rhs_u3_feas4 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v4_ok) : (i1, i1) -> i1
    %rhs_u3_feas5 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v5_ok) : (i1, i1) -> i1
    %rhs_u3_feas6 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v6_ok) : (i1, i1) -> i1
    %rhs_u3_feas7 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v7_ok) : (i1, i1) -> i1

    %rhs_u3_any01 = "arith.ori"(%rhs_u3_feas0, %rhs_u3_feas1) : (i1, i1) -> i1
    %rhs_u3_any23 = "arith.ori"(%rhs_u3_feas2, %rhs_u3_feas3) : (i1, i1) -> i1
    %rhs_u3_any45 = "arith.ori"(%rhs_u3_feas4, %rhs_u3_feas5) : (i1, i1) -> i1
    %rhs_u3_any67 = "arith.ori"(%rhs_u3_feas6, %rhs_u3_feas7) : (i1, i1) -> i1
    %rhs_u3_any0123 = "arith.ori"(%rhs_u3_any01, %rhs_u3_any23) : (i1, i1) -> i1
    %rhs_u3_any4567 = "arith.ori"(%rhs_u3_any45, %rhs_u3_any67) : (i1, i1) -> i1
    %rhs_u3_any = "arith.ori"(%rhs_u3_any0123, %rhs_u3_any4567) : (i1, i1) -> i1

    %rhs_u3_shift0_1 = "transfer.lshr"(%lhs0, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_2 = "transfer.lshr"(%lhs0, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_3 = "transfer.lshr"(%lhs0, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_4 = "transfer.lshr"(%lhs0, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_5 = "transfer.lshr"(%lhs0, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_6 = "transfer.lshr"(%lhs0, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_7 = "transfer.lshr"(%lhs0, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_lowmask_1 = "transfer.lshr"(%all_ones, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_2 = "transfer.lshr"(%all_ones, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_3 = "transfer.lshr"(%all_ones, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_4 = "transfer.lshr"(%all_ones, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_5 = "transfer.lshr"(%all_ones, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_6 = "transfer.lshr"(%all_ones, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_lowmask_7 = "transfer.lshr"(%all_ones, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_intro0_1 = "transfer.xor"(%rhs_u3_lowmask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_2 = "transfer.xor"(%rhs_u3_lowmask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_3 = "transfer.xor"(%rhs_u3_lowmask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_4 = "transfer.xor"(%rhs_u3_lowmask_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_5 = "transfer.xor"(%rhs_u3_lowmask_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_6 = "transfer.xor"(%rhs_u3_lowmask_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro0_7 = "transfer.xor"(%rhs_u3_lowmask_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res0_1 = "transfer.or"(%rhs_u3_shift0_1, %rhs_u3_intro0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_2 = "transfer.or"(%rhs_u3_shift0_2, %rhs_u3_intro0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_3 = "transfer.or"(%rhs_u3_shift0_3, %rhs_u3_intro0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_4 = "transfer.or"(%rhs_u3_shift0_4, %rhs_u3_intro0_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_5 = "transfer.or"(%rhs_u3_shift0_5, %rhs_u3_intro0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_6 = "transfer.or"(%rhs_u3_shift0_6, %rhs_u3_intro0_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_7 = "transfer.or"(%rhs_u3_shift0_7, %rhs_u3_intro0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel0_0 = "transfer.select"(%rhs_u3_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc0_01 = "transfer.and"(%rhs_u3_sel0_0, %rhs_u3_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_23 = "transfer.and"(%rhs_u3_sel0_2, %rhs_u3_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_45 = "transfer.and"(%rhs_u3_sel0_4, %rhs_u3_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_67 = "transfer.and"(%rhs_u3_sel0_6, %rhs_u3_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_0123 = "transfer.and"(%rhs_u3_acc0_01, %rhs_u3_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_4567 = "transfer.and"(%rhs_u3_acc0_45, %rhs_u3_acc0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0 = "transfer.and"(%rhs_u3_acc0_0123, %rhs_u3_acc0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res0 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res1_1 = "transfer.lshr"(%lhs1, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_2 = "transfer.lshr"(%lhs1, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_3 = "transfer.lshr"(%lhs1, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_4 = "transfer.lshr"(%lhs1, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_5 = "transfer.lshr"(%lhs1, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_6 = "transfer.lshr"(%lhs1, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_7 = "transfer.lshr"(%lhs1, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel1_0 = "transfer.select"(%rhs_u3_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res1_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res1_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res1_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res1_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc1_01 = "transfer.and"(%rhs_u3_sel1_0, %rhs_u3_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_23 = "transfer.and"(%rhs_u3_sel1_2, %rhs_u3_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_45 = "transfer.and"(%rhs_u3_sel1_4, %rhs_u3_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_67 = "transfer.and"(%rhs_u3_sel1_6, %rhs_u3_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_0123 = "transfer.and"(%rhs_u3_acc1_01, %rhs_u3_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_4567 = "transfer.and"(%rhs_u3_acc1_45, %rhs_u3_acc1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1 = "transfer.and"(%rhs_u3_acc1_0123, %rhs_u3_acc1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res1 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0 = "transfer.add"(%intro_zero_mask, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res0, %var_res0_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res1, %var_res1_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %res0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_lshrexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %k = "transfer.urem"(%rhs1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_shl = "transfer.shl"(%lhs0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_lshr = "transfer.lshr"(%lhs0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%lhs0_shl, %lhs0_lshr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl = "transfer.shl"(%lhs1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr = "transfer.lshr"(%lhs1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%lhs1_shl, %lhs1_lshr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%rhs_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_shl_alt = "transfer.shl"(%lhs0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_lshr_alt = "transfer.lshr"(%lhs0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%lhs0_shl_alt, %lhs0_lshr_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl_alt = "transfer.shl"(%lhs1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr_alt = "transfer.lshr"(%lhs1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%lhs1_shl_alt, %lhs1_lshr_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0_raw = "transfer.and"(%const_res0, %alt_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1_raw = "transfer.and"(%const_res1, %alt_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0 = "transfer.select"(%rhs_one_unknown, %one_unknown_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1 = "transfer.select"(%rhs_one_unknown, %one_unknown_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %res0_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %res1_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %lhs0_is_zero = "transfer.cmp"(%lhs0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_all_ones = "transfer.cmp"(%lhs1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_all_ones = "arith.andi"(%lhs0_is_zero, %lhs1_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_is_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_rotl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %k = "transfer.urem"(%rhs1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_lshr = "transfer.lshr"(%lhs0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_shl = "transfer.shl"(%lhs0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%lhs0_lshr, %lhs0_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr = "transfer.lshr"(%lhs1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl = "transfer.shl"(%lhs1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%lhs1_lshr, %lhs1_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%rhs_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_lshr_alt = "transfer.lshr"(%lhs0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_shl_alt = "transfer.shl"(%lhs0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%lhs0_lshr_alt, %lhs0_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr_alt = "transfer.lshr"(%lhs1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl_alt = "transfer.shl"(%lhs1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%lhs1_lshr_alt, %lhs1_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0_raw = "transfer.and"(%const_res0, %alt_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1_raw = "transfer.and"(%const_res1, %alt_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0 = "transfer.select"(%rhs_one_unknown, %one_unknown_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1 = "transfer.select"(%rhs_one_unknown, %one_unknown_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %res0_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %res1_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %lhs0_is_zero = "transfer.cmp"(%lhs0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_all_ones = "transfer.cmp"(%lhs1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_all_ones = "arith.andi"(%lhs0_is_zero, %lhs1_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_is_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_rotr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_lt_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max_lt_bw = "transfer.cmp"(%rhs_max, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_le_bw) : (i1, i1) -> i1

    %const_shift_res0 = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_mask = "transfer.shl"(%all_ones, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_zero = "transfer.xor"(%const_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro = "transfer.select"(%rhs1_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%const_shift_res0, %const_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_u3_rem1_not_pow2 = "arith.xori"(%rhs_u2_rem_pow2, %const_true) : (i1, i1) -> i1
    %rhs_u3_rem2 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_nonzero = "transfer.cmp"(%rhs_u3_rem2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_minus_1 = "transfer.sub"(%rhs_u3_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_and_minus_1 = "transfer.and"(%rhs_u3_rem2, %rhs_u3_rem2_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_pow2ish = "transfer.cmp"(%rhs_u3_rem2_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_pow2 = "arith.andi"(%rhs_u3_rem2_nonzero, %rhs_u3_rem2_pow2ish) : (i1, i1) -> i1
    %rhs_three_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown_1 = "arith.andi"(%rhs_three_unknown_0, %rhs_u3_rem1_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_three_unknown_1, %rhs_u3_rem2_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_lt_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas1 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas1) : (i1, i1) -> i1

    %alt_shift_res0 = "transfer.shl"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.shl"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_mask = "transfer.shl"(%all_ones, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_zero = "transfer.xor"(%alt_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro = "transfer.select"(%rhs_alt_lt_bw, %alt_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%alt_shift_res0, %alt_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%rhs_feas1, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%rhs_feas1, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_shift0_1 = "transfer.shl"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_2 = "transfer.shl"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_3 = "transfer.shl"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_v1_lt_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_lt_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_lt_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_intro_mask_1 = "transfer.shl"(%all_ones, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_mask_2 = "transfer.shl"(%all_ones, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_mask_3 = "transfer.shl"(%all_ones, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_1 = "transfer.xor"(%rhs_u2_intro_mask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_2 = "transfer.xor"(%rhs_u2_intro_mask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_3 = "transfer.xor"(%rhs_u2_intro_mask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_1 = "transfer.select"(%rhs_u2_v1_lt_bw, %rhs_u2_intro_zero_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_2 = "transfer.select"(%rhs_u2_v2_lt_bw, %rhs_u2_intro_zero_2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_3 = "transfer.select"(%rhs_u2_v3_lt_bw, %rhs_u2_intro_zero_3, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_1 = "transfer.or"(%rhs_u2_shift0_1, %rhs_u2_intro_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.or"(%rhs_u2_shift0_2, %rhs_u2_intro_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.or"(%rhs_u2_shift0_3, %rhs_u2_intro_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.shl"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.shl"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.shl"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_rem1_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit1 = "transfer.and"(%rhs_unknown_mask, %rhs_u3_rem1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_not = "transfer.xor"(%rhs_u3_rem2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit2 = "transfer.and"(%rhs_u3_rest, %rhs_u3_rem2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit3 = "transfer.xor"(%rhs_u3_rest, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_val1 = "transfer.add"(%rhs1, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val2 = "transfer.add"(%rhs1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val3 = "transfer.add"(%rhs1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit12 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit13 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit23 = "transfer.add"(%rhs_u3_bit2, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val4 = "transfer.add"(%rhs1, %rhs_u3_bit12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val5 = "transfer.add"(%rhs1, %rhs_u3_bit13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val6 = "transfer.add"(%rhs1, %rhs_u3_bit23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val7 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_le_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_le_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_le_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_le_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_le_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_le_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_le_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_u3_feas0 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v0_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas1 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v1_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas2 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v2_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas3 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v3_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas4 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v4_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas5 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v5_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas6 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v6_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas7 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v7_le_bw) : (i1, i1) -> i1

    %rhs_u3_any01 = "arith.ori"(%rhs_u3_feas0, %rhs_u3_feas1) : (i1, i1) -> i1
    %rhs_u3_any23 = "arith.ori"(%rhs_u3_feas2, %rhs_u3_feas3) : (i1, i1) -> i1
    %rhs_u3_any45 = "arith.ori"(%rhs_u3_feas4, %rhs_u3_feas5) : (i1, i1) -> i1
    %rhs_u3_any67 = "arith.ori"(%rhs_u3_feas6, %rhs_u3_feas7) : (i1, i1) -> i1
    %rhs_u3_any0123 = "arith.ori"(%rhs_u3_any01, %rhs_u3_any23) : (i1, i1) -> i1
    %rhs_u3_any4567 = "arith.ori"(%rhs_u3_any45, %rhs_u3_any67) : (i1, i1) -> i1
    %rhs_u3_any = "arith.ori"(%rhs_u3_any0123, %rhs_u3_any4567) : (i1, i1) -> i1

    %rhs_u3_shift0_1 = "transfer.shl"(%lhs0, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_2 = "transfer.shl"(%lhs0, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_3 = "transfer.shl"(%lhs0, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_4 = "transfer.shl"(%lhs0, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_5 = "transfer.shl"(%lhs0, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_6 = "transfer.shl"(%lhs0, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_7 = "transfer.shl"(%lhs0, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v1_lt_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_lt_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_lt_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_lt_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_lt_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_lt_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_lt_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_intro_mask_1 = "transfer.shl"(%all_ones, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_2 = "transfer.shl"(%all_ones, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_3 = "transfer.shl"(%all_ones, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_4 = "transfer.shl"(%all_ones, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_5 = "transfer.shl"(%all_ones, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_6 = "transfer.shl"(%all_ones, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_7 = "transfer.shl"(%all_ones, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_1 = "transfer.xor"(%rhs_u3_intro_mask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_2 = "transfer.xor"(%rhs_u3_intro_mask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_3 = "transfer.xor"(%rhs_u3_intro_mask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_4 = "transfer.xor"(%rhs_u3_intro_mask_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_5 = "transfer.xor"(%rhs_u3_intro_mask_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_6 = "transfer.xor"(%rhs_u3_intro_mask_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_7 = "transfer.xor"(%rhs_u3_intro_mask_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_1 = "transfer.select"(%rhs_u3_v1_lt_bw, %rhs_u3_intro_zero_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_2 = "transfer.select"(%rhs_u3_v2_lt_bw, %rhs_u3_intro_zero_2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_3 = "transfer.select"(%rhs_u3_v3_lt_bw, %rhs_u3_intro_zero_3, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_4 = "transfer.select"(%rhs_u3_v4_lt_bw, %rhs_u3_intro_zero_4, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_5 = "transfer.select"(%rhs_u3_v5_lt_bw, %rhs_u3_intro_zero_5, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_6 = "transfer.select"(%rhs_u3_v6_lt_bw, %rhs_u3_intro_zero_6, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_7 = "transfer.select"(%rhs_u3_v7_lt_bw, %rhs_u3_intro_zero_7, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_1 = "transfer.or"(%rhs_u3_shift0_1, %rhs_u3_intro_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_2 = "transfer.or"(%rhs_u3_shift0_2, %rhs_u3_intro_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_3 = "transfer.or"(%rhs_u3_shift0_3, %rhs_u3_intro_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_4 = "transfer.or"(%rhs_u3_shift0_4, %rhs_u3_intro_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_5 = "transfer.or"(%rhs_u3_shift0_5, %rhs_u3_intro_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_6 = "transfer.or"(%rhs_u3_shift0_6, %rhs_u3_intro_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_7 = "transfer.or"(%rhs_u3_shift0_7, %rhs_u3_intro_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel0_0 = "transfer.select"(%rhs_u3_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc0_01 = "transfer.and"(%rhs_u3_sel0_0, %rhs_u3_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_23 = "transfer.and"(%rhs_u3_sel0_2, %rhs_u3_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_45 = "transfer.and"(%rhs_u3_sel0_4, %rhs_u3_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_67 = "transfer.and"(%rhs_u3_sel0_6, %rhs_u3_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_0123 = "transfer.and"(%rhs_u3_acc0_01, %rhs_u3_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_4567 = "transfer.and"(%rhs_u3_acc0_45, %rhs_u3_acc0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0 = "transfer.and"(%rhs_u3_acc0_0123, %rhs_u3_acc0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res0 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res1_1 = "transfer.shl"(%lhs1, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_2 = "transfer.shl"(%lhs1, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_3 = "transfer.shl"(%lhs1, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_4 = "transfer.shl"(%lhs1, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_5 = "transfer.shl"(%lhs1, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_6 = "transfer.shl"(%lhs1, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_7 = "transfer.shl"(%lhs1, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel1_0 = "transfer.select"(%rhs_u3_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res1_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res1_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res1_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res1_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc1_01 = "transfer.and"(%rhs_u3_sel1_0, %rhs_u3_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_23 = "transfer.and"(%rhs_u3_sel1_2, %rhs_u3_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_45 = "transfer.and"(%rhs_u3_sel1_4, %rhs_u3_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_67 = "transfer.and"(%rhs_u3_sel1_6, %rhs_u3_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_0123 = "transfer.and"(%rhs_u3_acc1_01, %rhs_u3_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_4567 = "transfer.and"(%rhs_u3_acc1_45, %rhs_u3_acc1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1 = "transfer.and"(%rhs_u3_acc1_0123, %rhs_u3_acc1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res1 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_base_intro = "transfer.select"(%rhs_max_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0 = "transfer.add"(%var_base_intro, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res0, %var_res0_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res1, %var_res1_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %res0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

builtin.module {
  func.func @func0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v6 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v7 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.and"(%v6, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v8 = "transfer.constant"(%v9) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v4 = "transfer.cmp"(%v5, %v8) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v12 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v13 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.and"(%v12, %v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v14 = "transfer.constant"(%v15) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v10 = "transfer.cmp"(%v11, %v14) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v3 = "arith.andi"(%v4, %v10) : (i1, i1) -> i1
    %v18 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v19 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v17 = "transfer.and"(%v18, %v19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v21 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v20 = "transfer.constant"(%v21) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.cmp"(%v17, %v20) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v2 = "arith.andi"(%v3, %v16) : (i1, i1) -> i1
    %v26 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v28 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v27 = "transfer.constant"(%v28) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.cmp"(%v26, %v27) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v30 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v32 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get_all_ones"(%v32) : (!transfer.integer) -> !transfer.integer
    %v29 = "transfer.cmp"(%v30, %v31) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v24 = "arith.andi"(%v25, %v29) : (i1, i1) -> i1
    %v35 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.constant"(%v37) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v34 = "transfer.cmp"(%v35, %v36) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v39 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v41 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v40 = "transfer.get_all_ones"(%v41) : (!transfer.integer) -> !transfer.integer
    %v38 = "transfer.cmp"(%v39, %v40) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v33 = "arith.andi"(%v34, %v38) : (i1, i1) -> i1
    %v23 = "arith.andi"(%v24, %v33) : (i1, i1) -> i1
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.constant"(%v43) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v48 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v50 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v49 = "transfer.get_all_ones"(%v50) : (!transfer.integer) -> !transfer.integer
    %v47 = "transfer.cmp"(%v48, %v49) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v52 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v54 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v53 = "transfer.constant"(%v54) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v51 = "transfer.cmp"(%v52, %v53) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v46 = "arith.andi"(%v47, %v51) : (i1, i1) -> i1
    %v57 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v59 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v58 = "transfer.get_all_ones"(%v59) : (!transfer.integer) -> !transfer.integer
    %v56 = "transfer.cmp"(%v57, %v58) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v61 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v63 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v62 = "transfer.constant"(%v63) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v60 = "transfer.cmp"(%v61, %v62) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v55 = "arith.andi"(%v56, %v60) : (i1, i1) -> i1
    %v45 = "arith.andi"(%v46, %v55) : (i1, i1) -> i1
    %v65 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v64 = "transfer.get_all_ones"(%v65) : (!transfer.integer) -> !transfer.integer
    %v68 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v70 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v72 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v71 = "transfer.get_all_ones"(%v72) : (!transfer.integer) -> !transfer.integer
    %v69 = "transfer.xor"(%v70, %v71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v67 = "transfer.cmp"(%v68, %v69) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v75 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v77 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v79 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v78 = "transfer.get_bit_width"(%v79) : (!transfer.integer) -> !transfer.integer
    %v76 = "transfer.urem"(%v77, %v78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v74 = func.call @%h0(%v75, %v76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v81 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v84 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v83 = "transfer.get_bit_width"(%v84) : (!transfer.integer) -> !transfer.integer
    %v86 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v88 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v87 = "transfer.get_bit_width"(%v88) : (!transfer.integer) -> !transfer.integer
    %v85 = "transfer.urem"(%v86, %v87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v82 = "transfer.sub"(%v83, %v85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v80 = func.call @%h1(%v81, %v82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v73 = "transfer.or"(%v74, %v80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v94 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v95 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v93 = "transfer.or"(%v94, %v95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v97 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v96 = "transfer.get_all_ones"(%v97) : (!transfer.integer) -> !transfer.integer
    %v92 = "transfer.xor"(%v93, %v96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v99 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v98 = "transfer.constant"(%v99) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v91 = "transfer.cmp"(%v92, %v98) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v104 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v105 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v103 = "transfer.or"(%v104, %v105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v107 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v106 = "transfer.get_all_ones"(%v107) : (!transfer.integer) -> !transfer.integer
    %v102 = "transfer.xor"(%v103, %v106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v111 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v112 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v110 = "transfer.or"(%v111, %v112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v114 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v113 = "transfer.get_all_ones"(%v114) : (!transfer.integer) -> !transfer.integer
    %v109 = "transfer.xor"(%v110, %v113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v116 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v115 = "transfer.constant"(%v116) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v108 = "transfer.sub"(%v109, %v115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v101 = "transfer.and"(%v102, %v108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v118 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v117 = "transfer.constant"(%v118) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v100 = "transfer.cmp"(%v101, %v117) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v90 = "arith.andi"(%v91, %v100) : (i1, i1) -> i1
    %v125 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v126 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v124 = "transfer.or"(%v125, %v126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v128 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v127 = "transfer.get_all_ones"(%v128) : (!transfer.integer) -> !transfer.integer
    %v123 = "transfer.xor"(%v124, %v127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v130 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v129 = "transfer.constant"(%v130) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v122 = "transfer.cmp"(%v123, %v129) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v135 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v136 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v134 = "transfer.or"(%v135, %v136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v138 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v137 = "transfer.get_all_ones"(%v138) : (!transfer.integer) -> !transfer.integer
    %v133 = "transfer.xor"(%v134, %v137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v142 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v143 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v141 = "transfer.or"(%v142, %v143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v145 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v144 = "transfer.get_all_ones"(%v145) : (!transfer.integer) -> !transfer.integer
    %v140 = "transfer.xor"(%v141, %v144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v147 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v146 = "transfer.constant"(%v147) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v139 = "transfer.sub"(%v140, %v146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v132 = "transfer.and"(%v133, %v139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v149 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v148 = "transfer.constant"(%v149) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v131 = "transfer.cmp"(%v132, %v148) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v121 = "arith.andi"(%v122, %v131) : (i1, i1) -> i1
    %v152 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v154 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v156 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v155 = "transfer.get_bit_width"(%v156) : (!transfer.integer) -> !transfer.integer
    %v153 = "transfer.urem"(%v154, %v155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v151 = func.call @%h0(%v152, %v153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v158 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v161 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v160 = "transfer.get_bit_width"(%v161) : (!transfer.integer) -> !transfer.integer
    %v163 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v165 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v164 = "transfer.get_bit_width"(%v165) : (!transfer.integer) -> !transfer.integer
    %v162 = "transfer.urem"(%v163, %v164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v159 = "transfer.sub"(%v160, %v162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v157 = func.call @%h1(%v158, %v159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v150 = "transfer.or"(%v151, %v157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v167 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v166 = "transfer.get_all_ones"(%v167) : (!transfer.integer) -> !transfer.integer
    %v120 = "transfer.select"(%v121, %v150, %v166) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v173 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v174 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v172 = "transfer.or"(%v173, %v174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v176 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v175 = "transfer.get_all_ones"(%v176) : (!transfer.integer) -> !transfer.integer
    %v171 = "transfer.xor"(%v172, %v175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v178 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v177 = "transfer.constant"(%v178) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v170 = "transfer.cmp"(%v171, %v177) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v183 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v184 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v182 = "transfer.or"(%v183, %v184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v186 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v185 = "transfer.get_all_ones"(%v186) : (!transfer.integer) -> !transfer.integer
    %v181 = "transfer.xor"(%v182, %v185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v190 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v191 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v189 = "transfer.or"(%v190, %v191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v193 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v192 = "transfer.get_all_ones"(%v193) : (!transfer.integer) -> !transfer.integer
    %v188 = "transfer.xor"(%v189, %v192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v195 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v194 = "transfer.constant"(%v195) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v187 = "transfer.sub"(%v188, %v194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v180 = "transfer.and"(%v181, %v187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v197 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v196 = "transfer.constant"(%v197) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v179 = "transfer.cmp"(%v180, %v196) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v169 = "arith.andi"(%v170, %v179) : (i1, i1) -> i1
    %v200 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v203 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v206 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v207 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v205 = "transfer.or"(%v206, %v207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v209 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v208 = "transfer.get_all_ones"(%v209) : (!transfer.integer) -> !transfer.integer
    %v204 = "transfer.xor"(%v205, %v208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v202 = "transfer.add"(%v203, %v204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v211 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v210 = "transfer.get_bit_width"(%v211) : (!transfer.integer) -> !transfer.integer
    %v201 = "transfer.urem"(%v202, %v210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v199 = func.call @%h0(%v200, %v201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v213 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v216 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v215 = "transfer.get_bit_width"(%v216) : (!transfer.integer) -> !transfer.integer
    %v219 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v222 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v223 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v221 = "transfer.or"(%v222, %v223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v225 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v224 = "transfer.get_all_ones"(%v225) : (!transfer.integer) -> !transfer.integer
    %v220 = "transfer.xor"(%v221, %v224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v218 = "transfer.add"(%v219, %v220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v227 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v226 = "transfer.get_bit_width"(%v227) : (!transfer.integer) -> !transfer.integer
    %v217 = "transfer.urem"(%v218, %v226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v214 = "transfer.sub"(%v215, %v217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v212 = func.call @%h1(%v213, %v214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v198 = "transfer.or"(%v199, %v212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v229 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v228 = "transfer.get_all_ones"(%v229) : (!transfer.integer) -> !transfer.integer
    %v168 = "transfer.select"(%v169, %v198, %v228) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v119 = "transfer.and"(%v120, %v168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v231 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v230 = "transfer.constant"(%v231) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v89 = "transfer.select"(%v90, %v119, %v230) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v66 = "transfer.select"(%v67, %v73, %v89) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v44 = "transfer.select"(%v45, %v64, %v66) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v22 = "transfer.select"(%v23, %v42, %v44) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v233 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v232 = "transfer.get_all_ones"(%v233) : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v22, %v232) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v239 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v240 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v238 = "transfer.and"(%v239, %v240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v242 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v241 = "transfer.constant"(%v242) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v237 = "transfer.cmp"(%v238, %v241) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v245 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v246 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v244 = "transfer.and"(%v245, %v246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v248 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v247 = "transfer.constant"(%v248) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v243 = "transfer.cmp"(%v244, %v247) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v236 = "arith.andi"(%v237, %v243) : (i1, i1) -> i1
    %v251 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v252 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v250 = "transfer.and"(%v251, %v252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v254 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v253 = "transfer.constant"(%v254) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v249 = "transfer.cmp"(%v250, %v253) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v235 = "arith.andi"(%v236, %v249) : (i1, i1) -> i1
    %v259 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v261 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v260 = "transfer.constant"(%v261) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v258 = "transfer.cmp"(%v259, %v260) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v263 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v265 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v264 = "transfer.get_all_ones"(%v265) : (!transfer.integer) -> !transfer.integer
    %v262 = "transfer.cmp"(%v263, %v264) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v257 = "arith.andi"(%v258, %v262) : (i1, i1) -> i1
    %v268 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v270 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v269 = "transfer.constant"(%v270) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v267 = "transfer.cmp"(%v268, %v269) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v272 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v274 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v273 = "transfer.get_all_ones"(%v274) : (!transfer.integer) -> !transfer.integer
    %v271 = "transfer.cmp"(%v272, %v273) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v266 = "arith.andi"(%v267, %v271) : (i1, i1) -> i1
    %v256 = "arith.andi"(%v257, %v266) : (i1, i1) -> i1
    %v276 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v275 = "transfer.get_all_ones"(%v276) : (!transfer.integer) -> !transfer.integer
    %v281 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v283 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v282 = "transfer.get_all_ones"(%v283) : (!transfer.integer) -> !transfer.integer
    %v280 = "transfer.cmp"(%v281, %v282) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v285 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v287 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v286 = "transfer.constant"(%v287) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v284 = "transfer.cmp"(%v285, %v286) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v279 = "arith.andi"(%v280, %v284) : (i1, i1) -> i1
    %v290 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v292 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v291 = "transfer.get_all_ones"(%v292) : (!transfer.integer) -> !transfer.integer
    %v289 = "transfer.cmp"(%v290, %v291) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v294 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v296 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v295 = "transfer.constant"(%v296) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v293 = "transfer.cmp"(%v294, %v295) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v288 = "arith.andi"(%v289, %v293) : (i1, i1) -> i1
    %v278 = "arith.andi"(%v279, %v288) : (i1, i1) -> i1
    %v298 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v297 = "transfer.constant"(%v298) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v301 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v303 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v305 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v304 = "transfer.get_all_ones"(%v305) : (!transfer.integer) -> !transfer.integer
    %v302 = "transfer.xor"(%v303, %v304) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v300 = "transfer.cmp"(%v301, %v302) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v308 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v310 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v312 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v311 = "transfer.get_bit_width"(%v312) : (!transfer.integer) -> !transfer.integer
    %v309 = "transfer.urem"(%v310, %v311) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v307 = func.call @%h0(%v308, %v309) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v314 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v317 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v316 = "transfer.get_bit_width"(%v317) : (!transfer.integer) -> !transfer.integer
    %v319 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v321 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v320 = "transfer.get_bit_width"(%v321) : (!transfer.integer) -> !transfer.integer
    %v318 = "transfer.urem"(%v319, %v320) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v315 = "transfer.sub"(%v316, %v318) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v313 = func.call @%h1(%v314, %v315) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v306 = "transfer.or"(%v307, %v313) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v327 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v328 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v326 = "transfer.or"(%v327, %v328) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v330 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v329 = "transfer.get_all_ones"(%v330) : (!transfer.integer) -> !transfer.integer
    %v325 = "transfer.xor"(%v326, %v329) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v332 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v331 = "transfer.constant"(%v332) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v324 = "transfer.cmp"(%v325, %v331) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v337 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v338 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v336 = "transfer.or"(%v337, %v338) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v340 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v339 = "transfer.get_all_ones"(%v340) : (!transfer.integer) -> !transfer.integer
    %v335 = "transfer.xor"(%v336, %v339) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v344 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v345 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v343 = "transfer.or"(%v344, %v345) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v347 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v346 = "transfer.get_all_ones"(%v347) : (!transfer.integer) -> !transfer.integer
    %v342 = "transfer.xor"(%v343, %v346) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v349 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v348 = "transfer.constant"(%v349) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v341 = "transfer.sub"(%v342, %v348) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v334 = "transfer.and"(%v335, %v341) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v351 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v350 = "transfer.constant"(%v351) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v333 = "transfer.cmp"(%v334, %v350) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v323 = "arith.andi"(%v324, %v333) : (i1, i1) -> i1
    %v358 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v359 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v357 = "transfer.or"(%v358, %v359) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v361 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v360 = "transfer.get_all_ones"(%v361) : (!transfer.integer) -> !transfer.integer
    %v356 = "transfer.xor"(%v357, %v360) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v363 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v362 = "transfer.constant"(%v363) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v355 = "transfer.cmp"(%v356, %v362) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v368 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v369 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v367 = "transfer.or"(%v368, %v369) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v371 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v370 = "transfer.get_all_ones"(%v371) : (!transfer.integer) -> !transfer.integer
    %v366 = "transfer.xor"(%v367, %v370) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v375 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v376 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v374 = "transfer.or"(%v375, %v376) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v378 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v377 = "transfer.get_all_ones"(%v378) : (!transfer.integer) -> !transfer.integer
    %v373 = "transfer.xor"(%v374, %v377) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v380 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v379 = "transfer.constant"(%v380) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v372 = "transfer.sub"(%v373, %v379) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v365 = "transfer.and"(%v366, %v372) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v382 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v381 = "transfer.constant"(%v382) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v364 = "transfer.cmp"(%v365, %v381) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v354 = "arith.andi"(%v355, %v364) : (i1, i1) -> i1
    %v385 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v387 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v389 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v388 = "transfer.get_bit_width"(%v389) : (!transfer.integer) -> !transfer.integer
    %v386 = "transfer.urem"(%v387, %v388) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v384 = func.call @%h0(%v385, %v386) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v391 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v394 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v393 = "transfer.get_bit_width"(%v394) : (!transfer.integer) -> !transfer.integer
    %v396 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v398 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v397 = "transfer.get_bit_width"(%v398) : (!transfer.integer) -> !transfer.integer
    %v395 = "transfer.urem"(%v396, %v397) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v392 = "transfer.sub"(%v393, %v395) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v390 = func.call @%h1(%v391, %v392) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v383 = "transfer.or"(%v384, %v390) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v400 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v399 = "transfer.get_all_ones"(%v400) : (!transfer.integer) -> !transfer.integer
    %v353 = "transfer.select"(%v354, %v383, %v399) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v406 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v407 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v405 = "transfer.or"(%v406, %v407) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v409 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v408 = "transfer.get_all_ones"(%v409) : (!transfer.integer) -> !transfer.integer
    %v404 = "transfer.xor"(%v405, %v408) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v411 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v410 = "transfer.constant"(%v411) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v403 = "transfer.cmp"(%v404, %v410) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v416 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v417 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v415 = "transfer.or"(%v416, %v417) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v419 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v418 = "transfer.get_all_ones"(%v419) : (!transfer.integer) -> !transfer.integer
    %v414 = "transfer.xor"(%v415, %v418) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v423 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v424 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v422 = "transfer.or"(%v423, %v424) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v426 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v425 = "transfer.get_all_ones"(%v426) : (!transfer.integer) -> !transfer.integer
    %v421 = "transfer.xor"(%v422, %v425) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v428 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v427 = "transfer.constant"(%v428) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v420 = "transfer.sub"(%v421, %v427) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v413 = "transfer.and"(%v414, %v420) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v430 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v429 = "transfer.constant"(%v430) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v412 = "transfer.cmp"(%v413, %v429) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v402 = "arith.andi"(%v403, %v412) : (i1, i1) -> i1
    %v433 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v436 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v439 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v440 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v438 = "transfer.or"(%v439, %v440) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v442 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v441 = "transfer.get_all_ones"(%v442) : (!transfer.integer) -> !transfer.integer
    %v437 = "transfer.xor"(%v438, %v441) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v435 = "transfer.add"(%v436, %v437) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v444 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v443 = "transfer.get_bit_width"(%v444) : (!transfer.integer) -> !transfer.integer
    %v434 = "transfer.urem"(%v435, %v443) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v432 = func.call @%h0(%v433, %v434) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v446 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v449 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v448 = "transfer.get_bit_width"(%v449) : (!transfer.integer) -> !transfer.integer
    %v452 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v455 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v456 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v454 = "transfer.or"(%v455, %v456) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v458 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v457 = "transfer.get_all_ones"(%v458) : (!transfer.integer) -> !transfer.integer
    %v453 = "transfer.xor"(%v454, %v457) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v451 = "transfer.add"(%v452, %v453) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v460 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v459 = "transfer.get_bit_width"(%v460) : (!transfer.integer) -> !transfer.integer
    %v450 = "transfer.urem"(%v451, %v459) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v447 = "transfer.sub"(%v448, %v450) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v445 = func.call @%h1(%v446, %v447) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v431 = "transfer.or"(%v432, %v445) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v462 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v461 = "transfer.get_all_ones"(%v462) : (!transfer.integer) -> !transfer.integer
    %v401 = "transfer.select"(%v402, %v431, %v461) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v352 = "transfer.and"(%v353, %v401) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v464 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v463 = "transfer.constant"(%v464) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v322 = "transfer.select"(%v323, %v352, %v463) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v299 = "transfer.select"(%v300, %v306, %v322) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v277 = "transfer.select"(%v278, %v297, %v299) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v255 = "transfer.select"(%v256, %v275, %v277) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v466 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v465 = "transfer.get_all_ones"(%v466) : (!transfer.integer) -> !transfer.integer
    %v234 = "transfer.select"(%v235, %v255, %v465) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v234) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.constant"(%v6) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v3 = "transfer.cmp"(%v4, %v5) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v8 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v9 = "transfer.get_all_ones"(%v10) : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.cmp"(%v8, %v9) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v2 = "arith.andi"(%v3, %v7) : (i1, i1) -> i1
    %v12 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.constant"(%v12) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v18 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v17 = "transfer.get_all_ones"(%v18) : (!transfer.integer) -> !transfer.integer
    %v15 = "transfer.cmp"(%v16, %v17) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v20 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v21 = "transfer.constant"(%v22) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v19 = "transfer.cmp"(%v20, %v21) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v14 = "arith.andi"(%v15, %v19) : (i1, i1) -> i1
    %v24 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v23 = "transfer.get_all_ones"(%v24) : (!transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v29 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v30 = "transfer.get_all_ones"(%v31) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.xor"(%v29, %v30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v26 = "transfer.cmp"(%v27, %v28) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v34 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v38 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.get_bit_width"(%v38) : (!transfer.integer) -> !transfer.integer
    %v35 = "transfer.urem"(%v36, %v37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v33 = func.call @%h0(%v34, %v35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v40 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.get_bit_width"(%v43) : (!transfer.integer) -> !transfer.integer
    %v45 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v47 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v46 = "transfer.get_bit_width"(%v47) : (!transfer.integer) -> !transfer.integer
    %v44 = "transfer.urem"(%v45, %v46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = "transfer.sub"(%v42, %v44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v39 = func.call @%h1(%v40, %v41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v32 = "transfer.or"(%v33, %v39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v53 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v54 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v52 = "transfer.or"(%v53, %v54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v56 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v55 = "transfer.get_all_ones"(%v56) : (!transfer.integer) -> !transfer.integer
    %v51 = "transfer.xor"(%v52, %v55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v58 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v57 = "transfer.constant"(%v58) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v50 = "transfer.cmp"(%v51, %v57) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v63 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v64 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v62 = "transfer.or"(%v63, %v64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v66 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v65 = "transfer.get_all_ones"(%v66) : (!transfer.integer) -> !transfer.integer
    %v61 = "transfer.xor"(%v62, %v65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v70 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v71 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v69 = "transfer.or"(%v70, %v71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v73 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v72 = "transfer.get_all_ones"(%v73) : (!transfer.integer) -> !transfer.integer
    %v68 = "transfer.xor"(%v69, %v72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v75 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v74 = "transfer.constant"(%v75) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v67 = "transfer.sub"(%v68, %v74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v60 = "transfer.and"(%v61, %v67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v77 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v76 = "transfer.constant"(%v77) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v59 = "transfer.cmp"(%v60, %v76) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v49 = "arith.andi"(%v50, %v59) : (i1, i1) -> i1
    %v83 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v84 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v82 = "transfer.or"(%v83, %v84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v86 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v85 = "transfer.get_all_ones"(%v86) : (!transfer.integer) -> !transfer.integer
    %v81 = "transfer.xor"(%v82, %v85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v88 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v87 = "transfer.constant"(%v88) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v80 = "transfer.cmp"(%v81, %v87) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v93 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v94 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v92 = "transfer.or"(%v93, %v94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v96 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v95 = "transfer.get_all_ones"(%v96) : (!transfer.integer) -> !transfer.integer
    %v91 = "transfer.xor"(%v92, %v95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v100 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v101 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v99 = "transfer.or"(%v100, %v101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v103 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v102 = "transfer.get_all_ones"(%v103) : (!transfer.integer) -> !transfer.integer
    %v98 = "transfer.xor"(%v99, %v102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v105 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v104 = "transfer.constant"(%v105) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v97 = "transfer.sub"(%v98, %v104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v90 = "transfer.and"(%v91, %v97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v107 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v106 = "transfer.constant"(%v107) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v89 = "transfer.cmp"(%v90, %v106) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v79 = "arith.andi"(%v80, %v89) : (i1, i1) -> i1
    %v111 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v113 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v115 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v114 = "transfer.get_bit_width"(%v115) : (!transfer.integer) -> !transfer.integer
    %v112 = "transfer.urem"(%v113, %v114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v110 = func.call @%h0(%v111, %v112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v117 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v120 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v119 = "transfer.get_bit_width"(%v120) : (!transfer.integer) -> !transfer.integer
    %v122 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v124 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v123 = "transfer.get_bit_width"(%v124) : (!transfer.integer) -> !transfer.integer
    %v121 = "transfer.urem"(%v122, %v123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v118 = "transfer.sub"(%v119, %v121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v116 = func.call @%h1(%v117, %v118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v109 = "transfer.or"(%v110, %v116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v127 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v130 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v133 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v134 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v132 = "transfer.or"(%v133, %v134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v136 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v135 = "transfer.get_all_ones"(%v136) : (!transfer.integer) -> !transfer.integer
    %v131 = "transfer.xor"(%v132, %v135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v129 = "transfer.add"(%v130, %v131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v138 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v137 = "transfer.get_bit_width"(%v138) : (!transfer.integer) -> !transfer.integer
    %v128 = "transfer.urem"(%v129, %v137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v126 = func.call @%h0(%v127, %v128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v140 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v143 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v142 = "transfer.get_bit_width"(%v143) : (!transfer.integer) -> !transfer.integer
    %v146 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v149 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v150 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v148 = "transfer.or"(%v149, %v150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v152 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v151 = "transfer.get_all_ones"(%v152) : (!transfer.integer) -> !transfer.integer
    %v147 = "transfer.xor"(%v148, %v151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v145 = "transfer.add"(%v146, %v147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v154 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v153 = "transfer.get_bit_width"(%v154) : (!transfer.integer) -> !transfer.integer
    %v144 = "transfer.urem"(%v145, %v153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v141 = "transfer.sub"(%v142, %v144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v139 = func.call @%h1(%v140, %v141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v125 = "transfer.or"(%v126, %v139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v108 = "transfer.and"(%v109, %v125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v156 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v155 = "transfer.constant"(%v156) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v78 = "transfer.select"(%v79, %v108, %v155) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v158 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v157 = "transfer.constant"(%v158) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v48 = "transfer.select"(%v49, %v78, %v157) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v25 = "transfer.select"(%v26, %v32, %v48) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v13 = "transfer.select"(%v14, %v23, %v25) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v11, %v13) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v162 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v164 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v163 = "transfer.constant"(%v164) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v161 = "transfer.cmp"(%v162, %v163) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v166 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v168 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v167 = "transfer.get_all_ones"(%v168) : (!transfer.integer) -> !transfer.integer
    %v165 = "transfer.cmp"(%v166, %v167) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v160 = "arith.andi"(%v161, %v165) : (i1, i1) -> i1
    %v170 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v169 = "transfer.get_all_ones"(%v170) : (!transfer.integer) -> !transfer.integer
    %v174 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v176 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v175 = "transfer.get_all_ones"(%v176) : (!transfer.integer) -> !transfer.integer
    %v173 = "transfer.cmp"(%v174, %v175) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v178 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v180 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v179 = "transfer.constant"(%v180) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v177 = "transfer.cmp"(%v178, %v179) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v172 = "arith.andi"(%v173, %v177) : (i1, i1) -> i1
    %v182 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v181 = "transfer.constant"(%v182) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v185 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v187 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v189 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v188 = "transfer.get_all_ones"(%v189) : (!transfer.integer) -> !transfer.integer
    %v186 = "transfer.xor"(%v187, %v188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v184 = "transfer.cmp"(%v185, %v186) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v192 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v194 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v196 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v195 = "transfer.get_bit_width"(%v196) : (!transfer.integer) -> !transfer.integer
    %v193 = "transfer.urem"(%v194, %v195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v191 = func.call @%h0(%v192, %v193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v198 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v201 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v200 = "transfer.get_bit_width"(%v201) : (!transfer.integer) -> !transfer.integer
    %v203 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v205 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v204 = "transfer.get_bit_width"(%v205) : (!transfer.integer) -> !transfer.integer
    %v202 = "transfer.urem"(%v203, %v204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v199 = "transfer.sub"(%v200, %v202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v197 = func.call @%h1(%v198, %v199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v190 = "transfer.or"(%v191, %v197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v211 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v212 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v210 = "transfer.or"(%v211, %v212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v214 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v213 = "transfer.get_all_ones"(%v214) : (!transfer.integer) -> !transfer.integer
    %v209 = "transfer.xor"(%v210, %v213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v216 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v215 = "transfer.constant"(%v216) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v208 = "transfer.cmp"(%v209, %v215) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v221 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v222 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v220 = "transfer.or"(%v221, %v222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v224 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v223 = "transfer.get_all_ones"(%v224) : (!transfer.integer) -> !transfer.integer
    %v219 = "transfer.xor"(%v220, %v223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v228 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v229 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v227 = "transfer.or"(%v228, %v229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v231 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v230 = "transfer.get_all_ones"(%v231) : (!transfer.integer) -> !transfer.integer
    %v226 = "transfer.xor"(%v227, %v230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v233 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v232 = "transfer.constant"(%v233) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v225 = "transfer.sub"(%v226, %v232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v218 = "transfer.and"(%v219, %v225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v235 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v234 = "transfer.constant"(%v235) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v217 = "transfer.cmp"(%v218, %v234) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v207 = "arith.andi"(%v208, %v217) : (i1, i1) -> i1
    %v241 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v242 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v240 = "transfer.or"(%v241, %v242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v244 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v243 = "transfer.get_all_ones"(%v244) : (!transfer.integer) -> !transfer.integer
    %v239 = "transfer.xor"(%v240, %v243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v246 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v245 = "transfer.constant"(%v246) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v238 = "transfer.cmp"(%v239, %v245) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v251 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v252 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v250 = "transfer.or"(%v251, %v252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v254 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v253 = "transfer.get_all_ones"(%v254) : (!transfer.integer) -> !transfer.integer
    %v249 = "transfer.xor"(%v250, %v253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v258 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v259 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v257 = "transfer.or"(%v258, %v259) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v261 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v260 = "transfer.get_all_ones"(%v261) : (!transfer.integer) -> !transfer.integer
    %v256 = "transfer.xor"(%v257, %v260) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v263 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v262 = "transfer.constant"(%v263) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v255 = "transfer.sub"(%v256, %v262) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v248 = "transfer.and"(%v249, %v255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v265 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v264 = "transfer.constant"(%v265) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v247 = "transfer.cmp"(%v248, %v264) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v237 = "arith.andi"(%v238, %v247) : (i1, i1) -> i1
    %v269 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v271 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v273 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v272 = "transfer.get_bit_width"(%v273) : (!transfer.integer) -> !transfer.integer
    %v270 = "transfer.urem"(%v271, %v272) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v268 = func.call @%h0(%v269, %v270) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v275 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v278 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v277 = "transfer.get_bit_width"(%v278) : (!transfer.integer) -> !transfer.integer
    %v280 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v282 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v281 = "transfer.get_bit_width"(%v282) : (!transfer.integer) -> !transfer.integer
    %v279 = "transfer.urem"(%v280, %v281) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v276 = "transfer.sub"(%v277, %v279) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v274 = func.call @%h1(%v275, %v276) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v267 = "transfer.or"(%v268, %v274) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v285 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v288 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v291 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v292 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v290 = "transfer.or"(%v291, %v292) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v294 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v293 = "transfer.get_all_ones"(%v294) : (!transfer.integer) -> !transfer.integer
    %v289 = "transfer.xor"(%v290, %v293) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v287 = "transfer.add"(%v288, %v289) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v296 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v295 = "transfer.get_bit_width"(%v296) : (!transfer.integer) -> !transfer.integer
    %v286 = "transfer.urem"(%v287, %v295) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v284 = func.call @%h0(%v285, %v286) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v298 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v301 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v300 = "transfer.get_bit_width"(%v301) : (!transfer.integer) -> !transfer.integer
    %v304 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v307 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v308 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v306 = "transfer.or"(%v307, %v308) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v310 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v309 = "transfer.get_all_ones"(%v310) : (!transfer.integer) -> !transfer.integer
    %v305 = "transfer.xor"(%v306, %v309) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v303 = "transfer.add"(%v304, %v305) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v312 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v311 = "transfer.get_bit_width"(%v312) : (!transfer.integer) -> !transfer.integer
    %v302 = "transfer.urem"(%v303, %v311) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v299 = "transfer.sub"(%v300, %v302) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v297 = func.call @%h1(%v298, %v299) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v283 = "transfer.or"(%v284, %v297) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v266 = "transfer.and"(%v267, %v283) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v314 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v313 = "transfer.constant"(%v314) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v236 = "transfer.select"(%v237, %v266, %v313) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v316 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v315 = "transfer.constant"(%v316) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v206 = "transfer.select"(%v207, %v236, %v315) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v183 = "transfer.select"(%v184, %v190, %v206) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v171 = "transfer.select"(%v172, %v181, %v183) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v159 = "transfer.select"(%v160, %v169, %v171) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v159) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.and"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}


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