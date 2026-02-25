builtin.module {
  // Shift h1 left by h0, OR with h2, then apply abstract function h3.
  func.func @learned-20_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.integer, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v2 = "transfer.shl"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%h2, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h3(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Apply h1 to (arg0, h0) then apply h2 to the result — function composition through two abstract functions.
  func.func @learned-20_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v1 = func.call @%h1(%arg0, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Apply h2 to two pairs of abs_values and pack the two resulting integers into a new abs_value.
  func.func @learned-20_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v1 = func.call @%h2(%h1, %arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = func.call @%h2(%h3, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Compare arg0 == h0, then apply abstract function h1 to the boolean result.
  func.func @learned-20_3(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.cmp"(%arg0, %h0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Select h0 if h1 is true else arg0, then apply abstract function h2 to the chosen value.
  func.func @learned-20_4(%h0 : !transfer.integer, %h1 : i1, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.select"(%h1, %h0, %arg0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // OR three integers together and apply abstract function h3 to the result.
  func.func @learned-20_5(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.integer, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v2 = "transfer.or"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%v2, %h2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h3(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Create an all-ones integer of the same bitwidth as h0, then apply abstract function h1 to it.
  func.func @learned-20_6(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v1 = "transfer.get_all_ones"(%h0) : (!transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Subtract h0 from h1, use h3 to compute a count from the difference and h2, set that many high bits of h2, then apply h4.
  func.func @learned-20_7(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.integer, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h4 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v3 = "transfer.sub"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = func.call @%h3(%v3, %h2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.set_high_bits"(%h2, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h4(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // OR h0 and h1, pass the result with h4 into h3, then apply h2 to the output.
  func.func @learned-20_8(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h4 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v2 = "transfer.or"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h3(%v2, %h4) : (!transfer.integer, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // AND h1 and h4 each with h0, apply h3 to the two masked results, then apply h2 to the output.
  func.func @learned-20_9(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h4 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.and"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.and"(%h4, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = func.call @%h3(%v2, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Set the low arg0 bits of h0 to ones, then apply abstract function h1 to the result.
  func.func @learned-20_10(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.set_low_bits"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Package arg0 and h0 as a two-integer abstract value pair.
  func.func @learned-20_11(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.make"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Mask arg0 with h0 (bitwise AND), then apply abstract function h1 to the result.
  func.func @learned-20_12(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
