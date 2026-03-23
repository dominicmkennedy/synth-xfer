module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.lshr"(%1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.xor"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @mul_nuw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = call @mul_nuw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %4 = "transfer.lshr"(%2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = call @shifting_amount_less_bitwidth(%2, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %6 = "transfer.xor"(%0, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = arith.andi %true, %1 : i1
    %8 = arith.andi %7, %3 : i1
    %9 = arith.andi %8, %5 : i1
    return %9 : i1
  }
  func.func @mul_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
  }
  func.func @shifting_amount_less_bitwidth(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    return %4 : i1
  }
}