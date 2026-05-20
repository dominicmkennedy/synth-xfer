func.func @partial_solution_16_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "3_1022_156"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.set_sign_bit %4 : !transfer.integer
  %8 = transfer.set_high_bits %5, %3 : !transfer.integer
  %9 = transfer.countr_zero %2 : !transfer.integer
  %10 = transfer.clear_low_bits %8, %6 : !transfer.integer
  %11 = transfer.countr_one %4 : !transfer.integer
  %12 = transfer.or %5, %9 : !transfer.integer
  %13 = transfer.neg %11 : !transfer.integer
  %14 = transfer.sdiv %9, %7 : !transfer.integer
  %15 = transfer.clear_low_bits %14, %12 : !transfer.integer
  %16 = transfer.umin %13, %10 : !transfer.integer
  %17 = transfer.and %3, %15 : !transfer.integer
  %18 = transfer.make %17, %16 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
