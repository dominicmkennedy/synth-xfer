func.func @getConstraint(%x_abst: !transfer.abs_value<[i13]>) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i13]>) -> i13
  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i13) -> i13
  %ret = "transfer.cmp"(%const0, %x) {predicate = 1 : i64} : (i13, i13) -> i1
  return %ret : i1
}
