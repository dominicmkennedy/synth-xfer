module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.add"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_0_0 = func.call @add_nuw(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_0_1 = func.call @add_nsw(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.add"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @add_nuw(%arg2, %0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @add_nsw(%arg2, %0) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.add"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_2_0 = func.call @add_nuw(%arg1, %1) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_2_1 = func.call @add_nsw(%arg1, %1) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_3_0 = func.call @add_nuw(%arg0, %2) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_3_1 = func.call @add_nsw(%arg0, %2) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_0_0, %constraint_0_1 : i1
    %and_1 = arith.andi %and_0, %constraint_1_0 : i1
    %and_2 = arith.andi %and_1, %constraint_1_1 : i1
    %and_3 = arith.andi %and_2, %constraint_2_0 : i1
    %and_4 = arith.andi %and_3, %constraint_2_1 : i1
    %and_5 = arith.andi %and_4, %constraint_3_0 : i1
    %and_6 = arith.andi %and_5, %constraint_3_1 : i1
    return %and_6 : i1
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %uadd_ov = "transfer.uadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %uadd_ov, %true : i1
    return %no_ov : i1
  }
  func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %sadd_ov = "transfer.sadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %sadd_ov, %true : i1
    return %no_ov : i1
  }
}
