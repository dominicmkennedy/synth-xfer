func.func @partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "1_1662_132"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 0 : !transfer.integer
  %7 = transfer.constant %5, 1 : !transfer.integer
  %8 = transfer.get_all_ones %5 : !transfer.integer
  %9 = transfer.get_bit_width %5 : !transfer.integer
  %10 = transfer.sub %9, %8 : !transfer.integer
  %11 = transfer.and %3, %4 : !transfer.integer
  %12 = transfer.smax %8, %10 : !transfer.integer
  %13 = transfer.srem %11, %6 : !transfer.integer
  %14 = transfer.shl %13, %7 : !transfer.integer
  %15 = transfer.set_high_bits %5, %9 : !transfer.integer
  %16 = transfer.and %14, %11 : !transfer.integer
  %17 = transfer.and %2, %14 : !transfer.integer
  %18 = transfer.ashr %15, %12 : !transfer.integer
  %19 = transfer.and %18, %16 : !transfer.integer
  %20 = transfer.and %17, %4 : !transfer.integer
  %21 = transfer.make %20, %19 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %21 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
