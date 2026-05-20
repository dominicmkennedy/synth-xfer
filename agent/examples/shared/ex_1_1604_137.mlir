func.func @partial_solution_19_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "1_1604_137"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 0 : !transfer.integer
  %7 = transfer.get_all_ones %5 : !transfer.integer
  %8 = transfer.cmp ult, %4, %7 : !transfer.integer
  %9 = transfer.neg %3 : !transfer.integer
  %10 = transfer.countl_zero %9 : !transfer.integer
  %11 = transfer.umin %2, %9 : !transfer.integer
  %12 = transfer.set_high_bits %6, %10 : !transfer.integer
  %13 = transfer.select %8, %6, %11 : !transfer.integer
  %14 = transfer.make %13, %12 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
