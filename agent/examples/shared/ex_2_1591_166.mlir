func.func @partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "2_1591_166"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 1 : !transfer.integer
  %7 = transfer.get_bit_width %5 : !transfer.integer
  %8 = transfer.and %5, %3 : !transfer.integer
  %9 = transfer.countr_one %4 : !transfer.integer
  %10 = transfer.and %8, %3 : !transfer.integer
  %11 = transfer.countl_zero %4 : !transfer.integer
  %12 = transfer.umax %11, %5 : !transfer.integer
  %13 = transfer.clear_low_bits %2, %7 : !transfer.integer
  %14 = transfer.add %6, %4 : !transfer.integer
  %15 = transfer.clear_low_bits %9, %12 : !transfer.integer
  %16 = transfer.and %13, %15 : !transfer.integer
  %17 = transfer.and %14, %10 : !transfer.integer
  %18 = transfer.make %17, %16 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
