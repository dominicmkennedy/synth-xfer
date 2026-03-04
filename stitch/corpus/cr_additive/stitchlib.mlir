builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v1 = "transfer.select"(%h2, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%arg0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func1(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "transfer.select"(%arg0, %h1, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
