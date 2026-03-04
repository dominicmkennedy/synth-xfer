module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @add_nuw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.and"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = arith.andi %true, %1 : i1
    return %3 : i1
  }
  func.func @patternImpl(%arg0: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {CPPCLASS = ["non_cpp_class"], applied_to = ["llvm_pattern"], is_forward = true} {
    return %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.cmp"(%0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = arith.andi %1, %2 : i1
    return %3 : i1
  }
}

