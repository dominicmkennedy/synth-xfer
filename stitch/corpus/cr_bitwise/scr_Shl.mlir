"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero) : (i1, i1) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero) : (i1, i1) -> i1

    %rhs_upper_ge_0 = "transfer.cmp"(%rhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lower_le_bw = "transfer.cmp"(%rhs_lower, %bw) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_has_valid = "arith.andi"(%rhs_upper_ge_0, %rhs_lower_le_bw) : (i1, i1) -> i1
    %bw_is_small = "transfer.cmp"(%bw, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bw_not_small = "arith.xori"(%bw_is_small, %const_true) : (i1, i1) -> i1

    %rhs_lower_ge_0 = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_bw = "transfer.cmp"(%rhs_upper, %bw) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_all_valid = "arith.andi"(%rhs_lower_ge_0, %rhs_upper_le_bw) : (i1, i1) -> i1
    %rhs_has_valid_or_small = "arith.ori"(%rhs_has_valid, %bw_is_small) : (i1, i1) -> i1
    %rhs_has_valid_safe = "arith.andi"(%rhs_has_valid, %bw_not_small) : (i1, i1) -> i1
    %rhs_all_valid_safe = "arith.andi"(%rhs_all_valid, %bw_not_small) : (i1, i1) -> i1
    %rhs_eff_lower = "transfer.select"(%rhs_lower_ge_0, %rhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_eff_upper = "transfer.select"(%rhs_upper_le_bw, %rhs_upper, %bw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_valid_lower = "transfer.select"(%rhs_has_valid_or_small, %smin, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_valid_upper = "transfer.select"(%rhs_has_valid_or_small, %smax, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_lhs0_ok = "arith.andi"(%lhs_const_zero, %rhs_has_valid_safe) : (i1, i1) -> i1
    %cand_lhs0_lower = "transfer.select"(%cand_lhs0_ok, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_lhs0_upper = "transfer.select"(%cand_lhs0_ok, %const0, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_rhs0_ok = "arith.andi"(%rhs_const_zero, %rhs_all_valid_safe) : (i1, i1) -> i1
    %cand_rhs0_lower = "transfer.select"(%cand_rhs0_ok, %lhs_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_rhs0_upper = "transfer.select"(%cand_rhs0_ok, %lhs_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_const_ok = "arith.andi"(%both_const, %rhs_all_valid_safe) : (i1, i1) -> i1
    %const_shl = "transfer.shl"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_const_lower = "transfer.select"(%cand_const_ok, %const_shl, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_const_upper = "transfer.select"(%cand_const_ok, %const_shl, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %clz_upper = "transfer.countl_zero"(%lhs_upper) : (!transfer.integer) -> !transfer.integer
    %rhs_lt_clz = "transfer.cmp"(%rhs_eff_upper, %clz_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cand_nonneg_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_nonneg) : (i1, i1) -> i1
    %cand_nonneg_ok = "arith.andi"(%cand_nonneg_ok_0, %rhs_lt_clz) : (i1, i1) -> i1
    %nonneg_lower = "transfer.shl"(%lhs_lower, %rhs_eff_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nonneg_upper = "transfer.shl"(%lhs_upper, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_nonneg_lower = "transfer.select"(%cand_nonneg_ok, %nonneg_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_nonneg_upper = "transfer.select"(%cand_nonneg_ok, %nonneg_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %clo_lower = "transfer.countl_one"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %rhs_lt_clo = "transfer.cmp"(%rhs_eff_upper, %clo_lower) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cand_neg_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_neg) : (i1, i1) -> i1
    %cand_neg_ok = "arith.andi"(%cand_neg_ok_0, %rhs_lt_clo) : (i1, i1) -> i1
    %neg_lower = "transfer.shl"(%lhs_lower, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_upper = "transfer.shl"(%lhs_upper, %rhs_eff_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_neg_lower = "transfer.select"(%cand_neg_ok, %neg_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_neg_upper = "transfer.select"(%cand_neg_ok, %neg_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_mixed_neg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mixed_nonneg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mixed = "arith.andi"(%lhs_mixed_neg, %lhs_mixed_nonneg) : (i1, i1) -> i1
    %cand_mixed_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_mixed) : (i1, i1) -> i1
    %cand_mixed_ok_1 = "arith.andi"(%cand_mixed_ok_0, %rhs_lt_clz) : (i1, i1) -> i1
    %cand_mixed_ok = "arith.andi"(%cand_mixed_ok_1, %rhs_lt_clo) : (i1, i1) -> i1
    %mixed_lower = "transfer.shl"(%lhs_lower, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mixed_upper = "transfer.shl"(%lhs_upper, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_mixed_lower = "transfer.select"(%cand_mixed_ok, %mixed_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_mixed_upper = "transfer.select"(%cand_mixed_ok, %mixed_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_1 = "transfer.smax"(%smin, %cand_valid_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.smin"(%smax, %cand_valid_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_2 = "transfer.smax"(%ret_lower_1, %cand_lhs0_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.smin"(%ret_upper_1, %cand_lhs0_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_3 = "transfer.smax"(%ret_lower_2, %cand_rhs0_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_3 = "transfer.smin"(%ret_upper_2, %cand_rhs0_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_4 = "transfer.smax"(%ret_lower_3, %cand_const_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_4 = "transfer.smin"(%ret_upper_3, %cand_const_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_5 = "transfer.smax"(%ret_lower_4, %cand_nonneg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_5 = "transfer.smin"(%ret_upper_4, %cand_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_6 = "transfer.smax"(%ret_lower_5, %cand_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_6 = "transfer.smin"(%ret_upper_5, %cand_neg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.smax"(%ret_lower_6, %cand_mixed_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.smin"(%ret_upper_6, %cand_mixed_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
