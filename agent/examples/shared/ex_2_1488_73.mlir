func.func @partial_solution_8_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "2_1488_73"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.get_bit_width %5 : !transfer.integer
  %7 = transfer.countl_zero %6 : !transfer.integer
  %8 = transfer.countl_one %6 : !transfer.integer
  %9 = transfer.countl_one %6 : !transfer.integer
  %10 = transfer.smax %4, %4 : !transfer.integer
  %11 = transfer.sub %7, %8 : !transfer.integer
  %12 = transfer.clear_low_bits %2, %11 : !transfer.integer
  %13 = transfer.neg %10 : !transfer.integer
  %14 = transfer.udiv %3, %13 : !transfer.integer
  %15 = transfer.clear_high_bits %12, %9 : !transfer.integer
  %16 = transfer.make %15, %14 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
