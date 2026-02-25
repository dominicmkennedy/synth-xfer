builtin.module {
  // Builds a shifted-XOR abstract value: lower = (h1^h0)&(h0<<arg0), upper = h1&(h0<<arg0), both gated by boolean h2 (falls back to h0 if false).
  func.func @kb_bitcount_0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.shl"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.and"(%v1, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.and"(%h1, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.select"(%h2, %v2, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.select"(%h2, %v3, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v6 = "transfer.make"(%v4, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v6 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Finds the highest bit where h0(arg0[1]) and h1(arg0[0]) differ via countl_zero of their XOR, then delegates to fn_0.
  func.func @kb_bitcount_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v0 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.get_all_ones"(%v0) : (!transfer.integer) -> !transfer.integer
    %v3 = "transfer.constant"(%v0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v4 = "transfer.and"(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.cmp"(%v4, %v3) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v6 = func.call @%h0(%v1) : (!transfer.integer) -> !transfer.integer
    %v7 = func.call @%h1(%v0) : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.xor"(%v6, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.countl_zero"(%v8) : (!transfer.integer) -> !transfer.integer
    %v10 = "transfer.get_bit_width"(%v0) : (!transfer.integer) -> !transfer.integer
    %v12 = "transfer.sub"(%v10, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = func.call @fn_0(%v2, %v6, %v5, %v12) : (!transfer.integer, !transfer.integer, i1, !transfer.integer) -> !transfer.integer
    func.return %v11 : !transfer.integer
  }
  // Like kb_bitcount_1 but applies h0 to arg0[0] and h1 to arg0[1] (components swapped).
  func.func @kb_bitcount_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v0 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.get_all_ones"(%v0) : (!transfer.integer) -> !transfer.integer
    %v3 = "transfer.constant"(%v0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v4 = "transfer.and"(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.cmp"(%v4, %v3) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v6 = func.call @%h0(%v0) : (!transfer.integer) -> !transfer.integer
    %v7 = func.call @%h1(%v1) : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.xor"(%v6, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.countl_zero"(%v8) : (!transfer.integer) -> !transfer.integer
    %v10 = "transfer.get_bit_width"(%v0) : (!transfer.integer) -> !transfer.integer
    %v12 = "transfer.sub"(%v10, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = func.call @fn_0(%v2, %v6, %v5, %v12) : (!transfer.integer, !transfer.integer, i1, !transfer.integer) -> !transfer.integer
    func.return %v11 : !transfer.integer
  }
}
