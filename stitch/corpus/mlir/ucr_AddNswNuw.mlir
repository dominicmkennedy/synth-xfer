"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %max = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %sign_minus_1 = "transfer.lshr"(%max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg_exists = "transfer.cmp"(%lhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_upper = "transfer.umin"(%lhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.umin"(%rhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%sign_bit, %lhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%sign_bit, %rhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_lower = "transfer.umax"(%lhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.umax"(%rhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %case_a_lower = "transfer.add"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_upper_raw = "transfer.add"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_upper = "transfer.umin"(%case_a_upper_raw, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_a_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %case_a_lower_ok = "transfer.cmp"(%case_a_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %case_a_exists = "arith.andi"(%case_a_exists_0, %case_a_lower_ok) : (i1, i1) -> i1

    %case_b_lower = "transfer.add"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_upper_raw = "transfer.add"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_upper_ov = "transfer.uadd_overflow"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> i1
    %case_b_upper = "transfer.select"(%case_b_upper_ov, %max, %case_b_upper_raw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_b_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %case_b_lower_ov = "transfer.uadd_overflow"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> i1
    %case_b_lower_ok = "arith.xori"(%case_b_lower_ov, %const_true) : (i1, i1) -> i1
    %case_b_exists = "arith.andi"(%case_b_exists_0, %case_b_lower_ok) : (i1, i1) -> i1

    %case_c_lower = "transfer.add"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_upper_raw = "transfer.add"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_upper_ov = "transfer.uadd_overflow"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %case_c_upper = "transfer.select"(%case_c_upper_ov, %max, %case_c_upper_raw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %case_c_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %case_c_lower_ov = "transfer.uadd_overflow"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> i1
    %case_c_lower_ok = "arith.xori"(%case_c_lower_ov, %const_true) : (i1, i1) -> i1
    %case_c_exists = "arith.andi"(%case_c_exists_0, %case_c_lower_ok) : (i1, i1) -> i1

    %join_a_lower = "transfer.umin"(%max, %case_a_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %join_a_upper = "transfer.umax"(%const0, %case_a_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%case_a_exists, %join_a_lower, %max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%case_a_exists, %join_a_upper, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %join_b_lower = "transfer.umin"(%ret_lower_1, %case_b_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %join_b_upper = "transfer.umax"(%ret_upper_1, %case_b_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%case_b_exists, %join_b_lower, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%case_b_exists, %join_b_upper, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %join_c_lower = "transfer.umin"(%ret_lower_2, %case_c_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %join_c_upper = "transfer.umax"(%ret_upper_2, %case_c_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%case_c_exists, %join_c_lower, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%case_c_exists, %join_c_upper, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_addnswnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
