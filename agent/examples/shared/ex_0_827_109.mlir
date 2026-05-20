func.func @partial_solution_7_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_827_109"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get_all_ones %4 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.cmp ule, %5, %2 : !transfer.integer
  %8 = transfer.umin %4, %6 : !transfer.integer
  %9 = transfer.countl_one %6 : !transfer.integer
  %10 = transfer.clear_high_bits %4, %3 : !transfer.integer
  %11 = transfer.select %7, %3, %9 : !transfer.integer
  %12 = transfer.lshr %6, %6 : !transfer.integer
  %13 = transfer.set_sign_bit %6 : !transfer.integer
  %14 = transfer.or %9, %13 : !transfer.integer
  %15 = transfer.umax %10, %14 : !transfer.integer
  %16 = transfer.shl %8, %15 : !transfer.integer
  %17 = transfer.ashr %11, %12 : !transfer.integer
  %18 = transfer.make %17, %16 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
