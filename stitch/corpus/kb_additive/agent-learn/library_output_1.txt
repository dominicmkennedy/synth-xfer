builtin.module {
  func.func @compute_addition_carry_bounds(%min_and : !transfer.integer, %min_or : !transfer.integer, %sum_min : !transfer.integer, %max_and : !transfer.integer, %max_or : !transfer.integer, %sum_max : !transfer.integer, %all_ones : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // Derives carry-out lower/upper masks from known operand sum bounds.
    %sum_min_not = "transfer.xor"(%sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or_and_sum_not = "transfer.and"(%min_or, %sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_min = "transfer.or"(%min_and, %min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max_not = "transfer.xor"(%sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or_and_sum_not = "transfer.and"(%max_or, %sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_max = "transfer.or"(%max_and, %max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.make"(%carry_out_min, %carry_out_max) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %res : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @combine_xor_with_carry_masks(%xor_ab_0 : !transfer.integer, %xor_ab_1 : !transfer.integer, %carry_zero : !transfer.integer, %carry_one : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // Produces result zero/one masks by intersecting operand xor masks with carry possibilities.
    %res0_and0 = "transfer.and"(%xor_ab_0, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_and1 = "transfer.and"(%xor_ab_1, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%res0_and0, %res0_and1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_and0 = "transfer.and"(%xor_ab_0, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_and1 = "transfer.and"(%xor_ab_1, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%res1_and0, %res1_and1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %res : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}