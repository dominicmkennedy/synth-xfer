func.func @partial_solution_10_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_3_92"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 1 : !transfer.integer
  %5 = transfer.get_bit_width %3 : !transfer.integer
  %6 = transfer.and %5, %4 : !transfer.integer
  %7 = transfer.and %6, %4 : !transfer.integer
  %8 = transfer.srem %3, %7 : !transfer.integer
  %9 = transfer.and %3, %2 : !transfer.integer
  %10 = transfer.make %9, %8 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %10 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
