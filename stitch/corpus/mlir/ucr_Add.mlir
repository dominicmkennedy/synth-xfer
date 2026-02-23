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
