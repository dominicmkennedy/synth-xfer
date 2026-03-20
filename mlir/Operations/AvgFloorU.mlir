module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %xor = "transfer.xor"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_1 = "transfer.constant"(%arg0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %lshr = "transfer.lshr"(%xor, %const_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.add"(%and, %lshr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
