module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.udiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @udiv_exact(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @rhs_neq_zero(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_1_0, %constraint_1_1 : i1
    return %and_0 : i1
  }
  func.func @udiv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %urem = "transfer.urem"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%urem, %const_0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.cmp"(%const_0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %rhs_not : i1
  }
}
