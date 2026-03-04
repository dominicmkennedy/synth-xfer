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

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %sign_mask = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %not_sign_mask = "transfer.get_signed_max_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_nonneg = "transfer.cmp"(%lhs0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1


    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1
    %res0_rhs_zero = "transfer.select"(%rhs_is_zero, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_rhs_zero = "transfer.select"(%rhs_is_zero, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_known_union = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_mask = "transfer.xor"(%lhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_nonzero = "transfer.cmp"(%lhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_unknown_minus_1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_and_minus_1 = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_pow2ish = "transfer.cmp"(%lhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_one_unknown = "arith.andi"(%lhs_unknown_nonzero, %lhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_unknown_neg = "transfer.neg"(%lhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %lhs_unknown_lowbit = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_rest = "transfer.xor"(%lhs_unknown_mask, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_nonzero = "transfer.cmp"(%lhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rest_minus_1 = "transfer.sub"(%lhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_and_minus_1 = "transfer.and"(%lhs_unknown_rest, %lhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_pow2ish = "transfer.cmp"(%lhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_two_unknown = "arith.andi"(%lhs_rest_nonzero, %lhs_rest_pow2ish) : (i1, i1) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1

    %shl_const = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_const = "transfer.sshl_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_is_neg = "transfer.cmp"(%lhs1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_const = "transfer.select"(%lhs_const_is_neg, %sign_mask, %not_sign_mask) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res_const = "transfer.select"(%ov_const, %sat_const, %shl_const) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const = "transfer.xor"(%res_const, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_unknown_neg = "transfer.neg"(%rhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_nonzero = "transfer.cmp"(%rhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_rest_minus_1 = "transfer.sub"(%rhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_and_minus_1 = "transfer.and"(%rhs_unknown_rest, %rhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_pow2ish = "transfer.cmp"(%rhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_rest_nonzero, %rhs_rest_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_one_two = "arith.andi"(%lhs_one_unknown, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_one = "arith.andi"(%lhs_two_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_unknown_rest_neg = "transfer.neg"(%rhs_unknown_rest) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_midbit = "transfer.and"(%rhs_unknown_rest, %rhs_unknown_rest_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_highbit = "transfer.xor"(%rhs_unknown_rest, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_nonzero = "transfer.cmp"(%rhs_unknown_highbit, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_high_minus_1 = "transfer.sub"(%rhs_unknown_highbit, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_and_minus_1 = "transfer.and"(%rhs_unknown_highbit, %rhs_high_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_pow2ish = "transfer.cmp"(%rhs_high_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_high_nonzero, %rhs_high_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_three_unknown = "arith.andi"(%lhs_is_const, %rhs_three_unknown) : (i1, i1) -> i1
    %rhs_val1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_val2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_val3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_01 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_02 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_12 = "transfer.add"(%rhs_unknown_midbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val2 = "transfer.add"(%rhs1, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val3 = "transfer.add"(%rhs1, %rhs_01) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val4 = "transfer.add"(%rhs1, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val5 = "transfer.add"(%rhs1, %rhs_02) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val6 = "transfer.add"(%rhs1, %rhs_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_high_neg = "transfer.neg"(%rhs_unknown_highbit) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_topbit = "transfer.and"(%rhs_unknown_highbit, %rhs_unknown_high_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_lastbit = "transfer.xor"(%rhs_unknown_highbit, %rhs_unknown_topbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_last_nonzero = "transfer.cmp"(%rhs_unknown_lastbit, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_last_minus_1 = "transfer.sub"(%rhs_unknown_lastbit, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_last_and_minus_1 = "transfer.and"(%rhs_unknown_lastbit, %rhs_last_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_last_pow2ish = "transfer.cmp"(%rhs_last_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_four_unknown = "arith.andi"(%rhs_last_nonzero, %rhs_last_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_four_unknown = "arith.andi"(%lhs_is_const, %rhs_four_unknown) : (i1, i1) -> i1
    %rhs4_02 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_topbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_03 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_12 = "transfer.add"(%rhs_unknown_midbit, %rhs_unknown_topbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_13 = "transfer.add"(%rhs_unknown_midbit, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_23 = "transfer.add"(%rhs_unknown_topbit, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_012 = "transfer.add"(%rhs_01, %rhs_unknown_topbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_013 = "transfer.add"(%rhs_01, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_023 = "transfer.add"(%rhs4_02, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_123 = "transfer.add"(%rhs4_12, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val2 = "transfer.add"(%rhs1, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val3 = "transfer.add"(%rhs1, %rhs_01) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val4 = "transfer.add"(%rhs1, %rhs_unknown_topbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val5 = "transfer.add"(%rhs1, %rhs4_02) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val6 = "transfer.add"(%rhs1, %rhs4_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val7 = "transfer.add"(%rhs1, %rhs4_012) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val8 = "transfer.add"(%rhs1, %rhs_unknown_lastbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val9 = "transfer.add"(%rhs1, %rhs4_03) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val10 = "transfer.add"(%rhs1, %rhs4_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val11 = "transfer.add"(%rhs1, %rhs4_013) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val12 = "transfer.add"(%rhs1, %rhs4_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val13 = "transfer.add"(%rhs1, %rhs4_023) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs4_val14 = "transfer.add"(%rhs1, %rhs4_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_1 = "transfer.shl"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_1 = "transfer.sshl_overflow"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_1 = "transfer.select"(%ov_four_1, %sat_const, %shl_four_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_1 = "transfer.xor"(%res_four_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_2 = "transfer.shl"(%lhs1, %rhs4_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_2 = "transfer.sshl_overflow"(%lhs1, %rhs4_val2) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_2 = "transfer.select"(%ov_four_2, %sat_const, %shl_four_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_2 = "transfer.xor"(%res_four_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_3 = "transfer.shl"(%lhs1, %rhs4_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_3 = "transfer.sshl_overflow"(%lhs1, %rhs4_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_3 = "transfer.select"(%ov_four_3, %sat_const, %shl_four_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_3 = "transfer.xor"(%res_four_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_4 = "transfer.shl"(%lhs1, %rhs4_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_4 = "transfer.sshl_overflow"(%lhs1, %rhs4_val4) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_4 = "transfer.select"(%ov_four_4, %sat_const, %shl_four_4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_4 = "transfer.xor"(%res_four_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_5 = "transfer.shl"(%lhs1, %rhs4_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_5 = "transfer.sshl_overflow"(%lhs1, %rhs4_val5) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_5 = "transfer.select"(%ov_four_5, %sat_const, %shl_four_5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_5 = "transfer.xor"(%res_four_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_6 = "transfer.shl"(%lhs1, %rhs4_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_6 = "transfer.sshl_overflow"(%lhs1, %rhs4_val6) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_6 = "transfer.select"(%ov_four_6, %sat_const, %shl_four_6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_6 = "transfer.xor"(%res_four_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_7 = "transfer.shl"(%lhs1, %rhs4_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_7 = "transfer.sshl_overflow"(%lhs1, %rhs4_val7) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_7 = "transfer.select"(%ov_four_7, %sat_const, %shl_four_7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_7 = "transfer.xor"(%res_four_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_8 = "transfer.shl"(%lhs1, %rhs4_val8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_8 = "transfer.sshl_overflow"(%lhs1, %rhs4_val8) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_8 = "transfer.select"(%ov_four_8, %sat_const, %shl_four_8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_8 = "transfer.xor"(%res_four_8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_9 = "transfer.shl"(%lhs1, %rhs4_val9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_9 = "transfer.sshl_overflow"(%lhs1, %rhs4_val9) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_9 = "transfer.select"(%ov_four_9, %sat_const, %shl_four_9) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_9 = "transfer.xor"(%res_four_9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_10 = "transfer.shl"(%lhs1, %rhs4_val10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_10 = "transfer.sshl_overflow"(%lhs1, %rhs4_val10) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_10 = "transfer.select"(%ov_four_10, %sat_const, %shl_four_10) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_10 = "transfer.xor"(%res_four_10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_11 = "transfer.shl"(%lhs1, %rhs4_val11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_11 = "transfer.sshl_overflow"(%lhs1, %rhs4_val11) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_11 = "transfer.select"(%ov_four_11, %sat_const, %shl_four_11) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_11 = "transfer.xor"(%res_four_11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_12 = "transfer.shl"(%lhs1, %rhs4_val12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_12 = "transfer.sshl_overflow"(%lhs1, %rhs4_val12) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_12 = "transfer.select"(%ov_four_12, %sat_const, %shl_four_12) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_12 = "transfer.xor"(%res_four_12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_13 = "transfer.shl"(%lhs1, %rhs4_val13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_13 = "transfer.sshl_overflow"(%lhs1, %rhs4_val13) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_13 = "transfer.select"(%ov_four_13, %sat_const, %shl_four_13) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_13 = "transfer.xor"(%res_four_13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_14 = "transfer.shl"(%lhs1, %rhs4_val14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_14 = "transfer.sshl_overflow"(%lhs1, %rhs4_val14) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_14 = "transfer.select"(%ov_four_14, %sat_const, %shl_four_14) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_14 = "transfer.xor"(%res_four_14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_four_15 = "transfer.shl"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_four_15 = "transfer.sshl_overflow"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_four_15 = "transfer.select"(%ov_four_15, %sat_const, %shl_four_15) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_15 = "transfer.xor"(%res_four_15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_01 = "transfer.and"(%res0_const, %res0_four_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_23 = "transfer.and"(%res0_four_2, %res0_four_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_45 = "transfer.and"(%res0_four_4, %res0_four_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_67 = "transfer.and"(%res0_four_6, %res0_four_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_89 = "transfer.and"(%res0_four_8, %res0_four_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_1011 = "transfer.and"(%res0_four_10, %res0_four_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_1213 = "transfer.and"(%res0_four_12, %res0_four_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_1415 = "transfer.and"(%res0_four_14, %res0_four_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_0123 = "transfer.and"(%res0_four_01, %res0_four_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_4567 = "transfer.and"(%res0_four_45, %res0_four_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_891011 = "transfer.and"(%res0_four_89, %res0_four_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_12131415 = "transfer.and"(%res0_four_1213, %res0_four_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_0to7 = "transfer.and"(%res0_four_0123, %res0_four_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_8to15 = "transfer.and"(%res0_four_891011, %res0_four_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_four_unknown = "transfer.and"(%res0_four_0to7, %res0_four_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_01 = "transfer.and"(%res_const, %res_four_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_23 = "transfer.and"(%res_four_2, %res_four_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_45 = "transfer.and"(%res_four_4, %res_four_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_67 = "transfer.and"(%res_four_6, %res_four_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_89 = "transfer.and"(%res_four_8, %res_four_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_1011 = "transfer.and"(%res_four_10, %res_four_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_1213 = "transfer.and"(%res_four_12, %res_four_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_1415 = "transfer.and"(%res_four_14, %res_four_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_0123 = "transfer.and"(%res1_four_01, %res1_four_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_4567 = "transfer.and"(%res1_four_45, %res1_four_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_891011 = "transfer.and"(%res1_four_89, %res1_four_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_12131415 = "transfer.and"(%res1_four_1213, %res1_four_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_0to7 = "transfer.and"(%res1_four_0123, %res1_four_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_8to15 = "transfer.and"(%res1_four_891011, %res1_four_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_four_unknown = "transfer.and"(%res1_four_0to7, %res1_four_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_one_1 = "transfer.shl"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_one_1 = "transfer.sshl_overflow"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %res_one_1 = "transfer.select"(%ov_one_1, %sat_const, %shl_one_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_one_1 = "transfer.xor"(%res_one_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_one_unknown = "transfer.and"(%res0_const, %res0_one_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_one_unknown = "transfer.and"(%res_const, %res_one_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt_is_neg = "transfer.cmp"(%lhs_alt, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_lhs_alt = "transfer.select"(%lhs_alt_is_neg, %sign_mask, %not_sign_mask) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs_alt = "transfer.shl"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs_alt = "transfer.sshl_overflow"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs_alt = "transfer.select"(%ov_lhs_alt, %sat_lhs_alt, %shl_lhs_alt) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt = "transfer.xor"(%res_lhs_alt, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_one_unknown = "transfer.and"(%res0_const, %res0_lhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_one_unknown = "transfer.and"(%res_const, %res_lhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs_alt_rhs_alt = "transfer.shl"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs_alt_rhs_alt = "transfer.sshl_overflow"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs_alt_rhs_alt = "transfer.select"(%ov_lhs_alt_rhs_alt, %sat_lhs_alt, %shl_lhs_alt_rhs_alt) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_alt = "transfer.xor"(%res_lhs_alt_rhs_alt, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_rhs_10_11 = "transfer.and"(%res0_lhs_alt, %res0_lhs_alt_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_rhs_one_one = "transfer.and"(%res0_one_unknown, %res0_lhs_rhs_10_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_rhs_10_11 = "transfer.and"(%res_lhs_alt, %res_lhs_alt_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_rhs_one_one = "transfer.and"(%res1_one_unknown, %res1_lhs_rhs_10_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs2_val1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs2_val2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs2_val3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs2_val1_is_neg = "transfer.cmp"(%lhs2_val1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_lhs2_1 = "transfer.select"(%lhs2_val1_is_neg, %sign_mask, %not_sign_mask) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs2_1 = "transfer.shl"(%lhs2_val1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_1 = "transfer.sshl_overflow"(%lhs2_val1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_1 = "transfer.select"(%ov_lhs2_1, %sat_lhs2_1, %shl_lhs2_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_1 = "transfer.xor"(%res_lhs2_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs2_val2_is_neg = "transfer.cmp"(%lhs2_val2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_lhs2_2 = "transfer.select"(%lhs2_val2_is_neg, %sign_mask, %not_sign_mask) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs2_2 = "transfer.shl"(%lhs2_val2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_2 = "transfer.sshl_overflow"(%lhs2_val2, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_2 = "transfer.select"(%ov_lhs2_2, %sat_lhs2_2, %shl_lhs2_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_2 = "transfer.xor"(%res_lhs2_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs2_val3_is_neg = "transfer.cmp"(%lhs2_val3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_lhs2_3 = "transfer.select"(%lhs2_val3_is_neg, %sign_mask, %not_sign_mask) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs2_3 = "transfer.shl"(%lhs2_val3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_3 = "transfer.sshl_overflow"(%lhs2_val3, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_3 = "transfer.select"(%ov_lhs2_3, %sat_lhs2_3, %shl_lhs2_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_3 = "transfer.xor"(%res_lhs2_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_01 = "transfer.and"(%res0_const, %res0_lhs2_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_23 = "transfer.and"(%res0_lhs2_2, %res0_lhs2_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_two_unknown = "transfer.and"(%res0_lhs2_01, %res0_lhs2_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs2_01 = "transfer.and"(%res_const, %res_lhs2_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs2_23 = "transfer.and"(%res_lhs2_2, %res_lhs2_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_two_unknown = "transfer.and"(%res1_lhs2_01, %res1_lhs2_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_two_1 = "transfer.shl"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_two_1 = "transfer.sshl_overflow"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> i1
    %res_two_1 = "transfer.select"(%ov_two_1, %sat_const, %shl_two_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_two_1 = "transfer.xor"(%res_two_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_two_2 = "transfer.shl"(%lhs1, %rhs_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_two_2 = "transfer.sshl_overflow"(%lhs1, %rhs_val2) : (!transfer.integer, !transfer.integer) -> i1
    %res_two_2 = "transfer.select"(%ov_two_2, %sat_const, %shl_two_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_two_2 = "transfer.xor"(%res_two_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_two_3 = "transfer.shl"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_two_3 = "transfer.sshl_overflow"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_two_3 = "transfer.select"(%ov_two_3, %sat_const, %shl_two_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_two_3 = "transfer.xor"(%res_two_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_two_01 = "transfer.and"(%res0_const, %res0_two_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_two_23 = "transfer.and"(%res0_two_2, %res0_two_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_two_unknown = "transfer.and"(%res0_two_01, %res0_two_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_two_01 = "transfer.and"(%res_const, %res_two_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_two_23 = "transfer.and"(%res_two_2, %res_two_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_two_unknown = "transfer.and"(%res1_two_01, %res1_two_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_lhs_alt_rhs_val1 = "transfer.shl"(%lhs_alt, %rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs_alt_rhs_val1 = "transfer.sshl_overflow"(%lhs_alt, %rhs_val1) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs_alt_rhs_val1 = "transfer.select"(%ov_lhs_alt_rhs_val1, %sat_lhs_alt, %shl_lhs_alt_rhs_val1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_val1 = "transfer.xor"(%res_lhs_alt_rhs_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs_alt_rhs_val2 = "transfer.shl"(%lhs_alt, %rhs_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs_alt_rhs_val2 = "transfer.sshl_overflow"(%lhs_alt, %rhs_val2) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs_alt_rhs_val2 = "transfer.select"(%ov_lhs_alt_rhs_val2, %sat_lhs_alt, %shl_lhs_alt_rhs_val2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_val2 = "transfer.xor"(%res_lhs_alt_rhs_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs_alt_rhs_val3 = "transfer.shl"(%lhs_alt, %rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs_alt_rhs_val3 = "transfer.sshl_overflow"(%lhs_alt, %rhs_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs_alt_rhs_val3 = "transfer.select"(%ov_lhs_alt_rhs_val3, %sat_lhs_alt, %shl_lhs_alt_rhs_val3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_val3 = "transfer.xor"(%res_lhs_alt_rhs_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_01 = "transfer.and"(%res0_lhs_alt, %res0_lhs_alt_rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_23 = "transfer.and"(%res0_lhs_alt_rhs_val2, %res0_lhs_alt_rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_alt_rhs_two_unknown = "transfer.and"(%res0_lhs_alt_rhs_01, %res0_lhs_alt_rhs_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_alt_rhs_01 = "transfer.and"(%res_lhs_alt, %res_lhs_alt_rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_alt_rhs_23 = "transfer.and"(%res_lhs_alt_rhs_val2, %res_lhs_alt_rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_alt_rhs_two_unknown = "transfer.and"(%res1_lhs_alt_rhs_01, %res1_lhs_alt_rhs_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_rhs_one_two = "transfer.and"(%res0_two_unknown, %res0_lhs_alt_rhs_two_unknown) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_rhs_one_two = "transfer.and"(%res1_two_unknown, %res1_lhs_alt_rhs_two_unknown) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %shl_lhs2_1_rhs_alt = "transfer.shl"(%lhs2_val1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_1_rhs_alt = "transfer.sshl_overflow"(%lhs2_val1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_1_rhs_alt = "transfer.select"(%ov_lhs2_1_rhs_alt, %sat_lhs2_1, %shl_lhs2_1_rhs_alt) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_1_rhs_alt = "transfer.xor"(%res_lhs2_1_rhs_alt, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs2_2_rhs_alt = "transfer.shl"(%lhs2_val2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_2_rhs_alt = "transfer.sshl_overflow"(%lhs2_val2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_2_rhs_alt = "transfer.select"(%ov_lhs2_2_rhs_alt, %sat_lhs2_2, %shl_lhs2_2_rhs_alt) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_2_rhs_alt = "transfer.xor"(%res_lhs2_2_rhs_alt, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_lhs2_3_rhs_alt = "transfer.shl"(%lhs2_val3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_lhs2_3_rhs_alt = "transfer.sshl_overflow"(%lhs2_val3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %res_lhs2_3_rhs_alt = "transfer.select"(%ov_lhs2_3_rhs_alt, %sat_lhs2_3, %shl_lhs2_3_rhs_alt) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_3_rhs_alt = "transfer.xor"(%res_lhs2_3_rhs_alt, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_rhs_alt_01 = "transfer.and"(%res0_one_1, %res0_lhs2_1_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_rhs_alt_23 = "transfer.and"(%res0_lhs2_2_rhs_alt, %res0_lhs2_3_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs2_rhs_alt_all = "transfer.and"(%res0_lhs2_rhs_alt_01, %res0_lhs2_rhs_alt_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs2_rhs_alt_01 = "transfer.and"(%res_one_1, %res_lhs2_1_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs2_rhs_alt_23 = "transfer.and"(%res_lhs2_2_rhs_alt, %res_lhs2_3_rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs2_rhs_alt_all = "transfer.and"(%res1_lhs2_rhs_alt_01, %res1_lhs2_rhs_alt_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs_rhs_two_one = "transfer.and"(%res0_lhs_two_unknown, %res0_lhs2_rhs_alt_all) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_rhs_two_one = "transfer.and"(%res1_lhs_two_unknown, %res1_lhs2_rhs_alt_all) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_1 = "transfer.shl"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_1 = "transfer.sshl_overflow"(%lhs1, %rhs_val1) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_1 = "transfer.select"(%ov_three_1, %sat_const, %shl_three_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_1 = "transfer.xor"(%res_three_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_2 = "transfer.shl"(%lhs1, %rhs3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_2 = "transfer.sshl_overflow"(%lhs1, %rhs3_val2) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_2 = "transfer.select"(%ov_three_2, %sat_const, %shl_three_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_2 = "transfer.xor"(%res_three_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_3 = "transfer.shl"(%lhs1, %rhs3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_3 = "transfer.sshl_overflow"(%lhs1, %rhs3_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_3 = "transfer.select"(%ov_three_3, %sat_const, %shl_three_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_3 = "transfer.xor"(%res_three_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_4 = "transfer.shl"(%lhs1, %rhs3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_4 = "transfer.sshl_overflow"(%lhs1, %rhs3_val4) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_4 = "transfer.select"(%ov_three_4, %sat_const, %shl_three_4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_4 = "transfer.xor"(%res_three_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_5 = "transfer.shl"(%lhs1, %rhs3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_5 = "transfer.sshl_overflow"(%lhs1, %rhs3_val5) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_5 = "transfer.select"(%ov_three_5, %sat_const, %shl_three_5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_5 = "transfer.xor"(%res_three_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_6 = "transfer.shl"(%lhs1, %rhs3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_6 = "transfer.sshl_overflow"(%lhs1, %rhs3_val6) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_6 = "transfer.select"(%ov_three_6, %sat_const, %shl_three_6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_6 = "transfer.xor"(%res_three_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl_three_7 = "transfer.shl"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov_three_7 = "transfer.sshl_overflow"(%lhs1, %rhs_val3) : (!transfer.integer, !transfer.integer) -> i1
    %res_three_7 = "transfer.select"(%ov_three_7, %sat_const, %shl_three_7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_7 = "transfer.xor"(%res_three_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_01 = "transfer.and"(%res0_const, %res0_three_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_23 = "transfer.and"(%res0_three_2, %res0_three_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_45 = "transfer.and"(%res0_three_4, %res0_three_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_67 = "transfer.and"(%res0_three_6, %res0_three_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_0123 = "transfer.and"(%res0_three_01, %res0_three_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_4567 = "transfer.and"(%res0_three_45, %res0_three_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_three_unknown = "transfer.and"(%res0_three_0123, %res0_three_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_01 = "transfer.and"(%res_const, %res_three_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_23 = "transfer.and"(%res_three_2, %res_three_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_45 = "transfer.and"(%res_three_4, %res_three_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_67 = "transfer.and"(%res_three_6, %res_three_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_0123 = "transfer.and"(%res1_three_01, %res1_three_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_4567 = "transfer.and"(%res1_three_45, %res1_three_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_three_unknown = "transfer.and"(%res1_three_0123, %res1_three_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_nonzero = "transfer.cmp"(%rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_lhs_rhs_nonzero = "arith.andi"(%lhs_neg, %rhs1_nonzero) : (i1, i1) -> i1
    %lhs_mlz = "transfer.countl_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_mlo = "transfer.countl_one"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %lhs_lz_ub = "transfer.countl_zero"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %lhs_lo_ub = "transfer.countl_zero"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_min_tz = "transfer.countr_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_mlz_nonzero = "transfer.cmp"(%lhs_mlz, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mlo_nonzero = "transfer.cmp"(%lhs_mlo, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mlz_minus_1 = "transfer.sub"(%lhs_mlz, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_mlo_minus_1 = "transfer.sub"(%lhs_mlo, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_le_mlz_minus_1 = "transfer.cmp"(%rhs1, %lhs_mlz_minus_1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_le_mlo_minus_1 = "transfer.cmp"(%rhs1, %lhs_mlo_minus_1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lt_mlz = "arith.andi"(%lhs_mlz_nonzero, %rhs_le_mlz_minus_1) : (i1, i1) -> i1
    %rhs_lt_mlo = "arith.andi"(%lhs_mlo_nonzero, %rhs_le_mlo_minus_1) : (i1, i1) -> i1
    %no_ov_nonneg_pre = "arith.andi"(%lhs_nonneg, %rhs_lt_mlz) : (i1, i1) -> i1
    %no_ov_neg_pre = "arith.andi"(%lhs_neg, %rhs_lt_mlo) : (i1, i1) -> i1
    %no_ov_sign_known = "arith.ori"(%no_ov_nonneg_pre, %no_ov_neg_pre) : (i1, i1) -> i1
    %no_ov_all_signs = "arith.andi"(%rhs_lt_mlz, %rhs_lt_mlo) : (i1, i1) -> i1
    %no_ov_any_sign = "arith.ori"(%no_ov_sign_known, %no_ov_all_signs) : (i1, i1) -> i1
    %no_ov_known = "arith.andi"(%rhs_is_const, %no_ov_any_sign) : (i1, i1) -> i1
    %rhs_ge_lz_ub = "transfer.cmp"(%rhs1, %lhs_lz_ub) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_ge_lo_ub = "transfer.cmp"(%rhs1, %lhs_lo_ub) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %must_ov_nonneg = "arith.andi"(%lhs_nonneg, %rhs_ge_lz_ub) : (i1, i1) -> i1
    %must_ov_neg = "arith.andi"(%lhs_neg, %rhs_ge_lo_ub) : (i1, i1) -> i1
    %rhs_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_clamped = "transfer.select"(%rhs_le_bw, %rhs1, %bitwidth) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_inv = "transfer.sub"(%bitwidth, %rhs_clamped) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_cand = "transfer.lshr"(%all_ones, %rhs_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_no_sign = "transfer.and"(%low_zero_cand, %not_sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_mask = "transfer.select"(%neg_lhs_rhs_nonzero, %low_zero_no_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_plus_lhs_tz = "transfer.add"(%rhs1, %lhs_min_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_plus_lhs_tz_le_bw = "transfer.cmp"(%rhs_plus_lhs_tz, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_plus_lhs_tz_clamped = "transfer.select"(%rhs_plus_lhs_tz_le_bw, %rhs_plus_lhs_tz, %bitwidth) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_ext_inv = "transfer.sub"(%bitwidth, %rhs_plus_lhs_tz_clamped) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_ext_cand = "transfer.lshr"(%all_ones, %low_zero_ext_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_ext_no_sign = "transfer.and"(%low_zero_ext_cand, %not_sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_ext_mask = "transfer.select"(%neg_lhs_rhs_nonzero, %low_zero_ext_no_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_mask_refined = "transfer.or"(%low_zero_mask, %low_zero_ext_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_min_ge_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %sat_hi_nonneg = "arith.andi"(%rhs_min_ge_bw, %lhs_nonneg) : (i1, i1) -> i1
    %sat_hi_neg = "arith.andi"(%rhs_min_ge_bw, %lhs_neg) : (i1, i1) -> i1
    %sat_hi_res0_nonneg = "transfer.select"(%sat_hi_nonneg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_hi_res1_nonneg = "transfer.select"(%sat_hi_nonneg, %not_sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_hi_res0_neg = "transfer.select"(%sat_hi_neg, %not_sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_hi_res1_neg = "transfer.select"(%sat_hi_neg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %must_ov_res0_nonneg = "transfer.select"(%must_ov_nonneg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %must_ov_res1_nonneg = "transfer.select"(%must_ov_nonneg, %not_sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %must_ov_res0_neg = "transfer.select"(%must_ov_neg, %not_sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %must_ov_res1_neg = "transfer.select"(%must_ov_neg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_with_low = "transfer.or"(%res0_rhs_zero, %low_zero_mask_refined) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_sat_nonneg = "transfer.or"(%res1_rhs_zero, %sat_hi_res1_nonneg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_sat = "transfer.or"(%res1_with_sat_nonneg, %sat_hi_res1_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_sat_nonneg = "transfer.or"(%res0_with_low, %sat_hi_res0_nonneg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_sat = "transfer.or"(%res0_with_sat_nonneg, %sat_hi_res0_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_must_ov_nonneg = "transfer.or"(%res0_with_sat, %must_ov_res0_nonneg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_must_ov_nonneg = "transfer.or"(%res1_with_sat, %must_ov_res1_nonneg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_must_ov = "transfer.or"(%res0_with_must_ov_nonneg, %must_ov_res0_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_must_ov = "transfer.or"(%res1_with_must_ov_nonneg, %must_ov_res1_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nz_sign_zero_mask = "transfer.select"(%lhs_nonneg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nz_sign_one_mask = "transfer.select"(%lhs_neg, %sign_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %shl0_common = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl0_non_sign = "transfer.and"(%shl0_common, %not_sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl1_non_sign = "transfer.and"(%shl_const, %not_sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg_const = "arith.andi"(%lhs_nonneg, %rhs_is_const) : (i1, i1) -> i1
    %lhs_neg_const = "arith.andi"(%lhs_neg, %rhs_is_const) : (i1, i1) -> i1
    %common_one_nonneg = "transfer.select"(%lhs_nonneg_const, %shl1_non_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %common_zero_neg = "transfer.select"(%lhs_neg_const, %shl0_non_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_sign_base = "transfer.or"(%res0_with_must_ov, %nz_sign_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_sign_base = "transfer.or"(%res1_with_must_ov, %nz_sign_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_sign = "transfer.or"(%res0_with_sign_base, %common_zero_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_sign = "transfer.or"(%res1_with_sign_base, %common_one_nonneg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_no_ov_cand = "transfer.or"(%shl0_common, %low_zero_cand) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_no_ov_cand_refined = "transfer.or"(%res0_no_ov_cand, %res0_with_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_no_ov_cand_refined = "transfer.or"(%shl_const, %res1_with_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_no_ov = "transfer.select"(%no_ov_known, %res0_no_ov_cand_refined, %res0_with_sign) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_no_ov = "transfer.select"(%no_ov_known, %res1_no_ov_cand_refined, %res1_with_sign) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_with_rhs_four_unknown = "transfer.select"(%lhs_const_rhs_four_unknown, %res0_four_unknown, %res0_no_ov) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_rhs_four_unknown = "transfer.select"(%lhs_const_rhs_four_unknown, %res1_four_unknown, %res1_no_ov) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_rhs_three_unknown = "transfer.select"(%lhs_const_rhs_three_unknown, %res0_three_unknown, %res0_with_rhs_four_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_rhs_three_unknown = "transfer.select"(%lhs_const_rhs_three_unknown, %res1_three_unknown, %res1_with_rhs_four_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_rhs_two_unknown = "transfer.select"(%lhs_const_rhs_two_unknown, %res0_two_unknown, %res0_with_rhs_three_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_rhs_two_unknown = "transfer.select"(%lhs_const_rhs_two_unknown, %res1_two_unknown, %res1_with_rhs_three_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_rhs_one_unknown = "transfer.select"(%lhs_const_rhs_one_unknown, %res0_one_unknown, %res0_with_rhs_two_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_rhs_one_unknown = "transfer.select"(%lhs_const_rhs_one_unknown, %res1_one_unknown, %res1_with_rhs_two_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_lhs_two_unknown = "transfer.select"(%rhs_const_lhs_two_unknown, %res0_lhs_two_unknown, %res0_with_rhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_lhs_two_unknown = "transfer.select"(%rhs_const_lhs_two_unknown, %res1_lhs_two_unknown, %res1_with_rhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_lhs_one_unknown = "transfer.select"(%rhs_const_lhs_one_unknown, %res0_lhs_one_unknown, %res0_with_lhs_two_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_lhs_one_unknown = "transfer.select"(%rhs_const_lhs_one_unknown, %res1_lhs_one_unknown, %res1_with_lhs_two_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_lhs_rhs_one_two = "transfer.select"(%lhs_rhs_one_two, %res0_lhs_rhs_one_two, %res0_with_lhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_lhs_rhs_one_two = "transfer.select"(%lhs_rhs_one_two, %res1_lhs_rhs_one_two, %res1_with_lhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_lhs_rhs_two_one = "transfer.select"(%lhs_rhs_two_one, %res0_lhs_rhs_two_one, %res0_with_lhs_rhs_one_two) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_lhs_rhs_two_one = "transfer.select"(%lhs_rhs_two_one, %res1_lhs_rhs_two_one, %res1_with_lhs_rhs_one_two) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_with_lhs_rhs_one_one = "transfer.select"(%lhs_rhs_one_one, %res0_lhs_rhs_one_one, %res0_with_lhs_rhs_two_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_lhs_rhs_one_one = "transfer.select"(%lhs_rhs_one_one, %res1_lhs_rhs_one_one, %res1_with_lhs_rhs_two_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %res0_const, %res0_with_lhs_rhs_one_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %res_const, %res1_with_lhs_rhs_one_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_sshlsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %max_ov = "transfer.uadd_overflow"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> i1
    %never_ov = "arith.xori"(%max_ov, %const_true) : (i1, i1) -> i1
    %ov_ones = "transfer.select"(%min_ov, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // KnownBits transfer for plain add.
    %sum_min = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max = "transfer.add"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_and = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or = "transfer.or"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_min_not = "transfer.xor"(%sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or_and_sum_not = "transfer.and"(%min_or, %sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_min = "transfer.or"(%min_and, %min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_and = "transfer.and"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or = "transfer.or"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max_not = "transfer.xor"(%sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or_and_sum_not = "transfer.and"(%max_or, %sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_max = "transfer.or"(%max_and, %max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_one = "transfer.shl"(%carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_may_one = "transfer.shl"(%carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_zero = "transfer.xor"(%carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_lhs_rhs_00 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_lhs_rhs_11 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_01 = "transfer.and"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_10 = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_0 = "transfer.or"(%xor0_lhs_rhs_00, %xor0_lhs_rhs_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_1 = "transfer.or"(%xor1_lhs_rhs_01, %xor1_lhs_rhs_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_sum_carry_00 = "transfer.and"(%xor_lhs_rhs_0, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_sum_carry_11 = "transfer.and"(%xor_lhs_rhs_1, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_01 = "transfer.and"(%xor_lhs_rhs_0, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_10 = "transfer.and"(%xor_lhs_rhs_1, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %add0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %add1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sat0 = "transfer.select"(%never_ov, %add0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat1_add = "transfer.or"(%add1, %ov_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %id_res0_l = "transfer.select"(%lhs_is_zero, %rhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res1_l = "transfer.select"(%lhs_is_zero, %rhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res0 = "transfer.select"(%rhs_is_zero, %lhs0, %id_res0_l) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res1 = "transfer.select"(%rhs_is_zero, %lhs1, %id_res1_l) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_base = "transfer.or"(%sat0, %id_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_base = "transfer.or"(%sat1_add, %id_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_add = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %const_res1 = "transfer.select"(%const_ov, %all_ones, %const_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_ub = "transfer.select"(%max_ov, %all_ones, %sum_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_diff = "transfer.xor"(%const_res1, %range_ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%range_diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range0 = "transfer.and"(%const_res0, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1 = "transfer.and"(%const_res1, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    // Enumerate one/two unknown bits when one side is constant.
    %lhs_known_union = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_mask = "transfer.xor"(%lhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_nonzero = "transfer.cmp"(%lhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_unknown_minus_1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_and_minus_1 = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_pow2ish = "transfer.cmp"(%lhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_one_unknown = "arith.andi"(%lhs_unknown_nonzero, %lhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_unknown_neg = "transfer.neg"(%lhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %lhs_unknown_lowbit = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_rest = "transfer.xor"(%lhs_unknown_mask, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_nonzero = "transfer.cmp"(%lhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rest_minus_1 = "transfer.sub"(%lhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_and_minus_1 = "transfer.and"(%lhs_unknown_rest, %lhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_pow2ish = "transfer.cmp"(%lhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_two_unknown = "arith.andi"(%lhs_rest_nonzero, %lhs_rest_pow2ish) : (i1, i1) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_neg = "transfer.neg"(%rhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_nonzero = "transfer.cmp"(%rhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_rest_minus_1 = "transfer.sub"(%rhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_and_minus_1 = "transfer.and"(%rhs_unknown_rest, %rhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_pow2ish = "transfer.cmp"(%rhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_rest_nonzero, %rhs_rest_pow2ish) : (i1, i1) -> i1
    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_one_two = "arith.andi"(%lhs_one_unknown, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_one = "arith.andi"(%lhs_two_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_two = "arith.andi"(%lhs_two_unknown, %rhs_two_unknown) : (i1, i1) -> i1

    // lhs const, rhs one unknown.
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_add = "transfer.add"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %g_val1 = "transfer.select"(%g_val1_ov, %all_ones, %g_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0_raw = "transfer.and"(%g_val0_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g1_raw = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0 = "transfer.select"(%lhs_const_rhs_one_unknown, %g0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g1 = "transfer.select"(%lhs_const_rhs_one_unknown, %g1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs two unknown.
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %rhs_alt1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_add = "transfer.add"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %h_val1 = "transfer.select"(%h_val1_ov, %all_ones, %h_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_add = "transfer.add"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %h_val2 = "transfer.select"(%h_val2_ov, %all_ones, %h_val2_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_add = "transfer.add"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %h_val3 = "transfer.select"(%h_val3_ov, %all_ones, %h_val3_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_01 = "transfer.and"(%h_val0_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_raw = "transfer.and"(%h0_01, %h0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_raw = "transfer.and"(%h1_01, %h1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0 = "transfer.select"(%lhs_const_rhs_two_unknown, %h0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h1 = "transfer.select"(%lhs_const_rhs_two_unknown, %h1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs one unknown.
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_add = "transfer.add"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %i_val1 = "transfer.select"(%i_val1_ov, %all_ones, %i_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0_raw = "transfer.and"(%i_val0_not, %i_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i1_raw = "transfer.and"(%const_res1, %i_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0 = "transfer.select"(%rhs_const_lhs_one_unknown, %i0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i1 = "transfer.select"(%rhs_const_lhs_one_unknown, %i1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs two unknown.
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1
    %lhs_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_add = "transfer.add"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_ov = "transfer.uadd_overflow"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val1 = "transfer.select"(%j_val1_ov, %all_ones, %j_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_add = "transfer.add"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val2 = "transfer.select"(%j_val2_ov, %all_ones, %j_val2_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_add = "transfer.add"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val3 = "transfer.select"(%j_val3_ov, %all_ones, %j_val3_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_01 = "transfer.and"(%j_val0_not, %j_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_23 = "transfer.and"(%j_val2_not, %j_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_raw = "transfer.and"(%j0_01, %j0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_01 = "transfer.and"(%const_res1, %j_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_23 = "transfer.and"(%j_val2, %j_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_raw = "transfer.and"(%j1_01, %j1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0 = "transfer.select"(%rhs_const_lhs_two_unknown, %j0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j1 = "transfer.select"(%rhs_const_lhs_two_unknown, %j1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs one unknown, rhs one unknown.
    %n_val11_add = "transfer.add"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val11_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %n_val11 = "transfer.select"(%n_val11_ov, %all_ones, %n_val11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val01_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val10_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val11_not = "transfer.xor"(%n_val11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_01 = "transfer.and"(%n_val00_not, %n_val01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_23 = "transfer.and"(%n_val10_not, %n_val11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_raw = "transfer.and"(%n0_01, %n0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_01 = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_23 = "transfer.and"(%i_val1, %n_val11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_raw = "transfer.and"(%n1_01, %n1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0 = "transfer.select"(%lhs_rhs_one_one, %n0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n1 = "transfer.select"(%lhs_rhs_one_one, %n1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs one unknown, rhs two unknown.
    %p11_add = "transfer.add"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %p11 = "transfer.select"(%p11_ov, %all_ones, %p11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_add = "transfer.add"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %p12 = "transfer.select"(%p12_ov, %all_ones, %p12_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_add = "transfer.add"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %p13 = "transfer.select"(%p13_ov, %all_ones, %p13_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p01_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p02_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p03_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p10_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_not = "transfer.xor"(%p11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_not = "transfer.xor"(%p12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_not = "transfer.xor"(%p13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_01 = "transfer.and"(%p00_not, %p01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_23 = "transfer.and"(%p02_not, %p03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_45 = "transfer.and"(%p10_not, %p11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_67 = "transfer.and"(%p12_not, %p13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_0123 = "transfer.and"(%p0_01, %p0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_4567 = "transfer.and"(%p0_45, %p0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_raw = "transfer.and"(%p0_0123, %p0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_45 = "transfer.and"(%i_val1, %p11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_67 = "transfer.and"(%p12, %p13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_0123 = "transfer.and"(%p1_01, %p1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_4567 = "transfer.and"(%p1_45, %p1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_raw = "transfer.and"(%p1_0123, %p1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0 = "transfer.select"(%lhs_rhs_one_two, %p0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p1 = "transfer.select"(%lhs_rhs_one_two, %p1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs two unknown, rhs one unknown.
    %q11_add = "transfer.add"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q11_ov = "transfer.uadd_overflow"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q11 = "transfer.select"(%q11_ov, %all_ones, %q11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_add = "transfer.add"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q12 = "transfer.select"(%q12_ov, %all_ones, %q12_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_add = "transfer.add"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q13 = "transfer.select"(%q13_ov, %all_ones, %q13_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q01_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q02_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q03_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q04_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q05_not = "transfer.xor"(%q11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q06_not = "transfer.xor"(%q12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q07_not = "transfer.xor"(%q13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_01 = "transfer.and"(%q00_not, %q01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_23 = "transfer.and"(%q02_not, %q03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_45 = "transfer.and"(%q04_not, %q05_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_67 = "transfer.and"(%q06_not, %q07_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_0123 = "transfer.and"(%q0_01, %q0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_4567 = "transfer.and"(%q0_45, %q0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_raw = "transfer.and"(%q0_0123, %q0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_01 = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_23 = "transfer.and"(%j_val1, %j_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_45 = "transfer.and"(%j_val3, %q11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_67 = "transfer.and"(%q12, %q13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_0123 = "transfer.and"(%q1_01, %q1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_4567 = "transfer.and"(%q1_45, %q1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_raw = "transfer.and"(%q1_0123, %q1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0 = "transfer.select"(%lhs_rhs_two_one, %q0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q1 = "transfer.select"(%lhs_rhs_two_one, %q1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs two unknown, rhs two unknown.
    %r21_add = "transfer.add"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r21 = "transfer.select"(%r21_ov, %all_ones, %r21_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_add = "transfer.add"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r22 = "transfer.select"(%r22_ov, %all_ones, %r22_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_add = "transfer.add"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r23 = "transfer.select"(%r23_ov, %all_ones, %r23_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_add = "transfer.add"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r31 = "transfer.select"(%r31_ov, %all_ones, %r31_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_add = "transfer.add"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r32 = "transfer.select"(%r32_ov, %all_ones, %r32_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_add = "transfer.add"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r33 = "transfer.select"(%r33_ov, %all_ones, %r33_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r01_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r02_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r03_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r10_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r11_not = "transfer.xor"(%p11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r12_not = "transfer.xor"(%p12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r13_not = "transfer.xor"(%p13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r20_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_not = "transfer.xor"(%r21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_not = "transfer.xor"(%r22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_not = "transfer.xor"(%r23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r30_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_not = "transfer.xor"(%r31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_not = "transfer.xor"(%r32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_not = "transfer.xor"(%r33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_01 = "transfer.and"(%r00_not, %r01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_23 = "transfer.and"(%r02_not, %r03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_45 = "transfer.and"(%r10_not, %r11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_67 = "transfer.and"(%r12_not, %r13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_89 = "transfer.and"(%r20_not, %r21_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1011 = "transfer.and"(%r22_not, %r23_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1213 = "transfer.and"(%r30_not, %r31_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1415 = "transfer.and"(%r32_not, %r33_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0123 = "transfer.and"(%r0_01, %r0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_4567 = "transfer.and"(%r0_45, %r0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_891011 = "transfer.and"(%r0_89, %r0_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_12131415 = "transfer.and"(%r0_1213, %r0_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0to7 = "transfer.and"(%r0_0123, %r0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_8to15 = "transfer.and"(%r0_891011, %r0_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_raw = "transfer.and"(%r0_0to7, %r0_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_45 = "transfer.and"(%j_val1, %p11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_67 = "transfer.and"(%p12, %p13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_89 = "transfer.and"(%j_val2, %r21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1011 = "transfer.and"(%r22, %r23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1213 = "transfer.and"(%j_val3, %r31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1415 = "transfer.and"(%r32, %r33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0123 = "transfer.and"(%r1_01, %r1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_4567 = "transfer.and"(%r1_45, %r1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_891011 = "transfer.and"(%r1_89, %r1_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_12131415 = "transfer.and"(%r1_1213, %r1_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0to7 = "transfer.and"(%r1_0123, %r1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_8to15 = "transfer.and"(%r1_891011, %r1_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_raw = "transfer.and"(%r1_0to7, %r1_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0 = "transfer.select"(%lhs_rhs_two_two, %r0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r1 = "transfer.select"(%lhs_rhs_two_two, %r1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_g = "transfer.or"(%res0_base, %g0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_h = "transfer.or"(%res0_g, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_i = "transfer.or"(%res0_h, %i0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_j = "transfer.or"(%res0_i, %j0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_n = "transfer.or"(%res0_j, %n0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_p = "transfer.or"(%res0_n, %p0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_q = "transfer.or"(%res0_p, %q0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_r = "transfer.or"(%res0_q, %r0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_g = "transfer.or"(%res1_base, %g1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_h = "transfer.or"(%res1_g, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_i = "transfer.or"(%res1_h, %i1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_j = "transfer.or"(%res1_i, %j1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_n = "transfer.or"(%res1_j, %n1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_p = "transfer.or"(%res1_n, %p1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_q = "transfer.or"(%res1_p, %q1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_r = "transfer.or"(%res1_q, %r1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_range = "transfer.or"(%res0_r, %range0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_range = "transfer.or"(%res1_r, %range1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %const_res0, %res0_range) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_res1, %res1_range) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_uaddsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Endpoint interval candidate: lb = f(lhs_min, rhs_min), ub = f(lhs_max, rhs_max).
    %lb_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lb = "transfer.select"(%lb_ov, %all_ones, %lb_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ub_shl = "transfer.shl"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub_ov = "transfer.ushl_overflow"(%lhs_max, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub = "transfer.select"(%ub_ov, %all_ones, %ub_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    // Constant-rhs candidate: keep exact shifted one-bits; keep zero-bits only if never-overflow.
    %c_shl1 = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_shl0 = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_ov_max = "transfer.ushl_overflow"(%lhs_max, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_never_ov = "arith.xori"(%c_ov_max, %const_true) : (i1, i1) -> i1
    %c0_raw = "transfer.select"(%c_never_ov, %c_shl0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b0 = "transfer.select"(%rhs_is_const, %c0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b1 = "transfer.select"(%rhs_is_const, %c_shl1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs == 0 => exact passthrough.
    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1
    %c0 = "transfer.select"(%rhs_is_zero, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c1 = "transfer.select"(%rhs_is_zero, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs_min >= bw => always overflow => exact all ones.
    %rhs_ge_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d1 = "transfer.select"(%rhs_ge_bw, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    // Also overflow-always when rhs has nonzero lower bound and lhs has a guaranteed
    // one in bits that must be shifted out for that lower bound.
    %rhs_min_nonzero = "transfer.cmp"(%rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_inv = "transfer.sub"(%bitwidth, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_top_mask = "transfer.shl"(%all_ones, %rhs1_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_top_for_rhs1 = "transfer.and"(%lhs1, %rhs1_top_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_top_nonzero = "transfer.cmp"(%lhs_top_for_rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ov_by_high = "arith.andi"(%rhs_min_nonzero, %lhs_top_nonzero) : (i1, i1) -> i1
    %d2 = "transfer.select"(%ov_by_high, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs == 0 and rhs_max < bw => exact zero.
    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %rhs_max_lt_bw = "transfer.cmp"(%rhs_max, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_zero_safe = "arith.andi"(%lhs_is_zero, %rhs_max_lt_bw) : (i1, i1) -> i1
    %e0 = "transfer.select"(%lhs_zero_safe, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Exact-constant candidate.
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1
    %k_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %k_val = "transfer.select"(%k_ov, %all_ones, %k_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %k_val_not = "transfer.xor"(%k_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %f0 = "transfer.select"(%both_const, %k_val_not, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %f1 = "transfer.select"(%both_const, %k_val, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Enumerate 1-2 unknown bits when one side is constant.
    %lhs_known_union = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_mask = "transfer.xor"(%lhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_nonzero = "transfer.cmp"(%lhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_unknown_minus_1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_and_minus_1 = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_pow2ish = "transfer.cmp"(%lhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_one_unknown = "arith.andi"(%lhs_unknown_nonzero, %lhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_unknown_neg = "transfer.neg"(%lhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %lhs_unknown_lowbit = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_rest = "transfer.xor"(%lhs_unknown_mask, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_nonzero = "transfer.cmp"(%lhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rest_minus_1 = "transfer.sub"(%lhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_and_minus_1 = "transfer.and"(%lhs_unknown_rest, %lhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_pow2ish = "transfer.cmp"(%lhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_two_unknown = "arith.andi"(%lhs_rest_nonzero, %lhs_rest_pow2ish) : (i1, i1) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_neg = "transfer.neg"(%rhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_nonzero = "transfer.cmp"(%rhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_rest_minus_1 = "transfer.sub"(%rhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_and_minus_1 = "transfer.and"(%rhs_unknown_rest, %rhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_pow2ish = "transfer.cmp"(%rhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_rest_nonzero, %rhs_rest_pow2ish) : (i1, i1) -> i1
    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_unknown_rest_neg = "transfer.neg"(%rhs_unknown_rest) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_midbit = "transfer.and"(%rhs_unknown_rest, %rhs_unknown_rest_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_highbit = "transfer.xor"(%rhs_unknown_rest, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_nonzero = "transfer.cmp"(%rhs_unknown_highbit, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_high_minus_1 = "transfer.sub"(%rhs_unknown_highbit, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_and_minus_1 = "transfer.and"(%rhs_unknown_highbit, %rhs_high_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_pow2ish = "transfer.cmp"(%rhs_high_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_high_nonzero, %rhs_high_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_three_unknown = "arith.andi"(%lhs_is_const, %rhs_three_unknown) : (i1, i1) -> i1
    %rhs_01 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_02 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_12 = "transfer.add"(%rhs_unknown_midbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val2 = "transfer.add"(%rhs1, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val3 = "transfer.add"(%rhs1, %rhs_01) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val4 = "transfer.add"(%rhs1, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val5 = "transfer.add"(%rhs1, %rhs_02) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val6 = "transfer.add"(%rhs1, %rhs_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 1 unknown bit.
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_one_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %g_val0 = "transfer.select"(%g_val0_ov, %all_ones, %g_val0_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_shl = "transfer.shl"(%lhs1, %rhs_one_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_ov = "transfer.ushl_overflow"(%lhs1, %rhs_one_alt) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %g_val1 = "transfer.select"(%g_val1_ov, %all_ones, %g_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0_raw = "transfer.and"(%g_val0_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g1_raw = "transfer.and"(%g_val0, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0 = "transfer.select"(%lhs_const_rhs_one_unknown, %g0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g1 = "transfer.select"(%lhs_const_rhs_one_unknown, %g1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 2 unknown bits.
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %rhs_two_alt1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_two_alt2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_two_alt3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_shl = "transfer.shl"(%lhs1, %rhs_two_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val1 = "transfer.select"(%h_val1_ov, %all_ones, %h_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_shl = "transfer.shl"(%lhs1, %rhs_two_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val2 = "transfer.select"(%h_val2_ov, %all_ones, %h_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_shl = "transfer.shl"(%lhs1, %rhs_two_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val3 = "transfer.select"(%h_val3_ov, %all_ones, %h_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_01 = "transfer.and"(%h_val0_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_raw = "transfer.and"(%h0_01, %h0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_01 = "transfer.and"(%g_val0, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_raw = "transfer.and"(%h1_01, %h1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0 = "transfer.select"(%lhs_const_rhs_two_unknown, %h0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h1 = "transfer.select"(%lhs_const_rhs_two_unknown, %h1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 3 unknown bits.
    %m_val2_shl = "transfer.shl"(%lhs1, %rhs3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val2_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val2 = "transfer.select"(%m_val2_ov, %all_ones, %m_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_shl = "transfer.shl"(%lhs1, %rhs3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val3 = "transfer.select"(%m_val3_ov, %all_ones, %m_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_shl = "transfer.shl"(%lhs1, %rhs3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val4 = "transfer.select"(%m_val4_ov, %all_ones, %m_val4_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_shl = "transfer.shl"(%lhs1, %rhs3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val5 = "transfer.select"(%m_val5_ov, %all_ones, %m_val5_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_shl = "transfer.shl"(%lhs1, %rhs3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val6 = "transfer.select"(%m_val6_ov, %all_ones, %m_val6_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val2_not = "transfer.xor"(%m_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_not = "transfer.xor"(%m_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_not = "transfer.xor"(%m_val4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_not = "transfer.xor"(%m_val5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_not = "transfer.xor"(%m_val6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val7_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_01 = "transfer.and"(%m_val0_not, %m_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_23 = "transfer.and"(%m_val2_not, %m_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_45 = "transfer.and"(%m_val4_not, %m_val5_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_67 = "transfer.and"(%m_val6_not, %m_val7_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_0123 = "transfer.and"(%m0_01, %m0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_4567 = "transfer.and"(%m0_45, %m0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_raw = "transfer.and"(%m0_0123, %m0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_01 = "transfer.and"(%g_val0, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_23 = "transfer.and"(%m_val2, %m_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_45 = "transfer.and"(%m_val4, %m_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_67 = "transfer.and"(%m_val6, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_0123 = "transfer.and"(%m1_01, %m1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_4567 = "transfer.and"(%m1_45, %m1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_raw = "transfer.and"(%m1_0123, %m1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0 = "transfer.select"(%lhs_const_rhs_three_unknown, %m0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m1 = "transfer.select"(%lhs_const_rhs_three_unknown, %m1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs has exactly 1 unknown bit.
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_one_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %i_val0 = "transfer.select"(%i_val0_ov, %all_ones, %i_val0_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_shl = "transfer.shl"(%lhs_one_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_ov = "transfer.ushl_overflow"(%lhs_one_alt, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %i_val1 = "transfer.select"(%i_val1_ov, %all_ones, %i_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0_raw = "transfer.and"(%i_val0_not, %i_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i1_raw = "transfer.and"(%i_val0, %i_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0 = "transfer.select"(%rhs_const_lhs_one_unknown, %i0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i1 = "transfer.select"(%rhs_const_lhs_one_unknown, %i1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs has exactly 2 unknown bits.
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1
    %lhs_two_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_shl = "transfer.shl"(%lhs_two_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_ov = "transfer.ushl_overflow"(%lhs_two_alt1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val1 = "transfer.select"(%j_val1_ov, %all_ones, %j_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_shl = "transfer.shl"(%lhs_two_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_ov = "transfer.ushl_overflow"(%lhs_two_alt2, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val2 = "transfer.select"(%j_val2_ov, %all_ones, %j_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_shl = "transfer.shl"(%lhs_two_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_ov = "transfer.ushl_overflow"(%lhs_two_alt3, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val3 = "transfer.select"(%j_val3_ov, %all_ones, %j_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_01 = "transfer.and"(%j_val0_not, %j_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_23 = "transfer.and"(%j_val2_not, %j_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_raw = "transfer.and"(%j0_01, %j0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_01 = "transfer.and"(%i_val0, %j_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_23 = "transfer.and"(%j_val2, %j_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_raw = "transfer.and"(%j1_01, %j1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0 = "transfer.select"(%rhs_const_lhs_two_unknown, %j0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j1 = "transfer.select"(%rhs_const_lhs_two_unknown, %j1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs and rhs each have exactly 1 unknown bit.
    %n_val3_shl = "transfer.shl"(%lhs_one_alt, %rhs_one_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val3_ov = "transfer.ushl_overflow"(%lhs_one_alt, %rhs_one_alt) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %n_val3 = "transfer.select"(%n_val3_ov, %all_ones, %n_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val2_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val3_not = "transfer.xor"(%n_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_01 = "transfer.and"(%n_val0_not, %n_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_23 = "transfer.and"(%n_val2_not, %n_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_raw = "transfer.and"(%n0_01, %n0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_01 = "transfer.and"(%i_val0, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_23 = "transfer.and"(%i_val1, %n_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_raw = "transfer.and"(%n1_01, %n1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0 = "transfer.select"(%lhs_rhs_one_one, %n0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n1 = "transfer.select"(%lhs_rhs_one_one, %n1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ab0 = "transfer.or"(%a0, %b0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abc0 = "transfer.or"(%ab0, %c0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abce0 = "transfer.or"(%abc0, %e0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcef0 = "transfer.or"(%abce0, %f0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefg0 = "transfer.or"(%abcef0, %g0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefgh0 = "transfer.or"(%abcefg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghm0 = "transfer.or"(%abcefgh0, %m0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghmi0 = "transfer.or"(%abcefghm0, %i0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghmij0 = "transfer.or"(%abcefghmi0, %j0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%abcefghmij0, %n0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ab1 = "transfer.or"(%a1, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abc1 = "transfer.or"(%ab1, %c1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcd1 = "transfer.or"(%abc1, %d1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdd1 = "transfer.or"(%abcd1, %d2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdf1 = "transfer.or"(%abcdd1, %f1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfg1 = "transfer.or"(%abcdf1, %g1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfgh1 = "transfer.or"(%abcdfg1, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghm1 = "transfer.or"(%abcdfgh1, %m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghmi1 = "transfer.or"(%abcdfghm1, %i1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghmij1 = "transfer.or"(%abcdfghmi1, %j1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%abcdfghmij1, %n1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ushlsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const2 = "transfer.shl"(%const1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const4 = "transfer.shl"(%const2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const8 = "transfer.shl"(%const4, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const16 = "transfer.shl"(%const8, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const32 = "transfer.shl"(%const16, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const64 = "transfer.shl"(%const32, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %any_conflict = "transfer.or"(%lhs_conflict, %rhs_conflict) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%any_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %always_underflow = "transfer.cmp"(%lhs_max, %rhs1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %never_underflow = "transfer.cmp"(%lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_min_le_lhs_max = "transfer.cmp"(%rhs1, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub_non_raw = "transfer.sub"(%lhs_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub_non = "transfer.select"(%rhs_min_le_lhs_max, %ub_non_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ub = "transfer.select"(%always_underflow, %const0, %ub_non) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_raw = "transfer.sub"(%lhs1, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb = "transfer.select"(%never_underflow, %lb_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1
    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1

    %const_underflow = "transfer.cmp"(%lhs1, %rhs1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_sub = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.select"(%const_underflow, %const0, %const_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_uf = "transfer.select"(%always_underflow, %all_ones, %range0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_uf = "transfer.select"(%always_underflow, %const0, %range1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_uf) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs0 = "transfer.select"(%lhs_is_zero, %const0, %res1_uf) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_rhs0 = "transfer.select"(%rhs_is_zero, %lhs0, %res0_lhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_rhs0 = "transfer.select"(%rhs_is_zero, %lhs1, %res1_lhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%both_const, %const_res0, %res0_rhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_res1, %res1_rhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Compute lhs-rhs (mod 2^bw) known bits using (~rhs + 1) and add-style carry reasoning.
    %const1_not = "transfer.xor"(%const1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_a_max = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_b_max = "transfer.xor"(%const1_not, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_min = "transfer.add"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_max = "transfer.add"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_and = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_or = "transfer.or"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_min_not = "transfer.xor"(%neg_rhs_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_or_and_sum_not = "transfer.and"(%neg_rhs_min_or, %neg_rhs_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_out_min = "transfer.or"(%neg_rhs_min_and, %neg_rhs_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_and = "transfer.and"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_or = "transfer.or"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_max_not = "transfer.xor"(%neg_rhs_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_or_and_sum_not = "transfer.and"(%neg_rhs_max_or, %neg_rhs_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_out_max = "transfer.or"(%neg_rhs_max_and, %neg_rhs_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_one = "transfer.shl"(%neg_rhs_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_may_one = "transfer.shl"(%neg_rhs_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_zero = "transfer.xor"(%neg_rhs_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_ab_00 = "transfer.and"(%rhs1, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_ab_11 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_ab_01 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_ab_10 = "transfer.and"(%rhs0, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor_ab_0 = "transfer.or"(%neg_rhs_xor0_ab_00, %neg_rhs_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor_ab_1 = "transfer.or"(%neg_rhs_xor1_ab_01, %neg_rhs_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_sum_carry_00 = "transfer.and"(%neg_rhs_xor_ab_0, %neg_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_sum_carry_11 = "transfer.and"(%neg_rhs_xor_ab_1, %neg_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_sum_carry_01 = "transfer.and"(%neg_rhs_xor_ab_0, %neg_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_sum_carry_10 = "transfer.and"(%neg_rhs_xor_ab_1, %neg_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg0 = "transfer.or"(%neg_rhs_xor0_sum_carry_00, %neg_rhs_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg1 = "transfer.or"(%neg_rhs_xor1_sum_carry_01, %neg_rhs_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sub_a_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_b_max = "transfer.xor"(%rhs_neg0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_min = "transfer.add"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_max = "transfer.add"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_and = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_or = "transfer.or"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_min_not = "transfer.xor"(%sub_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_or_and_sum_not = "transfer.and"(%sub_min_or, %sub_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_out_min = "transfer.or"(%sub_min_and, %sub_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_and = "transfer.and"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_or = "transfer.or"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_max_not = "transfer.xor"(%sub_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_or_and_sum_not = "transfer.and"(%sub_max_or, %sub_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_out_max = "transfer.or"(%sub_max_and, %sub_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_one = "transfer.shl"(%sub_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_may_one = "transfer.shl"(%sub_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_zero = "transfer.xor"(%sub_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_ab_00 = "transfer.and"(%lhs0, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_ab_11 = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_ab_01 = "transfer.and"(%lhs0, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_ab_10 = "transfer.and"(%lhs1, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor_ab_0 = "transfer.or"(%sub_xor0_ab_00, %sub_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor_ab_1 = "transfer.or"(%sub_xor1_ab_01, %sub_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_sum_carry_00 = "transfer.and"(%sub_xor_ab_0, %sub_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_sum_carry_11 = "transfer.and"(%sub_xor_ab_1, %sub_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_sum_carry_01 = "transfer.and"(%sub_xor_ab_0, %sub_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_sum_carry_10 = "transfer.and"(%sub_xor_ab_1, %sub_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr0 = "transfer.or"(%sub_xor0_sum_carry_00, %sub_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr1 = "transfer.or"(%sub_xor1_sum_carry_01, %sub_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr1_nouf = "transfer.select"(%never_underflow, %sub_lr1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_sub = "transfer.or"(%res0, %sub_lr0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_sub = "transfer.or"(%res1, %sub_lr1_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Equal low bits imply trailing zeros in lhs-rhs; parity gives the exact low bit.
    %eq_low_known0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known = "transfer.or"(%eq_low_known0, %eq_low_known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_count = "transfer.countr_one"(%eq_low_known) : (!transfer.integer) -> !transfer.integer
    %eq_low_inv = "transfer.sub"(%bitwidth, %eq_low_count) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_mask = "transfer.lshr"(%all_ones, %eq_low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_eq = "transfer.or"(%res0_sub, %eq_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_lsb0 = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lsb1 = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lsb0 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lsb1 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero00 = "transfer.and"(%lhs_lsb0, %rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero11 = "transfer.and"(%lhs_lsb1, %rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one01 = "transfer.and"(%lhs_lsb0, %rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one10 = "transfer.and"(%lhs_lsb1, %rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero = "transfer.or"(%lsb_zero00, %lsb_zero11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one = "transfer.or"(%lsb_one01, %lsb_one10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_nouf = "transfer.select"(%never_underflow, %lsb_one, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lsb = "transfer.or"(%res0_eq, %lsb_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lsb = "transfer.or"(%res1_sub, %lsb_one_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Low known input bits give exact low bits of lhs-rhs (mod 2^k).
    %lhs_known_mask = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_known_mask = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low_known = "transfer.countr_one"(%lhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_low_known = "transfer.countr_one"(%rhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %low_known = "transfer.umin"(%lhs_low_known, %rhs_low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_inv = "transfer.sub"(%bitwidth, %low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_mask = "transfer.lshr"(%all_ones, %low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low = "transfer.and"(%lhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_low = "transfer.and"(%rhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub = "transfer.sub"(%lhs_low, %rhs_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub_masked = "transfer.and"(%low_sub, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub_not = "transfer.xor"(%low_sub_masked, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low0 = "transfer.and"(%low_sub_not, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low1 = "transfer.select"(%never_underflow, %low_sub_masked, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined = "transfer.or"(%res0_lsb, %low0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined = "transfer.or"(%res1_lsb, %low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Borrow-aware low-bit refinement for bits 1..3.
    %lhs0_b0_z = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b0_o = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b0_z = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b0_o = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_raw_o = "transfer.and"(%lhs0_b0_z, %rhs0_b0_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_raw_z = "transfer.or"(%lhs0_b0_o, %rhs0_b0_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_o = "transfer.shl"(%b1_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_z = "transfer.shl"(%b1_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b1_z = "transfer.and"(%lhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b1_o = "transfer.and"(%lhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b1_z = "transfer.and"(%rhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b1_o = "transfer.and"(%rhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_00 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_11 = "transfer.and"(%lhs0_b1_o, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_01 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_10 = "transfer.and"(%lhs0_b1_o, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_0 = "transfer.or"(%xy1_00, %xy1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_1 = "transfer.or"(%xy1_01, %xy1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_00 = "transfer.and"(%xy1_0, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_11 = "transfer.and"(%xy1_1, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_01 = "transfer.and"(%xy1_0, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_10 = "transfer.and"(%xy1_1, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0 = "transfer.or"(%r1_00, %r1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1 = "transfer.or"(%r1_01, %r1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_1 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_0 = "transfer.or"(%lhs0_b1_o, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1term_1 = "transfer.and"(%xy1_0, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1term_0 = "transfer.or"(%xy1_1, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_raw_o = "transfer.or"(%a1_1, %b1term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_raw_z = "transfer.and"(%a1_0, %b1term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_o = "transfer.shl"(%b2_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_z = "transfer.shl"(%b2_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b2_z = "transfer.and"(%lhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b2_o = "transfer.and"(%lhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b2_z = "transfer.and"(%rhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b2_o = "transfer.and"(%rhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_00 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_11 = "transfer.and"(%lhs0_b2_o, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_01 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_10 = "transfer.and"(%lhs0_b2_o, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_0 = "transfer.or"(%xy2_00, %xy2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_1 = "transfer.or"(%xy2_01, %xy2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_00 = "transfer.and"(%xy2_0, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_11 = "transfer.and"(%xy2_1, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_01 = "transfer.and"(%xy2_0, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_10 = "transfer.and"(%xy2_1, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_0 = "transfer.or"(%r2_00, %r2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_1 = "transfer.or"(%r2_01, %r2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a2_1 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a2_0 = "transfer.or"(%lhs0_b2_o, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2term_1 = "transfer.and"(%xy2_0, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2term_0 = "transfer.or"(%xy2_1, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_raw_o = "transfer.or"(%a2_1, %b2term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_raw_z = "transfer.and"(%a2_0, %b2term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_o = "transfer.shl"(%b3_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_z = "transfer.shl"(%b3_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b3_z = "transfer.and"(%lhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b3_o = "transfer.and"(%lhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b3_z = "transfer.and"(%rhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b3_o = "transfer.and"(%rhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_00 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_11 = "transfer.and"(%lhs0_b3_o, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_01 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_10 = "transfer.and"(%lhs0_b3_o, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_0 = "transfer.or"(%xy3_00, %xy3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_1 = "transfer.or"(%xy3_01, %xy3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_00 = "transfer.and"(%xy3_0, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_11 = "transfer.and"(%xy3_1, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_01 = "transfer.and"(%xy3_0, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_10 = "transfer.and"(%xy3_1, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_0 = "transfer.or"(%r3_00, %r3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_1 = "transfer.or"(%r3_01, %r3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %a3_1 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a3_0 = "transfer.or"(%lhs0_b3_o, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3term_1 = "transfer.and"(%xy3_0, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3term_0 = "transfer.or"(%xy3_1, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_raw_o = "transfer.or"(%a3_1, %b3term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_raw_z = "transfer.and"(%a3_0, %b3term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_o = "transfer.shl"(%b4_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_z = "transfer.shl"(%b4_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b4_z = "transfer.and"(%lhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b4_o = "transfer.and"(%lhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b4_z = "transfer.and"(%rhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b4_o = "transfer.and"(%rhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_00 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_11 = "transfer.and"(%lhs0_b4_o, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_01 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_10 = "transfer.and"(%lhs0_b4_o, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_0 = "transfer.or"(%xy4_00, %xy4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_1 = "transfer.or"(%xy4_01, %xy4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_00 = "transfer.and"(%xy4_0, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_11 = "transfer.and"(%xy4_1, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_01 = "transfer.and"(%xy4_0, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_10 = "transfer.and"(%xy4_1, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_0 = "transfer.or"(%r4_00, %r4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_1 = "transfer.or"(%r4_01, %r4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a4_1 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a4_0 = "transfer.or"(%lhs0_b4_o, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4term_1 = "transfer.and"(%xy4_0, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4term_0 = "transfer.or"(%xy4_1, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_raw_o = "transfer.or"(%a4_1, %b4term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_raw_z = "transfer.and"(%a4_0, %b4term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_o = "transfer.shl"(%b5_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_z = "transfer.shl"(%b5_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b5_z = "transfer.and"(%lhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b5_o = "transfer.and"(%lhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b5_z = "transfer.and"(%rhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b5_o = "transfer.and"(%rhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_00 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_11 = "transfer.and"(%lhs0_b5_o, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_01 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_10 = "transfer.and"(%lhs0_b5_o, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_0 = "transfer.or"(%xy5_00, %xy5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_1 = "transfer.or"(%xy5_01, %xy5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_00 = "transfer.and"(%xy5_0, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_11 = "transfer.and"(%xy5_1, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_01 = "transfer.and"(%xy5_0, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_10 = "transfer.and"(%xy5_1, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_0 = "transfer.or"(%r5_00, %r5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_1 = "transfer.or"(%r5_01, %r5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a5_1 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a5_0 = "transfer.or"(%lhs0_b5_o, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5term_1 = "transfer.and"(%xy5_0, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5term_0 = "transfer.or"(%xy5_1, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_raw_o = "transfer.or"(%a5_1, %b5term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_raw_z = "transfer.and"(%a5_0, %b5term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_o = "transfer.shl"(%b6_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_z = "transfer.shl"(%b6_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b6_z = "transfer.and"(%lhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b6_o = "transfer.and"(%lhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b6_z = "transfer.and"(%rhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b6_o = "transfer.and"(%rhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_00 = "transfer.and"(%lhs0_b6_z, %rhs0_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_11 = "transfer.and"(%lhs0_b6_o, %rhs0_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_01 = "transfer.and"(%lhs0_b6_z, %rhs0_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_10 = "transfer.and"(%lhs0_b6_o, %rhs0_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_0 = "transfer.or"(%xy6_00, %xy6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_1 = "transfer.or"(%xy6_01, %xy6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_00 = "transfer.and"(%xy6_0, %b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_11 = "transfer.and"(%xy6_1, %b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_01 = "transfer.and"(%xy6_0, %b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_10 = "transfer.and"(%xy6_1, %b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_0 = "transfer.or"(%r6_00, %r6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_1 = "transfer.or"(%r6_01, %r6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r_low_0a = "transfer.or"(%r1_0, %r2_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0b = "transfer.or"(%r3_0, %r4_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0c = "transfer.or"(%r5_0, %r6_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0d = "transfer.or"(%r_low_0a, %r_low_0b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0 = "transfer.or"(%r_low_0d, %r_low_0c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1a = "transfer.or"(%r1_1, %r2_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1b = "transfer.or"(%r3_1, %r4_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1c = "transfer.or"(%r5_1, %r6_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1d = "transfer.or"(%r_low_1a, %r_low_1b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1 = "transfer.or"(%r_low_1d, %r_low_1c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1_nouf = "transfer.select"(%never_underflow, %r_low_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined2 = "transfer.or"(%res0_refined, %r_low_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined2 = "transfer.or"(%res1_refined, %r_low_1_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0_refined2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1_refined2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_usubsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : i1, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.select"(%h0, %h1, %arg0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.and"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.and"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%v2, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
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