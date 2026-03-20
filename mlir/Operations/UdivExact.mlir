module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.udiv"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %rhs_not_0 = "transfer.cmp"(%const_0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %urem = "transfer.urem"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%urem, %const_0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %res = arith.andi %exact, %rhs_not_0 : i1
    return %res : i1
  }
}
