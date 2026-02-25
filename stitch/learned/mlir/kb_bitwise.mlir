builtin.module {
  // Abstract transfer for bitwise rotation of three known-bits pairs (arg0, arg1) by shift amount arg2, using h0/h1 as the left/right shift components; handles exact-power-of-two, zero-shift, and all-zero-known-bits special cases.
  func.func @kb_bitwise_0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.get_all_ones"(%v0) : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.constant"(%v0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.constant"(%v0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v9 = "transfer.and"(%v0, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v10 = "transfer.and"(%v2, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = "transfer.and"(%v4, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v12 = "transfer.cmp"(%v9, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v13 = "transfer.cmp"(%v10, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v14 = "transfer.cmp"(%v11, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v15 = "arith.andi"(%v12, %v13) : (i1, i1) -> i1
    %v16 = "arith.andi"(%v15, %v14) : (i1, i1) -> i1
    %v17 = "transfer.get_bit_width"(%v0) : (!transfer.integer) -> !transfer.integer
    %v18 = "transfer.urem"(%v5, %v17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v19 = "transfer.sub"(%v17, %v18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v20 = func.call @%h0(%v0, %v18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v21 = func.call @%h1(%v2, %v19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v22 = "transfer.or"(%v20, %v21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v23 = func.call @%h0(%v1, %v18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v24 = func.call @%h1(%v3, %v19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v25 = "transfer.or"(%v23, %v24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v26 = "transfer.xor"(%v5, %v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v27 = "transfer.cmp"(%v4, %v26) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v28 = "transfer.or"(%v4, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v29 = "transfer.xor"(%v28, %v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v30 = "transfer.cmp"(%v29, %v7) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v31 = "transfer.sub"(%v29, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v32 = "transfer.and"(%v29, %v31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v33 = "transfer.cmp"(%v32, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v34 = "arith.andi"(%v30, %v33) : (i1, i1) -> i1
    %v35 = "transfer.add"(%v5, %v29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v36 = "transfer.urem"(%v35, %v17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v37 = "transfer.sub"(%v17, %v36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v38 = func.call @%h0(%v0, %v36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v39 = func.call @%h1(%v2, %v37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v40 = "transfer.or"(%v38, %v39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = func.call @%h0(%v1, %v36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v42 = func.call @%h1(%v3, %v37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v43 = "transfer.or"(%v41, %v42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v44 = "transfer.select"(%v34, %v22, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v45 = "transfer.select"(%v34, %v40, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v46 = "transfer.and"(%v44, %v45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v47 = "transfer.select"(%v34, %v46, %v7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v48 = "transfer.select"(%v34, %v25, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v49 = "transfer.select"(%v34, %v43, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v50 = "transfer.and"(%v48, %v49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v51 = "transfer.select"(%v34, %v50, %v7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v52 = "transfer.select"(%v27, %v22, %v47) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v53 = "transfer.select"(%v27, %v25, %v51) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v54 = "transfer.cmp"(%v0, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v55 = "transfer.cmp"(%v1, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v56 = "arith.andi"(%v54, %v55) : (i1, i1) -> i1
    %v57 = "transfer.cmp"(%v2, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v58 = "transfer.cmp"(%v3, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v59 = "arith.andi"(%v57, %v58) : (i1, i1) -> i1
    %v60 = "arith.andi"(%v56, %v59) : (i1, i1) -> i1
    %v61 = "transfer.cmp"(%v0, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v62 = "transfer.cmp"(%v1, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v63 = "arith.andi"(%v61, %v62) : (i1, i1) -> i1
    %v64 = "transfer.cmp"(%v2, %v7) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v65 = "transfer.cmp"(%v3, %v6) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v66 = "arith.andi"(%v64, %v65) : (i1, i1) -> i1
    %v67 = "arith.andi"(%v63, %v66) : (i1, i1) -> i1
    %v68 = "transfer.select"(%v60, %v6, %v52) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v69 = "transfer.select"(%v60, %v7, %v53) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v70 = "transfer.select"(%v67, %v7, %v68) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v71 = "transfer.select"(%v67, %v6, %v69) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v72 = "transfer.select"(%v16, %v70, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v73 = "transfer.select"(%v16, %v71, %v6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v74 = "transfer.make"(%v72, %v73) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v74 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Abstract transfer for bitwise rotation of known-bits arg0 by the upper component of arg1, using h0/h1 as left/right shift components; handles exact-power-of-two, zero-shift, and all-ones/all-zeros special cases.
  func.func @kb_bitwise_1(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v1 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = "transfer.get_all_ones"(%v0) : (!transfer.integer) -> !transfer.integer
    %v5 = "transfer.constant"(%v0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v6 = "transfer.constant"(%v0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.get_bit_width"(%v0) : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.urem"(%v3, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.sub"(%v7, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v10 = func.call @%h0(%v0, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = func.call @%h1(%v0, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v12 = "transfer.or"(%v10, %v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v13 = func.call @%h0(%v1, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = func.call @%h1(%v1, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.or"(%v13, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v16 = "transfer.xor"(%v3, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v17 = "transfer.cmp"(%v2, %v16) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v18 = "transfer.or"(%v2, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v19 = "transfer.xor"(%v18, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v20 = "transfer.cmp"(%v19, %v5) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v21 = "transfer.sub"(%v19, %v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v22 = "transfer.and"(%v19, %v21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v23 = "transfer.cmp"(%v22, %v5) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v24 = "arith.andi"(%v20, %v23) : (i1, i1) -> i1
    %v25 = "transfer.add"(%v3, %v19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v26 = "transfer.urem"(%v25, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v27 = "transfer.sub"(%v7, %v26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v28 = func.call @%h0(%v0, %v26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v29 = func.call @%h1(%v0, %v27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v30 = "transfer.or"(%v28, %v29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v31 = func.call @%h0(%v1, %v26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v32 = func.call @%h1(%v1, %v27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v33 = "transfer.or"(%v31, %v32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v34 = "transfer.and"(%v12, %v30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v35 = "transfer.and"(%v15, %v33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v36 = "transfer.select"(%v24, %v34, %v5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v37 = "transfer.select"(%v24, %v35, %v5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v38 = "transfer.select"(%v24, %v36, %v5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v39 = "transfer.select"(%v24, %v37, %v5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v40 = "transfer.select"(%v17, %v12, %v38) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = "transfer.select"(%v17, %v15, %v39) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v42 = "transfer.cmp"(%v0, %v4) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v43 = "transfer.cmp"(%v1, %v5) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v44 = "arith.andi"(%v42, %v43) : (i1, i1) -> i1
    %v45 = "transfer.cmp"(%v0, %v5) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v46 = "transfer.cmp"(%v1, %v4) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v47 = "arith.andi"(%v45, %v46) : (i1, i1) -> i1
    %v48 = "transfer.select"(%v44, %v4, %v40) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v49 = "transfer.select"(%v44, %v5, %v41) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v50 = "transfer.select"(%v47, %v5, %v48) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v51 = "transfer.select"(%v47, %v4, %v49) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v52 = "transfer.make"(%v50, %v51) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v52 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  // Computes h1() & (arg0 & h0()) and passes the result to continuation h2.
  func.func @kb_bitwise_2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    %v0 = func.call @%h0() : () -> !transfer.integer
    %v1 = func.call @%h1() : () -> !transfer.integer
    %v2 = "transfer.and"(%arg0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.and"(%v1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = func.call @%h2(%v4) : (!transfer.integer) -> !transfer.integer
    func.return %v3 : !transfer.integer
  }
}
