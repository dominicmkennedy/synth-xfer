func.func @partial_solution_11_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "4_159_5"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_all_ones %4 : !transfer.integer
  %7 = transfer.sub %3, %6 : !transfer.integer
  %8 = transfer.smin %2, %6 : !transfer.integer
  %9 = transfer.udiv %2, %5 : !transfer.integer
  %10 = transfer.clear_high_bits %9, %8 : !transfer.integer
  %11 = transfer.and %3, %8 : !transfer.integer
  %12 = transfer.clear_high_bits %7, %11 : !transfer.integer
  %13 = transfer.umin %10, %5 : !transfer.integer
  %14 = transfer.countl_one %12 : !transfer.integer
  %15 = transfer.make %14, %13 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
