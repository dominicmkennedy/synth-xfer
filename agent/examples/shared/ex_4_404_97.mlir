func.func @partial_solution_7_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_404_97"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.cmp ule, %2, %2 : !transfer.integer
  %8 = transfer.and %4, %6 : !transfer.integer
  %9 = transfer.select %7, %4, %8 : !transfer.integer
  %10 = transfer.and %9, %2 : !transfer.integer
  %11 = transfer.shl %10, %5 : !transfer.integer
  %12 = transfer.and %2, %3 : !transfer.integer
  %13 = transfer.clear_low_bits %11, %10 : !transfer.integer
  %14 = transfer.clear_low_bits %5, %6 : !transfer.integer
  %15 = transfer.and %13, %2 : !transfer.integer
  %16 = transfer.and %14, %14 : !transfer.integer
  %17 = transfer.and %15, %12 : !transfer.integer
  %18 = transfer.make %17, %16 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
