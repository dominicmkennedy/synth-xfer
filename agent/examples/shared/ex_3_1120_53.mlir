func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "3_1120_53"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get_bit_width %3 : !transfer.integer
  %5 = transfer.countl_one %2 : !transfer.integer
  %6 = transfer.countl_zero %3 : !transfer.integer
  %7 = transfer.clear_low_bits %4, %5 : !transfer.integer
  %8 = transfer.countl_one %7 : !transfer.integer
  %9 = transfer.sdiv %5, %7 : !transfer.integer
  %10 = transfer.umin %9, %8 : !transfer.integer
  %11 = transfer.shl %5, %6 : !transfer.integer
  %12 = transfer.make %11, %10 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
