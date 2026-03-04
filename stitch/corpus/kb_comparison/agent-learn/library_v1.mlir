builtin.module {
  func.func @knownbits_are_consistent(%lhs0 : !transfer.integer, %lhs1 : !transfer.integer, %rhs0 : !transfer.integer, %rhs1 : !transfer.integer) -> i1 {
    // Determines whether both KnownBits values avoid zero/one conflicts.
    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %any_conflict = "transfer.or"(%lhs_conflict, %rhs_conflict) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%any_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    func.return %consistent : i1
  }
  func.func @knownbits_from_range_shared_prefix(%lb : !transfer.integer, %ub : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // Derives the mask of bits that are identical for every value in [lb, ub].
    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lb) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lb) : (!transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %iv0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %iv1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.make"(%iv0, %iv1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %res : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @clip_knownbits_to_lower_bound(%known0 : !transfer.integer, %known1 : !transfer.integer, %lower_bound : !transfer.integer, %value_max : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // Refines KnownBits so that every represented value is at least the lower bound.
    %diff = "transfer.xor"(%lower_bound, %value_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lower_bound) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lower_bound) : (!transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lower_bound, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %clip_iv0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %clip_iv1 = "transfer.and"(%lower_bound, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %clip0 = "transfer.or"(%known0, %clip_iv0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %clip1 = "transfer.or"(%known1, %clip_iv1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.make"(%clip0, %clip1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %res : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}