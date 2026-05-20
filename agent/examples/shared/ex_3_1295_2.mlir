func.func @partial_solution_7_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "3_1295_2"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.constant %4, 1 : !transfer.integer
  %7 = transfer.get_all_ones %4 : !transfer.integer
  %8 = transfer.cmp eq, %5, %7 : !transfer.integer
  %9 = transfer.countr_one %4 : !transfer.integer
  %10 = transfer.set_low_bits %5, %9 : !transfer.integer
  %11 = transfer.and %3, %2 : !transfer.integer
  %12 = transfer.set_high_bits %3, %6 : !transfer.integer
  %13 = transfer.sub %10, %4 : !transfer.integer
  %14 = transfer.udiv %5, %6 : !transfer.integer
  %15 = transfer.cmp eq, %7, %12 : !transfer.integer
  %16 = transfer.select %8, %13, %14 : !transfer.integer
  %17 = transfer.lshr %16, %11 : !transfer.integer
  %18 = transfer.select %15, %11, %17 : !transfer.integer
  %19 = transfer.clear_sign_bit %17 : !transfer.integer
  %20 = transfer.make %19, %18 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %20 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
