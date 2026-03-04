builtin.module {
  func.func @knownbits_range_is_singleton(%value : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    // Returns true when the KnownBits range collapses to a single concrete value.
    %lower = "transfer.get"(%value) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %upper = "transfer.get"(%value) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %is_singleton = "transfer.cmp"(%lower, %upper) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    func.return %is_singleton : i1
  }
  func.func @knownbits_range_equals_constant(%value : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %constant : !transfer.integer) -> i1 {
    // Returns true when the KnownBits range equals the supplied constant value.
    %lower = "transfer.get"(%value) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %upper = "transfer.get"(%value) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %is_singleton = "transfer.cmp"(%lower, %upper) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %matches_const = "transfer.cmp"(%lower, %constant) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %result = "arith.andi"(%is_singleton, %matches_const) : (i1, i1) -> i1
    func.return %result : i1
  }
}