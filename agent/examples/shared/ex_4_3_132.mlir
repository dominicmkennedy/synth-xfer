func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_3_132"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.constant %4, 1 : !transfer.integer
  %7 = transfer.get_all_ones %4 : !transfer.integer
  %8 = transfer.get_bit_width %4 : !transfer.integer
  %9 = transfer.cmp ult, %4, %5 : !transfer.integer
  %10 = transfer.select %9, %2, %7 : !transfer.integer
  %11 = transfer.shl %6, %8 : !transfer.integer
  %12 = transfer.select %9, %10, %3 : !transfer.integer
  %13 = transfer.clear_sign_bit %11 : !transfer.integer
  %14 = transfer.clear_low_bits %7, %13 : !transfer.integer
  %15 = transfer.umin %14, %13 : !transfer.integer
  %16 = transfer.and %6, %12 : !transfer.integer
  %17 = transfer.make %16, %15 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
