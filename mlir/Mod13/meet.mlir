func.func @meet(%lhs_abst: !transfer.abs_value<[i13]>, %rhs_abst: !transfer.abs_value<[i13]>) -> !transfer.abs_value<[i13]> {
  %lhs = "transfer.get"(%lhs_abst) {index = 0 : index} : (!transfer.abs_value<[i13]>) -> i13
  %rhs = "transfer.get"(%rhs_abst) {index = 0 : index} : (!transfer.abs_value<[i13]>) -> i13
  %ret = "transfer.and"(%lhs, %rhs) : (i13, i13) -> i13
  %ret_abst = "transfer.make"(%ret) : (i13) -> !transfer.abs_value<[i13]>
  return %ret_abst : !transfer.abs_value<[i13]>
}
