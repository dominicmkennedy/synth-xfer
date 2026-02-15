func.func @meet(%lhs: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs_z = "transfer.get"(%lhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %lhs_o = "transfer.get"(%lhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_z = "transfer.get"(%rhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_o = "transfer.get"(%rhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %res_z = "transfer.or"(%lhs_z, %rhs_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %res_o = "transfer.or"(%lhs_o, %rhs_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %result = "transfer.make"(%res_z, %res_o) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
