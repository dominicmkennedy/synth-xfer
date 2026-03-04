builtin.module {
  func.func @make_value_with_conditional_bound(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The abstract value pairing a concrete value with a bound chosen by a boolean condition.
    %v1 = "transfer.select"(%h2, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%arg0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @masked_flag_abstract_lookup(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    // The abstract image of a boolean flag conjuncted with a constant condition flag.
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @conditional_select_abstract_lookup(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    // The abstract image of a value chosen between two constants by a boolean condition.
    %v1 = "transfer.select"(%arg0, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
