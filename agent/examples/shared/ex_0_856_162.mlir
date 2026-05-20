func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_856_162"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 1 : !transfer.integer
  %7 = transfer.get_bit_width %5 : !transfer.integer
  %8 = transfer.clear_sign_bit %6 : !transfer.integer
  %9 = transfer.and %8, %4 : !transfer.integer
  %10 = transfer.urem %7, %3 : !transfer.integer
  %11 = transfer.popcount %10 : !transfer.integer
  %12 = transfer.countr_one %2 : !transfer.integer
  %13 = transfer.countl_one %11 : !transfer.integer
  %14 = transfer.smax %12, %9 : !transfer.integer
  %15 = transfer.make %14, %13 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
