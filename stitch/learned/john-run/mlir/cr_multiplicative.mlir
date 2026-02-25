builtin.module {
  // ANDs booleans h0 and arg0, then passes the result to continuation h1.
  func.func @cr_multiplicative_0(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%h0, %arg0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // ANDs booleans arg0 and h0 (operand-swapped variant of _0), then passes the result to continuation h1.
  func.func @cr_multiplicative_1(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Applies h1 to (arg0, h0()), then passes the result to continuation h2.
  func.func @cr_multiplicative_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v2 = func.call @%h1(%arg0, %v0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h2(%v2) : (!transfer.integer) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
}
