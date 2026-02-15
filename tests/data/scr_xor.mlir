"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_upper, %all_ones) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%rhs_upper, %all_ones) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_nonneg = "arith.andi"(%lhs_nonneg, %rhs_nonneg) : (i1, i1) -> i1
    %both_neg = "arith.andi"(%lhs_neg, %rhs_neg) : (i1, i1) -> i1
    %same_sign = "arith.ori"(%both_nonneg, %both_neg) : (i1, i1) -> i1
    %lhs_nonneg_rhs_neg = "arith.andi"(%lhs_nonneg, %rhs_neg) : (i1, i1) -> i1
    %lhs_neg_rhs_nonneg = "arith.andi"(%lhs_neg, %rhs_nonneg) : (i1, i1) -> i1
    %cross_sign = "arith.ori"(%lhs_nonneg_rhs_neg, %lhs_neg_rhs_nonneg) : (i1, i1) -> i1

    %lhs_before_rhs = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_before_lhs = "transfer.cmp"(%rhs_upper, %lhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %disjoint = "arith.ori"(%lhs_before_rhs, %rhs_before_lhs) : (i1, i1) -> i1
    %same_sign_disjoint = "arith.andi"(%same_sign, %disjoint) : (i1, i1) -> i1

    %fallback_lower_0 = "transfer.select"(%same_sign, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_lower = "transfer.select"(%same_sign_disjoint, %const1, %fallback_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_upper = "transfer.select"(%cross_sign, %all_ones, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero_val = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero_val) : (i1, i1) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero_val) : (i1, i1) -> i1

    %lhs_is_all_ones_val = "transfer.cmp"(%lhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_all_ones_val = "transfer.cmp"(%rhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_all_ones = "arith.andi"(%lhs_is_const, %lhs_is_all_ones_val) : (i1, i1) -> i1
    %rhs_const_all_ones = "arith.andi"(%rhs_is_const, %rhs_is_all_ones_val) : (i1, i1) -> i1

    %rhs_not_lower = "transfer.xor"(%rhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_not_upper = "transfer.xor"(%rhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_lower = "transfer.xor"(%lhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_upper = "transfer.xor"(%lhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %rhs_lower, %fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %rhs_upper, %fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rz = "transfer.select"(%rhs_const_zero, %lhs_lower, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rz = "transfer.select"(%rhs_const_zero, %lhs_upper, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_lower, %ret_lower_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_upper, %ret_upper_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_lower, %ret_lower_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_upper, %ret_upper_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%both_const, %const_res, %ret_lower_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%both_const, %const_res, %ret_upper_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_xor", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
