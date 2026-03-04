builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v3 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %v2 = "transfer.sub"(%h0, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.sub"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.shl"(%h0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
