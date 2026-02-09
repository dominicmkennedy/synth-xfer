func.func @getConstraint(%x_abst: !transfer.abs_value<[i3]>) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i3]>) -> i3
  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i3) -> i3
  %ret = "transfer.cmp"(%const0, %x) {predicate = 1 : i64} : (i3, i3) -> i1
  return %ret : i1
}
