module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg1, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.add"(%1, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %4 : !transfer.integer
  }
}
