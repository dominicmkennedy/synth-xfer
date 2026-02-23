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
