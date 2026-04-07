module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.udiv"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %check = "transfer.cmp"(%const_0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %check : i1
  }
}
