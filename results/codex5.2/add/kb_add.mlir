"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %knownmask_lhs = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %knownmask_rhs = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bothknown = "transfer.and"(%knownmask_lhs, %knownmask_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %t = "transfer.countr_one"(%bothknown) : (!transfer.integer) -> !transfer.integer
    %lowmask = "transfer.set_low_bits"(%const0, %t) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_low = "transfer.and"(%lhs1, %lowmask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_low = "transfer.and"(%rhs1, %lowmask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_low = "transfer.add"(%a_low, %b_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_low = "transfer.and"(%sum_low, %lowmask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_not_low = "transfer.xor"(%sum_low, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_low = "transfer.and"(%sum_not_low, %lowmask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0_or_b0 = "transfer.or"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %t0 = "transfer.countr_one"(%a0_or_b0) : (!transfer.integer) -> !transfer.integer
    %prefix0 = "transfer.set_low_bits"(%const0, %t0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bit_t0 = "transfer.shl"(%const1, %t0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry0mask = "transfer.or"(%prefix0, %bit_t0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_and_b1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %t1 = "transfer.countr_one"(%a1_and_b1) : (!transfer.integer) -> !transfer.integer
    %prefix1 = "transfer.set_low_bits"(%const0, %t1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry1mask = "transfer.shl"(%prefix1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mask0 = "transfer.and"(%carry0mask, %bothknown) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mask1 = "transfer.and"(%carry1mask, %bothknown) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_ab = "transfer.xor"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %not_xor = "transfer.xor"(%xor_ab, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_0 = "transfer.and"(%xor_ab, %mask0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_0 = "transfer.and"(%not_xor, %mask0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_1 = "transfer.and"(%not_xor, %mask1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_1 = "transfer.and"(%xor_ab, %mask1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_tmp = "transfer.or"(%res1_low, %res1_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%res1_tmp, %res1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_tmp = "transfer.or"(%res0_low, %res0_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%res0_tmp, %res0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_add", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()