func.func @meet(%lhs_abst: !transfer.abs_value<[i3]>, %rhs_abst: !transfer.abs_value<[i3]>) -> !transfer.abs_value<[i3]> {
  %lhs = "transfer.get"(%lhs_abst) {index = 0 : index} : (!transfer.abs_value<[i3]>) -> i3
  %rhs = "transfer.get"(%rhs_abst) {index = 0 : index} : (!transfer.abs_value<[i3]>) -> i3
  %ret = "transfer.and"(%lhs, %rhs) : (i3, i3) -> i3
  %ret_abst = "transfer.make"(%ret) : (i3) -> !transfer.abs_value<[i3]>
  return %ret_abst : !transfer.abs_value<[i3]>
}
