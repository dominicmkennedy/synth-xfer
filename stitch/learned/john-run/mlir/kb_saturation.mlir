builtin.module {
  // Selects h1 or arg0 based on h0(), then passes the chosen value to continuation h2.
  func.func @kb_saturation_0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v2 = "transfer.select"(%v0, %h1, %arg0) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
  // Computes arg0 & h1 & h0 and passes the result to continuation h2.
  func.func @kb_saturation_1(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = "transfer.and"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.and"(%arg0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
  // Computes arg0 | h0 | h1 and passes the result to continuation h2.
  func.func @kb_saturation_2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.or"(%v0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
}
