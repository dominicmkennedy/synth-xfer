builtin.module {
  // Computes arg0 | h0 and passes the result to continuation h1.
  func.func @kb_multiplicative_0(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Packs h0() and select(h2, arg0, h1) into an abstract value.
  func.func @kb_multiplicative_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v1 = "transfer.select"(%h2, %arg0, %h1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.make"(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Pipelines arg0 through three continuations in sequence: h0 → h1 → h2.
  func.func @kb_multiplicative_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v0 = func.call @%h0(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = func.call @%h1(%v0) : (!transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
}
