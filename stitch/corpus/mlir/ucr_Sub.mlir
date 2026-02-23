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
