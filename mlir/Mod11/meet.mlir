func.func @meet(%lhs_abst: !transfer.abs_value<[i11]>, %rhs_abst: !transfer.abs_value<[i11]>) -> !transfer.abs_value<[i11]> {
  %lhs = "transfer.get"(%lhs_abst) {index = 0 : index} : (!transfer.abs_value<[i11]>) -> i11
  %rhs = "transfer.get"(%rhs_abst) {index = 0 : index} : (!transfer.abs_value<[i11]>) -> i11
  %ret = "transfer.and"(%lhs, %rhs) : (i11, i11) -> i11
  %ret_abst = "transfer.make"(%ret) : (i11) -> !transfer.abs_value<[i11]>
  return %ret_abst : !transfer.abs_value<[i11]>
}
