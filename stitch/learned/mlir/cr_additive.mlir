builtin.module {
  // Packs arg0 and select(h2, h1, h0) into an abstract value.
  func.func @cr_additive_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.select"(%h2, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.make"(%arg0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // ANDs boolean arg0 with h0(), then passes the masked value to continuation h1.
  func.func @cr_additive_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v2 = "arith.andi"(%arg0, %v0) : (i1, !transfer.integer) -> i1
    %v1 = func.call @%h1(%v2) : (i1) -> !transfer.integer
    func.return %v1 : !transfer.integer
  }
  // Selects h1 or h0 based on boolean arg0, then passes the result to continuation h2.
  func.func @cr_additive_2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "transfer.select"(%arg0, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
