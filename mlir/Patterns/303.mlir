module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.xor"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.xor"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.xor"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.xor"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %true : i1
  }
  func.func @patternImpl(%arg0: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg3: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg4: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {CPPCLASS = ["non_cpp_class"], applied_to = ["llvm_pattern"], is_forward = true} {
    return %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

