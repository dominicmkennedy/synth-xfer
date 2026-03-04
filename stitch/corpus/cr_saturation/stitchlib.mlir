builtin.module {
  func.func @sub_arithmetic_shifted_constant_transfer(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input minus an arithmetic-right-shifted constant.
    %v2 = "transfer.ashr"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.sub"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @xor_constants_fn0_lookup(%h0 : !transfer.integer, %h1 : !transfer.integer) -> !transfer.integer {
    // The image of the XOR of two constant values under the base transfer function fn_0.
    %v1 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @fn_0(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @make_pair_fixed_upper_concrete_lower(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The abstract value whose upper component is a fixed constant and lower component is the concrete input.
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
