builtin.module {
  func.func @signed_half_thresholds(%input : !transfer.integer) -> (!transfer.integer, !transfer.integer) {
    // Returns the maximum non-negative signed value and the sign bit mask for this width.
    %const1 = "transfer.constant"(%input) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%input) : (!transfer.integer) -> !transfer.integer
    %sign_minus_1 = "transfer.lshr"(%all_ones, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %sign_minus_1, %sign_bit : !transfer.integer, !transfer.integer
  }
}