func.func @meet(%lhs_abst: !transfer.abs_value<[i5]>, %rhs_abst: !transfer.abs_value<[i5]>) -> !transfer.abs_value<[i5]> {
  %lhs = "transfer.get"(%lhs_abst) {index = 0 : index} : (!transfer.abs_value<[i5]>) -> i5
  %rhs = "transfer.get"(%rhs_abst) {index = 0 : index} : (!transfer.abs_value<[i5]>) -> i5
  %ret = "transfer.and"(%lhs, %rhs) : (i5, i5) -> i5
  %ret_abst = "transfer.make"(%ret) : (i5) -> !transfer.abs_value<[i5]>
  return %ret_abst : !transfer.abs_value<[i5]>
}
