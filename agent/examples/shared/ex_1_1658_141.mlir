func.func @partial_solution_7_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "1_1658_141"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_all_ones %4 : !transfer.integer
  %7 = transfer.get_bit_width %4 : !transfer.integer
  %8 = transfer.or %5, %7 : !transfer.integer
  %9 = transfer.ashr %6, %6 : !transfer.integer
  %10 = transfer.ashr %9, %8 : !transfer.integer
  %11 = transfer.countr_one %3 : !transfer.integer
  %12 = transfer.and %11, %2 : !transfer.integer
  %13 = transfer.countr_zero %8 : !transfer.integer
  %14 = transfer.ashr %10, %10 : !transfer.integer
  %15 = transfer.set_low_bits %14, %13 : !transfer.integer
  %16 = transfer.countl_zero %15 : !transfer.integer
  %17 = transfer.clear_low_bits %12, %13 : !transfer.integer
  %18 = transfer.clear_high_bits %16, %16 : !transfer.integer
  %19 = transfer.make %18, %17 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %19 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
