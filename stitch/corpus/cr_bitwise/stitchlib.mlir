builtin.module {
  func.func @conditional_merge_with_top_fallback(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The abstract value resulting from selecting between two abstract transfer outputs, defaulting to top when neither is definite.
    %v2 = func.call @%h1(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = func.call @%h0(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.get"(%v4) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v6 = func.call @getTop(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%v6) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v3, %v5) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = func.call @%h1(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = func.call @%h0(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v9 = "transfer.get"(%v10) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v12 = func.call @getTop(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.get"(%v12) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.select"(%v8, %v9, %v11) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @make_pair_fixed_lower_concrete_upper(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The abstract value whose lower component is a fixed constant and upper component is the concrete input.
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @shift_spacing_zero_mask(%arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The known-zero bits of a value after a shift determined by the interval spacing between the zero-masks of two operands.
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.cmp"(%v4, %v5) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v7 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.constant"(%v7) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.select"(%v3, %v6, %v8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = "transfer.neg"(%v11) : (!transfer.integer) -> !transfer.integer
    %v13 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v12 = "transfer.get_all_ones"(%v13) : (!transfer.integer) -> !transfer.integer
    %v9 = "transfer.add"(%v10, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.lshr"(%v2, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v21 = "transfer.get_bit_width"(%v22) : (!transfer.integer) -> !transfer.integer
    %v20 = "transfer.countr_one"(%v21) : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v24 = "transfer.neg"(%v25) : (!transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v26 = "transfer.get_all_ones"(%v27) : (!transfer.integer) -> !transfer.integer
    %v23 = "transfer.mul"(%v24, %v26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v19 = "transfer.srem"(%v20, %v23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v30 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v29 = "transfer.neg"(%v30) : (!transfer.integer) -> !transfer.integer
    %v32 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get_all_ones"(%v32) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.mul"(%v29, %v31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v18 = "transfer.clear_high_bits"(%v19, %v28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v35 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v34 = "transfer.cmp"(%v35, %v36) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v38 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.constant"(%v38) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v39 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v33 = "transfer.select"(%v34, %v37, %v39) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v17 = "transfer.umax"(%v18, %v33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v40 = "transfer.neg"(%v41) : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.urem"(%v17, %v40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.umax"(%v15, %v16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
