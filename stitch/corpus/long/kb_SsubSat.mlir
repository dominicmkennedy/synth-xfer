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
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %signed_max = "transfer.get_signed_max_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %signed_min = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1
    %id_res0 = "transfer.select"(%rhs_is_zero, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res1 = "transfer.select"(%rhs_is_zero, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
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
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_one_two = "arith.andi"(%lhs_one_unknown, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_one = "arith.andi"(%lhs_two_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_two = "arith.andi"(%lhs_two_unknown, %rhs_two_unknown) : (i1, i1) -> i1

    %lhs_sign_zero_bits = "transfer.and"(%lhs0, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_zero_bits = "transfer.and"(%rhs0, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one_bits = "transfer.and"(%lhs1, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_one_bits = "transfer.and"(%rhs1, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg = "transfer.cmp"(%lhs_sign_zero_bits, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg = "transfer.cmp"(%rhs_sign_zero_bits, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_sign_one_bits, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%rhs_sign_one_bits, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_nonneg = "arith.andi"(%lhs_nonneg, %rhs_nonneg) : (i1, i1) -> i1
    %both_neg = "arith.andi"(%lhs_neg, %rhs_neg) : (i1, i1) -> i1
    %mixed_pos = "arith.andi"(%lhs_nonneg, %rhs_neg) : (i1, i1) -> i1
    %mixed_neg = "arith.andi"(%lhs_neg, %rhs_nonneg) : (i1, i1) -> i1
    %same_sign = "arith.ori"(%both_nonneg, %both_neg) : (i1, i1) -> i1

    // Class-refined signed extrema for mixed-sign subtraction.
    %lhs_nonneg_min = "transfer.and"(%lhs1, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg_max = "transfer.and"(%lhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_min = "transfer.and"(%rhs1, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_max = "transfer.and"(%rhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_neg_min = "transfer.or"(%lhs1, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_neg_max = "transfer.or"(%lhs_nonneg_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_min = "transfer.or"(%rhs1, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_max = "transfer.or"(%rhs_nonneg_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ov_pos_min = "transfer.ssub_overflow"(%lhs_nonneg_min, %rhs_neg_max) : (!transfer.integer, !transfer.integer) -> i1
    %ov_pos_max = "transfer.ssub_overflow"(%lhs_nonneg_max, %rhs_neg_min) : (!transfer.integer, !transfer.integer) -> i1
    %ov_neg_min = "transfer.ssub_overflow"(%lhs_neg_min, %rhs_nonneg_max) : (!transfer.integer, !transfer.integer) -> i1
    %ov_neg_max = "transfer.ssub_overflow"(%lhs_neg_max, %rhs_nonneg_min) : (!transfer.integer, !transfer.integer) -> i1
    %not_ov_pos_max = "arith.xori"(%ov_pos_max, %const_true) : (i1, i1) -> i1
    %not_ov_neg_min = "arith.xori"(%ov_neg_min, %const_true) : (i1, i1) -> i1
    %must_pos = "arith.andi"(%mixed_pos, %ov_pos_min) : (i1, i1) -> i1
    %never_pos = "arith.andi"(%mixed_pos, %not_ov_pos_max) : (i1, i1) -> i1
    %must_neg = "arith.andi"(%mixed_neg, %ov_neg_max) : (i1, i1) -> i1
    %never_neg = "arith.andi"(%mixed_neg, %not_ov_neg_min) : (i1, i1) -> i1
    %not_must_pos = "arith.xori"(%must_pos, %const_true) : (i1, i1) -> i1
    %not_never_pos = "arith.xori"(%never_pos, %const_true) : (i1, i1) -> i1
    %maybe_pos0 = "arith.andi"(%mixed_pos, %not_must_pos) : (i1, i1) -> i1
    %maybe_pos = "arith.andi"(%maybe_pos0, %not_never_pos) : (i1, i1) -> i1
    %not_must_neg = "arith.xori"(%must_neg, %const_true) : (i1, i1) -> i1
    %not_never_neg = "arith.xori"(%never_neg, %const_true) : (i1, i1) -> i1
    %maybe_neg0 = "arith.andi"(%mixed_neg, %not_must_neg) : (i1, i1) -> i1
    %maybe_neg = "arith.andi"(%maybe_neg0, %not_never_neg) : (i1, i1) -> i1
    %no_ov_known_a = "arith.ori"(%same_sign, %never_pos) : (i1, i1) -> i1
    %no_ov_known = "arith.ori"(%no_ov_known_a, %never_neg) : (i1, i1) -> i1

    // KnownBits transfer for wrapping subtraction: lhs + (~rhs + 1).
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
    %sub0 = "transfer.or"(%sub_xor0_sum_carry_00, %sub_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub1 = "transfer.or"(%sub_xor1_sum_carry_01, %sub_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Wrapping-sub low-bit refinements (used only in proven no-overflow regions).
    %wr_eq_known0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_eq_known1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_eq_known = "transfer.or"(%wr_eq_known0, %wr_eq_known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_eq_count = "transfer.countr_one"(%wr_eq_known) : (!transfer.integer) -> !transfer.integer
    %wr_eq_inv = "transfer.sub"(%bitwidth, %wr_eq_count) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_eq_mask = "transfer.lshr"(%all_ones, %wr_eq_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr0_eq = "transfer.or"(%sub0, %wr_eq_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_lsb0 = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_lsb1 = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_lsb0 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_lsb1 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_zero00 = "transfer.and"(%wr_lhs_lsb0, %wr_rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_zero11 = "transfer.and"(%wr_lhs_lsb1, %wr_rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_one01 = "transfer.and"(%wr_lhs_lsb0, %wr_rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_one10 = "transfer.and"(%wr_lhs_lsb1, %wr_rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_zero = "transfer.or"(%wr_lsb_zero00, %wr_lsb_zero11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lsb_one = "transfer.or"(%wr_lsb_one01, %wr_lsb_one10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr0_lsb = "transfer.or"(%wr0_eq, %wr_lsb_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr1_lsb = "transfer.or"(%sub1, %wr_lsb_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_known_mask = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_known_mask = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_low_known = "transfer.countr_one"(%wr_lhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %wr_rhs_low_known = "transfer.countr_one"(%wr_rhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %wr_low_known = "transfer.umin"(%wr_lhs_low_known, %wr_rhs_low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_inv = "transfer.sub"(%bitwidth, %wr_low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_mask = "transfer.lshr"(%all_ones, %wr_low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_low = "transfer.and"(%lhs1, %wr_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_low = "transfer.and"(%rhs1, %wr_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_sub = "transfer.sub"(%wr_lhs_low, %wr_rhs_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_sub_masked = "transfer.and"(%wr_low_sub, %wr_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_sub_not = "transfer.xor"(%wr_low_sub_masked, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low0 = "transfer.and"(%wr_low_sub_not, %wr_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low1 = "transfer.and"(%wr_low_sub_masked, %wr_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr0_ref = "transfer.or"(%wr0_lsb, %wr_low0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr1_ref = "transfer.or"(%wr1_lsb, %wr_low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b0_z = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b0_o = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b0_z = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b0_o = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1_raw_o = "transfer.and"(%wr_lhs_b0_z, %wr_rhs_b0_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1_raw_z = "transfer.or"(%wr_lhs_b0_o, %wr_rhs_b0_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1_o = "transfer.shl"(%wr_b1_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1_z = "transfer.shl"(%wr_b1_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b1_z = "transfer.and"(%lhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b1_o = "transfer.and"(%lhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b1_z = "transfer.and"(%rhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b1_o = "transfer.and"(%rhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_00 = "transfer.and"(%wr_lhs_b1_z, %wr_rhs_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_11 = "transfer.and"(%wr_lhs_b1_o, %wr_rhs_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_01 = "transfer.and"(%wr_lhs_b1_z, %wr_rhs_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_10 = "transfer.and"(%wr_lhs_b1_o, %wr_rhs_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_0 = "transfer.or"(%wr_xy1_00, %wr_xy1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy1_1 = "transfer.or"(%wr_xy1_01, %wr_xy1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_00 = "transfer.and"(%wr_xy1_0, %wr_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_11 = "transfer.and"(%wr_xy1_1, %wr_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_01 = "transfer.and"(%wr_xy1_0, %wr_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_10 = "transfer.and"(%wr_xy1_1, %wr_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_0 = "transfer.or"(%wr_r1_00, %wr_r1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r1_1 = "transfer.or"(%wr_r1_01, %wr_r1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a1_1 = "transfer.and"(%wr_lhs_b1_z, %wr_rhs_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a1_0 = "transfer.or"(%wr_lhs_b1_o, %wr_rhs_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1term_1 = "transfer.and"(%wr_xy1_0, %wr_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b1term_0 = "transfer.or"(%wr_xy1_1, %wr_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2_raw_o = "transfer.or"(%wr_a1_1, %wr_b1term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2_raw_z = "transfer.and"(%wr_a1_0, %wr_b1term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2_o = "transfer.shl"(%wr_b2_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2_z = "transfer.shl"(%wr_b2_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b2_z = "transfer.and"(%lhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b2_o = "transfer.and"(%lhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b2_z = "transfer.and"(%rhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b2_o = "transfer.and"(%rhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_00 = "transfer.and"(%wr_lhs_b2_z, %wr_rhs_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_11 = "transfer.and"(%wr_lhs_b2_o, %wr_rhs_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_01 = "transfer.and"(%wr_lhs_b2_z, %wr_rhs_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_10 = "transfer.and"(%wr_lhs_b2_o, %wr_rhs_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_0 = "transfer.or"(%wr_xy2_00, %wr_xy2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy2_1 = "transfer.or"(%wr_xy2_01, %wr_xy2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_00 = "transfer.and"(%wr_xy2_0, %wr_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_11 = "transfer.and"(%wr_xy2_1, %wr_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_01 = "transfer.and"(%wr_xy2_0, %wr_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_10 = "transfer.and"(%wr_xy2_1, %wr_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_0 = "transfer.or"(%wr_r2_00, %wr_r2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r2_1 = "transfer.or"(%wr_r2_01, %wr_r2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a2_1 = "transfer.and"(%wr_lhs_b2_z, %wr_rhs_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a2_0 = "transfer.or"(%wr_lhs_b2_o, %wr_rhs_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2term_1 = "transfer.and"(%wr_xy2_0, %wr_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b2term_0 = "transfer.or"(%wr_xy2_1, %wr_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3_raw_o = "transfer.or"(%wr_a2_1, %wr_b2term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3_raw_z = "transfer.and"(%wr_a2_0, %wr_b2term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3_o = "transfer.shl"(%wr_b3_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3_z = "transfer.shl"(%wr_b3_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b3_z = "transfer.and"(%lhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b3_o = "transfer.and"(%lhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b3_z = "transfer.and"(%rhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b3_o = "transfer.and"(%rhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_00 = "transfer.and"(%wr_lhs_b3_z, %wr_rhs_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_11 = "transfer.and"(%wr_lhs_b3_o, %wr_rhs_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_01 = "transfer.and"(%wr_lhs_b3_z, %wr_rhs_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_10 = "transfer.and"(%wr_lhs_b3_o, %wr_rhs_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_0 = "transfer.or"(%wr_xy3_00, %wr_xy3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy3_1 = "transfer.or"(%wr_xy3_01, %wr_xy3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_00 = "transfer.and"(%wr_xy3_0, %wr_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_11 = "transfer.and"(%wr_xy3_1, %wr_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_01 = "transfer.and"(%wr_xy3_0, %wr_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_10 = "transfer.and"(%wr_xy3_1, %wr_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_0 = "transfer.or"(%wr_r3_00, %wr_r3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r3_1 = "transfer.or"(%wr_r3_01, %wr_r3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_a3_1 = "transfer.and"(%wr_lhs_b3_z, %wr_rhs_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a3_0 = "transfer.or"(%wr_lhs_b3_o, %wr_rhs_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3term_1 = "transfer.and"(%wr_xy3_0, %wr_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b3term_0 = "transfer.or"(%wr_xy3_1, %wr_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4_raw_o = "transfer.or"(%wr_a3_1, %wr_b3term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4_raw_z = "transfer.and"(%wr_a3_0, %wr_b3term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4_o = "transfer.shl"(%wr_b4_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4_z = "transfer.shl"(%wr_b4_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b4_z = "transfer.and"(%lhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b4_o = "transfer.and"(%lhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b4_z = "transfer.and"(%rhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b4_o = "transfer.and"(%rhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_00 = "transfer.and"(%wr_lhs_b4_z, %wr_rhs_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_11 = "transfer.and"(%wr_lhs_b4_o, %wr_rhs_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_01 = "transfer.and"(%wr_lhs_b4_z, %wr_rhs_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_10 = "transfer.and"(%wr_lhs_b4_o, %wr_rhs_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_0 = "transfer.or"(%wr_xy4_00, %wr_xy4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy4_1 = "transfer.or"(%wr_xy4_01, %wr_xy4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_00 = "transfer.and"(%wr_xy4_0, %wr_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_11 = "transfer.and"(%wr_xy4_1, %wr_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_01 = "transfer.and"(%wr_xy4_0, %wr_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_10 = "transfer.and"(%wr_xy4_1, %wr_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_0 = "transfer.or"(%wr_r4_00, %wr_r4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r4_1 = "transfer.or"(%wr_r4_01, %wr_r4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a4_1 = "transfer.and"(%wr_lhs_b4_z, %wr_rhs_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a4_0 = "transfer.or"(%wr_lhs_b4_o, %wr_rhs_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4term_1 = "transfer.and"(%wr_xy4_0, %wr_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b4term_0 = "transfer.or"(%wr_xy4_1, %wr_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5_raw_o = "transfer.or"(%wr_a4_1, %wr_b4term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5_raw_z = "transfer.and"(%wr_a4_0, %wr_b4term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5_o = "transfer.shl"(%wr_b5_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5_z = "transfer.shl"(%wr_b5_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b5_z = "transfer.and"(%lhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b5_o = "transfer.and"(%lhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b5_z = "transfer.and"(%rhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b5_o = "transfer.and"(%rhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_00 = "transfer.and"(%wr_lhs_b5_z, %wr_rhs_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_11 = "transfer.and"(%wr_lhs_b5_o, %wr_rhs_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_01 = "transfer.and"(%wr_lhs_b5_z, %wr_rhs_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_10 = "transfer.and"(%wr_lhs_b5_o, %wr_rhs_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_0 = "transfer.or"(%wr_xy5_00, %wr_xy5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy5_1 = "transfer.or"(%wr_xy5_01, %wr_xy5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_00 = "transfer.and"(%wr_xy5_0, %wr_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_11 = "transfer.and"(%wr_xy5_1, %wr_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_01 = "transfer.and"(%wr_xy5_0, %wr_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_10 = "transfer.and"(%wr_xy5_1, %wr_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_0 = "transfer.or"(%wr_r5_00, %wr_r5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r5_1 = "transfer.or"(%wr_r5_01, %wr_r5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a5_1 = "transfer.and"(%wr_lhs_b5_z, %wr_rhs_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_a5_0 = "transfer.or"(%wr_lhs_b5_o, %wr_rhs_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5term_1 = "transfer.and"(%wr_xy5_0, %wr_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b5term_0 = "transfer.or"(%wr_xy5_1, %wr_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b6_raw_o = "transfer.or"(%wr_a5_1, %wr_b5term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b6_raw_z = "transfer.and"(%wr_a5_0, %wr_b5term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b6_o = "transfer.shl"(%wr_b6_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_b6_z = "transfer.shl"(%wr_b6_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_lhs_b6_z = "transfer.and"(%lhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_lhs_b6_o = "transfer.and"(%lhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b6_z = "transfer.and"(%rhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_rhs_b6_o = "transfer.and"(%rhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_00 = "transfer.and"(%wr_lhs_b6_z, %wr_rhs_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_11 = "transfer.and"(%wr_lhs_b6_o, %wr_rhs_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_01 = "transfer.and"(%wr_lhs_b6_z, %wr_rhs_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_10 = "transfer.and"(%wr_lhs_b6_o, %wr_rhs_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_0 = "transfer.or"(%wr_xy6_00, %wr_xy6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_xy6_1 = "transfer.or"(%wr_xy6_01, %wr_xy6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_00 = "transfer.and"(%wr_xy6_0, %wr_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_11 = "transfer.and"(%wr_xy6_1, %wr_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_01 = "transfer.and"(%wr_xy6_0, %wr_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_10 = "transfer.and"(%wr_xy6_1, %wr_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_0 = "transfer.or"(%wr_r6_00, %wr_r6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_r6_1 = "transfer.or"(%wr_r6_01, %wr_r6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %wr_low_0a = "transfer.or"(%wr_r1_0, %wr_r2_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_0b = "transfer.or"(%wr_r3_0, %wr_r4_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_0c = "transfer.or"(%wr_r5_0, %wr_r6_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_0d = "transfer.or"(%wr_low_0a, %wr_low_0b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_0 = "transfer.or"(%wr_low_0d, %wr_low_0c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_1a = "transfer.or"(%wr_r1_1, %wr_r2_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_1b = "transfer.or"(%wr_r3_1, %wr_r4_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_1c = "transfer.or"(%wr_r5_1, %wr_r6_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_1d = "transfer.or"(%wr_low_1a, %wr_low_1b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr_low_1 = "transfer.or"(%wr_low_1d, %wr_low_1c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr0_ref2 = "transfer.or"(%wr0_ref, %wr_low_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wr1_ref2 = "transfer.or"(%wr1_ref, %wr_low_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %glob_lhs_sign_can_be_one = "transfer.and"(%lhs_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_rhs_sign_can_be_one = "transfer.and"(%rhs_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_lhs_smin = "transfer.or"(%lhs1, %glob_lhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_rhs_smin = "transfer.or"(%rhs1, %glob_rhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_lhs_upper_max = "transfer.and"(%lhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_rhs_upper_max = "transfer.and"(%rhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_lhs_smax = "transfer.or"(%glob_lhs_upper_max, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_rhs_smax = "transfer.or"(%glob_rhs_upper_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %glob_min_ov = "transfer.ssub_overflow"(%glob_lhs_smin, %glob_rhs_smax) : (!transfer.integer, !transfer.integer) -> i1
    %glob_max_ov = "transfer.ssub_overflow"(%glob_lhs_smax, %glob_rhs_smin) : (!transfer.integer, !transfer.integer) -> i1
    %glob_any_ov = "arith.ori"(%glob_min_ov, %glob_max_ov) : (i1, i1) -> i1
    %glob_no_ov = "arith.xori"(%glob_any_ov, %const_true) : (i1, i1) -> i1
    %no_ov = "arith.ori"(%no_ov_known, %glob_no_ov) : (i1, i1) -> i1

    %sub0_exact = "transfer.select"(%no_ov, %wr0_ref2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sub1_exact = "transfer.select"(%no_ov, %wr1_ref2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_pos0 = "transfer.select"(%must_pos, %signed_min, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_pos1 = "transfer.select"(%must_pos, %signed_max, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_neg0 = "transfer.select"(%must_neg, %signed_max, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat_neg1 = "transfer.select"(%must_neg, %signed_min, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_pos0_raw = "transfer.and"(%wr0_ref2, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_pos1_raw = "transfer.and"(%wr1_ref2, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_neg0_raw = "transfer.and"(%wr0_ref2, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_neg1_raw = "transfer.and"(%wr1_ref2, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_pos0 = "transfer.select"(%maybe_pos, %mix_pos0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_pos1 = "transfer.select"(%maybe_pos, %mix_pos1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_neg0 = "transfer.select"(%maybe_neg, %mix_neg0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %mix_neg1 = "transfer.select"(%maybe_neg, %mix_neg1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %no_smin_sat = "arith.ori"(%lhs_nonneg, %rhs_neg) : (i1, i1) -> i1
    %no_smax_sat = "arith.ori"(%lhs_neg, %rhs_nonneg) : (i1, i1) -> i1
    %broad_pos1_raw = "transfer.and"(%wr1_ref2, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %broad_neg0_raw = "transfer.and"(%wr0_ref2, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %broad_pos1 = "transfer.select"(%no_smin_sat, %broad_pos1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %broad_neg0 = "transfer.select"(%no_smax_sat, %broad_neg0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // One-unknown-bit enumeration for constant/near-constant cases.
    %e00_sub = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %e00_ov = "transfer.ssub_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_neg = "transfer.cmp"(%lhs1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %e00_sat = "transfer.select"(%lhs1_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %e00 = "transfer.select"(%e00_ov, %e00_sat, %e00_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %e00_not = "transfer.xor"(%e00, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_sub = "transfer.sub"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_ov = "transfer.ssub_overflow"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %g_val1 = "transfer.select"(%g_ov, %e00_sat, %g_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0_raw = "transfer.and"(%e00_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g1_raw = "transfer.and"(%e00, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0 = "transfer.select"(%lhs_const_rhs_one_unknown, %g0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g1 = "transfer.select"(%lhs_const_rhs_one_unknown, %g1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %h_sub1 = "transfer.sub"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_ov1 = "transfer.ssub_overflow"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %h_val1 = "transfer.select"(%h_ov1, %e00_sat, %h_sub1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_sub2 = "transfer.sub"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_ov2 = "transfer.ssub_overflow"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %h_val2 = "transfer.select"(%h_ov2, %e00_sat, %h_sub2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_sub3 = "transfer.sub"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_ov3 = "transfer.ssub_overflow"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %h_val3 = "transfer.select"(%h_ov3, %e00_sat, %h_sub3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_01 = "transfer.and"(%e00_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_raw = "transfer.and"(%h0_01, %h0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_01 = "transfer.and"(%e00, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_raw = "transfer.and"(%h1_01, %h1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0 = "transfer.select"(%lhs_const_rhs_two_unknown, %h0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h1 = "transfer.select"(%lhs_const_rhs_two_unknown, %h1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt_neg = "transfer.cmp"(%lhs_alt, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %i_sat = "transfer.select"(%lhs_alt_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_sub = "transfer.sub"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_ov = "transfer.ssub_overflow"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %i_val1 = "transfer.select"(%i_ov, %i_sat, %i_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0_raw = "transfer.and"(%e00_not, %i_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i1_raw = "transfer.and"(%e00, %i_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0 = "transfer.select"(%rhs_const_lhs_one_unknown, %i0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i1 = "transfer.select"(%rhs_const_lhs_one_unknown, %i1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %j_alt1_neg = "transfer.cmp"(%lhs_alt1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_sat1 = "transfer.select"(%j_alt1_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_sub1 = "transfer.sub"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_ov1 = "transfer.ssub_overflow"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val1 = "transfer.select"(%j_ov1, %j_sat1, %j_sub1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_alt2_neg = "transfer.cmp"(%lhs_alt2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_sat2 = "transfer.select"(%j_alt2_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_sub2 = "transfer.sub"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_ov2 = "transfer.ssub_overflow"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val2 = "transfer.select"(%j_ov2, %j_sat2, %j_sub2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_alt3_neg = "transfer.cmp"(%lhs_alt3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_sat3 = "transfer.select"(%j_alt3_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_sub3 = "transfer.sub"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_ov3 = "transfer.ssub_overflow"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val3 = "transfer.select"(%j_ov3, %j_sat3, %j_sub3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_01 = "transfer.and"(%e00_not, %j_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_23 = "transfer.and"(%j_val2_not, %j_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_raw = "transfer.and"(%j0_01, %j0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_01 = "transfer.and"(%e00, %j_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_23 = "transfer.and"(%j_val2, %j_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_raw = "transfer.and"(%j1_01, %j1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0 = "transfer.select"(%rhs_const_lhs_two_unknown, %j0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j1 = "transfer.select"(%rhs_const_lhs_two_unknown, %j1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %n_sub = "transfer.sub"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_ov = "transfer.ssub_overflow"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %n_val11 = "transfer.select"(%n_ov, %i_sat, %n_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val11_not = "transfer.xor"(%n_val11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_01 = "transfer.and"(%e00_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_23 = "transfer.and"(%i_val1_not, %n_val11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_raw = "transfer.and"(%n0_01, %n0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_01 = "transfer.and"(%e00, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_23 = "transfer.and"(%i_val1, %n_val11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_raw = "transfer.and"(%n1_01, %n1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0 = "transfer.select"(%lhs_rhs_one_one, %n0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n1 = "transfer.select"(%lhs_rhs_one_one, %n1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // One/two and two/two unknown enumeration.
    %p11_sub = "transfer.sub"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_ov = "transfer.ssub_overflow"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %p11 = "transfer.select"(%p11_ov, %i_sat, %p11_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_sub = "transfer.sub"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_ov = "transfer.ssub_overflow"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %p12 = "transfer.select"(%p12_ov, %i_sat, %p12_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_sub = "transfer.sub"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_ov = "transfer.ssub_overflow"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %p13 = "transfer.select"(%p13_ov, %i_sat, %p13_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_not = "transfer.xor"(%p11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_not = "transfer.xor"(%p12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_not = "transfer.xor"(%p13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_01 = "transfer.and"(%e00_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_45 = "transfer.and"(%i_val1_not, %p11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_67 = "transfer.and"(%p12_not, %p13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_0123 = "transfer.and"(%p0_01, %p0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_4567 = "transfer.and"(%p0_45, %p0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_raw = "transfer.and"(%p0_0123, %p0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_01 = "transfer.and"(%e00, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_45 = "transfer.and"(%i_val1, %p11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_67 = "transfer.and"(%p12, %p13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_0123 = "transfer.and"(%p1_01, %p1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_4567 = "transfer.and"(%p1_45, %p1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_raw = "transfer.and"(%p1_0123, %p1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0 = "transfer.select"(%lhs_rhs_one_two, %p0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p1 = "transfer.select"(%lhs_rhs_one_two, %p1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %q11_sub = "transfer.sub"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q11_ov = "transfer.ssub_overflow"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q11 = "transfer.select"(%q11_ov, %j_sat1, %q11_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_sub = "transfer.sub"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_ov = "transfer.ssub_overflow"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q12 = "transfer.select"(%q12_ov, %j_sat2, %q12_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_sub = "transfer.sub"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_ov = "transfer.ssub_overflow"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q13 = "transfer.select"(%q13_ov, %j_sat3, %q13_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q11_not = "transfer.xor"(%q11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_not = "transfer.xor"(%q12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_not = "transfer.xor"(%q13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_01 = "transfer.and"(%e00_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_23 = "transfer.and"(%j_val1_not, %j_val2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_45 = "transfer.and"(%j_val3_not, %q11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_67 = "transfer.and"(%q12_not, %q13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_0123 = "transfer.and"(%q0_01, %q0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_4567 = "transfer.and"(%q0_45, %q0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_raw = "transfer.and"(%q0_0123, %q0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_01 = "transfer.and"(%e00, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_23 = "transfer.and"(%j_val1, %j_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_45 = "transfer.and"(%j_val3, %q11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_67 = "transfer.and"(%q12, %q13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_0123 = "transfer.and"(%q1_01, %q1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_4567 = "transfer.and"(%q1_45, %q1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_raw = "transfer.and"(%q1_0123, %q1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0 = "transfer.select"(%lhs_rhs_two_one, %q0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q1 = "transfer.select"(%lhs_rhs_two_one, %q1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r21_sub = "transfer.sub"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_ov = "transfer.ssub_overflow"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r21 = "transfer.select"(%r21_ov, %j_sat2, %r21_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_sub = "transfer.sub"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_ov = "transfer.ssub_overflow"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r22 = "transfer.select"(%r22_ov, %j_sat2, %r22_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_sub = "transfer.sub"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_ov = "transfer.ssub_overflow"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r23 = "transfer.select"(%r23_ov, %j_sat2, %r23_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_sub = "transfer.sub"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_ov = "transfer.ssub_overflow"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r31 = "transfer.select"(%r31_ov, %j_sat3, %r31_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_sub = "transfer.sub"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_ov = "transfer.ssub_overflow"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r32 = "transfer.select"(%r32_ov, %j_sat3, %r32_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_sub = "transfer.sub"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_ov = "transfer.ssub_overflow"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r33 = "transfer.select"(%r33_ov, %j_sat3, %r33_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_not = "transfer.xor"(%r21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_not = "transfer.xor"(%r22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_not = "transfer.xor"(%r23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_not = "transfer.xor"(%r31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_not = "transfer.xor"(%r32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_not = "transfer.xor"(%r33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_01 = "transfer.and"(%e00_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_45 = "transfer.and"(%j_val1_not, %p11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_67 = "transfer.and"(%p12_not, %p13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_89 = "transfer.and"(%j_val2_not, %r21_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1011 = "transfer.and"(%r22_not, %r23_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1213 = "transfer.and"(%j_val3_not, %r31_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1415 = "transfer.and"(%r32_not, %r33_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0123 = "transfer.and"(%r0_01, %r0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_4567 = "transfer.and"(%r0_45, %r0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_891011 = "transfer.and"(%r0_89, %r0_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_12131415 = "transfer.and"(%r0_1213, %r0_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0to7 = "transfer.and"(%r0_0123, %r0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_8to15 = "transfer.and"(%r0_891011, %r0_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_raw = "transfer.and"(%r0_0to7, %r0_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_01 = "transfer.and"(%e00, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
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

    // Signed endpoint refinement: [sat_sub(smin(lhs), smax(rhs)), sat_sub(smax(lhs), smin(rhs))].
    %lhs_sign_can_be_one = "transfer.and"(%lhs_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_can_be_one = "transfer.and"(%rhs_max, %signed_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smin = "transfer.or"(%lhs1, %lhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smin = "transfer.or"(%rhs1, %rhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_max = "transfer.and"(%lhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_upper_max = "transfer.and"(%rhs_max, %signed_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smax = "transfer.or"(%lhs_upper_max, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smax = "transfer.or"(%rhs_upper_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_min_sub = "transfer.sub"(%lhs_smin, %rhs_smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_min_ov = "transfer.ssub_overflow"(%lhs_smin, %rhs_smax) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_smin_neg = "transfer.cmp"(%lhs_smin, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_min_sat = "transfer.select"(%lhs_smin_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_min_val = "transfer.select"(%range_min_ov, %range_min_sat, %range_min_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_max_sub = "transfer.sub"(%lhs_smax, %rhs_smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_max_ov = "transfer.ssub_overflow"(%lhs_smax, %rhs_smin) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_smax_neg = "transfer.cmp"(%lhs_smax, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_max_sat = "transfer.select"(%lhs_smax_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_max_val = "transfer.select"(%range_max_ov, %range_max_sat, %range_max_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_diff = "transfer.xor"(%range_min_val, %range_max_val) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%range_diff) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_min_not = "transfer.xor"(%range_min_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range0 = "transfer.and"(%range_min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1 = "transfer.and"(%range_min_val, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_min_nonneg = "transfer.cmp"(%range_min_val, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_max_neg = "transfer.cmp"(%range_max_val, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_sign0 = "transfer.select"(%range_min_nonneg, %signed_min, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_sign1 = "transfer.select"(%range_max_neg, %signed_min, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range0_ext = "transfer.or"(%range0, %range_sign0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1_ext = "transfer.or"(%range1, %range_sign1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Mixed-sign class-local endpoint refinement.
    %pos_min_sub = "transfer.sub"(%lhs_nonneg_min, %rhs_neg_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_min_val = "transfer.select"(%ov_pos_min, %signed_max, %pos_min_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_max_sub = "transfer.sub"(%lhs_nonneg_max, %rhs_neg_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_max_val = "transfer.select"(%ov_pos_max, %signed_max, %pos_max_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_diff = "transfer.xor"(%pos_min_val, %pos_max_val) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_lz = "transfer.countl_zero"(%pos_diff) : (!transfer.integer) -> !transfer.integer
    %pos_inv = "transfer.sub"(%bitwidth, %pos_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_mask = "transfer.shl"(%all_ones, %pos_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_min_not = "transfer.xor"(%pos_min_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos0_raw = "transfer.and"(%pos_min_not, %pos_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos1_raw = "transfer.and"(%pos_min_val, %pos_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos0 = "transfer.select"(%mixed_pos, %pos0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pos1 = "transfer.select"(%mixed_pos, %pos1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_min_sub = "transfer.sub"(%lhs_neg_min, %rhs_nonneg_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_min_val = "transfer.select"(%ov_neg_min, %signed_min, %neg_min_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_max_sub = "transfer.sub"(%lhs_neg_max, %rhs_nonneg_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_max_val = "transfer.select"(%ov_neg_max, %signed_min, %neg_max_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_diff = "transfer.xor"(%neg_min_val, %neg_max_val) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_lz = "transfer.countl_zero"(%neg_diff) : (!transfer.integer) -> !transfer.integer
    %neg_inv = "transfer.sub"(%bitwidth, %neg_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_mask = "transfer.shl"(%all_ones, %neg_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_min_not = "transfer.xor"(%neg_min_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg0_raw = "transfer.and"(%neg_min_not, %neg_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg1_raw = "transfer.and"(%neg_min_val, %neg_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg0 = "transfer.select"(%mixed_neg, %neg0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %neg1 = "transfer.select"(%mixed_neg, %neg1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %base00 = "transfer.or"(%id_res0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base01 = "transfer.or"(%base00, %sub0_exact) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base02 = "transfer.or"(%base01, %sat_pos0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base03 = "transfer.or"(%base02, %sat_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base04 = "transfer.or"(%base03, %mix_pos0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base05 = "transfer.or"(%base04, %mix_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base06 = "transfer.or"(%base05, %broad_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base060 = "transfer.or"(%base06, %g0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base07 = "transfer.or"(%base060, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base08 = "transfer.or"(%base07, %i0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base09 = "transfer.or"(%base08, %j0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base010 = "transfer.or"(%base09, %n0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base011 = "transfer.or"(%base010, %p0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base012 = "transfer.or"(%base011, %q0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base013 = "transfer.or"(%base012, %r0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base014 = "transfer.or"(%base013, %range0_ext) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base015 = "transfer.or"(%base014, %pos0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base0 = "transfer.or"(%base015, %neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base10 = "transfer.or"(%id_res1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base11 = "transfer.or"(%base10, %sub1_exact) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base12 = "transfer.or"(%base11, %sat_pos1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base13 = "transfer.or"(%base12, %sat_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base14 = "transfer.or"(%base13, %mix_pos1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base15 = "transfer.or"(%base14, %mix_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base16 = "transfer.or"(%base15, %broad_pos1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base160 = "transfer.or"(%base16, %g1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base17 = "transfer.or"(%base160, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base18 = "transfer.or"(%base17, %i1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base19 = "transfer.or"(%base18, %j1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base110 = "transfer.or"(%base19, %n1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base111 = "transfer.or"(%base110, %p1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base112 = "transfer.or"(%base111, %q1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base113 = "transfer.or"(%base112, %r1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base114 = "transfer.or"(%base113, %range1_ext) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base115 = "transfer.or"(%base114, %pos1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base1 = "transfer.or"(%base115, %neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_sub = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_ov = "transfer.ssub_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_neg = "transfer.cmp"(%lhs1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_sat = "transfer.select"(%lhs_const_neg, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.select"(%const_ov, %const_sat, %const_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %const_res0, %base0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_res1, %base1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ssubsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
