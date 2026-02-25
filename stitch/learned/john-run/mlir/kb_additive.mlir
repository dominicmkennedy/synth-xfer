builtin.module {
  // Selects between (h1-h0) and (h0-h1) based on boolean arg0, then passes the result to continuation h2.
  func.func @kb_additive_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v0 = "transfer.sub"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.sub"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.select"(%arg0, %v0, %v1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = func.call @%h2(%v3) : (!transfer.integer) -> !transfer.integer
    func.return %v2 : !transfer.integer
  }
  // Computes arg0 | (h0() & h1()) and passes the result to continuation h2.
  func.func @kb_additive_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v1 = func.call @%h1() : () -> !transfer.integer
    %v2 = "transfer.and"(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.or"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = func.call @%h2(%v4) : (!transfer.integer) -> !transfer.integer
    func.return %v3 : !transfer.integer
  }
  // Shifts h1 left by (h0 - arg0) and passes the result to continuation h2.
  func.func @kb_additive_2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = "transfer.sub"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.shl"(%h1, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
}
