builtin.module {
  // Computes arg0 - (h0() >> h1) via arithmetic right shift, then passes the result to continuation h2.
  func.func @cr_saturation_0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v1 = "transfer.ashr"(%v0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.sub"(%arg0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = func.call @%h2(%v3) : (!transfer.integer) -> !transfer.integer
    func.return %v2 : !transfer.integer
  }
  // Applies learned abstraction fn_0 to the XOR of h1 and h0.
  func.func @cr_saturation_1(%h0 : !transfer.integer, %h1 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @fn_0(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Packs h0 and arg0 directly into an abstract value.
  func.func @cr_saturation_2(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
