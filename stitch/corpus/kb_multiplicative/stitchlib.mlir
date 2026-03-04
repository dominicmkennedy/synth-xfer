builtin.module {
  func.func @conditional_constant_override_transfer(%h0 : i1, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of a value that is either a fixed constant or the input, chosen by a condition.
    %v1 = "transfer.select"(%h0, %h1, %arg0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @double_and_mask_transfer(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input masked by the conjunction of two constant bit-masks.
    %v2 = "transfer.and"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.and"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @or_two_masks_transfer(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input OR'd with two constant bit-masks.
    %v2 = "transfer.or"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%v2, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
