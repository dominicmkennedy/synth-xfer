func.func @KnownBits_top(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs0 = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %const0 = transfer.constant %lhs0, 0 : !transfer.integer
  %r = transfer.make %const0, %const0 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
