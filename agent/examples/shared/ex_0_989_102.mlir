func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_989_102"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 0 : !transfer.integer
  %5 = transfer.constant %3, 1 : !transfer.integer
  %6 = transfer.get_all_ones %3 : !transfer.integer
  %7 = transfer.neg %3 : !transfer.integer
  %8 = transfer.udiv %2, %7 : !transfer.integer
  %9 = transfer.smax %8, %4 : !transfer.integer
  %10 = transfer.ashr %9, %5 : !transfer.integer
  %11 = transfer.mul %8, %6 : !transfer.integer
  %12 = transfer.popcount %10 : !transfer.integer
  %13 = transfer.make %12, %11 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %13 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
