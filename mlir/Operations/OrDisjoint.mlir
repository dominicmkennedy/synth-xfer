module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.or"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %and = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %disjoint = "transfer.cmp"(%const_0, %and) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %disjoint : i1
  }
}
