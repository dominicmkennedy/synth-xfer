module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.ashr"(%1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.mul"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @mul_nsw(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = call @add_nsw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %4 = "transfer.ashr"(%2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = call @shifting_amount_less_bitwidth(%2, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.andi %true, %1 : i1
    %7 = arith.andi %6, %3 : i1
    %8 = arith.andi %7, %5 : i1
    return %8 : i1
  }
  func.func @mul_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
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
  func.func @shifting_amount_less_bitwidth(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    return %4 : i1
  }
}