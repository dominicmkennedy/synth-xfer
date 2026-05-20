func.func @partial_solution_12_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_0_95"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get_bit_width %4 : !transfer.integer
  %6 = transfer.set_sign_bit %4 : !transfer.integer
  %7 = transfer.countr_one %5 : !transfer.integer
  %8 = transfer.xor %7, %6 : !transfer.integer
  %9 = transfer.and %5, %3 : !transfer.integer
  %10 = transfer.and %8, %2 : !transfer.integer
  %11 = transfer.make %10, %9 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
