func.func @partial_solution_14_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "3_966_1"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.get_bit_width %5 : !transfer.integer
  %7 = transfer.countl_one %6 : !transfer.integer
  %8 = transfer.neg %4 : !transfer.integer
  %9 = transfer.cmp eq, %8, %2 : !transfer.integer
  %10 = transfer.select %9, %3, %7 : !transfer.integer
  %11 = transfer.countl_one %6 : !transfer.integer
  %12 = transfer.make %11, %10 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
