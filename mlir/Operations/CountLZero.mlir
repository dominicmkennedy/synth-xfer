module {
  func.func @concrete_op(%arg0: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
}
