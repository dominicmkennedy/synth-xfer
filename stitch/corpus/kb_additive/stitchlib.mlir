builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v2 = "transfer.sub"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.sub"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%arg0, %v2, %v3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.and"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.or"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.sub"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
