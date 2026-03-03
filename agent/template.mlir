builtin.module {
  func.func @TODO(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %const0 = "transfer.constant"(%lhs0) {value = 0} : () -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1} : () -> !transfer.integer
    %const_all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    // TODO (multiple lines)

    func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
