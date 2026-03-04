## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions in MLIR. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## Synthesized transfer functions (inputs)


"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer

    %conflict = "transfer.and"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    // min leading ones = guaranteed leading ones
    %min_lo = "transfer.countl_one"(%x1) : (!transfer.integer) -> !transfer.integer
    // max leading ones = until first guaranteed zero
    %max_lo = "transfer.countl_zero"(%x0) : (!transfer.integer) -> !transfer.integer

    // convert unsigned range [min_lo, max_lo] to knownbits by common prefix
    %diff = "transfer.xor"(%min_lo, %max_lo) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_lo, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%min_lo, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_countlone", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer

    %conflict = "transfer.and"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    // min leading zeros = guaranteed leading zeros
    %min_lz = "transfer.countl_one"(%x0) : (!transfer.integer) -> !transfer.integer
    // max leading zeros = until first guaranteed one
    %max_lz = "transfer.countl_zero"(%x1) : (!transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%min_lz, %max_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_lz, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%min_lz, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_countlzero", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer

    %conflict = "transfer.and"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %min_to = "transfer.countr_one"(%x1) : (!transfer.integer) -> !transfer.integer
    %max_to = "transfer.countr_zero"(%x0) : (!transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%min_to, %max_to) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_to, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%min_to, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_countrone", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer

    %conflict = "transfer.and"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %min_tz = "transfer.countr_one"(%x0) : (!transfer.integer) -> !transfer.integer
    %max_tz = "transfer.countr_zero"(%x1) : (!transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%min_tz, %max_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_tz, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%min_tz, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_countrzero", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer

    %conflict = "transfer.and"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %min_pc = "transfer.popcount"(%x1) : (!transfer.integer) -> !transfer.integer
    %num_known_zero = "transfer.popcount"(%x0) : (!transfer.integer) -> !transfer.integer
    %max_pc = "transfer.sub"(%bitwidth, %num_known_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%min_pc, %max_pc) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_pc, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.and"(%min_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%min_pc, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_popcount", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

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


## Existing library (do not duplicate)

The library already contains the following helpers. Do not re-emit functions that are already present or are trivially equivalent to them:

```mlir
builtin.module {}
```

## Available primitives

Library functions must use only these building blocks:

### Constructor and Deconstructor

- transfer.get : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
- transfer.make : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

### Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

### Integer Operations

- transfer.neg: (!transfer.integer) -> !transfer.integer
- transfer.and: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.or: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.xor: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.add: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sub: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.select: (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.mul: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.lshr: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.shl: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.udiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sdiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.urem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.srem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.countl_one: (!transfer.integer) -> !transfer.integer
- transfer.countl_zero: (!transfer.integer) -> !transfer.integer
- transfer.countr_one: (!transfer.integer) -> !transfer.integer
- transfer.countr_zero: (!transfer.integer) -> !transfer.integer

## Utility Operations

- transfer.constant: (!transfer.integer) -> !transfer.integer
    - example: `%const0 = "transfer.constant"(%arg){value=42:index} : (!transfer.integer) -> !transfer.integer` provides constant 42.
    - the argument `%arg` is to decide bitwidth
- transfer.get_all_ones: (!transfer.integer) -> !transfer.integer
    - the argument is to decide bitwidth
- transfer.get_bit_width: (!transfer.integer) -> !transfer.integer


## What to extract

A good library function:
1. **Encodes a meaningful semantic concept** — e.g., "extract the maybe-zero mask", "compute the carry-propagate bits", "get the minimum possible concrete value of a KnownBits". Prefer names that describe what the function *means*, not how it is computed.
2. **Appears across multiple transfer functions**, or is a large, self-contained sub-computation that would reduce duplication if future transfer functions were refactored to use it.
3. **Is non-trivial** — it should be at least 3 operations long. Do not extract single-op wrappers.
4. **Is general** — parameters should be abstract values or integers; do not hard-code bitwidth-specific constants unless the concept is inherently about a specific constant.

Do **not** extract the transfer functions themselves (e.g. `@kb_add`). Only extract helper functions that could be called from within transfer functions.

## Output format

Output a single `builtin.module` containing only the new library functions you are adding. Do not include the transfer functions from the input. Use `func.func` with:
- SSA form only
- One allowed operation per line
- Descriptive `snake_case` function names
- A brief `//` comment on the first line of each function body explaining its purpose
- Arguments typed as `!transfer.integer` or `!transfer.abs_value<[!transfer.integer, !transfer.integer]>` as appropriate

Example output shape (illustrative, do not copy verbatim):

```mlir
builtin.module {
  func.func @maybe_zero(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Returns the mask of bits that might be 0: complement of known-one.
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known1) : (!transfer.integer) -> !transfer.integer
    %res = "transfer.xor"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }
}
```

## Required workflow

1. Read each synthesized transfer function carefully. For each one, annotate (mentally) which sub-sequences of operations compute a semantically coherent intermediate result.
2. Look for sub-computations that appear in more than one function, or that are large enough to deserve a name on their own.
3. For each candidate, decide on a precise semantic description and a clear name.
4. Write the MLIR for each helper function. Verify it uses only allowed primitives and is in valid SSA form.
5. Output **only** the `builtin.module` containing the new helper functions — no explanation, no transfer functions, no markdown fences around the final answer.