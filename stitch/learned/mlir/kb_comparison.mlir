builtin.module {
  // Shifts h1 left by (h0 - clz(arg0)) and passes the result to continuation h2.
  func.func @kb_comparison_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.sub"(%h0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.shl"(%h1, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = func.call @%h2(%v3) : (!transfer.integer) -> !transfer.integer
    func.return %v2 : !transfer.integer
  }
  // Masks arg0 with h0 and passes the result to continuation h1.
  func.func @kb_comparison_1(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Shifts h0 left by (arg0 - h0) and passes the result to continuation h1.
  func.func @kb_comparison_2(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = "transfer.sub"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.shl"(%h0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h1(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
}
