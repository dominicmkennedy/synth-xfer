module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.lshr"(%1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %0 = "transfer.mul"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_0_0 = func.call @mul_nuw(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_0_1 = func.call @mul_nsw(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @add_nuw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @add_nsw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_2_0 = func.call @shift_lt_bw(%1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_0_0, %constraint_0_1 : i1
    %and_1 = arith.andi %and_0, %constraint_1_0 : i1
    %and_2 = arith.andi %and_1, %constraint_1_1 : i1
    %and_3 = arith.andi %and_2, %constraint_2_0 : i1
    return %and_3 : i1
  }
  func.func @mul_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
  }
  func.func @mul_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
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
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
