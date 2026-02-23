"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const1_not = "transfer.xor"(%const1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %n_rhs_a_max = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_b_max = "transfer.xor"(%const1_not, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum_min = "transfer.add"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum_max = "transfer.add"(%n_rhs_a_max, %n_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min_and = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min_or = "transfer.or"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum_min_not = "transfer.xor"(%n_rhs_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min_or_and_sum_not = "transfer.and"(%n_rhs_min_or, %n_rhs_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry_out_min = "transfer.or"(%n_rhs_min_and, %n_rhs_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max_and = "transfer.and"(%n_rhs_a_max, %n_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max_or = "transfer.or"(%n_rhs_a_max, %n_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum_max_not = "transfer.xor"(%n_rhs_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max_or_and_sum_not = "transfer.and"(%n_rhs_max_or, %n_rhs_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry_out_max = "transfer.or"(%n_rhs_max_and, %n_rhs_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry_one = "transfer.shl"(%n_rhs_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry_may_one = "transfer.shl"(%n_rhs_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry_zero = "transfer.xor"(%n_rhs_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor0_ab_00 = "transfer.and"(%rhs1, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor0_ab_11 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor1_ab_01 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor1_ab_10 = "transfer.and"(%rhs0, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor_ab_0 = "transfer.or"(%n_rhs_xor0_ab_00, %n_rhs_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor_ab_1 = "transfer.or"(%n_rhs_xor1_ab_01, %n_rhs_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor0_sum_carry_00 = "transfer.and"(%n_rhs_xor_ab_0, %n_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor0_sum_carry_11 = "transfer.and"(%n_rhs_xor_ab_1, %n_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor1_sum_carry_01 = "transfer.and"(%n_rhs_xor_ab_0, %n_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor1_sum_carry_10 = "transfer.and"(%n_rhs_xor_ab_1, %n_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg0 = "transfer.or"(%n_rhs_xor0_sum_carry_00, %n_rhs_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg1 = "transfer.or"(%n_rhs_xor1_sum_carry_01, %n_rhs_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %n_lhs_a_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_b_max = "transfer.xor"(%rhs_neg0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_sum_min = "transfer.add"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_sum_max = "transfer.add"(%n_lhs_a_max, %n_lhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_min_and = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_min_or = "transfer.or"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_sum_min_not = "transfer.xor"(%n_lhs_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_min_or_and_sum_not = "transfer.and"(%n_lhs_min_or, %n_lhs_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_carry_out_min = "transfer.or"(%n_lhs_min_and, %n_lhs_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_max_and = "transfer.and"(%n_lhs_a_max, %n_lhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_max_or = "transfer.or"(%n_lhs_a_max, %n_lhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_sum_max_not = "transfer.xor"(%n_lhs_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_max_or_and_sum_not = "transfer.and"(%n_lhs_max_or, %n_lhs_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_carry_out_max = "transfer.or"(%n_lhs_max_and, %n_lhs_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_carry_one = "transfer.shl"(%n_lhs_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_carry_may_one = "transfer.shl"(%n_lhs_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_carry_zero = "transfer.xor"(%n_lhs_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor0_ab_00 = "transfer.and"(%lhs0, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor0_ab_11 = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor1_ab_01 = "transfer.and"(%lhs0, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor1_ab_10 = "transfer.and"(%lhs1, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor_ab_0 = "transfer.or"(%n_lhs_xor0_ab_00, %n_lhs_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor_ab_1 = "transfer.or"(%n_lhs_xor1_ab_01, %n_lhs_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor0_sum_carry_00 = "transfer.and"(%n_lhs_xor_ab_0, %n_lhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor0_sum_carry_11 = "transfer.and"(%n_lhs_xor_ab_1, %n_lhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor1_sum_carry_01 = "transfer.and"(%n_lhs_xor_ab_0, %n_lhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhs_xor1_sum_carry_10 = "transfer.and"(%n_lhs_xor_ab_1, %n_lhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr0 = "transfer.or"(%n_lhs_xor0_sum_carry_00, %n_lhs_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr1 = "transfer.or"(%n_lhs_xor1_sum_carry_01, %n_lhs_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %n_lhsn_a_max = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_b_max = "transfer.xor"(%const1_not, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_sum_min = "transfer.add"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_sum_max = "transfer.add"(%n_lhsn_a_max, %n_lhsn_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_min_and = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_min_or = "transfer.or"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_sum_min_not = "transfer.xor"(%n_lhsn_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_min_or_and_sum_not = "transfer.and"(%n_lhsn_min_or, %n_lhsn_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_carry_out_min = "transfer.or"(%n_lhsn_min_and, %n_lhsn_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_max_and = "transfer.and"(%n_lhsn_a_max, %n_lhsn_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_max_or = "transfer.or"(%n_lhsn_a_max, %n_lhsn_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_sum_max_not = "transfer.xor"(%n_lhsn_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_max_or_and_sum_not = "transfer.and"(%n_lhsn_max_or, %n_lhsn_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_carry_out_max = "transfer.or"(%n_lhsn_max_and, %n_lhsn_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_carry_one = "transfer.shl"(%n_lhsn_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_carry_may_one = "transfer.shl"(%n_lhsn_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_carry_zero = "transfer.xor"(%n_lhsn_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor0_ab_00 = "transfer.and"(%lhs1, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor0_ab_11 = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor1_ab_01 = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor1_ab_10 = "transfer.and"(%lhs0, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor_ab_0 = "transfer.or"(%n_lhsn_xor0_ab_00, %n_lhsn_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor_ab_1 = "transfer.or"(%n_lhsn_xor1_ab_01, %n_lhsn_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor0_sum_carry_00 = "transfer.and"(%n_lhsn_xor_ab_0, %n_lhsn_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor0_sum_carry_11 = "transfer.and"(%n_lhsn_xor_ab_1, %n_lhsn_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor1_sum_carry_01 = "transfer.and"(%n_lhsn_xor_ab_0, %n_lhsn_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_lhsn_xor1_sum_carry_10 = "transfer.and"(%n_lhsn_xor_ab_1, %n_lhsn_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_neg0 = "transfer.or"(%n_lhsn_xor0_sum_carry_00, %n_lhsn_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_neg1 = "transfer.or"(%n_lhsn_xor1_sum_carry_01, %n_lhsn_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %n_rhs_a2_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_b2_max = "transfer.xor"(%lhs_neg0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum2_min = "transfer.add"(%rhs1, %lhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum2_max = "transfer.add"(%n_rhs_a2_max, %n_rhs_b2_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min2_and = "transfer.and"(%rhs1, %lhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min2_or = "transfer.or"(%rhs1, %lhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum2_min_not = "transfer.xor"(%n_rhs_sum2_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_min2_or_and_sum_not = "transfer.and"(%n_rhs_min2_or, %n_rhs_sum2_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry2_out_min = "transfer.or"(%n_rhs_min2_and, %n_rhs_min2_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max2_and = "transfer.and"(%n_rhs_a2_max, %n_rhs_b2_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max2_or = "transfer.or"(%n_rhs_a2_max, %n_rhs_b2_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_sum2_max_not = "transfer.xor"(%n_rhs_sum2_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_max2_or_and_sum_not = "transfer.and"(%n_rhs_max2_or, %n_rhs_sum2_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry2_out_max = "transfer.or"(%n_rhs_max2_and, %n_rhs_max2_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry2_one = "transfer.shl"(%n_rhs_carry2_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry2_may_one = "transfer.shl"(%n_rhs_carry2_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_carry2_zero = "transfer.xor"(%n_rhs_carry2_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_ab_00 = "transfer.and"(%rhs0, %lhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_ab_11 = "transfer.and"(%rhs1, %lhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_ab_01 = "transfer.and"(%rhs0, %lhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_ab_10 = "transfer.and"(%rhs1, %lhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_0 = "transfer.or"(%n_rhs_xor2_ab_00, %n_rhs_xor2_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_1 = "transfer.or"(%n_rhs_xor2_ab_01, %n_rhs_xor2_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_sum_carry_00 = "transfer.and"(%n_rhs_xor2_0, %n_rhs_carry2_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_sum_carry_11 = "transfer.and"(%n_rhs_xor2_1, %n_rhs_carry2_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_sum_carry_01 = "transfer.and"(%n_rhs_xor2_0, %n_rhs_carry2_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_rhs_xor2_sum_carry_10 = "transfer.and"(%n_rhs_xor2_1, %n_rhs_carry2_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_rl0 = "transfer.or"(%n_rhs_xor2_sum_carry_00, %n_rhs_xor2_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_rl1 = "transfer.or"(%n_rhs_xor2_sum_carry_01, %n_rhs_xor2_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %join0 = "transfer.and"(%sub_lr0, %sub_rl0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %join1 = "transfer.and"(%sub_lr1, %sub_rl1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_smin_sign = "transfer.and"(%lhs_max, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smin = "transfer.or"(%lhs1, %lhs_smin_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_max = "transfer.and"(%lhs_max, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_smax = "transfer.or"(%lhs_upper_max, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_smin_sign = "transfer.and"(%rhs_max, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smin = "transfer.or"(%rhs1, %rhs_smin_sign) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_upper_max = "transfer.and"(%rhs_max, %smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_smax = "transfer.or"(%rhs_upper_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_ge_rhs_always = "transfer.cmp"(%lhs_smin, %rhs_smax) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lt_rhs_always = "transfer.cmp"(%lhs_smax, %rhs_smin) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %res0_uncertain = "transfer.select"(%lhs_lt_rhs_always, %sub_rl0, %join0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_uncertain = "transfer.select"(%lhs_lt_rhs_always, %sub_rl1, %join1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_nonconst = "transfer.select"(%lhs_ge_rhs_always, %sub_lr0, %res0_uncertain) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%lhs_ge_rhs_always, %sub_lr1, %res1_uncertain) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_sign_zero = "transfer.and"(%lhs0, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_zero = "transfer.and"(%rhs0, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one = "transfer.and"(%lhs1, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_one = "transfer.and"(%rhs1, %smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg_known = "transfer.cmp"(%lhs_sign_zero, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_known = "transfer.cmp"(%rhs_sign_zero, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_known = "transfer.cmp"(%lhs_sign_one, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_known = "transfer.cmp"(%rhs_sign_one, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_nonneg_known = "arith.andi"(%lhs_nonneg_known, %rhs_nonneg_known) : (i1, i1) -> i1
    %both_neg_known = "arith.andi"(%lhs_neg_known, %rhs_neg_known) : (i1, i1) -> i1
    %same_sign_known = "arith.ori"(%both_nonneg_known, %both_neg_known) : (i1, i1) -> i1
    %same_sign_nonneg_mask = "transfer.select"(%same_sign_known, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg_rhs_neg = "arith.andi"(%lhs_nonneg_known, %rhs_neg_known) : (i1, i1) -> i1
    %lr_min_ov = "transfer.ssub_overflow"(%lhs_smin, %rhs_smax) : (!transfer.integer, !transfer.integer) -> i1
    %lr_max_ov = "transfer.ssub_overflow"(%lhs_smax, %rhs_smin) : (!transfer.integer, !transfer.integer) -> i1
    %lr_sign_zero_pre = "transfer.select"(%lr_max_ov, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lr_sign_zero_mask = "transfer.select"(%lhs_nonneg_rhs_neg, %lr_sign_zero_pre, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lr_sign_one_pre = "transfer.select"(%lr_min_ov, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lr_sign_one_mask = "transfer.select"(%lhs_nonneg_rhs_neg, %lr_sign_one_pre, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_rhs_nonneg = "arith.andi"(%lhs_neg_known, %rhs_nonneg_known) : (i1, i1) -> i1
    %rl_min_ov = "transfer.ssub_overflow"(%rhs_smin, %lhs_smax) : (!transfer.integer, !transfer.integer) -> i1
    %rl_max_ov = "transfer.ssub_overflow"(%rhs_smax, %lhs_smin) : (!transfer.integer, !transfer.integer) -> i1
    %rl_sign_zero_pre = "transfer.select"(%rl_max_ov, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rl_sign_zero_mask = "transfer.select"(%lhs_neg_rhs_nonneg, %rl_sign_zero_pre, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rl_sign_one_pre = "transfer.select"(%rl_min_ov, %smin, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rl_sign_one_mask = "transfer.select"(%lhs_neg_rhs_nonneg, %rl_sign_one_pre, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %sign_zero_mask_a = "transfer.or"(%same_sign_nonneg_mask, %lr_sign_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_zero_mask = "transfer.or"(%sign_zero_mask_a, %rl_sign_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_one_mask = "transfer.or"(%lr_sign_one_mask, %rl_sign_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sign_one_clear_mask = "transfer.xor"(%sign_one_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_zero_clear_mask = "transfer.xor"(%sign_zero_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_sign_base = "transfer.and"(%res0_nonconst, %sign_one_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_sign_base = "transfer.and"(%res1_nonconst, %sign_zero_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_signed = "transfer.or"(%res0_sign_base, %sign_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_signed = "transfer.or"(%res1_sign_base, %sign_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %same_diff1_ge = "transfer.cmp"(%lhs_smin, %rhs_smax) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %same_diff1_ab = "transfer.sub"(%lhs_smin, %rhs_smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_diff1_ba = "transfer.sub"(%rhs_smax, %lhs_smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_diff1 = "transfer.select"(%same_diff1_ge, %same_diff1_ab, %same_diff1_ba) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %same_diff2_ge = "transfer.cmp"(%lhs_smax, %rhs_smin) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %same_diff2_ab = "transfer.sub"(%lhs_smax, %rhs_smin) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_diff2_ba = "transfer.sub"(%rhs_smin, %lhs_smax) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_diff2 = "transfer.select"(%same_diff2_ge, %same_diff2_ab, %same_diff2_ba) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %same_sign_ub = "transfer.umax"(%same_diff1, %same_diff2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %same_sign_ub_lz = "transfer.countl_zero"(%same_sign_ub) : (!transfer.integer) -> !transfer.integer
    %same_sign_shift = "transfer.sub"(%bitwidth, %same_sign_ub_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_sign_high_zero = "transfer.shl"(%all_ones, %same_sign_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %same_sign_high_zero_mask = "transfer.select"(%same_sign_known, %same_sign_high_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %same_sign_high_zero_clear = "transfer.xor"(%same_sign_high_zero_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_same_sign = "transfer.or"(%res0_signed, %same_sign_high_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_same_sign = "transfer.and"(%res1_signed, %same_sign_high_zero_clear) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_low0 = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low1 = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_low0 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_low1 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero_eq00 = "transfer.and"(%lhs_low0, %rhs_low0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero_eq11 = "transfer.and"(%lhs_low1, %rhs_low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_neq01 = "transfer.and"(%lhs_low0, %rhs_low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_neq10 = "transfer.and"(%lhs_low1, %rhs_low0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero_mask = "transfer.or"(%lsb_zero_eq00, %lsb_zero_eq11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_mask = "transfer.or"(%lsb_one_neq01, %lsb_one_neq10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_clear_mask = "transfer.xor"(%lsb_one_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero_clear_mask = "transfer.xor"(%lsb_zero_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lsb_base = "transfer.and"(%res0_same_sign, %lsb_one_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lsb_base = "transfer.and"(%res1_same_sign, %lsb_zero_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined = "transfer.or"(%res0_lsb_base, %lsb_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined = "transfer.or"(%res1_lsb_base, %lsb_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %const_sub_lr = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_sub_rl = "transfer.sub"(%rhs1, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_lhs_ge_rhs = "transfer.cmp"(%lhs1, %rhs1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_val = "transfer.select"(%const_lhs_ge_rhs, %const_sub_lr, %const_sub_rl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_val_not = "transfer.xor"(%const_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // If one operand is constant and the other has exactly one unknown bit,
    // enumerate both values and intersect.
    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_ge0 = "transfer.cmp"(%lhs1, %rhs1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rhs_sub_ab0 = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_sub_ba0 = "transfer.sub"(%rhs1, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_val0 = "transfer.select"(%lhs_rhs_ge0, %lhs_rhs_sub_ab0, %lhs_rhs_sub_ba0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_ge1 = "transfer.cmp"(%lhs1, %rhs_alt) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rhs_sub_ab1 = "transfer.sub"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_sub_ba1 = "transfer.sub"(%rhs_alt, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_val1 = "transfer.select"(%lhs_rhs_ge1, %lhs_rhs_sub_ab1, %lhs_rhs_sub_ba1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_z0 = "transfer.xor"(%lhs_rhs_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_z1 = "transfer.xor"(%lhs_rhs_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_res0 = "transfer.and"(%lhs_rhs_z0, %lhs_rhs_z1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_res1 = "transfer.and"(%lhs_rhs_val0, %lhs_rhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_known_union = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_mask = "transfer.xor"(%lhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_nonzero = "transfer.cmp"(%lhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_unknown_minus1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_and_minus1 = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_minus1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_pow2ish = "transfer.cmp"(%lhs_unknown_and_minus1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_one_unknown = "arith.andi"(%lhs_unknown_nonzero, %lhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_ge0 = "transfer.cmp"(%lhs1, %rhs1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lhs_sub_ab0 = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_sub_ba0 = "transfer.sub"(%rhs1, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_val0 = "transfer.select"(%rhs_lhs_ge0, %rhs_lhs_sub_ab0, %rhs_lhs_sub_ba0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_ge1 = "transfer.cmp"(%lhs_alt, %rhs1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lhs_sub_ab1 = "transfer.sub"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_sub_ba1 = "transfer.sub"(%rhs1, %lhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_val1 = "transfer.select"(%rhs_lhs_ge1, %rhs_lhs_sub_ab1, %rhs_lhs_sub_ba1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_z0 = "transfer.xor"(%rhs_lhs_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_z1 = "transfer.xor"(%rhs_lhs_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_res0 = "transfer.and"(%rhs_lhs_z0, %rhs_lhs_z1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lhs_res1 = "transfer.and"(%rhs_lhs_val0, %rhs_lhs_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_lhs_one_unknown = "transfer.select"(%lhs_const_rhs_one_unknown, %lhs_rhs_res0, %res0_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs_one_unknown = "transfer.select"(%lhs_const_rhs_one_unknown, %lhs_rhs_res1, %res1_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_one_unknown = "transfer.select"(%rhs_const_lhs_one_unknown, %rhs_lhs_res0, %res0_lhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_one_unknown = "transfer.select"(%rhs_const_lhs_one_unknown, %rhs_lhs_res1, %res1_lhs_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %const_val_not, %res0_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_val, %res1_one_unknown) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer


    %lhsu_known = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_unk = "transfer.xor"(%lhsu_known, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_unk_m1 = "transfer.sub"(%lhsu_unk, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem1 = "transfer.and"(%lhsu_unk, %lhsu_unk_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem1_m1 = "transfer.sub"(%lhsu_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem2 = "transfer.and"(%lhsu_rem1, %lhsu_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem2_m1 = "transfer.sub"(%lhsu_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_le2 = "transfer.cmp"(%lhsu_rem2, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhsu_b1 = "transfer.xor"(%lhsu_unk, %lhsu_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_b2 = "transfer.xor"(%lhsu_rem1, %lhsu_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v0 = "transfer.add"(%lhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v1 = "transfer.add"(%lhsu_v0, %lhsu_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v2 = "transfer.add"(%lhsu_v0, %lhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v3 = "transfer.add"(%lhsu_v1, %lhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_known = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_unk = "transfer.xor"(%rhsu_known, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_unk_m1 = "transfer.sub"(%rhsu_unk, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem1 = "transfer.and"(%rhsu_unk, %rhsu_unk_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem1_m1 = "transfer.sub"(%rhsu_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem2 = "transfer.and"(%rhsu_rem1, %rhsu_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem2_m1 = "transfer.sub"(%rhsu_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_le2 = "transfer.cmp"(%rhsu_rem2, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhsu_b1 = "transfer.xor"(%rhsu_unk, %rhsu_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_b2 = "transfer.xor"(%rhsu_rem1, %rhsu_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v0 = "transfer.add"(%rhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v1 = "transfer.add"(%rhsu_v0, %rhsu_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v2 = "transfer.add"(%rhsu_v0, %rhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v3 = "transfer.add"(%rhsu_v1, %rhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact_on = "arith.andi"(%lhsu_le2, %rhsu_le2) : (i1, i1) -> i1
    %pair_ge_0 = "transfer.cmp"(%lhsu_v0, %rhsu_v0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_0 = "transfer.sub"(%lhsu_v0, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_0 = "transfer.sub"(%rhsu_v0, %lhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_0 = "transfer.select"(%pair_ge_0, %pair_sub_lr_0, %pair_sub_rl_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_0 = "transfer.xor"(%pair_res_0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_0 = "transfer.and"(%all_ones, %pair_not_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_0 = "transfer.and"(%all_ones, %pair_res_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_1 = "transfer.cmp"(%lhsu_v0, %rhsu_v1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_1 = "transfer.sub"(%lhsu_v0, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_1 = "transfer.sub"(%rhsu_v1, %lhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_1 = "transfer.select"(%pair_ge_1, %pair_sub_lr_1, %pair_sub_rl_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_1 = "transfer.xor"(%pair_res_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_1 = "transfer.and"(%acc0_0, %pair_not_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_1 = "transfer.and"(%acc1_0, %pair_res_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_2 = "transfer.cmp"(%lhsu_v0, %rhsu_v2) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_2 = "transfer.sub"(%lhsu_v0, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_2 = "transfer.sub"(%rhsu_v2, %lhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_2 = "transfer.select"(%pair_ge_2, %pair_sub_lr_2, %pair_sub_rl_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_2 = "transfer.xor"(%pair_res_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_2 = "transfer.and"(%acc0_1, %pair_not_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_2 = "transfer.and"(%acc1_1, %pair_res_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_3 = "transfer.cmp"(%lhsu_v0, %rhsu_v3) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_3 = "transfer.sub"(%lhsu_v0, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_3 = "transfer.sub"(%rhsu_v3, %lhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_3 = "transfer.select"(%pair_ge_3, %pair_sub_lr_3, %pair_sub_rl_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_3 = "transfer.xor"(%pair_res_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_3 = "transfer.and"(%acc0_2, %pair_not_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_3 = "transfer.and"(%acc1_2, %pair_res_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_4 = "transfer.cmp"(%lhsu_v1, %rhsu_v0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_4 = "transfer.sub"(%lhsu_v1, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_4 = "transfer.sub"(%rhsu_v0, %lhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_4 = "transfer.select"(%pair_ge_4, %pair_sub_lr_4, %pair_sub_rl_4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_4 = "transfer.xor"(%pair_res_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_4 = "transfer.and"(%acc0_3, %pair_not_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_4 = "transfer.and"(%acc1_3, %pair_res_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_5 = "transfer.cmp"(%lhsu_v1, %rhsu_v1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_5 = "transfer.sub"(%lhsu_v1, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_5 = "transfer.sub"(%rhsu_v1, %lhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_5 = "transfer.select"(%pair_ge_5, %pair_sub_lr_5, %pair_sub_rl_5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_5 = "transfer.xor"(%pair_res_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_5 = "transfer.and"(%acc0_4, %pair_not_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_5 = "transfer.and"(%acc1_4, %pair_res_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_6 = "transfer.cmp"(%lhsu_v1, %rhsu_v2) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_6 = "transfer.sub"(%lhsu_v1, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_6 = "transfer.sub"(%rhsu_v2, %lhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_6 = "transfer.select"(%pair_ge_6, %pair_sub_lr_6, %pair_sub_rl_6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_6 = "transfer.xor"(%pair_res_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_6 = "transfer.and"(%acc0_5, %pair_not_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_6 = "transfer.and"(%acc1_5, %pair_res_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_7 = "transfer.cmp"(%lhsu_v1, %rhsu_v3) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_7 = "transfer.sub"(%lhsu_v1, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_7 = "transfer.sub"(%rhsu_v3, %lhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_7 = "transfer.select"(%pair_ge_7, %pair_sub_lr_7, %pair_sub_rl_7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_7 = "transfer.xor"(%pair_res_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_7 = "transfer.and"(%acc0_6, %pair_not_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_7 = "transfer.and"(%acc1_6, %pair_res_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_8 = "transfer.cmp"(%lhsu_v2, %rhsu_v0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_8 = "transfer.sub"(%lhsu_v2, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_8 = "transfer.sub"(%rhsu_v0, %lhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_8 = "transfer.select"(%pair_ge_8, %pair_sub_lr_8, %pair_sub_rl_8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_8 = "transfer.xor"(%pair_res_8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_8 = "transfer.and"(%acc0_7, %pair_not_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_8 = "transfer.and"(%acc1_7, %pair_res_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_9 = "transfer.cmp"(%lhsu_v2, %rhsu_v1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_9 = "transfer.sub"(%lhsu_v2, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_9 = "transfer.sub"(%rhsu_v1, %lhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_9 = "transfer.select"(%pair_ge_9, %pair_sub_lr_9, %pair_sub_rl_9) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_9 = "transfer.xor"(%pair_res_9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_9 = "transfer.and"(%acc0_8, %pair_not_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_9 = "transfer.and"(%acc1_8, %pair_res_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_10 = "transfer.cmp"(%lhsu_v2, %rhsu_v2) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_10 = "transfer.sub"(%lhsu_v2, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_10 = "transfer.sub"(%rhsu_v2, %lhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_10 = "transfer.select"(%pair_ge_10, %pair_sub_lr_10, %pair_sub_rl_10) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_10 = "transfer.xor"(%pair_res_10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_10 = "transfer.and"(%acc0_9, %pair_not_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_10 = "transfer.and"(%acc1_9, %pair_res_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_11 = "transfer.cmp"(%lhsu_v2, %rhsu_v3) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_11 = "transfer.sub"(%lhsu_v2, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_11 = "transfer.sub"(%rhsu_v3, %lhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_11 = "transfer.select"(%pair_ge_11, %pair_sub_lr_11, %pair_sub_rl_11) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_11 = "transfer.xor"(%pair_res_11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_11 = "transfer.and"(%acc0_10, %pair_not_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_11 = "transfer.and"(%acc1_10, %pair_res_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_12 = "transfer.cmp"(%lhsu_v3, %rhsu_v0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_12 = "transfer.sub"(%lhsu_v3, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_12 = "transfer.sub"(%rhsu_v0, %lhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_12 = "transfer.select"(%pair_ge_12, %pair_sub_lr_12, %pair_sub_rl_12) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_12 = "transfer.xor"(%pair_res_12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_12 = "transfer.and"(%acc0_11, %pair_not_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_12 = "transfer.and"(%acc1_11, %pair_res_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_13 = "transfer.cmp"(%lhsu_v3, %rhsu_v1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_13 = "transfer.sub"(%lhsu_v3, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_13 = "transfer.sub"(%rhsu_v1, %lhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_13 = "transfer.select"(%pair_ge_13, %pair_sub_lr_13, %pair_sub_rl_13) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_13 = "transfer.xor"(%pair_res_13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_13 = "transfer.and"(%acc0_12, %pair_not_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_13 = "transfer.and"(%acc1_12, %pair_res_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_14 = "transfer.cmp"(%lhsu_v3, %rhsu_v2) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_14 = "transfer.sub"(%lhsu_v3, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_14 = "transfer.sub"(%rhsu_v2, %lhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_14 = "transfer.select"(%pair_ge_14, %pair_sub_lr_14, %pair_sub_rl_14) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_14 = "transfer.xor"(%pair_res_14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_14 = "transfer.and"(%acc0_13, %pair_not_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_14 = "transfer.and"(%acc1_13, %pair_res_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ge_15 = "transfer.cmp"(%lhsu_v3, %rhsu_v3) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_sub_lr_15 = "transfer.sub"(%lhsu_v3, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sub_rl_15 = "transfer.sub"(%rhsu_v3, %lhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_res_15 = "transfer.select"(%pair_ge_15, %pair_sub_lr_15, %pair_sub_rl_15) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_not_15 = "transfer.xor"(%pair_res_15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_15 = "transfer.and"(%acc0_14, %pair_not_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_15 = "transfer.and"(%acc1_14, %pair_res_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_out = "transfer.select"(%exact_on, %acc0_15, %res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_out = "transfer.select"(%exact_on, %acc1_15, %res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0_out, %res1_out) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_abds", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
