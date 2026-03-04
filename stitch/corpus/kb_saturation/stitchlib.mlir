builtin.module {
  func.func @or_constant_mask_transfer(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input OR'd with a constant bit-mask.
    %v1 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @make_pair_conditional_lower(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The abstract value pairing a fixed upper bound with a lower bound chosen by a boolean condition.
    %v1 = "transfer.select"(%h2, %arg0, %h1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%h0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @composed_triple_lookup_transfer(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // The abstract image of a value passed through three composed abstract transformations in sequence.
    %v2 = func.call @%h0(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = func.call @%h1(%v2) : (!transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
