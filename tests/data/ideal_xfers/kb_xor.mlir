func.func @kb_xor(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs0 = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %lhs1 = transfer.get %lhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %rhs0 = transfer.get %rhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %rhs1 = transfer.get %rhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %and0s = transfer.and %lhs0, %rhs0 : !transfer.integer
  %and1s = transfer.and %lhs1, %rhs1 : !transfer.integer
  %and01 = transfer.and %lhs0, %rhs1 : !transfer.integer
  %and10 = transfer.and %lhs1, %rhs0 : !transfer.integer
  %res0 = transfer.or %and0s, %and1s : !transfer.integer
  %res1 = transfer.or %and01, %and10 : !transfer.integer
  %r = transfer.make %res0, %res1 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
