module {
  func.func @concrete_op(%arg0: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.countr_one"(%arg0) : (!transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
}
