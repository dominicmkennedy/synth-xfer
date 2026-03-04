builtin.module {
  func.func @func0(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%h0, %arg0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v1 = func.call @%h1(%arg0, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
