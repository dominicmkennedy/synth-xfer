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
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_ge_rhs_always = "transfer.cmp"(%lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lt_rhs_always = "transfer.cmp"(%lhs_max, %rhs1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %res0_uncertain = "transfer.select"(%lhs_lt_rhs_always, %sub_rl0, %join0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_uncertain = "transfer.select"(%lhs_lt_rhs_always, %sub_rl1, %join1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_nonconst = "transfer.select"(%lhs_ge_rhs_always, %sub_lr0, %res0_uncertain) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%lhs_ge_rhs_always, %sub_lr1, %res1_uncertain) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ub1_ge = "transfer.cmp"(%lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub1_ab = "transfer.sub"(%lhs1, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub1_ba = "transfer.sub"(%rhs_max, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub1 = "transfer.select"(%ub1_ge, %ub1_ab, %ub1_ba) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ub2_ge = "transfer.cmp"(%lhs_max, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub2_ab = "transfer.sub"(%lhs_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub2_ba = "transfer.sub"(%rhs1, %lhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub2 = "transfer.select"(%ub2_ge, %ub2_ab, %ub2_ba) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ub = "transfer.umax"(%ub1, %ub2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub_lz = "transfer.countl_zero"(%ub) : (!transfer.integer) -> !transfer.integer
    %ub_shift = "transfer.sub"(%bitwidth, %ub_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.shl"(%all_ones, %ub_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_clear = "transfer.xor"(%high_zero_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_bounded = "transfer.or"(%res0_nonconst, %high_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_bounded = "transfer.and"(%res1_nonconst, %high_zero_clear) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %eq_low_known0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known = "transfer.or"(%eq_low_known0, %eq_low_known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_count = "transfer.countr_one"(%eq_low_known) : (!transfer.integer) -> !transfer.integer
    %eq_low_inv = "transfer.sub"(%bitwidth, %eq_low_count) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_mask = "transfer.lshr"(%all_ones, %eq_low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_clear = "transfer.xor"(%eq_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_eq = "transfer.or"(%res0_bounded, %eq_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_eq = "transfer.and"(%res1_bounded, %eq_low_clear) : (!transfer.integer, !transfer.integer) -> !transfer.integer

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
    %res0_lsb_base = "transfer.and"(%res0_eq, %lsb_one_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lsb_base = "transfer.and"(%res1_eq, %lsb_zero_clear_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined = "transfer.or"(%res0_lsb_base, %lsb_zero_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined = "transfer.or"(%res1_lsb_base, %lsb_one_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %const_sub_lr = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_sub_rl = "transfer.sub"(%rhs1, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_lhs_ge_rhs = "transfer.cmp"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_val = "transfer.select"(%const_lhs_ge_rhs, %const_sub_lr, %const_sub_rl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_val_not = "transfer.xor"(%const_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %const_val_not, %res0_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_val, %res1_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_abdu", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

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
    %res0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_add", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

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
    %base0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_lower = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_lower_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %nuw_exists = "arith.xori"(%nuw_lower_ov, %const_true) : (i1, i1) -> i1
    %nuw_upper_sum = "transfer.add"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_upper_ov = "transfer.uadd_overflow"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> i1
    %nuw_upper = "transfer.select"(%nuw_upper_ov, %all_ones, %nuw_upper_sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_diff = "transfer.xor"(%nuw_lower, %nuw_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_lz = "transfer.countl_zero"(%nuw_diff) : (!transfer.integer) -> !transfer.integer
    %nuw_shift = "transfer.sub"(%bitwidth, %nuw_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_mask = "transfer.shl"(%all_ones, %nuw_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_not_low = "transfer.xor"(%nuw_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k0 = "transfer.and"(%nuw_not_low, %nuw_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k1 = "transfer.and"(%nuw_lower, %nuw_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k0_use = "transfer.select"(%nuw_exists, %nuw_k0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k1_use = "transfer.select"(%nuw_exists, %nuw_k1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.or"(%base0, %nuw_k0_use) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%base1, %nuw_k1_use) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_addnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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
    %sub_lr1_nouf = "transfer.select"(%consistent, %sub_lr1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
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
    %lsb_one_nouf = "transfer.select"(%consistent, %lsb_one, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
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
    %low1 = "transfer.select"(%consistent, %low_sub_masked, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
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
    %r_low_1_nouf = "transfer.select"(%consistent, %r_low_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined2 = "transfer.or"(%res0_refined, %r_low_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined2 = "transfer.or"(%res1_refined, %r_low_1_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sign_mask_local = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %res_sign0_a = "transfer.and"(%lhs0, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign0_b = "transfer.and"(%rhs1, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign0 = "transfer.or"(%res_sign0_a, %res_sign0_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1_a = "transfer.and"(%lhs1, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1_b = "transfer.and"(%rhs0, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1 = "transfer.and"(%res_sign1_a, %res_sign1_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_refined3 = "transfer.add"(%res0_refined2, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined3 = "transfer.add"(%res1_refined2, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer


    %sign_mask = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_sign_zero_known = "transfer.and"(%lhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one_known = "transfer.and"(%lhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_zero_known = "transfer.and"(%rhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_one_known = "transfer.and"(%rhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_can_nonneg = "transfer.cmp"(%lhs_sign_one_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_can_neg = "transfer.cmp"(%lhs_sign_zero_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_can_nonneg = "transfer.cmp"(%rhs_sign_one_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_can_neg = "transfer.cmp"(%rhs_sign_zero_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %sign_case_nn = "arith.andi"(%lhs_can_nonneg, %rhs_can_nonneg) : (i1, i1) -> i1
    %sign_case_npn = "arith.andi"(%lhs_can_neg, %rhs_can_nonneg) : (i1, i1) -> i1
    %sign_case_pp = "arith.andi"(%lhs_can_neg, %rhs_can_neg) : (i1, i1) -> i1
    %sign_case_any_0 = "arith.ori"(%sign_case_nn, %sign_case_npn) : (i1, i1) -> i1
    %sign_case_any = "arith.ori"(%sign_case_any_0, %sign_case_pp) : (i1, i1) -> i1

    %nuw_possible = "transfer.cmp"(%rhs1, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %feasible_0 = "arith.andi"(%consistent, %nuw_possible) : (i1, i1) -> i1
    %feasible = "arith.andi"(%feasible_0, %sign_case_any) : (i1, i1) -> i1

    %res0_final = "transfer.select"(%feasible, %res0_refined3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%feasible, %res1_refined3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_subnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v2 = "transfer.sub"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.sub"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%arg0, %v2, %v3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.and"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.sub"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
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