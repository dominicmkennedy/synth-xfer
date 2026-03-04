"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %sign_minus_1 = "transfer.lshr"(%all_ones, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Partition inputs into nonnegative (low half) and negative (high half).
    %lhs_nonneg_exists = "transfer.cmp"(%lhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_upper = "transfer.umin"(%lhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.umin"(%rhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%sign_bit, %lhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%sign_bit, %rhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_lower = "transfer.umax"(%lhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.umax"(%rhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case A: lhs>=0, rhs>=0, nuw requires lhs >= rhs.
    %a_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %a_order = "transfer.cmp"(%lhs_nonneg_upper, %rhs_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_exists = "arith.andi"(%a_exists_0, %a_order) : (i1, i1) -> i1
    %a_overlap_0 = "transfer.cmp"(%lhs_nonneg_upper, %rhs_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_overlap_1 = "transfer.cmp"(%rhs_nonneg_upper, %lhs_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_overlap = "arith.andi"(%a_overlap_0, %a_overlap_1) : (i1, i1) -> i1
    %a_min_nonover = "transfer.sub"(%lhs_lower, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min = "transfer.select"(%a_overlap, %const0, %a_min_nonover) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max = "transfer.sub"(%lhs_nonneg_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case B: lhs<0, rhs<0, nuw requires lhs >= rhs (same order in high half).
    %b_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %b_order = "transfer.cmp"(%lhs_upper, %rhs_neg_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_exists = "arith.andi"(%b_exists_0, %b_order) : (i1, i1) -> i1
    %b_overlap_0 = "transfer.cmp"(%lhs_upper, %rhs_neg_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_overlap_1 = "transfer.cmp"(%rhs_upper, %lhs_neg_lower) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_overlap = "arith.andi"(%b_overlap_0, %b_overlap_1) : (i1, i1) -> i1
    %b_min_nonover = "transfer.sub"(%lhs_neg_lower, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min = "transfer.select"(%b_overlap, %const0, %b_min_nonover) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max = "transfer.sub"(%lhs_upper, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case C: lhs<0, rhs>=0. nuw always holds; nsw requires lhs >= smin + rhs.
    %c_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %c_thresh = "transfer.add"(%sign_bit, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_lhs_start = "transfer.umax"(%lhs_neg_lower, %c_thresh) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_order = "transfer.cmp"(%lhs_upper, %c_lhs_start) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_exists = "arith.andi"(%c_exists_0, %c_order) : (i1, i1) -> i1
    %c_min_raw = "transfer.sub"(%c_lhs_start, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_ov = "transfer.ssub_overflow"(%c_lhs_start, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> i1
    %c_min = "transfer.select"(%c_min_ov, %sign_bit, %c_min_raw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max = "transfer.sub"(%lhs_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Join all case ranges (start from bottom = [max, 0]).
    %ret_lower_0 = "transfer.add"(%all_ones, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_0 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_a = "transfer.umin"(%ret_lower_0, %a_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_a = "transfer.umax"(%ret_upper_0, %a_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%a_exists, %ret_lower_a, %ret_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%a_exists, %ret_upper_a, %ret_upper_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_b = "transfer.umin"(%ret_lower_1, %b_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_b = "transfer.umax"(%ret_upper_1, %b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%b_exists, %ret_lower_b, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%b_exists, %ret_upper_b, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_c = "transfer.umin"(%ret_lower_2, %c_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_c = "transfer.umax"(%ret_upper_2, %c_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%c_exists, %ret_lower_c, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%c_exists, %ret_upper_c, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_subnswnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
