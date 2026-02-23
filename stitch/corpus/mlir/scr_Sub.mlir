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
