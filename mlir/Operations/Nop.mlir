module {
  func.func @concrete_op(%arg0: !transfer.integer) -> !transfer.integer {
    return %arg0 : !transfer.integer
  }
}
