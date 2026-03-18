module {
  func.func @concrete_op(%arg0: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.countr_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %not_0 = "transfer.cmp"(%arg0, %const_0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %not_0 : i1
  }
}
