func.func @partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_985_120"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.cmp ule, %4, %2 : !transfer.integer
  %7 = transfer.udiv %5, %5 : !transfer.integer
  %8 = transfer.set_low_bits %4, %4 : !transfer.integer
  %9 = transfer.select %6, %8, %5 : !transfer.integer
  %10 = transfer.smax %3, %5 : !transfer.integer
  %11 = transfer.set_high_bits %9, %3 : !transfer.integer
  %12 = transfer.countl_zero %11 : !transfer.integer
  %13 = transfer.shl %9, %10 : !transfer.integer
  %14 = transfer.set_low_bits %12, %7 : !transfer.integer
  %15 = transfer.make %14, %13 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
