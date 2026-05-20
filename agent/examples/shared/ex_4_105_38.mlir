func.func @partial_solution_10_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "4_105_38"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get_bit_width %3 : !transfer.integer
  %5 = transfer.set_sign_bit %3 : !transfer.integer
  %6 = transfer.neg %5 : !transfer.integer
  %7 = transfer.set_sign_bit %4 : !transfer.integer
  %8 = transfer.srem %3, %7 : !transfer.integer
  %9 = transfer.clear_high_bits %2, %4 : !transfer.integer
  %10 = transfer.clear_low_bits %8, %6 : !transfer.integer
  %11 = transfer.make %10, %9 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
