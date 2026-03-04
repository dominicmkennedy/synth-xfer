builtin.module {
  func.func @knownbits_are_consistent(%known0 : !transfer.integer, %known1 : !transfer.integer, %width_ref : !transfer.integer) -> i1 {
    // Verifies that known-zero and known-one masks do not overlap.
    %const0 = "transfer.constant"(%width_ref) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %conflict = "transfer.and"(%known0, %known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    func.return %consistent : i1
  }
  func.func @range_common_prefix_knownbits(%width_ref : !transfer.integer, %range_min : !transfer.integer, %range_max : !transfer.integer) -> (!transfer.integer, !transfer.integer) {
    // Builds known-zero/one masks from the shared prefix of the range endpoints.
    %diff = "transfer.xor"(%range_min, %range_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%width_ref) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%width_ref) : (!transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%range_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%range_min, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res0, %res1 : (!transfer.integer, !transfer.integer)
  }
}