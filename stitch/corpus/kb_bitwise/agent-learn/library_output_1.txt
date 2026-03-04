builtin.module {
  func.func @kb_knownbits_consistent(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    // Check that the known-zero and known-one masks do not overlap.
    %known_zero = "transfer.get"(%kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known_one = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %conflict = "transfer.and"(%known_zero, %known_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%known_zero) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    func.return %consistent : i1
  }
  func.func @kb_unknown_mask(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Return the mask of bits whose value is not known to be 0 or 1.
    %known_zero = "transfer.get"(%kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known_one = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known_union = "transfer.or"(%known_zero, %known_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known_zero) : (!transfer.integer) -> !transfer.integer
    %unknown_mask = "transfer.xor"(%known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %unknown_mask : !transfer.integer
  }
}