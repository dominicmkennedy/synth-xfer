builtin.module {
  func.func @leading_zeros_offset_shift_transfer(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of a constant shifted by the difference between a bound and the input's leading-zero count.
    %v3 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %v2 = "transfer.sub"(%h0, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @masked_input_abstract_lookup(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input masked to its known bits by a constant bit-mask.
    %v1 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @self_referenced_shift_transfer(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of a constant shifted by its own distance from the input value.
    %v2 = "transfer.sub"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
