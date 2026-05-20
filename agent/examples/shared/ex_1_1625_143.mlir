func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "1_1625_143"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 0 : !transfer.integer
  %7 = transfer.get_all_ones %5 : !transfer.integer
  %8 = transfer.get_bit_width %5 : !transfer.integer
  %9 = transfer.sdiv %3, %7 : !transfer.integer
  %10 = transfer.sub %5, %9 : !transfer.integer
  %11 = transfer.sub %3, %4 : !transfer.integer
  %12 = transfer.urem %6, %11 : !transfer.integer
  %13 = transfer.set_sign_bit %6 : !transfer.integer
  %14 = transfer.udiv %13, %8 : !transfer.integer
  %15 = transfer.clear_low_bits %10, %14 : !transfer.integer
  %16 = transfer.umin %2, %12 : !transfer.integer
  %17 = transfer.make %16, %15 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
