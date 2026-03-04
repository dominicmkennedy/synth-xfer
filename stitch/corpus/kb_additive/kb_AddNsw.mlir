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
    %res0 = "transfer.or"(%res0_with_min, %nsw_zero_from_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%res1_with_min, %nsw_one_from_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_addnsw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
