module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.add"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %0_constraint_0 = func.call @add_nuw(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %0_constraint_1 = func.call @add_nsw(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1_constraint_0 = func.call @add_nuw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %1_constraint_1 = func.call @add_nsw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %2_constraint_0 = func.call @add_nuw(%arg0, %1) : (!transfer.integer, !transfer.integer) -> i1
    %2_constraint_1 = func.call @add_nsw(%arg0, %1) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %0_constraint_0, %0_constraint_1 : i1
    %and_1 = arith.andi %and_0, %1_constraint_0 : i1
    %and_2 = arith.andi %and_1, %1_constraint_1 : i1
    %and_3 = arith.andi %and_2, %2_constraint_0 : i1
    %and_4 = arith.andi %and_3, %2_constraint_1 : i1
    return %and_4 : i1
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.cmp"(%0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = arith.andi %1, %2 : i1
    return %3 : i1
  }
  func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.and"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.constant"(%arg0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%3, %4) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %5 : i1
  }
}