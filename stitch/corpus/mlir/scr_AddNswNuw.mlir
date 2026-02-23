"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %minus1 = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%lhs_lower, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_upper_le_m1 = "transfer.cmp"(%lhs_upper, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_upper = "transfer.select"(%lhs_upper_le_m1, %lhs_upper, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_pos_exists = "transfer.cmp"(%lhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lower_ge_0 = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_pos_lower = "transfer.select"(%lhs_lower_ge_0, %lhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_neg_exists = "transfer.cmp"(%rhs_lower, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_m1 = "transfer.cmp"(%rhs_upper, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_upper = "transfer.select"(%rhs_upper_le_m1, %rhs_upper, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_pos_exists = "transfer.cmp"(%rhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lower_ge_0 = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_pos_lower = "transfer.select"(%rhs_lower_ge_0, %rhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %pos_lo = "transfer.add"(%lhs_pos_lower, %rhs_pos_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_hi = "transfer.add"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_lo_ov = "transfer.sadd_overflow"(%lhs_pos_lower, %rhs_pos_lower) : (!transfer.integer, !transfer.integer) -> i1
    %pos_hi_ov = "transfer.sadd_overflow"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %pos_lo_no_ov = "arith.xori"(%pos_lo_ov, %const_true) : (i1, i1) -> i1
    %pos_exists_0 = "arith.andi"(%lhs_pos_exists, %rhs_pos_exists) : (i1, i1) -> i1
    %pos_exists = "arith.andi"(%pos_exists_0, %pos_lo_no_ov) : (i1, i1) -> i1
    %pos_upper = "transfer.select"(%pos_hi_ov, %smax, %pos_hi) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_lhs_lo = "transfer.add"(%lhs_lower, %rhs_pos_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_lhs_hi = "transfer.add"(%lhs_neg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_lhs_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_pos_exists) : (i1, i1) -> i1
    %neg_lhs_lo_le_m1 = "transfer.cmp"(%neg_lhs_lo, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_lhs_exists = "arith.andi"(%neg_lhs_exists_0, %neg_lhs_lo_le_m1) : (i1, i1) -> i1
    %neg_lhs_hi_le_m1 = "transfer.cmp"(%neg_lhs_hi, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_lhs_upper = "transfer.select"(%neg_lhs_hi_le_m1, %neg_lhs_hi, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_rhs_lo = "transfer.add"(%lhs_pos_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_hi = "transfer.add"(%lhs_upper, %rhs_neg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_exists_0 = "arith.andi"(%lhs_pos_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %neg_rhs_lo_le_m1 = "transfer.cmp"(%neg_rhs_lo, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_rhs_exists = "arith.andi"(%neg_rhs_exists_0, %neg_rhs_lo_le_m1) : (i1, i1) -> i1
    %neg_rhs_hi_le_m1 = "transfer.cmp"(%neg_rhs_hi, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_rhs_upper = "transfer.select"(%neg_rhs_hi_le_m1, %neg_rhs_hi, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_join_lower = "transfer.smin"(%smax, %pos_lo) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pos_join_upper = "transfer.smax"(%smin, %pos_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%pos_exists, %pos_join_lower, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%pos_exists, %pos_join_upper, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_lhs_join_lower = "transfer.smin"(%ret_lower_1, %neg_lhs_lo) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_lhs_join_upper = "transfer.smax"(%ret_upper_1, %neg_lhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%neg_lhs_exists, %neg_lhs_join_lower, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%neg_lhs_exists, %neg_lhs_join_upper, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_rhs_join_lower = "transfer.smin"(%ret_lower_2, %neg_rhs_lo) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_join_upper = "transfer.smax"(%ret_upper_2, %neg_rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%neg_rhs_exists, %neg_rhs_join_lower, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%neg_rhs_exists, %neg_rhs_join_upper, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_addnswnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
