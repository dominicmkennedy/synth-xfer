func.func @meet(%lhs_abst: !transfer.abs_value<[i7]>, %rhs_abst: !transfer.abs_value<[i7]>) -> !transfer.abs_value<[i7]> {
  %lhs = "transfer.get"(%lhs_abst) {index = 0 : index} : (!transfer.abs_value<[i7]>) -> i7
  %rhs = "transfer.get"(%rhs_abst) {index = 0 : index} : (!transfer.abs_value<[i7]>) -> i7
  %ret = "transfer.and"(%lhs, %rhs) : (i7, i7) -> i7
  %ret_abst = "transfer.make"(%ret) : (i7) -> !transfer.abs_value<[i7]>
  return %ret_abst : !transfer.abs_value<[i7]>
}
