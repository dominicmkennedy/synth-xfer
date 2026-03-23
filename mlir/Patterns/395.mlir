module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.add"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @add_nuw(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %2 = call @add_nsw(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.add"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @add_nuw(%arg2, %0) : (!transfer.integer, !transfer.integer) -> i1
    %5 = call @add_nsw(%arg2, %0) : (!transfer.integer, !transfer.integer) -> i1
    %6 = "transfer.add"(%arg1, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = call @add_nuw(%arg1, %3) : (!transfer.integer, !transfer.integer) -> i1
    %8 = call @add_nsw(%arg1, %3) : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.add"(%arg0, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = call @add_nuw(%arg0, %6) : (!transfer.integer, !transfer.integer) -> i1
    %11 = call @add_nsw(%arg0, %6) : (!transfer.integer, !transfer.integer) -> i1
    %12 = arith.andi %true, %1 : i1
    %13 = arith.andi %12, %2 : i1
    %14 = arith.andi %13, %4 : i1
    %15 = arith.andi %14, %5 : i1
    %16 = arith.andi %15, %7 : i1
    %17 = arith.andi %16, %8 : i1
    %18 = arith.andi %17, %10 : i1
    %19 = arith.andi %18, %11 : i1
    return %19 : i1
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