module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.ashr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.ashr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @ashr_exact(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %2 = call @shifting_amount_less_bitwidth(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.sub"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @sub_nuw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %5 = call @sub_nsw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.andi %true, %1 : i1
    %7 = arith.andi %6, %2 : i1
    %8 = arith.andi %7, %4 : i1
    %9 = arith.andi %8, %5 : i1
    return %9 : i1
  }
  func.func @ashr_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.ashr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = "transfer.shl"(%5, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.andi %4, %7 : i1
    return %8 : i1
  }
  func.func @shifting_amount_less_bitwidth(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    return %4 : i1
  }
  func.func @sub_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.cmp"(%arg0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %0 : i1
  }
  func.func @sub_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.sub"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.and"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.constant"(%arg0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%3, %4) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %5 : i1
  }
}