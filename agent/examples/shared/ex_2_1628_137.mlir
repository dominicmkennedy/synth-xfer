func.func @partial_solution_14_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "2_1628_137"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.constant %4, 1 : !transfer.integer
  %7 = transfer.get_all_ones %4 : !transfer.integer
  %8 = transfer.countr_one %3 : !transfer.integer
  %9 = transfer.sub %6, %7 : !transfer.integer
  %10 = transfer.sdiv %9, %2 : !transfer.integer
  %11 = transfer.and %8, %9 : !transfer.integer
  %12 = transfer.umin %4, %10 : !transfer.integer
  %13 = transfer.cmp ule, %6, %10 : !transfer.integer
  %14 = transfer.set_sign_bit %5 : !transfer.integer
  %15 = transfer.clear_low_bits %14, %11 : !transfer.integer
  %16 = transfer.select %13, %15, %2 : !transfer.integer
  %17 = transfer.set_high_bits %8, %9 : !transfer.integer
  %18 = transfer.set_sign_bit %12 : !transfer.integer
  %19 = transfer.clear_low_bits %7, %18 : !transfer.integer
  %20 = transfer.and %16, %17 : !transfer.integer
  %21 = transfer.make %20, %19 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %21 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
