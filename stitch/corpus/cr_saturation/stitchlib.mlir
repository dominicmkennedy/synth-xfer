builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v2 = "transfer.ashr"(%h0, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.sub"(%arg0, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : !transfer.integer, %h1 : !transfer.integer) -> !transfer.integer {
    %v1 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @fn_0(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
