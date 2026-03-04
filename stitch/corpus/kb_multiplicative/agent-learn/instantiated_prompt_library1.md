## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions in MLIR. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## Synthesized transfer functions (inputs)


"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%x0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %bit1_mask_raw = "transfer.shl"(%const1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_gt_1 = "transfer.cmp"(%const1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bit1_mask = "transfer.select"(%bw_gt_1, %bit1_mask_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %bit2_mask = "transfer.shl"(%bit1_mask_raw, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Fallback: trailing-zero and low-bit facts that hold for all squares.
    %min_tz = "transfer.countr_one"(%x0) : (!transfer.integer) -> !transfer.integer
    %tz2 = "transfer.add"(%min_tz, %min_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %tz2_le_bw = "transfer.cmp"(%tz2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %tz2_clamped = "transfer.select"(%tz2_le_bw, %tz2, %bitwidth) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %tz2_inv = "transfer.sub"(%bitwidth, %tz2_clamped) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_mask = "transfer.lshr"(%all_ones, %tz2_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lsb_one = "transfer.and"(%x1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %x_is_odd = "transfer.cmp"(%lsb_one, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bit2_zero_if_odd = "transfer.select"(%x_is_odd, %bit2_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_fb_0 = "transfer.or"(%low_zero_mask, %bit1_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_fb = "transfer.or"(%res0_fb_0, %bit2_zero_if_odd) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_fb = "transfer.and"(%lsb_one, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Exact constant case.
    %x1_not = "transfer.xor"(%x1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %x_is_const = "transfer.cmp"(%x0, %x1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_sq = "transfer.mul"(%x1, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_sq_not = "transfer.xor"(%const_sq, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const = "transfer.select"(%x_is_const, %const_sq_not, %res0_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const = "transfer.select"(%x_is_const, %const_sq, %res1_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Enumerate exactly when there are <= 4 unknown bits.
    %known_union = "transfer.or"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown = "transfer.xor"(%known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown_m1 = "transfer.sub"(%unknown, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem1 = "transfer.and"(%unknown, %unknown_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem1_m1 = "transfer.sub"(%rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem2 = "transfer.and"(%rem1, %rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem2_m1 = "transfer.sub"(%rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem3 = "transfer.and"(%rem2, %rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem3_m1 = "transfer.sub"(%rem3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem4 = "transfer.and"(%rem3, %rem3_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown_le4 = "transfer.cmp"(%rem4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %b1 = "transfer.xor"(%unknown, %rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2 = "transfer.xor"(%rem1, %rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3 = "transfer.xor"(%rem2, %rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4 = "transfer.xor"(%rem3, %rem4) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %v0 = "transfer.add"(%x1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.add"(%v0, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.add"(%v0, %b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.add"(%v1, %b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.add"(%v0, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.add"(%v1, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v6 = "transfer.add"(%v2, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = "transfer.add"(%v3, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = "transfer.add"(%v0, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.add"(%v1, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v10 = "transfer.add"(%v2, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = "transfer.add"(%v3, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v12 = "transfer.add"(%v4, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v13 = "transfer.add"(%v5, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.add"(%v6, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.add"(%v7, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sq0 = "transfer.mul"(%v0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq0_not = "transfer.xor"(%sq0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_0 = "transfer.and"(%all_ones, %sq0_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_0 = "transfer.and"(%all_ones, %sq0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq1 = "transfer.mul"(%v1, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq1_not = "transfer.xor"(%sq1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_1 = "transfer.and"(%acc0_0, %sq1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_1 = "transfer.and"(%acc1_0, %sq1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq2 = "transfer.mul"(%v2, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq2_not = "transfer.xor"(%sq2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_2 = "transfer.and"(%acc0_1, %sq2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_2 = "transfer.and"(%acc1_1, %sq2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq3 = "transfer.mul"(%v3, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq3_not = "transfer.xor"(%sq3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_3 = "transfer.and"(%acc0_2, %sq3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_3 = "transfer.and"(%acc1_2, %sq3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq4 = "transfer.mul"(%v4, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq4_not = "transfer.xor"(%sq4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_4 = "transfer.and"(%acc0_3, %sq4_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_4 = "transfer.and"(%acc1_3, %sq4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq5 = "transfer.mul"(%v5, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq5_not = "transfer.xor"(%sq5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_5 = "transfer.and"(%acc0_4, %sq5_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_5 = "transfer.and"(%acc1_4, %sq5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq6 = "transfer.mul"(%v6, %v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq6_not = "transfer.xor"(%sq6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_6 = "transfer.and"(%acc0_5, %sq6_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_6 = "transfer.and"(%acc1_5, %sq6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq7 = "transfer.mul"(%v7, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq7_not = "transfer.xor"(%sq7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_7 = "transfer.and"(%acc0_6, %sq7_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_7 = "transfer.and"(%acc1_6, %sq7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq8 = "transfer.mul"(%v8, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq8_not = "transfer.xor"(%sq8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_8 = "transfer.and"(%acc0_7, %sq8_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_8 = "transfer.and"(%acc1_7, %sq8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq9 = "transfer.mul"(%v9, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq9_not = "transfer.xor"(%sq9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_9 = "transfer.and"(%acc0_8, %sq9_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_9 = "transfer.and"(%acc1_8, %sq9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq10 = "transfer.mul"(%v10, %v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq10_not = "transfer.xor"(%sq10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_10 = "transfer.and"(%acc0_9, %sq10_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_10 = "transfer.and"(%acc1_9, %sq10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq11 = "transfer.mul"(%v11, %v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq11_not = "transfer.xor"(%sq11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_11 = "transfer.and"(%acc0_10, %sq11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_11 = "transfer.and"(%acc1_10, %sq11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq12 = "transfer.mul"(%v12, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq12_not = "transfer.xor"(%sq12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_12 = "transfer.and"(%acc0_11, %sq12_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_12 = "transfer.and"(%acc1_11, %sq12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq13 = "transfer.mul"(%v13, %v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq13_not = "transfer.xor"(%sq13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_13 = "transfer.and"(%acc0_12, %sq13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_13 = "transfer.and"(%acc1_12, %sq13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq14 = "transfer.mul"(%v14, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq14_not = "transfer.xor"(%sq14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_14 = "transfer.and"(%acc0_13, %sq14_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_14 = "transfer.and"(%acc1_13, %sq14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq15 = "transfer.mul"(%v15, %v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq15_not = "transfer.xor"(%sq15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_15 = "transfer.and"(%acc0_14, %sq15_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_15 = "transfer.and"(%acc1_14, %sq15) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%unknown_le4, %acc0_15, %res0_const) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%unknown_le4, %acc1_15, %res1_const) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_square", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1

    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs0_not_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_nonzero = "transfer.cmp"(%rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_has_nonzero = "arith.ori"(%rhs0_not_all_ones, %rhs1_nonzero) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_has_nonzero) : (i1, i1) -> i1

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %not_const1 = "transfer.xor"(%const1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_is_not1 = "transfer.cmp"(%rhs0, %not_const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_1 = "transfer.cmp"(%rhs1, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_one = "arith.andi"(%rhs0_is_not1, %rhs1_is_1) : (i1, i1) -> i1

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min_tz = "transfer.countr_one"(%rhs0) : (!transfer.integer) -> !transfer.integer
    %rhs_min_nonzero_pow2 = "transfer.shl"(%const1, %rhs_min_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min_nonzero = "transfer.select"(%rhs1_nonzero, %rhs1, %rhs_min_nonzero_pow2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max_is_zero = "transfer.cmp"(%rhs_max, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max_safe = "transfer.select"(%rhs_max_is_zero, %const1, %rhs_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %max_res = "transfer.udiv"(%lhs_max, %rhs_min_nonzero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_res = "transfer.udiv"(%lhs1, %rhs_max_safe) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %max_res_lz = "transfer.countl_zero"(%max_res) : (!transfer.integer) -> !transfer.integer
    %max_res_lz_inv = "transfer.sub"(%bitwidth, %max_res_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask_raw = "transfer.shl"(%all_ones, %max_res_lz_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.select"(%has_feasible_pair, %high_zero_mask_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %range_valid_0 = "transfer.cmp"(%min_res, %max_res) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_valid = "arith.andi"(%has_feasible_pair, %range_valid_0) : (i1, i1) -> i1
    %range_diff = "transfer.xor"(%min_res, %max_res) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_common_lz = "transfer.countl_zero"(%range_diff) : (!transfer.integer) -> !transfer.integer
    %range_common_inv = "transfer.sub"(%bitwidth, %range_common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_common_mask = "transfer.shl"(%all_ones, %range_common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_res_not = "transfer.xor"(%min_res, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res0_raw = "transfer.and"(%min_res_not, %range_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res1_raw = "transfer.and"(%min_res, %range_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res0 = "transfer.select"(%range_valid, %range_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res1 = "transfer.select"(%range_valid, %range_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_zero_feasible = "arith.andi"(%has_feasible_pair, %lhs_is_zero) : (i1, i1) -> i1
    %lhs_zero_res0 = "transfer.select"(%lhs_zero_feasible, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_zero_res1 = "transfer.select"(%lhs_zero_feasible, %const0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_one_feasible = "arith.andi"(%has_feasible_pair, %rhs_is_one) : (i1, i1) -> i1
    %rhs_one_res0 = "transfer.select"(%rhs_one_feasible, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_one_res1 = "transfer.select"(%rhs_one_feasible, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_lt_rhs_0 = "transfer.cmp"(%lhs_max, %rhs_min_nonzero) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lt_rhs = "arith.andi"(%has_feasible_pair, %lhs_lt_rhs_0) : (i1, i1) -> i1
    %lhs_lt_rhs_res0 = "transfer.select"(%lhs_lt_rhs, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lt_rhs_res1 = "transfer.select"(%lhs_lt_rhs, %const0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %both_const_feasible = "arith.andi"(%has_feasible_pair, %both_const) : (i1, i1) -> i1
    %rhs_const_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_safe = "transfer.select"(%rhs_const_is_zero, %const1, %rhs1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_q = "transfer.udiv"(%lhs1, %rhs_const_safe) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0_raw = "transfer.xor"(%const_q, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.select"(%both_const_feasible, %const_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.select"(%both_const_feasible, %const_q, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_0 = "transfer.or"(%high_zero_mask, %range_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_1 = "transfer.or"(%res0_0, %lhs_zero_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_2 = "transfer.or"(%res0_1, %rhs_one_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_3 = "transfer.or"(%res0_2, %lhs_lt_rhs_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%res0_3, %const_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res1_0 = "transfer.or"(%range_res1, %lhs_zero_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_1 = "transfer.or"(%res1_0, %rhs_one_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_2 = "transfer.or"(%res1_1, %lhs_lt_rhs_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%res1_2, %const_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_udiv", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v1 = "transfer.select"(%h2, %arg0, %h1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%h0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v2 = func.call @%h0(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = func.call @%h1(%v2) : (!transfer.integer) -> !transfer.integer
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