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
