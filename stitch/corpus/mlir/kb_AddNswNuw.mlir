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
    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sum_min = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_plus_rhs = "transfer.add"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %min_and = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or = "transfer.or"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_min_not = "transfer.xor"(%sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or_and_sum_not = "transfer.and"(%min_or, %sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_min = "transfer.or"(%min_and, %min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %max_and = "transfer.and"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or = "transfer.or"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max_not = "transfer.add"(%lhs_plus_rhs, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or_and_sum_not = "transfer.and"(%max_or, %sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_max = "transfer.or"(%max_and, %max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %carry_one = "transfer.shl"(%carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_may_one = "transfer.shl"(%carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_zero = "transfer.xor"(%carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %xor0_lhs_rhs_00 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_01 = "transfer.and"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_10 = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_0 = "transfer.or"(%xor0_lhs_rhs_00, %min_and) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_1 = "transfer.or"(%xor1_lhs_rhs_01, %xor1_lhs_rhs_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %xor0_sum_carry_00 = "transfer.and"(%xor_lhs_rhs_0, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_sum_carry_11 = "transfer.and"(%xor_lhs_rhs_1, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_01 = "transfer.and"(%xor_lhs_rhs_0, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_10 = "transfer.and"(%xor_lhs_rhs_1, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base_res0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base_res1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_sign_can_be_one = "transfer.and"(%lhs_max, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_can_be_one = "transfer.and"(%rhs_max, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smin = "transfer.or"(%lhs1, %lhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smin = "transfer.or"(%rhs1, %rhs_sign_can_be_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_upper_max = "transfer.and"(%lhs_max, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_upper_max = "transfer.and"(%rhs_max, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smax = "transfer.or"(%lhs_upper_max, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smax = "transfer.or"(%rhs_upper_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %smin_sum = "transfer.add"(%lhs_smin, %rhs_smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %smin_ov = "transfer.sadd_overflow"(%lhs_smin, %rhs_smin) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_smin_is_neg = "transfer.cmp"(%lhs_smin, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %smin_sat = "transfer.select"(%lhs_smin_is_neg, %smin, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw_min_val = "transfer.select"(%smin_ov, %smin_sat, %smin_sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %smax_sum = "transfer.add"(%lhs_smax, %rhs_smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %smax_ov = "transfer.sadd_overflow"(%lhs_smax, %rhs_smax) : (!transfer.integer, !transfer.integer) -> i1
    %lhs_smax_is_neg = "transfer.cmp"(%lhs1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %smax_sat = "transfer.select"(%lhs_smax_is_neg, %smin, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw_max_val = "transfer.select"(%smax_ov, %smax_sat, %smax_sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %min_non_neg = "transfer.cmp"(%nsw_min_val, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %max_is_neg = "transfer.cmp"(%nsw_max_val, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %min_shifted = "transfer.shl"(%nsw_min_val, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_leading_ones = "transfer.countl_one"(%min_shifted) : (!transfer.integer) -> !transfer.integer
    %min_shift_amt = "transfer.sub"(%bw_minus_1, %min_leading_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_high_mask = "transfer.shl"(%all_ones, %min_shift_amt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_ones_no_sign = "transfer.and"(%min_high_mask, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %max_shifted = "transfer.shl"(%nsw_max_val, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_leading_zeros = "transfer.countl_zero"(%max_shifted) : (!transfer.integer) -> !transfer.integer
    %max_shift_amt = "transfer.sub"(%bw_minus_1, %max_leading_zeros) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_high_mask = "transfer.shl"(%all_ones, %max_shift_amt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_zeros_no_sign = "transfer.and"(%max_high_mask, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %nsw_zero_from_min = "transfer.select"(%min_non_neg, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw_one_from_min = "transfer.select"(%min_non_neg, %min_ones_no_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw_zero_from_max = "transfer.select"(%max_is_neg, %max_zeros_no_sign, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw_one_from_max = "transfer.and"(%nsw_max_val, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_with_min = "transfer.or"(%base_res0, %nsw_zero_from_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_with_min = "transfer.or"(%base_res1, %nsw_one_from_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_nsw = "transfer.or"(%res0_with_min, %nsw_zero_from_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nsw = "transfer.or"(%res1_with_min, %nsw_one_from_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %lhs_sign_zero = "transfer.and"(%lhs0, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_zero = "transfer.and"(%rhs0, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one = "transfer.and"(%lhs1, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_one = "transfer.and"(%rhs1, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg_known = "transfer.cmp"(%lhs_sign_zero, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_known = "transfer.cmp"(%rhs_sign_zero, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_known = "transfer.cmp"(%lhs_sign_one, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_known = "transfer.cmp"(%rhs_sign_one, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %both_nonneg_known = "arith.andi"(%lhs_nonneg_known, %rhs_nonneg_known) : (i1, i1) -> i1
    %lhs_neg_rhs_nonneg = "arith.andi"(%lhs_neg_known, %rhs_nonneg_known) : (i1, i1) -> i1
    %lhs_nonneg_rhs_neg = "arith.andi"(%lhs_nonneg_known, %rhs_neg_known) : (i1, i1) -> i1
    %mixed_sign_known = "arith.ori"(%lhs_neg_rhs_nonneg, %lhs_nonneg_rhs_neg) : (i1, i1) -> i1

    %nuw_sign_zero_mask = "transfer.select"(%both_nonneg_known, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_sign_one_mask = "transfer.select"(%mixed_sign_known, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_sign_one_clear = "transfer.xor"(%nuw_sign_one_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_sign_zero_clear = "transfer.xor"(%nuw_sign_zero_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_nuw_base = "transfer.and"(%res0_nsw, %nuw_sign_one_clear) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nuw_base = "transfer.and"(%res1_nsw, %nuw_sign_zero_clear) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_nuw = "transfer.or"(%res0_nuw_base, %nuw_sign_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nuw = "transfer.or"(%res1_nuw_base, %nuw_sign_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sign_minus_1 = "transfer.lshr"(%all_ones, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg_exists = "transfer.cmp"(%lhs1, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs1, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_upper = "transfer.umin"(%lhs_max, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.umin"(%rhs_max, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%sign_bit, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%sign_bit, %rhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_lower = "transfer.umax"(%lhs1, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.umax"(%rhs1, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %case_a_lower = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_upper_raw = "transfer.add"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_upper = "transfer.umin"(%case_a_upper_raw, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %case_a_lower_ok = "transfer.cmp"(%case_a_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %case_a_exists = "arith.andi"(%case_a_exists_0, %case_a_lower_ok) : (i1, i1) -> i1

    %case_b_lower = "transfer.add"(%lhs_neg_lower, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_upper_raw = "transfer.add"(%lhs_max, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_upper_ov = "transfer.uadd_overflow"(%lhs_max, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> i1
    %case_b_upper = "transfer.select"(%case_b_upper_ov, %all_ones, %case_b_upper_raw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %case_b_lower_ov = "transfer.uadd_overflow"(%lhs_neg_lower, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %case_b_lower_ok = "arith.xori"(%case_b_lower_ov, %const_true) : (i1, i1) -> i1
    %case_b_exists = "arith.andi"(%case_b_exists_0, %case_b_lower_ok) : (i1, i1) -> i1

    %case_c_lower = "transfer.add"(%lhs1, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_upper_raw = "transfer.add"(%lhs_nonneg_upper, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_upper_ov = "transfer.uadd_overflow"(%lhs_nonneg_upper, %rhs_max) : (!transfer.integer, !transfer.integer) -> i1
    %case_c_upper = "transfer.select"(%case_c_upper_ov, %all_ones, %case_c_upper_raw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %case_c_lower_ov = "transfer.uadd_overflow"(%lhs1, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> i1
    %case_c_lower_ok = "arith.xori"(%case_c_lower_ov, %const_true) : (i1, i1) -> i1
    %case_c_exists = "arith.andi"(%case_c_exists_0, %case_c_lower_ok) : (i1, i1) -> i1

    %case_a_diff = "transfer.xor"(%case_a_lower, %case_a_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_lz = "transfer.countl_zero"(%case_a_diff) : (!transfer.integer) -> !transfer.integer
    %case_a_shift = "transfer.sub"(%bitwidth, %case_a_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_mask = "transfer.shl"(%all_ones, %case_a_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_not_low = "transfer.xor"(%case_a_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_k0 = "transfer.and"(%case_a_not_low, %case_a_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_k1 = "transfer.and"(%case_a_lower, %case_a_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %case_b_diff = "transfer.xor"(%case_b_lower, %case_b_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_lz = "transfer.countl_zero"(%case_b_diff) : (!transfer.integer) -> !transfer.integer
    %case_b_shift = "transfer.sub"(%bitwidth, %case_b_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_mask = "transfer.shl"(%all_ones, %case_b_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_not_low = "transfer.xor"(%case_b_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_k0 = "transfer.and"(%case_b_not_low, %case_b_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_k1 = "transfer.and"(%case_b_lower, %case_b_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %case_c_diff = "transfer.xor"(%case_c_lower, %case_c_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_lz = "transfer.countl_zero"(%case_c_diff) : (!transfer.integer) -> !transfer.integer
    %case_c_shift = "transfer.sub"(%bitwidth, %case_c_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_mask = "transfer.shl"(%all_ones, %case_c_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_not_low = "transfer.xor"(%case_c_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_k0 = "transfer.and"(%case_c_not_low, %case_c_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_k1 = "transfer.and"(%case_c_lower, %case_c_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %case_a_k0_or_top = "transfer.select"(%case_a_exists, %case_a_k0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_k1_or_top = "transfer.select"(%case_a_exists, %case_a_k1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_k0_or_top = "transfer.select"(%case_b_exists, %case_b_k0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_k1_or_top = "transfer.select"(%case_b_exists, %case_b_k1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_k0_or_top = "transfer.select"(%case_c_exists, %case_c_k0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_k1_or_top = "transfer.select"(%case_c_exists, %case_c_k1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_ab_k0 = "transfer.and"(%case_a_k0_or_top, %case_b_k0_or_top) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_ab_k1 = "transfer.and"(%case_a_k1_or_top, %case_b_k1_or_top) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_k0 = "transfer.and"(%case_ab_k0, %case_c_k0_or_top) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_k1 = "transfer.and"(%case_ab_k1, %case_c_k1_or_top) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %exists_ab = "arith.ori"(%case_a_exists, %case_b_exists) : (i1, i1) -> i1
    %exists_any = "arith.ori"(%exists_ab, %case_c_exists) : (i1, i1) -> i1
    %res0_cases = "transfer.or"(%res0_nuw, %case_k0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_cases = "transfer.or"(%res1_nuw, %case_k1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%exists_any, %res0_cases, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%exists_any, %res1_cases, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_min_sum2 = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_min_ov2 = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %nuw_min_sat2 = "transfer.select"(%nuw_min_ov2, %all_ones, %nuw_min_sum2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_full_l1 = "transfer.countl_one"(%nuw_min_sat2) : (!transfer.integer) -> !transfer.integer
    %nuw_full_shift = "transfer.sub"(%bitwidth, %nuw_full_l1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_full_mask = "transfer.shl"(%all_ones, %nuw_full_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_shifted = "transfer.shl"(%nuw_min_sat2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_l1_no_sign = "transfer.countl_one"(%nuw_shifted) : (!transfer.integer) -> !transfer.integer
    %nuw_shift_no_sign = "transfer.sub"(%bw_minus_1, %nuw_l1_no_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_mask_no_sign_raw = "transfer.shl"(%all_ones, %nuw_shift_no_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_mask_no_sign = "transfer.and"(%nuw_mask_no_sign_raw, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_extra_ones = "transfer.or"(%nuw_full_mask, %nuw_mask_no_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res1_final = "transfer.or"(%res1, %nuw_extra_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_addnswnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
