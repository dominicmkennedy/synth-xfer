func.func @getConstraint(%x_abst: !transfer.abs_value<[i5]>) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i5]>) -> i5
  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i5) -> i5
  %ret = "transfer.cmp"(%const0, %x) {predicate = 1 : i64} : (i5, i5) -> i1
  return %ret : i1
}
