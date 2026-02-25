"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %minus1 = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    // Sign-partition each input interval.
    %lhs_nonneg_exists = "transfer.cmp"(%lhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lower_ge_0 = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lower_ge_0 = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_lower = "transfer.select"(%lhs_lower_ge_0, %lhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_lower = "transfer.select"(%rhs_lower_ge_0, %rhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg_upper = "transfer.select"(%lhs_nonneg_exists, %lhs_upper, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.select"(%rhs_nonneg_exists, %rhs_upper, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%lhs_lower, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%rhs_lower, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_upper_le_m1 = "transfer.cmp"(%lhs_upper, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_m1 = "transfer.cmp"(%rhs_upper, %minus1) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_upper = "transfer.select"(%lhs_upper_le_m1, %lhs_upper, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_upper = "transfer.select"(%rhs_upper_le_m1, %rhs_upper, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_neg_lower = "transfer.select"(%lhs_neg_exists, %lhs_lower, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.select"(%rhs_neg_exists, %rhs_lower, %minus1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Case A: lhs>=0, rhs>=0, and nuw requires lhs >= rhs.
    %a_exists_0 = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %a_order = "transfer.cmp"(%lhs_nonneg_upper, %rhs_nonneg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_exists = "arith.andi"(%a_exists_0, %a_order) : (i1, i1) -> i1
    %a_overlap_0 = "transfer.cmp"(%lhs_nonneg_upper, %rhs_nonneg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_overlap_1 = "transfer.cmp"(%rhs_nonneg_upper, %lhs_nonneg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_overlap = "arith.andi"(%a_overlap_0, %a_overlap_1) : (i1, i1) -> i1
    %a_min_nonover = "transfer.sub"(%lhs_nonneg_lower, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min = "transfer.select"(%a_overlap, %const0, %a_min_nonover) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max = "transfer.sub"(%lhs_nonneg_upper, %rhs_nonneg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case B: lhs<0, rhs<0, and nuw requires lhs >= rhs (same as signed here).
    %b_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %b_order = "transfer.cmp"(%lhs_neg_upper, %rhs_neg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_exists = "arith.andi"(%b_exists_0, %b_order) : (i1, i1) -> i1
    %b_overlap_0 = "transfer.cmp"(%lhs_neg_upper, %rhs_neg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_overlap_1 = "transfer.cmp"(%rhs_neg_upper, %lhs_neg_lower) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_overlap = "arith.andi"(%b_overlap_0, %b_overlap_1) : (i1, i1) -> i1
    %b_min_nonover = "transfer.sub"(%lhs_neg_lower, %rhs_neg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min = "transfer.select"(%b_overlap, %const0, %b_min_nonover) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max = "transfer.sub"(%lhs_neg_upper, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case C: lhs<0, rhs>=0. nuw is automatic; nsw requires lhs >= smin + rhs.
    %c_exists_0 = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %c_thresh = "transfer.add"(%smin, %rhs_nonneg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_lhs_start = "transfer.smax"(%lhs_neg_lower, %c_thresh) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_order = "transfer.cmp"(%lhs_neg_upper, %c_lhs_start) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_exists = "arith.andi"(%c_exists_0, %c_order) : (i1, i1) -> i1
    %c_min_exact = "transfer.sub"(%c_lhs_start, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_ov = "transfer.ssub_overflow"(%c_lhs_start, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> i1
    %c_min = "transfer.select"(%c_min_ov, %smin, %c_min_exact) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max = "transfer.sub"(%lhs_neg_upper, %rhs_nonneg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Join of sound case candidates. Starts at bottom.
    %ret_lower_0 = "transfer.add"(%smax, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_0 = "transfer.add"(%smin, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_a = "transfer.smin"(%ret_lower_0, %a_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_a = "transfer.smax"(%ret_upper_0, %a_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%a_exists, %ret_lower_a, %ret_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%a_exists, %ret_upper_a, %ret_upper_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_b = "transfer.smin"(%ret_lower_1, %b_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_b = "transfer.smax"(%ret_upper_1, %b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%b_exists, %ret_lower_b, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%b_exists, %ret_upper_b, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_c = "transfer.smin"(%ret_lower_2, %c_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_c = "transfer.smax"(%ret_upper_2, %c_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%c_exists, %ret_lower_c, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%c_exists, %ret_upper_c, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_subnswnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
