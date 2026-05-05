func.func @cr_add(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs_lower = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %lhs_upper = transfer.get %lhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %rhs_lower = transfer.get %rhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %rhs_upper = transfer.get %rhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %res_lower = transfer.add %lhs_lower, %rhs_lower : !transfer.integer
  %res_upper = transfer.add %lhs_upper, %rhs_upper : !transfer.integer
  %res_lower_ov = transfer.uadd_overflow %lhs_lower, %rhs_lower : !transfer.integer
  %res_upper_ov = transfer.uadd_overflow %lhs_upper, %rhs_upper : !transfer.integer
  %lower_ge_upper = transfer.cmp ugt, %res_lower, %res_upper : !transfer.integer
  %overflow = arith.xori %res_lower_ov, %res_upper_ov : i1
  %ret_top_cond = arith.ori %lower_ge_upper, %overflow : i1
  %min = transfer.constant %lhs_lower, 0 : !transfer.integer
  %max = transfer.get_all_ones %lhs_lower : !transfer.integer
  %ret_lower = transfer.select %ret_top_cond, %min, %res_lower : !transfer.integer
  %ret_upper = transfer.select %ret_top_cond, %max, %res_upper : !transfer.integer
  %r = transfer.make %ret_lower, %ret_upper : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
