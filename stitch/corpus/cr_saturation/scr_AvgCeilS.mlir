"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    // lower = avgceils(lhs_lower, rhs_lower) = (a | b) - ((a ^ b) >>s 1)
    %lower_or = "transfer.or"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_xor = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_ashr = "transfer.ashr"(%lower_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_lower = "transfer.sub"(%lower_or, %lower_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // upper = avgceils(lhs_upper, rhs_upper) = (a | b) - ((a ^ b) >>s 1)
    %upper_or = "transfer.or"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_xor = "transfer.xor"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_ashr = "transfer.ashr"(%upper_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_upper = "transfer.sub"(%upper_or, %upper_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res_lower, %res_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_avgceils", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
