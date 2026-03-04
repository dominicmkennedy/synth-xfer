builtin.module {
  func.func @unknown_mask(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Computes the mask of bits that are neither known-zero nor known-one.
    %known_zero = "transfer.get"(%kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known_one = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known_union = "transfer.or"(%known_zero, %known_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known_zero) : (!transfer.integer) -> !transfer.integer
    %unknown = "transfer.xor"(%known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %unknown : !transfer.integer
  }
  func.func @maybe_zero_mask(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Returns the mask of bits that may be zero (complement of known-one).
    %known_one = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known_one) : (!transfer.integer) -> !transfer.integer
    %maybe_zero = "transfer.xor"(%known_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %maybe_zero : !transfer.integer
  }
  func.func @common_prefix_mask(%a : !transfer.integer, %b : !transfer.integer) -> !transfer.integer {
    // Builds a mask of the high bits that are identical in both inputs.
    %diff = "transfer.xor"(%a, %b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %clz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%a) : (!transfer.integer) -> !transfer.integer
    %shift = "transfer.sub"(%bitwidth, %clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%a) : (!transfer.integer) -> !transfer.integer
    %mask = "transfer.shl"(%all_ones, %shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %mask : !transfer.integer
  }
}