module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %true : i1
  }
  func.func @patternImpl(%arg0: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg3: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {CPPCLASS = ["non_cpp_class"], applied_to = ["llvm_pattern"], is_forward = true} {
    return %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

