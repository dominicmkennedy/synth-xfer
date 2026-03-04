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

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %res_lower = "transfer.sub"(%lhs_lower, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_upper = "transfer.sub"(%lhs_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res_lower_ov = "transfer.ssub_overflow"(%lhs_lower, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %res_upper_ov = "transfer.ssub_overflow"(%lhs_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> i1
    %mixed_overflow = "arith.xori"(%res_lower_ov, %res_upper_ov) : (i1, i1) -> i1

    %min = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %max = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lower_gt_upper = "transfer.cmp"(%res_lower, %res_upper) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ret_top_cond = "arith.ori"(%mixed_overflow, %lower_gt_upper) : (i1, i1) -> i1

    %ret_lower = "transfer.select"(%ret_top_cond, %min, %res_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%ret_top_cond, %max, %res_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_sub", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v1 = "transfer.select"(%h2, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%arg0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func1(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "transfer.select"(%arg0, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}

 "func.func"() ({
   ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
     %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
     %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
     %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
     %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

     %res_lower = "transfer.add"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
     %res_upper = "transfer.add"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
     %res_lower_ov = "transfer.uadd_overflow"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> i1
     %res_upper_ov = "transfer.uadd_overflow"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1

     %lower_ge_upper = "transfer.cmp"(%res_lower, %res_upper) {predicate=8:i64}: (!transfer.integer, !transfer.integer) -> i1
     %overflow = "arith.xori"(%res_lower_ov, %res_upper_ov): (i1, i1) -> i1
     %ret_top_cond = "arith.ori"(%lower_ge_upper, %overflow): (i1, i1) -> i1

     %min = "transfer.constant"(%lhs_lower) {value=0:index} : (!transfer.integer)->!transfer.integer
     %max = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

     %ret_lower = "transfer.select"(%ret_top_cond, %min, %res_lower) : (i1, !transfer.integer, !transfer.integer) ->!transfer.integer
     %ret_upper = "transfer.select"(%ret_top_cond, %max, %res_upper) : (i1, !transfer.integer, !transfer.integer) ->!transfer.integer

     %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
     "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
 }) {"sym_name" = "ucr_add", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %max = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    // Feasibility: there exists a valid nuw pair iff lhs_lower + rhs_lower does not overflow.
    %lower_ov = "transfer.uadd_overflow"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> i1
    %exists = "arith.xori"(%lower_ov, %const_true) : (i1, i1) -> i1

    %res_lower = "transfer.add"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Upper endpoint is either lhs_upper + rhs_upper (no overflow) or all-ones (overflow => cap at max valid sum).
    %upper_sum = "transfer.add"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_ov = "transfer.uadd_overflow"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %res_upper = "transfer.select"(%upper_ov, %max, %upper_sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // No feasible pair means empty result set (domain bottom encoded as [max, 0]).
    %ret_lower = "transfer.select"(%exists, %res_lower, %max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%exists, %res_upper, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_addnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %res_lower = "transfer.sub"(%lhs_lower, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_upper = "transfer.sub"(%lhs_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %no_wrap = "transfer.cmp"(%lhs_lower, %rhs_upper) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %all_wrap = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %single_interval = "arith.ori"(%no_wrap, %all_wrap) : (i1, i1) -> i1

    %ret_lower = "transfer.select"(%single_interval, %res_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%single_interval, %res_upper, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_sub", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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