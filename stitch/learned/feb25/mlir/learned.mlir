builtin.module {
  // Apply h3 to (h2 | (h1 << h0)): OR h2 with h1 shifted left by h0, then pass to continuation h3.
  func.func @learned_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.integer, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v2 = "transfer.shl"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%h2, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h3(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Compose two abstract functions: apply h1 to (arg0, h0), then apply h2 to the result.
  func.func @learned_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v1 = func.call @%h1(%arg0, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Build an abstract pair by applying h2 to two different argument pairs: (h1, arg0) and (h3, h0).
  func.func @learned_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h3 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v1 = func.call @%h2(%h1, %arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = func.call @%h2(%h3, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Compare arg0 == h0 (predicate 0), then pass the boolean result to continuation h1.
  func.func @learned_3(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.cmp"(%arg0, %h0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  // Select h0 if h1 is true else arg0, then pass the chosen value to continuation h2.
  func.func @learned_4(%h0 : !transfer.integer, %h1 : i1, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.select"(%h1, %h0, %arg0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
