builtin.module {
  func.func @func0(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : i1, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v3 = "transfer.xor"(%h1, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.shl"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.and"(%v3, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%h2, %v2, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = "transfer.shl"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v6 = "transfer.and"(%h1, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.select"(%h2, %v6, %h0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.and"(%v4, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.constant"(%v7) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v2 = "transfer.cmp"(%v3, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v11 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = func.call @%h0(%v11) : (!transfer.integer) -> !transfer.integer
    %v13 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v12 = "transfer.get_all_ones"(%v13) : (!transfer.integer) -> !transfer.integer
    %v9 = "transfer.xor"(%v10, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v16 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v15 = "transfer.get_all_ones"(%v16) : (!transfer.integer) -> !transfer.integer
    %v19 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v18 = "transfer.get_bit_width"(%v19) : (!transfer.integer) -> !transfer.integer
    %v23 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = func.call @%h0(%v23) : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v24 = func.call @%h1(%v25) : (!transfer.integer) -> !transfer.integer
    %v21 = "transfer.xor"(%v22, %v24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v20 = "transfer.countl_zero"(%v21) : (!transfer.integer) -> !transfer.integer
    %v17 = "transfer.sub"(%v18, %v20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.shl"(%v15, %v17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = "transfer.and"(%v9, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v26 = "transfer.get_all_ones"(%v27) : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v8, %v26) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v31 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v32 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v30 = "transfer.and"(%v31, %v32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v34 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v33 = "transfer.constant"(%v34) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v29 = "transfer.cmp"(%v30, %v33) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v37 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = func.call @%h0(%v37) : (!transfer.integer) -> !transfer.integer
    %v40 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v39 = "transfer.get_all_ones"(%v40) : (!transfer.integer) -> !transfer.integer
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.get_bit_width"(%v43) : (!transfer.integer) -> !transfer.integer
    %v47 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v46 = func.call @%h0(%v47) : (!transfer.integer) -> !transfer.integer
    %v49 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v48 = func.call @%h1(%v49) : (!transfer.integer) -> !transfer.integer
    %v45 = "transfer.xor"(%v46, %v48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v44 = "transfer.countl_zero"(%v45) : (!transfer.integer) -> !transfer.integer
    %v41 = "transfer.sub"(%v42, %v44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v38 = "transfer.shl"(%v39, %v41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v35 = "transfer.and"(%v36, %v38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v51 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v50 = "transfer.get_all_ones"(%v51) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.select"(%v29, %v35, %v50) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v28) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.and"(%v4, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.constant"(%v7) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v2 = "transfer.cmp"(%v3, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v11 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = func.call @%h0(%v11) : (!transfer.integer) -> !transfer.integer
    %v13 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v12 = "transfer.get_all_ones"(%v13) : (!transfer.integer) -> !transfer.integer
    %v9 = "transfer.xor"(%v10, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v16 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v15 = "transfer.get_all_ones"(%v16) : (!transfer.integer) -> !transfer.integer
    %v19 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v18 = "transfer.get_bit_width"(%v19) : (!transfer.integer) -> !transfer.integer
    %v23 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = func.call @%h0(%v23) : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v24 = func.call @%h1(%v25) : (!transfer.integer) -> !transfer.integer
    %v21 = "transfer.xor"(%v22, %v24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v20 = "transfer.countl_zero"(%v21) : (!transfer.integer) -> !transfer.integer
    %v17 = "transfer.sub"(%v18, %v20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.shl"(%v15, %v17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = "transfer.and"(%v9, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v26 = "transfer.get_all_ones"(%v27) : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v8, %v26) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v31 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v32 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v30 = "transfer.and"(%v31, %v32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v34 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v33 = "transfer.constant"(%v34) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v29 = "transfer.cmp"(%v30, %v33) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v37 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = func.call @%h0(%v37) : (!transfer.integer) -> !transfer.integer
    %v40 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v39 = "transfer.get_all_ones"(%v40) : (!transfer.integer) -> !transfer.integer
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.get_bit_width"(%v43) : (!transfer.integer) -> !transfer.integer
    %v47 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v46 = func.call @%h0(%v47) : (!transfer.integer) -> !transfer.integer
    %v49 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v48 = func.call @%h1(%v49) : (!transfer.integer) -> !transfer.integer
    %v45 = "transfer.xor"(%v46, %v48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v44 = "transfer.countl_zero"(%v45) : (!transfer.integer) -> !transfer.integer
    %v41 = "transfer.sub"(%v42, %v44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v38 = "transfer.shl"(%v39, %v41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v35 = "transfer.and"(%v36, %v38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v51 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v50 = "transfer.get_all_ones"(%v51) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.select"(%v29, %v35, %v50) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v28) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}
