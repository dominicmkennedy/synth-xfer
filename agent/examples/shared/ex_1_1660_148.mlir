func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "1_1660_148"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.set_high_bits %3, %5 : !transfer.integer
  %7 = transfer.and %6, %5 : !transfer.integer
  %8 = transfer.neg %4 : !transfer.integer
  %9 = transfer.and %2, %7 : !transfer.integer
  %10 = transfer.shl %5, %8 : !transfer.integer
  %11 = transfer.make %10, %9 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
