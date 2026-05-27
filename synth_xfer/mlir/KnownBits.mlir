builtin.module {
  func.func @meet(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %lhs_known_z = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %lhs_known_o = transfer.get %lhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %rhs_known_z = transfer.get %rhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %rhs_known_o = transfer.get %rhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %new_known_z = transfer.or %lhs_known_z, %rhs_known_z : !transfer.integer
    %new_known_o = transfer.or %lhs_known_o, %rhs_known_o : !transfer.integer
    %result = transfer.make %new_known_z, %new_known_o : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @top(%arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %arg00 = transfer.get %arg0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %const0 = transfer.constant %arg00, 0 : !transfer.integer
    %result = transfer.make %const0, %const0 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @is_not_bottom(%abst_val : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    %known_z = transfer.get %abst_val[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %known_o = transfer.get %abst_val[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %conflicting_bits = transfer.and %known_z, %known_o : !transfer.integer
    %const0 = transfer.constant %known_z, 0 : !transfer.integer
    %result = transfer.cmp eq, %conflicting_bits, %const0 : !transfer.integer
    func.return %result : i1
  }
  func.func @abstract_val_contains(%abst_val : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %concrete_val : !transfer.integer) -> i1 {
    %known_z = transfer.get %abst_val[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %known_o = transfer.get %abst_val[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %not_concrete_val = transfer.neg %concrete_val : !transfer.integer
    %z_bits_union = transfer.or %not_concrete_val, %known_z : !transfer.integer
    %o_bits_union = transfer.or %concrete_val, %known_o : !transfer.integer
    %known_z_match = transfer.cmp eq, %z_bits_union, %not_concrete_val : !transfer.integer
    %known_o_match = transfer.cmp eq, %o_bits_union, %concrete_val : !transfer.integer
    %result = arith.andi %known_z_match, %known_o_match : i1
    func.return %result : i1
  }
}
