builtin.module {
  // Merges h0(arg0,arg1) components with getTop(arg0) components, selecting between them based on h1(arg0,arg1).
  func.func @cr_bitwise _0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = func.call @getTop(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = "transfer.get"(%v0) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v2 = "transfer.get"(%v0) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v3 = func.call @%h0(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = "transfer.get"(%v3) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v5 = "transfer.get"(%v3) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v6 = func.call @%h1(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v7 = "transfer.select"(%v6, %v4, %v1) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = "transfer.select"(%v6, %v5, %v2) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.make"(%v7, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v9 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Packs h0() as the lower component and arg0 as the upper component into an abstract value.
  func.func @cr_bitwise _1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v1 = "transfer.make"(%v0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Computes the lattice meet of six partial solutions applied to (h1, h0).
  func.func @cr_bitwise _2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v0 = func.call @partial_solution_0(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = func.call @partial_solution_1(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = func.call @partial_solution_2(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = func.call @partial_solution_3(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = func.call @partial_solution_4(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = func.call @partial_solution_5(%h1, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = func.call @meet(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = func.call @meet(%v6, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = func.call @meet(%v7, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = func.call @meet(%v8, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v10 = func.call @meet(%v9, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %v10 : !transfer.integer
  }
}
