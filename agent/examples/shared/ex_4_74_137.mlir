func.func @partial_solution_12_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_74_137"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get_all_ones %4 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.cmp eq, %3, %5 : !transfer.integer
  %8 = transfer.select %7, %2, %6 : !transfer.integer
  %9 = transfer.select %7, %8, %4 : !transfer.integer
  %10 = transfer.clear_low_bits %8, %4 : !transfer.integer
  %11 = transfer.countl_one %6 : !transfer.integer
  %12 = transfer.and %10, %9 : !transfer.integer
  %13 = transfer.make %12, %11 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %13 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
