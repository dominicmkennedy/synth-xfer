builtin.module {
  func.func @bitwise_average_ceil(%a : !transfer.integer, %b : !transfer.integer) -> !transfer.integer {
    // Computes the bitwise average ceiling of two masks for KnownBits intervals.
    %const1 = "transfer.constant"(%a) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %or = "transfer.or"(%a, %b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor = "transfer.xor"(%a, %b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shr = "transfer.ashr"(%xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.sub"(%or, %shr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }
}