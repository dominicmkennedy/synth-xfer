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
