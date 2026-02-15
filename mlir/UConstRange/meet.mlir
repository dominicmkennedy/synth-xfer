func.func @meet(%lhs: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs_lb = "transfer.get"(%lhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %lhs_ub = "transfer.get"(%lhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_lb = "transfer.get"(%rhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_ub = "transfer.get"(%rhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %res_lb = "transfer.umax"(%lhs_lb, %rhs_lb) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %res_ub = "transfer.umin"(%lhs_ub, %rhs_ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %result = "transfer.make"(%res_lb, %res_ub) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
