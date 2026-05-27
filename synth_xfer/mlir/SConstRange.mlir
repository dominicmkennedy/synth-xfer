builtin.module {
  func.func @meet(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %lhs_lb = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %lhs_ub = transfer.get %lhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %rhs_lb = transfer.get %rhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %rhs_ub = transfer.get %rhs[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %min = transfer.smax %lhs_lb, %rhs_lb : !transfer.integer
    %max = transfer.smin %lhs_ub, %rhs_ub : !transfer.integer
    %result = transfer.make %min, %max : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @top(%arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %arg00 = transfer.get %arg0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %int_min = transfer.get_signed_min_value %arg00 {value = 0 : index} : !transfer.integer
    %int_max = transfer.get_signed_max_value %arg00 {value = 0 : index} : !transfer.integer
    %result = transfer.make %int_min, %int_max : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @is_not_bottom(%abst_val : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    %lower_bound = transfer.get %abst_val[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %upper_bound = transfer.get %abst_val[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %result = transfer.cmp sle, %lower_bound, %upper_bound : !transfer.integer
    func.return %result : i1
  }
  func.func @abstract_val_contains(%abst_val : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %inst : !transfer.integer) -> i1 {
    %lower_bound = transfer.get %abst_val[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %upper_bound = transfer.get %abst_val[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
    %within_lb = transfer.cmp sle, %lower_bound, %inst : !transfer.integer
    %within_ub = transfer.cmp sle, %inst, %upper_bound : !transfer.integer
    %result = arith.andi %within_lb, %within_ub : i1
    func.return %result : i1
  }
}
