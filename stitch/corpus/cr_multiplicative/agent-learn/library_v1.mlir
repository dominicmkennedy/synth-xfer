builtin.module {
  func.func @knownbits_is_constant(%value : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    // Returns true if KnownBits represents a single constant value.
    %lower = "transfer.get"(%value) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %upper = "transfer.get"(%value) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %is_const = "transfer.cmp"(%lower, %upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    func.return %is_const : i1
  }
  func.func @knownbits_equals_constant(%value : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %constant : !transfer.integer) -> i1 {
    // Returns true if KnownBits is a constant equal to the provided immediate.
    %lower = "transfer.get"(%value) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %upper = "transfer.get"(%value) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %is_const = "transfer.cmp"(%lower, %upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %matches_value = "transfer.cmp"(%lower, %constant) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %result = "arith.andi"(%is_const, %matches_value) : (i1, i1) -> i1
    func.return %result : i1
  }
}