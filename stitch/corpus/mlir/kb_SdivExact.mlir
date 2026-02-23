"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %const_false = "arith.constant"() {value = 0 : i1} : () -> i1
    %signed_min = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhsu_known = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_unk = "transfer.xor"(%lhsu_known, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_unk_m1 = "transfer.sub"(%lhsu_unk, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem1 = "transfer.and"(%lhsu_unk, %lhsu_unk_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem1_m1 = "transfer.sub"(%lhsu_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem2 = "transfer.and"(%lhsu_rem1, %lhsu_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem2_m1 = "transfer.sub"(%lhsu_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem3 = "transfer.and"(%lhsu_rem2, %lhsu_rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem3_m1 = "transfer.sub"(%lhsu_rem3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_rem4 = "transfer.and"(%lhsu_rem3, %lhsu_rem3_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_le4 = "transfer.cmp"(%lhsu_rem4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhsu_b1 = "transfer.xor"(%lhsu_unk, %lhsu_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_b2 = "transfer.xor"(%lhsu_rem1, %lhsu_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_b3 = "transfer.xor"(%lhsu_rem2, %lhsu_rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_b4 = "transfer.xor"(%lhsu_rem3, %lhsu_rem4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v0 = "transfer.add"(%lhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v1 = "transfer.add"(%lhsu_v0, %lhsu_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v2 = "transfer.add"(%lhsu_v0, %lhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v3 = "transfer.add"(%lhsu_v1, %lhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v4 = "transfer.add"(%lhsu_v0, %lhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v5 = "transfer.add"(%lhsu_v1, %lhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v6 = "transfer.add"(%lhsu_v2, %lhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v7 = "transfer.add"(%lhsu_v3, %lhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v8 = "transfer.add"(%lhsu_v0, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v9 = "transfer.add"(%lhsu_v1, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v10 = "transfer.add"(%lhsu_v2, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v11 = "transfer.add"(%lhsu_v3, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v12 = "transfer.add"(%lhsu_v4, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v13 = "transfer.add"(%lhsu_v5, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v14 = "transfer.add"(%lhsu_v6, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhsu_v15 = "transfer.add"(%lhsu_v7, %lhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_known = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_unk = "transfer.xor"(%rhsu_known, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_unk_m1 = "transfer.sub"(%rhsu_unk, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem1 = "transfer.and"(%rhsu_unk, %rhsu_unk_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem1_m1 = "transfer.sub"(%rhsu_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem2 = "transfer.and"(%rhsu_rem1, %rhsu_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem2_m1 = "transfer.sub"(%rhsu_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem3 = "transfer.and"(%rhsu_rem2, %rhsu_rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem3_m1 = "transfer.sub"(%rhsu_rem3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_rem4 = "transfer.and"(%rhsu_rem3, %rhsu_rem3_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_le4 = "transfer.cmp"(%rhsu_rem4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhsu_b1 = "transfer.xor"(%rhsu_unk, %rhsu_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_b2 = "transfer.xor"(%rhsu_rem1, %rhsu_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_b3 = "transfer.xor"(%rhsu_rem2, %rhsu_rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_b4 = "transfer.xor"(%rhsu_rem3, %rhsu_rem4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v0 = "transfer.add"(%rhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v1 = "transfer.add"(%rhsu_v0, %rhsu_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v2 = "transfer.add"(%rhsu_v0, %rhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v3 = "transfer.add"(%rhsu_v1, %rhsu_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v4 = "transfer.add"(%rhsu_v0, %rhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v5 = "transfer.add"(%rhsu_v1, %rhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v6 = "transfer.add"(%rhsu_v2, %rhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v7 = "transfer.add"(%rhsu_v3, %rhsu_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v8 = "transfer.add"(%rhsu_v0, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v9 = "transfer.add"(%rhsu_v1, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v10 = "transfer.add"(%rhsu_v2, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v11 = "transfer.add"(%rhsu_v3, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v12 = "transfer.add"(%rhsu_v4, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v13 = "transfer.add"(%rhsu_v5, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v14 = "transfer.add"(%rhsu_v6, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhsu_v15 = "transfer.add"(%rhsu_v7, %rhsu_b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact_on = "arith.andi"(%lhsu_le4, %rhsu_le4) : (i1, i1) -> i1
    %res0_fb = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_fb = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rhs_nz_0 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_0 = "transfer.select"(%pair_rhs_nz_0, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_0 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_0 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_0 = "arith.andi"(%pair_lhs_eq_smin_0, %pair_rhs_eq_m1_0) : (i1, i1) -> i1
    %pair_not_ub_0 = "arith.xori"(%pair_ub_0, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_0 = "arith.andi"(%pair_rhs_nz_0, %pair_not_ub_0) : (i1, i1) -> i1
    %pair_val_0 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_0 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_0 = "transfer.cmp"(%pair_rem_0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_0 = "arith.andi"(%pair_valid_sdiv_0, %pair_exact_0) : (i1, i1) -> i1
    %pair_val0_0 = "transfer.xor"(%pair_val_0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_0 = "transfer.select"(%pair_valid_0, %pair_val0_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_0 = "transfer.select"(%pair_valid_0, %pair_val_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_0 = "transfer.and"(%all_ones, %pair_sel0_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_0 = "transfer.and"(%all_ones, %pair_sel1_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_0 = "arith.ori"(%const_false, %pair_valid_0) : (i1, i1) -> i1
    %pair_rhs_nz_1 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_1 = "transfer.select"(%pair_rhs_nz_1, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_1 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_1 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_1 = "arith.andi"(%pair_lhs_eq_smin_1, %pair_rhs_eq_m1_1) : (i1, i1) -> i1
    %pair_not_ub_1 = "arith.xori"(%pair_ub_1, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_1 = "arith.andi"(%pair_rhs_nz_1, %pair_not_ub_1) : (i1, i1) -> i1
    %pair_val_1 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_1 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_1 = "transfer.cmp"(%pair_rem_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_1 = "arith.andi"(%pair_valid_sdiv_1, %pair_exact_1) : (i1, i1) -> i1
    %pair_val0_1 = "transfer.xor"(%pair_val_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_1 = "transfer.select"(%pair_valid_1, %pair_val0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_1 = "transfer.select"(%pair_valid_1, %pair_val_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_1 = "transfer.and"(%pair_acc0_0, %pair_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_1 = "transfer.and"(%pair_acc1_0, %pair_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_1 = "arith.ori"(%pair_any_0, %pair_valid_1) : (i1, i1) -> i1
    %pair_rhs_nz_2 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_2 = "transfer.select"(%pair_rhs_nz_2, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_2 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_2 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_2 = "arith.andi"(%pair_lhs_eq_smin_2, %pair_rhs_eq_m1_2) : (i1, i1) -> i1
    %pair_not_ub_2 = "arith.xori"(%pair_ub_2, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_2 = "arith.andi"(%pair_rhs_nz_2, %pair_not_ub_2) : (i1, i1) -> i1
    %pair_val_2 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_2 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_2 = "transfer.cmp"(%pair_rem_2, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_2 = "arith.andi"(%pair_valid_sdiv_2, %pair_exact_2) : (i1, i1) -> i1
    %pair_val0_2 = "transfer.xor"(%pair_val_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_2 = "transfer.select"(%pair_valid_2, %pair_val0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_2 = "transfer.select"(%pair_valid_2, %pair_val_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_2 = "transfer.and"(%pair_acc0_1, %pair_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_2 = "transfer.and"(%pair_acc1_1, %pair_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_2 = "arith.ori"(%pair_any_1, %pair_valid_2) : (i1, i1) -> i1
    %pair_rhs_nz_3 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_3 = "transfer.select"(%pair_rhs_nz_3, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_3 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_3 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_3 = "arith.andi"(%pair_lhs_eq_smin_3, %pair_rhs_eq_m1_3) : (i1, i1) -> i1
    %pair_not_ub_3 = "arith.xori"(%pair_ub_3, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_3 = "arith.andi"(%pair_rhs_nz_3, %pair_not_ub_3) : (i1, i1) -> i1
    %pair_val_3 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_3 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_3 = "transfer.cmp"(%pair_rem_3, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_3 = "arith.andi"(%pair_valid_sdiv_3, %pair_exact_3) : (i1, i1) -> i1
    %pair_val0_3 = "transfer.xor"(%pair_val_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_3 = "transfer.select"(%pair_valid_3, %pair_val0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_3 = "transfer.select"(%pair_valid_3, %pair_val_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_3 = "transfer.and"(%pair_acc0_2, %pair_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_3 = "transfer.and"(%pair_acc1_2, %pair_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_3 = "arith.ori"(%pair_any_2, %pair_valid_3) : (i1, i1) -> i1
    %pair_rhs_nz_4 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_4 = "transfer.select"(%pair_rhs_nz_4, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_4 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_4 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_4 = "arith.andi"(%pair_lhs_eq_smin_4, %pair_rhs_eq_m1_4) : (i1, i1) -> i1
    %pair_not_ub_4 = "arith.xori"(%pair_ub_4, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_4 = "arith.andi"(%pair_rhs_nz_4, %pair_not_ub_4) : (i1, i1) -> i1
    %pair_val_4 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_4 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_4 = "transfer.cmp"(%pair_rem_4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_4 = "arith.andi"(%pair_valid_sdiv_4, %pair_exact_4) : (i1, i1) -> i1
    %pair_val0_4 = "transfer.xor"(%pair_val_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_4 = "transfer.select"(%pair_valid_4, %pair_val0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_4 = "transfer.select"(%pair_valid_4, %pair_val_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_4 = "transfer.and"(%pair_acc0_3, %pair_sel0_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_4 = "transfer.and"(%pair_acc1_3, %pair_sel1_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_4 = "arith.ori"(%pair_any_3, %pair_valid_4) : (i1, i1) -> i1
    %pair_rhs_nz_5 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_5 = "transfer.select"(%pair_rhs_nz_5, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_5 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_5 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_5 = "arith.andi"(%pair_lhs_eq_smin_5, %pair_rhs_eq_m1_5) : (i1, i1) -> i1
    %pair_not_ub_5 = "arith.xori"(%pair_ub_5, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_5 = "arith.andi"(%pair_rhs_nz_5, %pair_not_ub_5) : (i1, i1) -> i1
    %pair_val_5 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_5 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_5 = "transfer.cmp"(%pair_rem_5, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_5 = "arith.andi"(%pair_valid_sdiv_5, %pair_exact_5) : (i1, i1) -> i1
    %pair_val0_5 = "transfer.xor"(%pair_val_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_5 = "transfer.select"(%pair_valid_5, %pair_val0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_5 = "transfer.select"(%pair_valid_5, %pair_val_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_5 = "transfer.and"(%pair_acc0_4, %pair_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_5 = "transfer.and"(%pair_acc1_4, %pair_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_5 = "arith.ori"(%pair_any_4, %pair_valid_5) : (i1, i1) -> i1
    %pair_rhs_nz_6 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_6 = "transfer.select"(%pair_rhs_nz_6, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_6 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_6 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_6 = "arith.andi"(%pair_lhs_eq_smin_6, %pair_rhs_eq_m1_6) : (i1, i1) -> i1
    %pair_not_ub_6 = "arith.xori"(%pair_ub_6, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_6 = "arith.andi"(%pair_rhs_nz_6, %pair_not_ub_6) : (i1, i1) -> i1
    %pair_val_6 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_6 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_6 = "transfer.cmp"(%pair_rem_6, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_6 = "arith.andi"(%pair_valid_sdiv_6, %pair_exact_6) : (i1, i1) -> i1
    %pair_val0_6 = "transfer.xor"(%pair_val_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_6 = "transfer.select"(%pair_valid_6, %pair_val0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_6 = "transfer.select"(%pair_valid_6, %pair_val_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_6 = "transfer.and"(%pair_acc0_5, %pair_sel0_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_6 = "transfer.and"(%pair_acc1_5, %pair_sel1_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_6 = "arith.ori"(%pair_any_5, %pair_valid_6) : (i1, i1) -> i1
    %pair_rhs_nz_7 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_7 = "transfer.select"(%pair_rhs_nz_7, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_7 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_7 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_7 = "arith.andi"(%pair_lhs_eq_smin_7, %pair_rhs_eq_m1_7) : (i1, i1) -> i1
    %pair_not_ub_7 = "arith.xori"(%pair_ub_7, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_7 = "arith.andi"(%pair_rhs_nz_7, %pair_not_ub_7) : (i1, i1) -> i1
    %pair_val_7 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_7 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_7 = "transfer.cmp"(%pair_rem_7, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_7 = "arith.andi"(%pair_valid_sdiv_7, %pair_exact_7) : (i1, i1) -> i1
    %pair_val0_7 = "transfer.xor"(%pair_val_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_7 = "transfer.select"(%pair_valid_7, %pair_val0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_7 = "transfer.select"(%pair_valid_7, %pair_val_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_7 = "transfer.and"(%pair_acc0_6, %pair_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_7 = "transfer.and"(%pair_acc1_6, %pair_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_7 = "arith.ori"(%pair_any_6, %pair_valid_7) : (i1, i1) -> i1
    %pair_rhs_nz_8 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_8 = "transfer.select"(%pair_rhs_nz_8, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_8 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_8 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_8 = "arith.andi"(%pair_lhs_eq_smin_8, %pair_rhs_eq_m1_8) : (i1, i1) -> i1
    %pair_not_ub_8 = "arith.xori"(%pair_ub_8, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_8 = "arith.andi"(%pair_rhs_nz_8, %pair_not_ub_8) : (i1, i1) -> i1
    %pair_val_8 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_8 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_8 = "transfer.cmp"(%pair_rem_8, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_8 = "arith.andi"(%pair_valid_sdiv_8, %pair_exact_8) : (i1, i1) -> i1
    %pair_val0_8 = "transfer.xor"(%pair_val_8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_8 = "transfer.select"(%pair_valid_8, %pair_val0_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_8 = "transfer.select"(%pair_valid_8, %pair_val_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_8 = "transfer.and"(%pair_acc0_7, %pair_sel0_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_8 = "transfer.and"(%pair_acc1_7, %pair_sel1_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_8 = "arith.ori"(%pair_any_7, %pair_valid_8) : (i1, i1) -> i1
    %pair_rhs_nz_9 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_9 = "transfer.select"(%pair_rhs_nz_9, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_9 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_9 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_9 = "arith.andi"(%pair_lhs_eq_smin_9, %pair_rhs_eq_m1_9) : (i1, i1) -> i1
    %pair_not_ub_9 = "arith.xori"(%pair_ub_9, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_9 = "arith.andi"(%pair_rhs_nz_9, %pair_not_ub_9) : (i1, i1) -> i1
    %pair_val_9 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_9 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_9 = "transfer.cmp"(%pair_rem_9, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_9 = "arith.andi"(%pair_valid_sdiv_9, %pair_exact_9) : (i1, i1) -> i1
    %pair_val0_9 = "transfer.xor"(%pair_val_9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_9 = "transfer.select"(%pair_valid_9, %pair_val0_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_9 = "transfer.select"(%pair_valid_9, %pair_val_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_9 = "transfer.and"(%pair_acc0_8, %pair_sel0_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_9 = "transfer.and"(%pair_acc1_8, %pair_sel1_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_9 = "arith.ori"(%pair_any_8, %pair_valid_9) : (i1, i1) -> i1
    %pair_rhs_nz_10 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_10 = "transfer.select"(%pair_rhs_nz_10, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_10 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_10 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_10 = "arith.andi"(%pair_lhs_eq_smin_10, %pair_rhs_eq_m1_10) : (i1, i1) -> i1
    %pair_not_ub_10 = "arith.xori"(%pair_ub_10, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_10 = "arith.andi"(%pair_rhs_nz_10, %pair_not_ub_10) : (i1, i1) -> i1
    %pair_val_10 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_10 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_10 = "transfer.cmp"(%pair_rem_10, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_10 = "arith.andi"(%pair_valid_sdiv_10, %pair_exact_10) : (i1, i1) -> i1
    %pair_val0_10 = "transfer.xor"(%pair_val_10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_10 = "transfer.select"(%pair_valid_10, %pair_val0_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_10 = "transfer.select"(%pair_valid_10, %pair_val_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_10 = "transfer.and"(%pair_acc0_9, %pair_sel0_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_10 = "transfer.and"(%pair_acc1_9, %pair_sel1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_10 = "arith.ori"(%pair_any_9, %pair_valid_10) : (i1, i1) -> i1
    %pair_rhs_nz_11 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_11 = "transfer.select"(%pair_rhs_nz_11, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_11 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_11 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_11 = "arith.andi"(%pair_lhs_eq_smin_11, %pair_rhs_eq_m1_11) : (i1, i1) -> i1
    %pair_not_ub_11 = "arith.xori"(%pair_ub_11, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_11 = "arith.andi"(%pair_rhs_nz_11, %pair_not_ub_11) : (i1, i1) -> i1
    %pair_val_11 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_11 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_11 = "transfer.cmp"(%pair_rem_11, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_11 = "arith.andi"(%pair_valid_sdiv_11, %pair_exact_11) : (i1, i1) -> i1
    %pair_val0_11 = "transfer.xor"(%pair_val_11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_11 = "transfer.select"(%pair_valid_11, %pair_val0_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_11 = "transfer.select"(%pair_valid_11, %pair_val_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_11 = "transfer.and"(%pair_acc0_10, %pair_sel0_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_11 = "transfer.and"(%pair_acc1_10, %pair_sel1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_11 = "arith.ori"(%pair_any_10, %pair_valid_11) : (i1, i1) -> i1
    %pair_rhs_nz_12 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_12 = "transfer.select"(%pair_rhs_nz_12, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_12 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_12 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_12 = "arith.andi"(%pair_lhs_eq_smin_12, %pair_rhs_eq_m1_12) : (i1, i1) -> i1
    %pair_not_ub_12 = "arith.xori"(%pair_ub_12, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_12 = "arith.andi"(%pair_rhs_nz_12, %pair_not_ub_12) : (i1, i1) -> i1
    %pair_val_12 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_12 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_12 = "transfer.cmp"(%pair_rem_12, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_12 = "arith.andi"(%pair_valid_sdiv_12, %pair_exact_12) : (i1, i1) -> i1
    %pair_val0_12 = "transfer.xor"(%pair_val_12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_12 = "transfer.select"(%pair_valid_12, %pair_val0_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_12 = "transfer.select"(%pair_valid_12, %pair_val_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_12 = "transfer.and"(%pair_acc0_11, %pair_sel0_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_12 = "transfer.and"(%pair_acc1_11, %pair_sel1_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_12 = "arith.ori"(%pair_any_11, %pair_valid_12) : (i1, i1) -> i1
    %pair_rhs_nz_13 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_13 = "transfer.select"(%pair_rhs_nz_13, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_13 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_13 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_13 = "arith.andi"(%pair_lhs_eq_smin_13, %pair_rhs_eq_m1_13) : (i1, i1) -> i1
    %pair_not_ub_13 = "arith.xori"(%pair_ub_13, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_13 = "arith.andi"(%pair_rhs_nz_13, %pair_not_ub_13) : (i1, i1) -> i1
    %pair_val_13 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_13 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_13 = "transfer.cmp"(%pair_rem_13, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_13 = "arith.andi"(%pair_valid_sdiv_13, %pair_exact_13) : (i1, i1) -> i1
    %pair_val0_13 = "transfer.xor"(%pair_val_13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_13 = "transfer.select"(%pair_valid_13, %pair_val0_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_13 = "transfer.select"(%pair_valid_13, %pair_val_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_13 = "transfer.and"(%pair_acc0_12, %pair_sel0_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_13 = "transfer.and"(%pair_acc1_12, %pair_sel1_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_13 = "arith.ori"(%pair_any_12, %pair_valid_13) : (i1, i1) -> i1
    %pair_rhs_nz_14 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_14 = "transfer.select"(%pair_rhs_nz_14, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_14 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_14 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_14 = "arith.andi"(%pair_lhs_eq_smin_14, %pair_rhs_eq_m1_14) : (i1, i1) -> i1
    %pair_not_ub_14 = "arith.xori"(%pair_ub_14, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_14 = "arith.andi"(%pair_rhs_nz_14, %pair_not_ub_14) : (i1, i1) -> i1
    %pair_val_14 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_14 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_14 = "transfer.cmp"(%pair_rem_14, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_14 = "arith.andi"(%pair_valid_sdiv_14, %pair_exact_14) : (i1, i1) -> i1
    %pair_val0_14 = "transfer.xor"(%pair_val_14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_14 = "transfer.select"(%pair_valid_14, %pair_val0_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_14 = "transfer.select"(%pair_valid_14, %pair_val_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_14 = "transfer.and"(%pair_acc0_13, %pair_sel0_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_14 = "transfer.and"(%pair_acc1_13, %pair_sel1_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_14 = "arith.ori"(%pair_any_13, %pair_valid_14) : (i1, i1) -> i1
    %pair_rhs_nz_15 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_15 = "transfer.select"(%pair_rhs_nz_15, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_15 = "transfer.cmp"(%lhsu_v0, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_15 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_15 = "arith.andi"(%pair_lhs_eq_smin_15, %pair_rhs_eq_m1_15) : (i1, i1) -> i1
    %pair_not_ub_15 = "arith.xori"(%pair_ub_15, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_15 = "arith.andi"(%pair_rhs_nz_15, %pair_not_ub_15) : (i1, i1) -> i1
    %pair_val_15 = "transfer.sdiv"(%lhsu_v0, %pair_rhs_safe_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_15 = "transfer.srem"(%lhsu_v0, %pair_rhs_safe_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_15 = "transfer.cmp"(%pair_rem_15, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_15 = "arith.andi"(%pair_valid_sdiv_15, %pair_exact_15) : (i1, i1) -> i1
    %pair_val0_15 = "transfer.xor"(%pair_val_15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_15 = "transfer.select"(%pair_valid_15, %pair_val0_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_15 = "transfer.select"(%pair_valid_15, %pair_val_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_15 = "transfer.and"(%pair_acc0_14, %pair_sel0_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_15 = "transfer.and"(%pair_acc1_14, %pair_sel1_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_15 = "arith.ori"(%pair_any_14, %pair_valid_15) : (i1, i1) -> i1
    %pair_rhs_nz_16 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_16 = "transfer.select"(%pair_rhs_nz_16, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_16 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_16 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_16 = "arith.andi"(%pair_lhs_eq_smin_16, %pair_rhs_eq_m1_16) : (i1, i1) -> i1
    %pair_not_ub_16 = "arith.xori"(%pair_ub_16, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_16 = "arith.andi"(%pair_rhs_nz_16, %pair_not_ub_16) : (i1, i1) -> i1
    %pair_val_16 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_16 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_16 = "transfer.cmp"(%pair_rem_16, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_16 = "arith.andi"(%pair_valid_sdiv_16, %pair_exact_16) : (i1, i1) -> i1
    %pair_val0_16 = "transfer.xor"(%pair_val_16, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_16 = "transfer.select"(%pair_valid_16, %pair_val0_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_16 = "transfer.select"(%pair_valid_16, %pair_val_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_16 = "transfer.and"(%pair_acc0_15, %pair_sel0_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_16 = "transfer.and"(%pair_acc1_15, %pair_sel1_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_16 = "arith.ori"(%pair_any_15, %pair_valid_16) : (i1, i1) -> i1
    %pair_rhs_nz_17 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_17 = "transfer.select"(%pair_rhs_nz_17, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_17 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_17 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_17 = "arith.andi"(%pair_lhs_eq_smin_17, %pair_rhs_eq_m1_17) : (i1, i1) -> i1
    %pair_not_ub_17 = "arith.xori"(%pair_ub_17, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_17 = "arith.andi"(%pair_rhs_nz_17, %pair_not_ub_17) : (i1, i1) -> i1
    %pair_val_17 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_17 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_17 = "transfer.cmp"(%pair_rem_17, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_17 = "arith.andi"(%pair_valid_sdiv_17, %pair_exact_17) : (i1, i1) -> i1
    %pair_val0_17 = "transfer.xor"(%pair_val_17, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_17 = "transfer.select"(%pair_valid_17, %pair_val0_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_17 = "transfer.select"(%pair_valid_17, %pair_val_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_17 = "transfer.and"(%pair_acc0_16, %pair_sel0_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_17 = "transfer.and"(%pair_acc1_16, %pair_sel1_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_17 = "arith.ori"(%pair_any_16, %pair_valid_17) : (i1, i1) -> i1
    %pair_rhs_nz_18 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_18 = "transfer.select"(%pair_rhs_nz_18, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_18 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_18 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_18 = "arith.andi"(%pair_lhs_eq_smin_18, %pair_rhs_eq_m1_18) : (i1, i1) -> i1
    %pair_not_ub_18 = "arith.xori"(%pair_ub_18, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_18 = "arith.andi"(%pair_rhs_nz_18, %pair_not_ub_18) : (i1, i1) -> i1
    %pair_val_18 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_18 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_18 = "transfer.cmp"(%pair_rem_18, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_18 = "arith.andi"(%pair_valid_sdiv_18, %pair_exact_18) : (i1, i1) -> i1
    %pair_val0_18 = "transfer.xor"(%pair_val_18, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_18 = "transfer.select"(%pair_valid_18, %pair_val0_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_18 = "transfer.select"(%pair_valid_18, %pair_val_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_18 = "transfer.and"(%pair_acc0_17, %pair_sel0_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_18 = "transfer.and"(%pair_acc1_17, %pair_sel1_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_18 = "arith.ori"(%pair_any_17, %pair_valid_18) : (i1, i1) -> i1
    %pair_rhs_nz_19 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_19 = "transfer.select"(%pair_rhs_nz_19, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_19 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_19 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_19 = "arith.andi"(%pair_lhs_eq_smin_19, %pair_rhs_eq_m1_19) : (i1, i1) -> i1
    %pair_not_ub_19 = "arith.xori"(%pair_ub_19, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_19 = "arith.andi"(%pair_rhs_nz_19, %pair_not_ub_19) : (i1, i1) -> i1
    %pair_val_19 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_19 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_19 = "transfer.cmp"(%pair_rem_19, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_19 = "arith.andi"(%pair_valid_sdiv_19, %pair_exact_19) : (i1, i1) -> i1
    %pair_val0_19 = "transfer.xor"(%pair_val_19, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_19 = "transfer.select"(%pair_valid_19, %pair_val0_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_19 = "transfer.select"(%pair_valid_19, %pair_val_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_19 = "transfer.and"(%pair_acc0_18, %pair_sel0_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_19 = "transfer.and"(%pair_acc1_18, %pair_sel1_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_19 = "arith.ori"(%pair_any_18, %pair_valid_19) : (i1, i1) -> i1
    %pair_rhs_nz_20 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_20 = "transfer.select"(%pair_rhs_nz_20, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_20 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_20 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_20 = "arith.andi"(%pair_lhs_eq_smin_20, %pair_rhs_eq_m1_20) : (i1, i1) -> i1
    %pair_not_ub_20 = "arith.xori"(%pair_ub_20, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_20 = "arith.andi"(%pair_rhs_nz_20, %pair_not_ub_20) : (i1, i1) -> i1
    %pair_val_20 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_20 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_20 = "transfer.cmp"(%pair_rem_20, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_20 = "arith.andi"(%pair_valid_sdiv_20, %pair_exact_20) : (i1, i1) -> i1
    %pair_val0_20 = "transfer.xor"(%pair_val_20, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_20 = "transfer.select"(%pair_valid_20, %pair_val0_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_20 = "transfer.select"(%pair_valid_20, %pair_val_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_20 = "transfer.and"(%pair_acc0_19, %pair_sel0_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_20 = "transfer.and"(%pair_acc1_19, %pair_sel1_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_20 = "arith.ori"(%pair_any_19, %pair_valid_20) : (i1, i1) -> i1
    %pair_rhs_nz_21 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_21 = "transfer.select"(%pair_rhs_nz_21, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_21 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_21 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_21 = "arith.andi"(%pair_lhs_eq_smin_21, %pair_rhs_eq_m1_21) : (i1, i1) -> i1
    %pair_not_ub_21 = "arith.xori"(%pair_ub_21, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_21 = "arith.andi"(%pair_rhs_nz_21, %pair_not_ub_21) : (i1, i1) -> i1
    %pair_val_21 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_21 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_21 = "transfer.cmp"(%pair_rem_21, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_21 = "arith.andi"(%pair_valid_sdiv_21, %pair_exact_21) : (i1, i1) -> i1
    %pair_val0_21 = "transfer.xor"(%pair_val_21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_21 = "transfer.select"(%pair_valid_21, %pair_val0_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_21 = "transfer.select"(%pair_valid_21, %pair_val_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_21 = "transfer.and"(%pair_acc0_20, %pair_sel0_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_21 = "transfer.and"(%pair_acc1_20, %pair_sel1_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_21 = "arith.ori"(%pair_any_20, %pair_valid_21) : (i1, i1) -> i1
    %pair_rhs_nz_22 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_22 = "transfer.select"(%pair_rhs_nz_22, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_22 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_22 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_22 = "arith.andi"(%pair_lhs_eq_smin_22, %pair_rhs_eq_m1_22) : (i1, i1) -> i1
    %pair_not_ub_22 = "arith.xori"(%pair_ub_22, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_22 = "arith.andi"(%pair_rhs_nz_22, %pair_not_ub_22) : (i1, i1) -> i1
    %pair_val_22 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_22 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_22 = "transfer.cmp"(%pair_rem_22, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_22 = "arith.andi"(%pair_valid_sdiv_22, %pair_exact_22) : (i1, i1) -> i1
    %pair_val0_22 = "transfer.xor"(%pair_val_22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_22 = "transfer.select"(%pair_valid_22, %pair_val0_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_22 = "transfer.select"(%pair_valid_22, %pair_val_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_22 = "transfer.and"(%pair_acc0_21, %pair_sel0_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_22 = "transfer.and"(%pair_acc1_21, %pair_sel1_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_22 = "arith.ori"(%pair_any_21, %pair_valid_22) : (i1, i1) -> i1
    %pair_rhs_nz_23 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_23 = "transfer.select"(%pair_rhs_nz_23, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_23 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_23 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_23 = "arith.andi"(%pair_lhs_eq_smin_23, %pair_rhs_eq_m1_23) : (i1, i1) -> i1
    %pair_not_ub_23 = "arith.xori"(%pair_ub_23, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_23 = "arith.andi"(%pair_rhs_nz_23, %pair_not_ub_23) : (i1, i1) -> i1
    %pair_val_23 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_23 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_23 = "transfer.cmp"(%pair_rem_23, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_23 = "arith.andi"(%pair_valid_sdiv_23, %pair_exact_23) : (i1, i1) -> i1
    %pair_val0_23 = "transfer.xor"(%pair_val_23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_23 = "transfer.select"(%pair_valid_23, %pair_val0_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_23 = "transfer.select"(%pair_valid_23, %pair_val_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_23 = "transfer.and"(%pair_acc0_22, %pair_sel0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_23 = "transfer.and"(%pair_acc1_22, %pair_sel1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_23 = "arith.ori"(%pair_any_22, %pair_valid_23) : (i1, i1) -> i1
    %pair_rhs_nz_24 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_24 = "transfer.select"(%pair_rhs_nz_24, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_24 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_24 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_24 = "arith.andi"(%pair_lhs_eq_smin_24, %pair_rhs_eq_m1_24) : (i1, i1) -> i1
    %pair_not_ub_24 = "arith.xori"(%pair_ub_24, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_24 = "arith.andi"(%pair_rhs_nz_24, %pair_not_ub_24) : (i1, i1) -> i1
    %pair_val_24 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_24 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_24 = "transfer.cmp"(%pair_rem_24, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_24 = "arith.andi"(%pair_valid_sdiv_24, %pair_exact_24) : (i1, i1) -> i1
    %pair_val0_24 = "transfer.xor"(%pair_val_24, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_24 = "transfer.select"(%pair_valid_24, %pair_val0_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_24 = "transfer.select"(%pair_valid_24, %pair_val_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_24 = "transfer.and"(%pair_acc0_23, %pair_sel0_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_24 = "transfer.and"(%pair_acc1_23, %pair_sel1_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_24 = "arith.ori"(%pair_any_23, %pair_valid_24) : (i1, i1) -> i1
    %pair_rhs_nz_25 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_25 = "transfer.select"(%pair_rhs_nz_25, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_25 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_25 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_25 = "arith.andi"(%pair_lhs_eq_smin_25, %pair_rhs_eq_m1_25) : (i1, i1) -> i1
    %pair_not_ub_25 = "arith.xori"(%pair_ub_25, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_25 = "arith.andi"(%pair_rhs_nz_25, %pair_not_ub_25) : (i1, i1) -> i1
    %pair_val_25 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_25 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_25 = "transfer.cmp"(%pair_rem_25, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_25 = "arith.andi"(%pair_valid_sdiv_25, %pair_exact_25) : (i1, i1) -> i1
    %pair_val0_25 = "transfer.xor"(%pair_val_25, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_25 = "transfer.select"(%pair_valid_25, %pair_val0_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_25 = "transfer.select"(%pair_valid_25, %pair_val_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_25 = "transfer.and"(%pair_acc0_24, %pair_sel0_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_25 = "transfer.and"(%pair_acc1_24, %pair_sel1_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_25 = "arith.ori"(%pair_any_24, %pair_valid_25) : (i1, i1) -> i1
    %pair_rhs_nz_26 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_26 = "transfer.select"(%pair_rhs_nz_26, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_26 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_26 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_26 = "arith.andi"(%pair_lhs_eq_smin_26, %pair_rhs_eq_m1_26) : (i1, i1) -> i1
    %pair_not_ub_26 = "arith.xori"(%pair_ub_26, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_26 = "arith.andi"(%pair_rhs_nz_26, %pair_not_ub_26) : (i1, i1) -> i1
    %pair_val_26 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_26 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_26 = "transfer.cmp"(%pair_rem_26, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_26 = "arith.andi"(%pair_valid_sdiv_26, %pair_exact_26) : (i1, i1) -> i1
    %pair_val0_26 = "transfer.xor"(%pair_val_26, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_26 = "transfer.select"(%pair_valid_26, %pair_val0_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_26 = "transfer.select"(%pair_valid_26, %pair_val_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_26 = "transfer.and"(%pair_acc0_25, %pair_sel0_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_26 = "transfer.and"(%pair_acc1_25, %pair_sel1_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_26 = "arith.ori"(%pair_any_25, %pair_valid_26) : (i1, i1) -> i1
    %pair_rhs_nz_27 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_27 = "transfer.select"(%pair_rhs_nz_27, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_27 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_27 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_27 = "arith.andi"(%pair_lhs_eq_smin_27, %pair_rhs_eq_m1_27) : (i1, i1) -> i1
    %pair_not_ub_27 = "arith.xori"(%pair_ub_27, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_27 = "arith.andi"(%pair_rhs_nz_27, %pair_not_ub_27) : (i1, i1) -> i1
    %pair_val_27 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_27 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_27 = "transfer.cmp"(%pair_rem_27, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_27 = "arith.andi"(%pair_valid_sdiv_27, %pair_exact_27) : (i1, i1) -> i1
    %pair_val0_27 = "transfer.xor"(%pair_val_27, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_27 = "transfer.select"(%pair_valid_27, %pair_val0_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_27 = "transfer.select"(%pair_valid_27, %pair_val_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_27 = "transfer.and"(%pair_acc0_26, %pair_sel0_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_27 = "transfer.and"(%pair_acc1_26, %pair_sel1_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_27 = "arith.ori"(%pair_any_26, %pair_valid_27) : (i1, i1) -> i1
    %pair_rhs_nz_28 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_28 = "transfer.select"(%pair_rhs_nz_28, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_28 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_28 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_28 = "arith.andi"(%pair_lhs_eq_smin_28, %pair_rhs_eq_m1_28) : (i1, i1) -> i1
    %pair_not_ub_28 = "arith.xori"(%pair_ub_28, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_28 = "arith.andi"(%pair_rhs_nz_28, %pair_not_ub_28) : (i1, i1) -> i1
    %pair_val_28 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_28 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_28 = "transfer.cmp"(%pair_rem_28, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_28 = "arith.andi"(%pair_valid_sdiv_28, %pair_exact_28) : (i1, i1) -> i1
    %pair_val0_28 = "transfer.xor"(%pair_val_28, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_28 = "transfer.select"(%pair_valid_28, %pair_val0_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_28 = "transfer.select"(%pair_valid_28, %pair_val_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_28 = "transfer.and"(%pair_acc0_27, %pair_sel0_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_28 = "transfer.and"(%pair_acc1_27, %pair_sel1_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_28 = "arith.ori"(%pair_any_27, %pair_valid_28) : (i1, i1) -> i1
    %pair_rhs_nz_29 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_29 = "transfer.select"(%pair_rhs_nz_29, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_29 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_29 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_29 = "arith.andi"(%pair_lhs_eq_smin_29, %pair_rhs_eq_m1_29) : (i1, i1) -> i1
    %pair_not_ub_29 = "arith.xori"(%pair_ub_29, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_29 = "arith.andi"(%pair_rhs_nz_29, %pair_not_ub_29) : (i1, i1) -> i1
    %pair_val_29 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_29 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_29 = "transfer.cmp"(%pair_rem_29, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_29 = "arith.andi"(%pair_valid_sdiv_29, %pair_exact_29) : (i1, i1) -> i1
    %pair_val0_29 = "transfer.xor"(%pair_val_29, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_29 = "transfer.select"(%pair_valid_29, %pair_val0_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_29 = "transfer.select"(%pair_valid_29, %pair_val_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_29 = "transfer.and"(%pair_acc0_28, %pair_sel0_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_29 = "transfer.and"(%pair_acc1_28, %pair_sel1_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_29 = "arith.ori"(%pair_any_28, %pair_valid_29) : (i1, i1) -> i1
    %pair_rhs_nz_30 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_30 = "transfer.select"(%pair_rhs_nz_30, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_30 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_30 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_30 = "arith.andi"(%pair_lhs_eq_smin_30, %pair_rhs_eq_m1_30) : (i1, i1) -> i1
    %pair_not_ub_30 = "arith.xori"(%pair_ub_30, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_30 = "arith.andi"(%pair_rhs_nz_30, %pair_not_ub_30) : (i1, i1) -> i1
    %pair_val_30 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_30 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_30 = "transfer.cmp"(%pair_rem_30, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_30 = "arith.andi"(%pair_valid_sdiv_30, %pair_exact_30) : (i1, i1) -> i1
    %pair_val0_30 = "transfer.xor"(%pair_val_30, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_30 = "transfer.select"(%pair_valid_30, %pair_val0_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_30 = "transfer.select"(%pair_valid_30, %pair_val_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_30 = "transfer.and"(%pair_acc0_29, %pair_sel0_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_30 = "transfer.and"(%pair_acc1_29, %pair_sel1_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_30 = "arith.ori"(%pair_any_29, %pair_valid_30) : (i1, i1) -> i1
    %pair_rhs_nz_31 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_31 = "transfer.select"(%pair_rhs_nz_31, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_31 = "transfer.cmp"(%lhsu_v1, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_31 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_31 = "arith.andi"(%pair_lhs_eq_smin_31, %pair_rhs_eq_m1_31) : (i1, i1) -> i1
    %pair_not_ub_31 = "arith.xori"(%pair_ub_31, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_31 = "arith.andi"(%pair_rhs_nz_31, %pair_not_ub_31) : (i1, i1) -> i1
    %pair_val_31 = "transfer.sdiv"(%lhsu_v1, %pair_rhs_safe_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_31 = "transfer.srem"(%lhsu_v1, %pair_rhs_safe_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_31 = "transfer.cmp"(%pair_rem_31, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_31 = "arith.andi"(%pair_valid_sdiv_31, %pair_exact_31) : (i1, i1) -> i1
    %pair_val0_31 = "transfer.xor"(%pair_val_31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_31 = "transfer.select"(%pair_valid_31, %pair_val0_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_31 = "transfer.select"(%pair_valid_31, %pair_val_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_31 = "transfer.and"(%pair_acc0_30, %pair_sel0_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_31 = "transfer.and"(%pair_acc1_30, %pair_sel1_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_31 = "arith.ori"(%pair_any_30, %pair_valid_31) : (i1, i1) -> i1
    %pair_rhs_nz_32 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_32 = "transfer.select"(%pair_rhs_nz_32, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_32 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_32 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_32 = "arith.andi"(%pair_lhs_eq_smin_32, %pair_rhs_eq_m1_32) : (i1, i1) -> i1
    %pair_not_ub_32 = "arith.xori"(%pair_ub_32, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_32 = "arith.andi"(%pair_rhs_nz_32, %pair_not_ub_32) : (i1, i1) -> i1
    %pair_val_32 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_32 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_32 = "transfer.cmp"(%pair_rem_32, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_32 = "arith.andi"(%pair_valid_sdiv_32, %pair_exact_32) : (i1, i1) -> i1
    %pair_val0_32 = "transfer.xor"(%pair_val_32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_32 = "transfer.select"(%pair_valid_32, %pair_val0_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_32 = "transfer.select"(%pair_valid_32, %pair_val_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_32 = "transfer.and"(%pair_acc0_31, %pair_sel0_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_32 = "transfer.and"(%pair_acc1_31, %pair_sel1_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_32 = "arith.ori"(%pair_any_31, %pair_valid_32) : (i1, i1) -> i1
    %pair_rhs_nz_33 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_33 = "transfer.select"(%pair_rhs_nz_33, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_33 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_33 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_33 = "arith.andi"(%pair_lhs_eq_smin_33, %pair_rhs_eq_m1_33) : (i1, i1) -> i1
    %pair_not_ub_33 = "arith.xori"(%pair_ub_33, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_33 = "arith.andi"(%pair_rhs_nz_33, %pair_not_ub_33) : (i1, i1) -> i1
    %pair_val_33 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_33 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_33 = "transfer.cmp"(%pair_rem_33, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_33 = "arith.andi"(%pair_valid_sdiv_33, %pair_exact_33) : (i1, i1) -> i1
    %pair_val0_33 = "transfer.xor"(%pair_val_33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_33 = "transfer.select"(%pair_valid_33, %pair_val0_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_33 = "transfer.select"(%pair_valid_33, %pair_val_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_33 = "transfer.and"(%pair_acc0_32, %pair_sel0_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_33 = "transfer.and"(%pair_acc1_32, %pair_sel1_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_33 = "arith.ori"(%pair_any_32, %pair_valid_33) : (i1, i1) -> i1
    %pair_rhs_nz_34 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_34 = "transfer.select"(%pair_rhs_nz_34, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_34 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_34 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_34 = "arith.andi"(%pair_lhs_eq_smin_34, %pair_rhs_eq_m1_34) : (i1, i1) -> i1
    %pair_not_ub_34 = "arith.xori"(%pair_ub_34, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_34 = "arith.andi"(%pair_rhs_nz_34, %pair_not_ub_34) : (i1, i1) -> i1
    %pair_val_34 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_34 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_34 = "transfer.cmp"(%pair_rem_34, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_34 = "arith.andi"(%pair_valid_sdiv_34, %pair_exact_34) : (i1, i1) -> i1
    %pair_val0_34 = "transfer.xor"(%pair_val_34, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_34 = "transfer.select"(%pair_valid_34, %pair_val0_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_34 = "transfer.select"(%pair_valid_34, %pair_val_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_34 = "transfer.and"(%pair_acc0_33, %pair_sel0_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_34 = "transfer.and"(%pair_acc1_33, %pair_sel1_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_34 = "arith.ori"(%pair_any_33, %pair_valid_34) : (i1, i1) -> i1
    %pair_rhs_nz_35 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_35 = "transfer.select"(%pair_rhs_nz_35, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_35 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_35 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_35 = "arith.andi"(%pair_lhs_eq_smin_35, %pair_rhs_eq_m1_35) : (i1, i1) -> i1
    %pair_not_ub_35 = "arith.xori"(%pair_ub_35, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_35 = "arith.andi"(%pair_rhs_nz_35, %pair_not_ub_35) : (i1, i1) -> i1
    %pair_val_35 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_35 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_35 = "transfer.cmp"(%pair_rem_35, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_35 = "arith.andi"(%pair_valid_sdiv_35, %pair_exact_35) : (i1, i1) -> i1
    %pair_val0_35 = "transfer.xor"(%pair_val_35, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_35 = "transfer.select"(%pair_valid_35, %pair_val0_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_35 = "transfer.select"(%pair_valid_35, %pair_val_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_35 = "transfer.and"(%pair_acc0_34, %pair_sel0_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_35 = "transfer.and"(%pair_acc1_34, %pair_sel1_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_35 = "arith.ori"(%pair_any_34, %pair_valid_35) : (i1, i1) -> i1
    %pair_rhs_nz_36 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_36 = "transfer.select"(%pair_rhs_nz_36, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_36 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_36 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_36 = "arith.andi"(%pair_lhs_eq_smin_36, %pair_rhs_eq_m1_36) : (i1, i1) -> i1
    %pair_not_ub_36 = "arith.xori"(%pair_ub_36, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_36 = "arith.andi"(%pair_rhs_nz_36, %pair_not_ub_36) : (i1, i1) -> i1
    %pair_val_36 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_36 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_36 = "transfer.cmp"(%pair_rem_36, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_36 = "arith.andi"(%pair_valid_sdiv_36, %pair_exact_36) : (i1, i1) -> i1
    %pair_val0_36 = "transfer.xor"(%pair_val_36, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_36 = "transfer.select"(%pair_valid_36, %pair_val0_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_36 = "transfer.select"(%pair_valid_36, %pair_val_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_36 = "transfer.and"(%pair_acc0_35, %pair_sel0_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_36 = "transfer.and"(%pair_acc1_35, %pair_sel1_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_36 = "arith.ori"(%pair_any_35, %pair_valid_36) : (i1, i1) -> i1
    %pair_rhs_nz_37 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_37 = "transfer.select"(%pair_rhs_nz_37, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_37 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_37 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_37 = "arith.andi"(%pair_lhs_eq_smin_37, %pair_rhs_eq_m1_37) : (i1, i1) -> i1
    %pair_not_ub_37 = "arith.xori"(%pair_ub_37, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_37 = "arith.andi"(%pair_rhs_nz_37, %pair_not_ub_37) : (i1, i1) -> i1
    %pair_val_37 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_37 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_37 = "transfer.cmp"(%pair_rem_37, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_37 = "arith.andi"(%pair_valid_sdiv_37, %pair_exact_37) : (i1, i1) -> i1
    %pair_val0_37 = "transfer.xor"(%pair_val_37, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_37 = "transfer.select"(%pair_valid_37, %pair_val0_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_37 = "transfer.select"(%pair_valid_37, %pair_val_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_37 = "transfer.and"(%pair_acc0_36, %pair_sel0_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_37 = "transfer.and"(%pair_acc1_36, %pair_sel1_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_37 = "arith.ori"(%pair_any_36, %pair_valid_37) : (i1, i1) -> i1
    %pair_rhs_nz_38 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_38 = "transfer.select"(%pair_rhs_nz_38, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_38 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_38 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_38 = "arith.andi"(%pair_lhs_eq_smin_38, %pair_rhs_eq_m1_38) : (i1, i1) -> i1
    %pair_not_ub_38 = "arith.xori"(%pair_ub_38, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_38 = "arith.andi"(%pair_rhs_nz_38, %pair_not_ub_38) : (i1, i1) -> i1
    %pair_val_38 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_38 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_38 = "transfer.cmp"(%pair_rem_38, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_38 = "arith.andi"(%pair_valid_sdiv_38, %pair_exact_38) : (i1, i1) -> i1
    %pair_val0_38 = "transfer.xor"(%pair_val_38, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_38 = "transfer.select"(%pair_valid_38, %pair_val0_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_38 = "transfer.select"(%pair_valid_38, %pair_val_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_38 = "transfer.and"(%pair_acc0_37, %pair_sel0_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_38 = "transfer.and"(%pair_acc1_37, %pair_sel1_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_38 = "arith.ori"(%pair_any_37, %pair_valid_38) : (i1, i1) -> i1
    %pair_rhs_nz_39 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_39 = "transfer.select"(%pair_rhs_nz_39, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_39 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_39 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_39 = "arith.andi"(%pair_lhs_eq_smin_39, %pair_rhs_eq_m1_39) : (i1, i1) -> i1
    %pair_not_ub_39 = "arith.xori"(%pair_ub_39, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_39 = "arith.andi"(%pair_rhs_nz_39, %pair_not_ub_39) : (i1, i1) -> i1
    %pair_val_39 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_39 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_39 = "transfer.cmp"(%pair_rem_39, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_39 = "arith.andi"(%pair_valid_sdiv_39, %pair_exact_39) : (i1, i1) -> i1
    %pair_val0_39 = "transfer.xor"(%pair_val_39, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_39 = "transfer.select"(%pair_valid_39, %pair_val0_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_39 = "transfer.select"(%pair_valid_39, %pair_val_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_39 = "transfer.and"(%pair_acc0_38, %pair_sel0_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_39 = "transfer.and"(%pair_acc1_38, %pair_sel1_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_39 = "arith.ori"(%pair_any_38, %pair_valid_39) : (i1, i1) -> i1
    %pair_rhs_nz_40 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_40 = "transfer.select"(%pair_rhs_nz_40, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_40 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_40 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_40 = "arith.andi"(%pair_lhs_eq_smin_40, %pair_rhs_eq_m1_40) : (i1, i1) -> i1
    %pair_not_ub_40 = "arith.xori"(%pair_ub_40, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_40 = "arith.andi"(%pair_rhs_nz_40, %pair_not_ub_40) : (i1, i1) -> i1
    %pair_val_40 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_40 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_40 = "transfer.cmp"(%pair_rem_40, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_40 = "arith.andi"(%pair_valid_sdiv_40, %pair_exact_40) : (i1, i1) -> i1
    %pair_val0_40 = "transfer.xor"(%pair_val_40, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_40 = "transfer.select"(%pair_valid_40, %pair_val0_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_40 = "transfer.select"(%pair_valid_40, %pair_val_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_40 = "transfer.and"(%pair_acc0_39, %pair_sel0_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_40 = "transfer.and"(%pair_acc1_39, %pair_sel1_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_40 = "arith.ori"(%pair_any_39, %pair_valid_40) : (i1, i1) -> i1
    %pair_rhs_nz_41 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_41 = "transfer.select"(%pair_rhs_nz_41, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_41 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_41 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_41 = "arith.andi"(%pair_lhs_eq_smin_41, %pair_rhs_eq_m1_41) : (i1, i1) -> i1
    %pair_not_ub_41 = "arith.xori"(%pair_ub_41, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_41 = "arith.andi"(%pair_rhs_nz_41, %pair_not_ub_41) : (i1, i1) -> i1
    %pair_val_41 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_41 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_41 = "transfer.cmp"(%pair_rem_41, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_41 = "arith.andi"(%pair_valid_sdiv_41, %pair_exact_41) : (i1, i1) -> i1
    %pair_val0_41 = "transfer.xor"(%pair_val_41, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_41 = "transfer.select"(%pair_valid_41, %pair_val0_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_41 = "transfer.select"(%pair_valid_41, %pair_val_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_41 = "transfer.and"(%pair_acc0_40, %pair_sel0_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_41 = "transfer.and"(%pair_acc1_40, %pair_sel1_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_41 = "arith.ori"(%pair_any_40, %pair_valid_41) : (i1, i1) -> i1
    %pair_rhs_nz_42 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_42 = "transfer.select"(%pair_rhs_nz_42, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_42 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_42 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_42 = "arith.andi"(%pair_lhs_eq_smin_42, %pair_rhs_eq_m1_42) : (i1, i1) -> i1
    %pair_not_ub_42 = "arith.xori"(%pair_ub_42, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_42 = "arith.andi"(%pair_rhs_nz_42, %pair_not_ub_42) : (i1, i1) -> i1
    %pair_val_42 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_42 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_42 = "transfer.cmp"(%pair_rem_42, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_42 = "arith.andi"(%pair_valid_sdiv_42, %pair_exact_42) : (i1, i1) -> i1
    %pair_val0_42 = "transfer.xor"(%pair_val_42, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_42 = "transfer.select"(%pair_valid_42, %pair_val0_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_42 = "transfer.select"(%pair_valid_42, %pair_val_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_42 = "transfer.and"(%pair_acc0_41, %pair_sel0_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_42 = "transfer.and"(%pair_acc1_41, %pair_sel1_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_42 = "arith.ori"(%pair_any_41, %pair_valid_42) : (i1, i1) -> i1
    %pair_rhs_nz_43 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_43 = "transfer.select"(%pair_rhs_nz_43, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_43 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_43 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_43 = "arith.andi"(%pair_lhs_eq_smin_43, %pair_rhs_eq_m1_43) : (i1, i1) -> i1
    %pair_not_ub_43 = "arith.xori"(%pair_ub_43, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_43 = "arith.andi"(%pair_rhs_nz_43, %pair_not_ub_43) : (i1, i1) -> i1
    %pair_val_43 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_43 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_43 = "transfer.cmp"(%pair_rem_43, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_43 = "arith.andi"(%pair_valid_sdiv_43, %pair_exact_43) : (i1, i1) -> i1
    %pair_val0_43 = "transfer.xor"(%pair_val_43, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_43 = "transfer.select"(%pair_valid_43, %pair_val0_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_43 = "transfer.select"(%pair_valid_43, %pair_val_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_43 = "transfer.and"(%pair_acc0_42, %pair_sel0_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_43 = "transfer.and"(%pair_acc1_42, %pair_sel1_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_43 = "arith.ori"(%pair_any_42, %pair_valid_43) : (i1, i1) -> i1
    %pair_rhs_nz_44 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_44 = "transfer.select"(%pair_rhs_nz_44, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_44 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_44 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_44 = "arith.andi"(%pair_lhs_eq_smin_44, %pair_rhs_eq_m1_44) : (i1, i1) -> i1
    %pair_not_ub_44 = "arith.xori"(%pair_ub_44, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_44 = "arith.andi"(%pair_rhs_nz_44, %pair_not_ub_44) : (i1, i1) -> i1
    %pair_val_44 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_44 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_44 = "transfer.cmp"(%pair_rem_44, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_44 = "arith.andi"(%pair_valid_sdiv_44, %pair_exact_44) : (i1, i1) -> i1
    %pair_val0_44 = "transfer.xor"(%pair_val_44, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_44 = "transfer.select"(%pair_valid_44, %pair_val0_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_44 = "transfer.select"(%pair_valid_44, %pair_val_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_44 = "transfer.and"(%pair_acc0_43, %pair_sel0_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_44 = "transfer.and"(%pair_acc1_43, %pair_sel1_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_44 = "arith.ori"(%pair_any_43, %pair_valid_44) : (i1, i1) -> i1
    %pair_rhs_nz_45 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_45 = "transfer.select"(%pair_rhs_nz_45, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_45 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_45 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_45 = "arith.andi"(%pair_lhs_eq_smin_45, %pair_rhs_eq_m1_45) : (i1, i1) -> i1
    %pair_not_ub_45 = "arith.xori"(%pair_ub_45, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_45 = "arith.andi"(%pair_rhs_nz_45, %pair_not_ub_45) : (i1, i1) -> i1
    %pair_val_45 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_45 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_45 = "transfer.cmp"(%pair_rem_45, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_45 = "arith.andi"(%pair_valid_sdiv_45, %pair_exact_45) : (i1, i1) -> i1
    %pair_val0_45 = "transfer.xor"(%pair_val_45, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_45 = "transfer.select"(%pair_valid_45, %pair_val0_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_45 = "transfer.select"(%pair_valid_45, %pair_val_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_45 = "transfer.and"(%pair_acc0_44, %pair_sel0_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_45 = "transfer.and"(%pair_acc1_44, %pair_sel1_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_45 = "arith.ori"(%pair_any_44, %pair_valid_45) : (i1, i1) -> i1
    %pair_rhs_nz_46 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_46 = "transfer.select"(%pair_rhs_nz_46, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_46 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_46 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_46 = "arith.andi"(%pair_lhs_eq_smin_46, %pair_rhs_eq_m1_46) : (i1, i1) -> i1
    %pair_not_ub_46 = "arith.xori"(%pair_ub_46, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_46 = "arith.andi"(%pair_rhs_nz_46, %pair_not_ub_46) : (i1, i1) -> i1
    %pair_val_46 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_46 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_46 = "transfer.cmp"(%pair_rem_46, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_46 = "arith.andi"(%pair_valid_sdiv_46, %pair_exact_46) : (i1, i1) -> i1
    %pair_val0_46 = "transfer.xor"(%pair_val_46, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_46 = "transfer.select"(%pair_valid_46, %pair_val0_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_46 = "transfer.select"(%pair_valid_46, %pair_val_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_46 = "transfer.and"(%pair_acc0_45, %pair_sel0_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_46 = "transfer.and"(%pair_acc1_45, %pair_sel1_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_46 = "arith.ori"(%pair_any_45, %pair_valid_46) : (i1, i1) -> i1
    %pair_rhs_nz_47 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_47 = "transfer.select"(%pair_rhs_nz_47, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_47 = "transfer.cmp"(%lhsu_v2, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_47 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_47 = "arith.andi"(%pair_lhs_eq_smin_47, %pair_rhs_eq_m1_47) : (i1, i1) -> i1
    %pair_not_ub_47 = "arith.xori"(%pair_ub_47, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_47 = "arith.andi"(%pair_rhs_nz_47, %pair_not_ub_47) : (i1, i1) -> i1
    %pair_val_47 = "transfer.sdiv"(%lhsu_v2, %pair_rhs_safe_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_47 = "transfer.srem"(%lhsu_v2, %pair_rhs_safe_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_47 = "transfer.cmp"(%pair_rem_47, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_47 = "arith.andi"(%pair_valid_sdiv_47, %pair_exact_47) : (i1, i1) -> i1
    %pair_val0_47 = "transfer.xor"(%pair_val_47, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_47 = "transfer.select"(%pair_valid_47, %pair_val0_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_47 = "transfer.select"(%pair_valid_47, %pair_val_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_47 = "transfer.and"(%pair_acc0_46, %pair_sel0_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_47 = "transfer.and"(%pair_acc1_46, %pair_sel1_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_47 = "arith.ori"(%pair_any_46, %pair_valid_47) : (i1, i1) -> i1
    %pair_rhs_nz_48 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_48 = "transfer.select"(%pair_rhs_nz_48, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_48 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_48 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_48 = "arith.andi"(%pair_lhs_eq_smin_48, %pair_rhs_eq_m1_48) : (i1, i1) -> i1
    %pair_not_ub_48 = "arith.xori"(%pair_ub_48, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_48 = "arith.andi"(%pair_rhs_nz_48, %pair_not_ub_48) : (i1, i1) -> i1
    %pair_val_48 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_48 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_48 = "transfer.cmp"(%pair_rem_48, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_48 = "arith.andi"(%pair_valid_sdiv_48, %pair_exact_48) : (i1, i1) -> i1
    %pair_val0_48 = "transfer.xor"(%pair_val_48, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_48 = "transfer.select"(%pair_valid_48, %pair_val0_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_48 = "transfer.select"(%pair_valid_48, %pair_val_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_48 = "transfer.and"(%pair_acc0_47, %pair_sel0_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_48 = "transfer.and"(%pair_acc1_47, %pair_sel1_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_48 = "arith.ori"(%pair_any_47, %pair_valid_48) : (i1, i1) -> i1
    %pair_rhs_nz_49 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_49 = "transfer.select"(%pair_rhs_nz_49, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_49 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_49 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_49 = "arith.andi"(%pair_lhs_eq_smin_49, %pair_rhs_eq_m1_49) : (i1, i1) -> i1
    %pair_not_ub_49 = "arith.xori"(%pair_ub_49, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_49 = "arith.andi"(%pair_rhs_nz_49, %pair_not_ub_49) : (i1, i1) -> i1
    %pair_val_49 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_49 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_49 = "transfer.cmp"(%pair_rem_49, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_49 = "arith.andi"(%pair_valid_sdiv_49, %pair_exact_49) : (i1, i1) -> i1
    %pair_val0_49 = "transfer.xor"(%pair_val_49, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_49 = "transfer.select"(%pair_valid_49, %pair_val0_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_49 = "transfer.select"(%pair_valid_49, %pair_val_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_49 = "transfer.and"(%pair_acc0_48, %pair_sel0_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_49 = "transfer.and"(%pair_acc1_48, %pair_sel1_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_49 = "arith.ori"(%pair_any_48, %pair_valid_49) : (i1, i1) -> i1
    %pair_rhs_nz_50 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_50 = "transfer.select"(%pair_rhs_nz_50, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_50 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_50 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_50 = "arith.andi"(%pair_lhs_eq_smin_50, %pair_rhs_eq_m1_50) : (i1, i1) -> i1
    %pair_not_ub_50 = "arith.xori"(%pair_ub_50, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_50 = "arith.andi"(%pair_rhs_nz_50, %pair_not_ub_50) : (i1, i1) -> i1
    %pair_val_50 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_50 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_50 = "transfer.cmp"(%pair_rem_50, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_50 = "arith.andi"(%pair_valid_sdiv_50, %pair_exact_50) : (i1, i1) -> i1
    %pair_val0_50 = "transfer.xor"(%pair_val_50, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_50 = "transfer.select"(%pair_valid_50, %pair_val0_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_50 = "transfer.select"(%pair_valid_50, %pair_val_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_50 = "transfer.and"(%pair_acc0_49, %pair_sel0_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_50 = "transfer.and"(%pair_acc1_49, %pair_sel1_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_50 = "arith.ori"(%pair_any_49, %pair_valid_50) : (i1, i1) -> i1
    %pair_rhs_nz_51 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_51 = "transfer.select"(%pair_rhs_nz_51, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_51 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_51 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_51 = "arith.andi"(%pair_lhs_eq_smin_51, %pair_rhs_eq_m1_51) : (i1, i1) -> i1
    %pair_not_ub_51 = "arith.xori"(%pair_ub_51, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_51 = "arith.andi"(%pair_rhs_nz_51, %pair_not_ub_51) : (i1, i1) -> i1
    %pair_val_51 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_51 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_51 = "transfer.cmp"(%pair_rem_51, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_51 = "arith.andi"(%pair_valid_sdiv_51, %pair_exact_51) : (i1, i1) -> i1
    %pair_val0_51 = "transfer.xor"(%pair_val_51, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_51 = "transfer.select"(%pair_valid_51, %pair_val0_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_51 = "transfer.select"(%pair_valid_51, %pair_val_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_51 = "transfer.and"(%pair_acc0_50, %pair_sel0_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_51 = "transfer.and"(%pair_acc1_50, %pair_sel1_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_51 = "arith.ori"(%pair_any_50, %pair_valid_51) : (i1, i1) -> i1
    %pair_rhs_nz_52 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_52 = "transfer.select"(%pair_rhs_nz_52, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_52 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_52 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_52 = "arith.andi"(%pair_lhs_eq_smin_52, %pair_rhs_eq_m1_52) : (i1, i1) -> i1
    %pair_not_ub_52 = "arith.xori"(%pair_ub_52, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_52 = "arith.andi"(%pair_rhs_nz_52, %pair_not_ub_52) : (i1, i1) -> i1
    %pair_val_52 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_52 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_52 = "transfer.cmp"(%pair_rem_52, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_52 = "arith.andi"(%pair_valid_sdiv_52, %pair_exact_52) : (i1, i1) -> i1
    %pair_val0_52 = "transfer.xor"(%pair_val_52, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_52 = "transfer.select"(%pair_valid_52, %pair_val0_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_52 = "transfer.select"(%pair_valid_52, %pair_val_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_52 = "transfer.and"(%pair_acc0_51, %pair_sel0_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_52 = "transfer.and"(%pair_acc1_51, %pair_sel1_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_52 = "arith.ori"(%pair_any_51, %pair_valid_52) : (i1, i1) -> i1
    %pair_rhs_nz_53 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_53 = "transfer.select"(%pair_rhs_nz_53, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_53 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_53 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_53 = "arith.andi"(%pair_lhs_eq_smin_53, %pair_rhs_eq_m1_53) : (i1, i1) -> i1
    %pair_not_ub_53 = "arith.xori"(%pair_ub_53, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_53 = "arith.andi"(%pair_rhs_nz_53, %pair_not_ub_53) : (i1, i1) -> i1
    %pair_val_53 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_53 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_53 = "transfer.cmp"(%pair_rem_53, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_53 = "arith.andi"(%pair_valid_sdiv_53, %pair_exact_53) : (i1, i1) -> i1
    %pair_val0_53 = "transfer.xor"(%pair_val_53, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_53 = "transfer.select"(%pair_valid_53, %pair_val0_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_53 = "transfer.select"(%pair_valid_53, %pair_val_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_53 = "transfer.and"(%pair_acc0_52, %pair_sel0_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_53 = "transfer.and"(%pair_acc1_52, %pair_sel1_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_53 = "arith.ori"(%pair_any_52, %pair_valid_53) : (i1, i1) -> i1
    %pair_rhs_nz_54 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_54 = "transfer.select"(%pair_rhs_nz_54, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_54 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_54 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_54 = "arith.andi"(%pair_lhs_eq_smin_54, %pair_rhs_eq_m1_54) : (i1, i1) -> i1
    %pair_not_ub_54 = "arith.xori"(%pair_ub_54, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_54 = "arith.andi"(%pair_rhs_nz_54, %pair_not_ub_54) : (i1, i1) -> i1
    %pair_val_54 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_54 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_54 = "transfer.cmp"(%pair_rem_54, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_54 = "arith.andi"(%pair_valid_sdiv_54, %pair_exact_54) : (i1, i1) -> i1
    %pair_val0_54 = "transfer.xor"(%pair_val_54, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_54 = "transfer.select"(%pair_valid_54, %pair_val0_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_54 = "transfer.select"(%pair_valid_54, %pair_val_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_54 = "transfer.and"(%pair_acc0_53, %pair_sel0_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_54 = "transfer.and"(%pair_acc1_53, %pair_sel1_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_54 = "arith.ori"(%pair_any_53, %pair_valid_54) : (i1, i1) -> i1
    %pair_rhs_nz_55 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_55 = "transfer.select"(%pair_rhs_nz_55, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_55 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_55 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_55 = "arith.andi"(%pair_lhs_eq_smin_55, %pair_rhs_eq_m1_55) : (i1, i1) -> i1
    %pair_not_ub_55 = "arith.xori"(%pair_ub_55, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_55 = "arith.andi"(%pair_rhs_nz_55, %pair_not_ub_55) : (i1, i1) -> i1
    %pair_val_55 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_55 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_55 = "transfer.cmp"(%pair_rem_55, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_55 = "arith.andi"(%pair_valid_sdiv_55, %pair_exact_55) : (i1, i1) -> i1
    %pair_val0_55 = "transfer.xor"(%pair_val_55, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_55 = "transfer.select"(%pair_valid_55, %pair_val0_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_55 = "transfer.select"(%pair_valid_55, %pair_val_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_55 = "transfer.and"(%pair_acc0_54, %pair_sel0_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_55 = "transfer.and"(%pair_acc1_54, %pair_sel1_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_55 = "arith.ori"(%pair_any_54, %pair_valid_55) : (i1, i1) -> i1
    %pair_rhs_nz_56 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_56 = "transfer.select"(%pair_rhs_nz_56, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_56 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_56 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_56 = "arith.andi"(%pair_lhs_eq_smin_56, %pair_rhs_eq_m1_56) : (i1, i1) -> i1
    %pair_not_ub_56 = "arith.xori"(%pair_ub_56, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_56 = "arith.andi"(%pair_rhs_nz_56, %pair_not_ub_56) : (i1, i1) -> i1
    %pair_val_56 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_56 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_56 = "transfer.cmp"(%pair_rem_56, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_56 = "arith.andi"(%pair_valid_sdiv_56, %pair_exact_56) : (i1, i1) -> i1
    %pair_val0_56 = "transfer.xor"(%pair_val_56, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_56 = "transfer.select"(%pair_valid_56, %pair_val0_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_56 = "transfer.select"(%pair_valid_56, %pair_val_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_56 = "transfer.and"(%pair_acc0_55, %pair_sel0_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_56 = "transfer.and"(%pair_acc1_55, %pair_sel1_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_56 = "arith.ori"(%pair_any_55, %pair_valid_56) : (i1, i1) -> i1
    %pair_rhs_nz_57 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_57 = "transfer.select"(%pair_rhs_nz_57, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_57 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_57 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_57 = "arith.andi"(%pair_lhs_eq_smin_57, %pair_rhs_eq_m1_57) : (i1, i1) -> i1
    %pair_not_ub_57 = "arith.xori"(%pair_ub_57, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_57 = "arith.andi"(%pair_rhs_nz_57, %pair_not_ub_57) : (i1, i1) -> i1
    %pair_val_57 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_57 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_57 = "transfer.cmp"(%pair_rem_57, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_57 = "arith.andi"(%pair_valid_sdiv_57, %pair_exact_57) : (i1, i1) -> i1
    %pair_val0_57 = "transfer.xor"(%pair_val_57, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_57 = "transfer.select"(%pair_valid_57, %pair_val0_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_57 = "transfer.select"(%pair_valid_57, %pair_val_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_57 = "transfer.and"(%pair_acc0_56, %pair_sel0_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_57 = "transfer.and"(%pair_acc1_56, %pair_sel1_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_57 = "arith.ori"(%pair_any_56, %pair_valid_57) : (i1, i1) -> i1
    %pair_rhs_nz_58 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_58 = "transfer.select"(%pair_rhs_nz_58, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_58 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_58 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_58 = "arith.andi"(%pair_lhs_eq_smin_58, %pair_rhs_eq_m1_58) : (i1, i1) -> i1
    %pair_not_ub_58 = "arith.xori"(%pair_ub_58, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_58 = "arith.andi"(%pair_rhs_nz_58, %pair_not_ub_58) : (i1, i1) -> i1
    %pair_val_58 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_58 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_58 = "transfer.cmp"(%pair_rem_58, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_58 = "arith.andi"(%pair_valid_sdiv_58, %pair_exact_58) : (i1, i1) -> i1
    %pair_val0_58 = "transfer.xor"(%pair_val_58, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_58 = "transfer.select"(%pair_valid_58, %pair_val0_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_58 = "transfer.select"(%pair_valid_58, %pair_val_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_58 = "transfer.and"(%pair_acc0_57, %pair_sel0_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_58 = "transfer.and"(%pair_acc1_57, %pair_sel1_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_58 = "arith.ori"(%pair_any_57, %pair_valid_58) : (i1, i1) -> i1
    %pair_rhs_nz_59 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_59 = "transfer.select"(%pair_rhs_nz_59, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_59 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_59 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_59 = "arith.andi"(%pair_lhs_eq_smin_59, %pair_rhs_eq_m1_59) : (i1, i1) -> i1
    %pair_not_ub_59 = "arith.xori"(%pair_ub_59, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_59 = "arith.andi"(%pair_rhs_nz_59, %pair_not_ub_59) : (i1, i1) -> i1
    %pair_val_59 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_59 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_59 = "transfer.cmp"(%pair_rem_59, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_59 = "arith.andi"(%pair_valid_sdiv_59, %pair_exact_59) : (i1, i1) -> i1
    %pair_val0_59 = "transfer.xor"(%pair_val_59, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_59 = "transfer.select"(%pair_valid_59, %pair_val0_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_59 = "transfer.select"(%pair_valid_59, %pair_val_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_59 = "transfer.and"(%pair_acc0_58, %pair_sel0_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_59 = "transfer.and"(%pair_acc1_58, %pair_sel1_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_59 = "arith.ori"(%pair_any_58, %pair_valid_59) : (i1, i1) -> i1
    %pair_rhs_nz_60 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_60 = "transfer.select"(%pair_rhs_nz_60, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_60 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_60 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_60 = "arith.andi"(%pair_lhs_eq_smin_60, %pair_rhs_eq_m1_60) : (i1, i1) -> i1
    %pair_not_ub_60 = "arith.xori"(%pair_ub_60, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_60 = "arith.andi"(%pair_rhs_nz_60, %pair_not_ub_60) : (i1, i1) -> i1
    %pair_val_60 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_60 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_60 = "transfer.cmp"(%pair_rem_60, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_60 = "arith.andi"(%pair_valid_sdiv_60, %pair_exact_60) : (i1, i1) -> i1
    %pair_val0_60 = "transfer.xor"(%pair_val_60, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_60 = "transfer.select"(%pair_valid_60, %pair_val0_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_60 = "transfer.select"(%pair_valid_60, %pair_val_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_60 = "transfer.and"(%pair_acc0_59, %pair_sel0_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_60 = "transfer.and"(%pair_acc1_59, %pair_sel1_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_60 = "arith.ori"(%pair_any_59, %pair_valid_60) : (i1, i1) -> i1
    %pair_rhs_nz_61 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_61 = "transfer.select"(%pair_rhs_nz_61, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_61 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_61 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_61 = "arith.andi"(%pair_lhs_eq_smin_61, %pair_rhs_eq_m1_61) : (i1, i1) -> i1
    %pair_not_ub_61 = "arith.xori"(%pair_ub_61, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_61 = "arith.andi"(%pair_rhs_nz_61, %pair_not_ub_61) : (i1, i1) -> i1
    %pair_val_61 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_61 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_61 = "transfer.cmp"(%pair_rem_61, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_61 = "arith.andi"(%pair_valid_sdiv_61, %pair_exact_61) : (i1, i1) -> i1
    %pair_val0_61 = "transfer.xor"(%pair_val_61, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_61 = "transfer.select"(%pair_valid_61, %pair_val0_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_61 = "transfer.select"(%pair_valid_61, %pair_val_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_61 = "transfer.and"(%pair_acc0_60, %pair_sel0_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_61 = "transfer.and"(%pair_acc1_60, %pair_sel1_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_61 = "arith.ori"(%pair_any_60, %pair_valid_61) : (i1, i1) -> i1
    %pair_rhs_nz_62 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_62 = "transfer.select"(%pair_rhs_nz_62, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_62 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_62 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_62 = "arith.andi"(%pair_lhs_eq_smin_62, %pair_rhs_eq_m1_62) : (i1, i1) -> i1
    %pair_not_ub_62 = "arith.xori"(%pair_ub_62, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_62 = "arith.andi"(%pair_rhs_nz_62, %pair_not_ub_62) : (i1, i1) -> i1
    %pair_val_62 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_62 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_62 = "transfer.cmp"(%pair_rem_62, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_62 = "arith.andi"(%pair_valid_sdiv_62, %pair_exact_62) : (i1, i1) -> i1
    %pair_val0_62 = "transfer.xor"(%pair_val_62, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_62 = "transfer.select"(%pair_valid_62, %pair_val0_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_62 = "transfer.select"(%pair_valid_62, %pair_val_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_62 = "transfer.and"(%pair_acc0_61, %pair_sel0_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_62 = "transfer.and"(%pair_acc1_61, %pair_sel1_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_62 = "arith.ori"(%pair_any_61, %pair_valid_62) : (i1, i1) -> i1
    %pair_rhs_nz_63 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_63 = "transfer.select"(%pair_rhs_nz_63, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_63 = "transfer.cmp"(%lhsu_v3, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_63 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_63 = "arith.andi"(%pair_lhs_eq_smin_63, %pair_rhs_eq_m1_63) : (i1, i1) -> i1
    %pair_not_ub_63 = "arith.xori"(%pair_ub_63, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_63 = "arith.andi"(%pair_rhs_nz_63, %pair_not_ub_63) : (i1, i1) -> i1
    %pair_val_63 = "transfer.sdiv"(%lhsu_v3, %pair_rhs_safe_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_63 = "transfer.srem"(%lhsu_v3, %pair_rhs_safe_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_63 = "transfer.cmp"(%pair_rem_63, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_63 = "arith.andi"(%pair_valid_sdiv_63, %pair_exact_63) : (i1, i1) -> i1
    %pair_val0_63 = "transfer.xor"(%pair_val_63, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_63 = "transfer.select"(%pair_valid_63, %pair_val0_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_63 = "transfer.select"(%pair_valid_63, %pair_val_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_63 = "transfer.and"(%pair_acc0_62, %pair_sel0_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_63 = "transfer.and"(%pair_acc1_62, %pair_sel1_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_63 = "arith.ori"(%pair_any_62, %pair_valid_63) : (i1, i1) -> i1
    %pair_rhs_nz_64 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_64 = "transfer.select"(%pair_rhs_nz_64, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_64 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_64 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_64 = "arith.andi"(%pair_lhs_eq_smin_64, %pair_rhs_eq_m1_64) : (i1, i1) -> i1
    %pair_not_ub_64 = "arith.xori"(%pair_ub_64, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_64 = "arith.andi"(%pair_rhs_nz_64, %pair_not_ub_64) : (i1, i1) -> i1
    %pair_val_64 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_64 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_64 = "transfer.cmp"(%pair_rem_64, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_64 = "arith.andi"(%pair_valid_sdiv_64, %pair_exact_64) : (i1, i1) -> i1
    %pair_val0_64 = "transfer.xor"(%pair_val_64, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_64 = "transfer.select"(%pair_valid_64, %pair_val0_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_64 = "transfer.select"(%pair_valid_64, %pair_val_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_64 = "transfer.and"(%pair_acc0_63, %pair_sel0_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_64 = "transfer.and"(%pair_acc1_63, %pair_sel1_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_64 = "arith.ori"(%pair_any_63, %pair_valid_64) : (i1, i1) -> i1
    %pair_rhs_nz_65 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_65 = "transfer.select"(%pair_rhs_nz_65, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_65 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_65 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_65 = "arith.andi"(%pair_lhs_eq_smin_65, %pair_rhs_eq_m1_65) : (i1, i1) -> i1
    %pair_not_ub_65 = "arith.xori"(%pair_ub_65, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_65 = "arith.andi"(%pair_rhs_nz_65, %pair_not_ub_65) : (i1, i1) -> i1
    %pair_val_65 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_65 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_65 = "transfer.cmp"(%pair_rem_65, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_65 = "arith.andi"(%pair_valid_sdiv_65, %pair_exact_65) : (i1, i1) -> i1
    %pair_val0_65 = "transfer.xor"(%pair_val_65, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_65 = "transfer.select"(%pair_valid_65, %pair_val0_65, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_65 = "transfer.select"(%pair_valid_65, %pair_val_65, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_65 = "transfer.and"(%pair_acc0_64, %pair_sel0_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_65 = "transfer.and"(%pair_acc1_64, %pair_sel1_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_65 = "arith.ori"(%pair_any_64, %pair_valid_65) : (i1, i1) -> i1
    %pair_rhs_nz_66 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_66 = "transfer.select"(%pair_rhs_nz_66, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_66 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_66 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_66 = "arith.andi"(%pair_lhs_eq_smin_66, %pair_rhs_eq_m1_66) : (i1, i1) -> i1
    %pair_not_ub_66 = "arith.xori"(%pair_ub_66, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_66 = "arith.andi"(%pair_rhs_nz_66, %pair_not_ub_66) : (i1, i1) -> i1
    %pair_val_66 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_66 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_66 = "transfer.cmp"(%pair_rem_66, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_66 = "arith.andi"(%pair_valid_sdiv_66, %pair_exact_66) : (i1, i1) -> i1
    %pair_val0_66 = "transfer.xor"(%pair_val_66, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_66 = "transfer.select"(%pair_valid_66, %pair_val0_66, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_66 = "transfer.select"(%pair_valid_66, %pair_val_66, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_66 = "transfer.and"(%pair_acc0_65, %pair_sel0_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_66 = "transfer.and"(%pair_acc1_65, %pair_sel1_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_66 = "arith.ori"(%pair_any_65, %pair_valid_66) : (i1, i1) -> i1
    %pair_rhs_nz_67 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_67 = "transfer.select"(%pair_rhs_nz_67, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_67 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_67 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_67 = "arith.andi"(%pair_lhs_eq_smin_67, %pair_rhs_eq_m1_67) : (i1, i1) -> i1
    %pair_not_ub_67 = "arith.xori"(%pair_ub_67, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_67 = "arith.andi"(%pair_rhs_nz_67, %pair_not_ub_67) : (i1, i1) -> i1
    %pair_val_67 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_67 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_67 = "transfer.cmp"(%pair_rem_67, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_67 = "arith.andi"(%pair_valid_sdiv_67, %pair_exact_67) : (i1, i1) -> i1
    %pair_val0_67 = "transfer.xor"(%pair_val_67, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_67 = "transfer.select"(%pair_valid_67, %pair_val0_67, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_67 = "transfer.select"(%pair_valid_67, %pair_val_67, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_67 = "transfer.and"(%pair_acc0_66, %pair_sel0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_67 = "transfer.and"(%pair_acc1_66, %pair_sel1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_67 = "arith.ori"(%pair_any_66, %pair_valid_67) : (i1, i1) -> i1
    %pair_rhs_nz_68 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_68 = "transfer.select"(%pair_rhs_nz_68, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_68 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_68 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_68 = "arith.andi"(%pair_lhs_eq_smin_68, %pair_rhs_eq_m1_68) : (i1, i1) -> i1
    %pair_not_ub_68 = "arith.xori"(%pair_ub_68, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_68 = "arith.andi"(%pair_rhs_nz_68, %pair_not_ub_68) : (i1, i1) -> i1
    %pair_val_68 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_68 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_68 = "transfer.cmp"(%pair_rem_68, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_68 = "arith.andi"(%pair_valid_sdiv_68, %pair_exact_68) : (i1, i1) -> i1
    %pair_val0_68 = "transfer.xor"(%pair_val_68, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_68 = "transfer.select"(%pair_valid_68, %pair_val0_68, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_68 = "transfer.select"(%pair_valid_68, %pair_val_68, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_68 = "transfer.and"(%pair_acc0_67, %pair_sel0_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_68 = "transfer.and"(%pair_acc1_67, %pair_sel1_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_68 = "arith.ori"(%pair_any_67, %pair_valid_68) : (i1, i1) -> i1
    %pair_rhs_nz_69 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_69 = "transfer.select"(%pair_rhs_nz_69, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_69 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_69 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_69 = "arith.andi"(%pair_lhs_eq_smin_69, %pair_rhs_eq_m1_69) : (i1, i1) -> i1
    %pair_not_ub_69 = "arith.xori"(%pair_ub_69, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_69 = "arith.andi"(%pair_rhs_nz_69, %pair_not_ub_69) : (i1, i1) -> i1
    %pair_val_69 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_69 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_69 = "transfer.cmp"(%pair_rem_69, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_69 = "arith.andi"(%pair_valid_sdiv_69, %pair_exact_69) : (i1, i1) -> i1
    %pair_val0_69 = "transfer.xor"(%pair_val_69, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_69 = "transfer.select"(%pair_valid_69, %pair_val0_69, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_69 = "transfer.select"(%pair_valid_69, %pair_val_69, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_69 = "transfer.and"(%pair_acc0_68, %pair_sel0_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_69 = "transfer.and"(%pair_acc1_68, %pair_sel1_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_69 = "arith.ori"(%pair_any_68, %pair_valid_69) : (i1, i1) -> i1
    %pair_rhs_nz_70 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_70 = "transfer.select"(%pair_rhs_nz_70, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_70 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_70 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_70 = "arith.andi"(%pair_lhs_eq_smin_70, %pair_rhs_eq_m1_70) : (i1, i1) -> i1
    %pair_not_ub_70 = "arith.xori"(%pair_ub_70, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_70 = "arith.andi"(%pair_rhs_nz_70, %pair_not_ub_70) : (i1, i1) -> i1
    %pair_val_70 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_70 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_70 = "transfer.cmp"(%pair_rem_70, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_70 = "arith.andi"(%pair_valid_sdiv_70, %pair_exact_70) : (i1, i1) -> i1
    %pair_val0_70 = "transfer.xor"(%pair_val_70, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_70 = "transfer.select"(%pair_valid_70, %pair_val0_70, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_70 = "transfer.select"(%pair_valid_70, %pair_val_70, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_70 = "transfer.and"(%pair_acc0_69, %pair_sel0_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_70 = "transfer.and"(%pair_acc1_69, %pair_sel1_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_70 = "arith.ori"(%pair_any_69, %pair_valid_70) : (i1, i1) -> i1
    %pair_rhs_nz_71 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_71 = "transfer.select"(%pair_rhs_nz_71, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_71 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_71 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_71 = "arith.andi"(%pair_lhs_eq_smin_71, %pair_rhs_eq_m1_71) : (i1, i1) -> i1
    %pair_not_ub_71 = "arith.xori"(%pair_ub_71, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_71 = "arith.andi"(%pair_rhs_nz_71, %pair_not_ub_71) : (i1, i1) -> i1
    %pair_val_71 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_71 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_71 = "transfer.cmp"(%pair_rem_71, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_71 = "arith.andi"(%pair_valid_sdiv_71, %pair_exact_71) : (i1, i1) -> i1
    %pair_val0_71 = "transfer.xor"(%pair_val_71, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_71 = "transfer.select"(%pair_valid_71, %pair_val0_71, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_71 = "transfer.select"(%pair_valid_71, %pair_val_71, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_71 = "transfer.and"(%pair_acc0_70, %pair_sel0_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_71 = "transfer.and"(%pair_acc1_70, %pair_sel1_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_71 = "arith.ori"(%pair_any_70, %pair_valid_71) : (i1, i1) -> i1
    %pair_rhs_nz_72 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_72 = "transfer.select"(%pair_rhs_nz_72, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_72 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_72 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_72 = "arith.andi"(%pair_lhs_eq_smin_72, %pair_rhs_eq_m1_72) : (i1, i1) -> i1
    %pair_not_ub_72 = "arith.xori"(%pair_ub_72, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_72 = "arith.andi"(%pair_rhs_nz_72, %pair_not_ub_72) : (i1, i1) -> i1
    %pair_val_72 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_72 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_72 = "transfer.cmp"(%pair_rem_72, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_72 = "arith.andi"(%pair_valid_sdiv_72, %pair_exact_72) : (i1, i1) -> i1
    %pair_val0_72 = "transfer.xor"(%pair_val_72, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_72 = "transfer.select"(%pair_valid_72, %pair_val0_72, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_72 = "transfer.select"(%pair_valid_72, %pair_val_72, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_72 = "transfer.and"(%pair_acc0_71, %pair_sel0_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_72 = "transfer.and"(%pair_acc1_71, %pair_sel1_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_72 = "arith.ori"(%pair_any_71, %pair_valid_72) : (i1, i1) -> i1
    %pair_rhs_nz_73 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_73 = "transfer.select"(%pair_rhs_nz_73, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_73 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_73 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_73 = "arith.andi"(%pair_lhs_eq_smin_73, %pair_rhs_eq_m1_73) : (i1, i1) -> i1
    %pair_not_ub_73 = "arith.xori"(%pair_ub_73, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_73 = "arith.andi"(%pair_rhs_nz_73, %pair_not_ub_73) : (i1, i1) -> i1
    %pair_val_73 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_73 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_73 = "transfer.cmp"(%pair_rem_73, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_73 = "arith.andi"(%pair_valid_sdiv_73, %pair_exact_73) : (i1, i1) -> i1
    %pair_val0_73 = "transfer.xor"(%pair_val_73, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_73 = "transfer.select"(%pair_valid_73, %pair_val0_73, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_73 = "transfer.select"(%pair_valid_73, %pair_val_73, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_73 = "transfer.and"(%pair_acc0_72, %pair_sel0_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_73 = "transfer.and"(%pair_acc1_72, %pair_sel1_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_73 = "arith.ori"(%pair_any_72, %pair_valid_73) : (i1, i1) -> i1
    %pair_rhs_nz_74 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_74 = "transfer.select"(%pair_rhs_nz_74, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_74 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_74 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_74 = "arith.andi"(%pair_lhs_eq_smin_74, %pair_rhs_eq_m1_74) : (i1, i1) -> i1
    %pair_not_ub_74 = "arith.xori"(%pair_ub_74, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_74 = "arith.andi"(%pair_rhs_nz_74, %pair_not_ub_74) : (i1, i1) -> i1
    %pair_val_74 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_74 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_74 = "transfer.cmp"(%pair_rem_74, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_74 = "arith.andi"(%pair_valid_sdiv_74, %pair_exact_74) : (i1, i1) -> i1
    %pair_val0_74 = "transfer.xor"(%pair_val_74, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_74 = "transfer.select"(%pair_valid_74, %pair_val0_74, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_74 = "transfer.select"(%pair_valid_74, %pair_val_74, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_74 = "transfer.and"(%pair_acc0_73, %pair_sel0_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_74 = "transfer.and"(%pair_acc1_73, %pair_sel1_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_74 = "arith.ori"(%pair_any_73, %pair_valid_74) : (i1, i1) -> i1
    %pair_rhs_nz_75 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_75 = "transfer.select"(%pair_rhs_nz_75, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_75 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_75 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_75 = "arith.andi"(%pair_lhs_eq_smin_75, %pair_rhs_eq_m1_75) : (i1, i1) -> i1
    %pair_not_ub_75 = "arith.xori"(%pair_ub_75, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_75 = "arith.andi"(%pair_rhs_nz_75, %pair_not_ub_75) : (i1, i1) -> i1
    %pair_val_75 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_75 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_75 = "transfer.cmp"(%pair_rem_75, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_75 = "arith.andi"(%pair_valid_sdiv_75, %pair_exact_75) : (i1, i1) -> i1
    %pair_val0_75 = "transfer.xor"(%pair_val_75, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_75 = "transfer.select"(%pair_valid_75, %pair_val0_75, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_75 = "transfer.select"(%pair_valid_75, %pair_val_75, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_75 = "transfer.and"(%pair_acc0_74, %pair_sel0_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_75 = "transfer.and"(%pair_acc1_74, %pair_sel1_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_75 = "arith.ori"(%pair_any_74, %pair_valid_75) : (i1, i1) -> i1
    %pair_rhs_nz_76 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_76 = "transfer.select"(%pair_rhs_nz_76, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_76 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_76 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_76 = "arith.andi"(%pair_lhs_eq_smin_76, %pair_rhs_eq_m1_76) : (i1, i1) -> i1
    %pair_not_ub_76 = "arith.xori"(%pair_ub_76, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_76 = "arith.andi"(%pair_rhs_nz_76, %pair_not_ub_76) : (i1, i1) -> i1
    %pair_val_76 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_76 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_76 = "transfer.cmp"(%pair_rem_76, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_76 = "arith.andi"(%pair_valid_sdiv_76, %pair_exact_76) : (i1, i1) -> i1
    %pair_val0_76 = "transfer.xor"(%pair_val_76, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_76 = "transfer.select"(%pair_valid_76, %pair_val0_76, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_76 = "transfer.select"(%pair_valid_76, %pair_val_76, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_76 = "transfer.and"(%pair_acc0_75, %pair_sel0_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_76 = "transfer.and"(%pair_acc1_75, %pair_sel1_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_76 = "arith.ori"(%pair_any_75, %pair_valid_76) : (i1, i1) -> i1
    %pair_rhs_nz_77 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_77 = "transfer.select"(%pair_rhs_nz_77, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_77 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_77 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_77 = "arith.andi"(%pair_lhs_eq_smin_77, %pair_rhs_eq_m1_77) : (i1, i1) -> i1
    %pair_not_ub_77 = "arith.xori"(%pair_ub_77, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_77 = "arith.andi"(%pair_rhs_nz_77, %pair_not_ub_77) : (i1, i1) -> i1
    %pair_val_77 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_77 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_77 = "transfer.cmp"(%pair_rem_77, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_77 = "arith.andi"(%pair_valid_sdiv_77, %pair_exact_77) : (i1, i1) -> i1
    %pair_val0_77 = "transfer.xor"(%pair_val_77, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_77 = "transfer.select"(%pair_valid_77, %pair_val0_77, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_77 = "transfer.select"(%pair_valid_77, %pair_val_77, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_77 = "transfer.and"(%pair_acc0_76, %pair_sel0_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_77 = "transfer.and"(%pair_acc1_76, %pair_sel1_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_77 = "arith.ori"(%pair_any_76, %pair_valid_77) : (i1, i1) -> i1
    %pair_rhs_nz_78 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_78 = "transfer.select"(%pair_rhs_nz_78, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_78 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_78 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_78 = "arith.andi"(%pair_lhs_eq_smin_78, %pair_rhs_eq_m1_78) : (i1, i1) -> i1
    %pair_not_ub_78 = "arith.xori"(%pair_ub_78, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_78 = "arith.andi"(%pair_rhs_nz_78, %pair_not_ub_78) : (i1, i1) -> i1
    %pair_val_78 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_78 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_78 = "transfer.cmp"(%pair_rem_78, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_78 = "arith.andi"(%pair_valid_sdiv_78, %pair_exact_78) : (i1, i1) -> i1
    %pair_val0_78 = "transfer.xor"(%pair_val_78, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_78 = "transfer.select"(%pair_valid_78, %pair_val0_78, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_78 = "transfer.select"(%pair_valid_78, %pair_val_78, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_78 = "transfer.and"(%pair_acc0_77, %pair_sel0_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_78 = "transfer.and"(%pair_acc1_77, %pair_sel1_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_78 = "arith.ori"(%pair_any_77, %pair_valid_78) : (i1, i1) -> i1
    %pair_rhs_nz_79 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_79 = "transfer.select"(%pair_rhs_nz_79, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_79 = "transfer.cmp"(%lhsu_v4, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_79 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_79 = "arith.andi"(%pair_lhs_eq_smin_79, %pair_rhs_eq_m1_79) : (i1, i1) -> i1
    %pair_not_ub_79 = "arith.xori"(%pair_ub_79, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_79 = "arith.andi"(%pair_rhs_nz_79, %pair_not_ub_79) : (i1, i1) -> i1
    %pair_val_79 = "transfer.sdiv"(%lhsu_v4, %pair_rhs_safe_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_79 = "transfer.srem"(%lhsu_v4, %pair_rhs_safe_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_79 = "transfer.cmp"(%pair_rem_79, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_79 = "arith.andi"(%pair_valid_sdiv_79, %pair_exact_79) : (i1, i1) -> i1
    %pair_val0_79 = "transfer.xor"(%pair_val_79, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_79 = "transfer.select"(%pair_valid_79, %pair_val0_79, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_79 = "transfer.select"(%pair_valid_79, %pair_val_79, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_79 = "transfer.and"(%pair_acc0_78, %pair_sel0_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_79 = "transfer.and"(%pair_acc1_78, %pair_sel1_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_79 = "arith.ori"(%pair_any_78, %pair_valid_79) : (i1, i1) -> i1
    %pair_rhs_nz_80 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_80 = "transfer.select"(%pair_rhs_nz_80, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_80 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_80 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_80 = "arith.andi"(%pair_lhs_eq_smin_80, %pair_rhs_eq_m1_80) : (i1, i1) -> i1
    %pair_not_ub_80 = "arith.xori"(%pair_ub_80, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_80 = "arith.andi"(%pair_rhs_nz_80, %pair_not_ub_80) : (i1, i1) -> i1
    %pair_val_80 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_80 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_80 = "transfer.cmp"(%pair_rem_80, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_80 = "arith.andi"(%pair_valid_sdiv_80, %pair_exact_80) : (i1, i1) -> i1
    %pair_val0_80 = "transfer.xor"(%pair_val_80, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_80 = "transfer.select"(%pair_valid_80, %pair_val0_80, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_80 = "transfer.select"(%pair_valid_80, %pair_val_80, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_80 = "transfer.and"(%pair_acc0_79, %pair_sel0_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_80 = "transfer.and"(%pair_acc1_79, %pair_sel1_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_80 = "arith.ori"(%pair_any_79, %pair_valid_80) : (i1, i1) -> i1
    %pair_rhs_nz_81 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_81 = "transfer.select"(%pair_rhs_nz_81, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_81 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_81 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_81 = "arith.andi"(%pair_lhs_eq_smin_81, %pair_rhs_eq_m1_81) : (i1, i1) -> i1
    %pair_not_ub_81 = "arith.xori"(%pair_ub_81, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_81 = "arith.andi"(%pair_rhs_nz_81, %pair_not_ub_81) : (i1, i1) -> i1
    %pair_val_81 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_81 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_81 = "transfer.cmp"(%pair_rem_81, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_81 = "arith.andi"(%pair_valid_sdiv_81, %pair_exact_81) : (i1, i1) -> i1
    %pair_val0_81 = "transfer.xor"(%pair_val_81, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_81 = "transfer.select"(%pair_valid_81, %pair_val0_81, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_81 = "transfer.select"(%pair_valid_81, %pair_val_81, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_81 = "transfer.and"(%pair_acc0_80, %pair_sel0_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_81 = "transfer.and"(%pair_acc1_80, %pair_sel1_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_81 = "arith.ori"(%pair_any_80, %pair_valid_81) : (i1, i1) -> i1
    %pair_rhs_nz_82 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_82 = "transfer.select"(%pair_rhs_nz_82, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_82 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_82 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_82 = "arith.andi"(%pair_lhs_eq_smin_82, %pair_rhs_eq_m1_82) : (i1, i1) -> i1
    %pair_not_ub_82 = "arith.xori"(%pair_ub_82, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_82 = "arith.andi"(%pair_rhs_nz_82, %pair_not_ub_82) : (i1, i1) -> i1
    %pair_val_82 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_82 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_82 = "transfer.cmp"(%pair_rem_82, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_82 = "arith.andi"(%pair_valid_sdiv_82, %pair_exact_82) : (i1, i1) -> i1
    %pair_val0_82 = "transfer.xor"(%pair_val_82, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_82 = "transfer.select"(%pair_valid_82, %pair_val0_82, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_82 = "transfer.select"(%pair_valid_82, %pair_val_82, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_82 = "transfer.and"(%pair_acc0_81, %pair_sel0_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_82 = "transfer.and"(%pair_acc1_81, %pair_sel1_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_82 = "arith.ori"(%pair_any_81, %pair_valid_82) : (i1, i1) -> i1
    %pair_rhs_nz_83 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_83 = "transfer.select"(%pair_rhs_nz_83, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_83 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_83 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_83 = "arith.andi"(%pair_lhs_eq_smin_83, %pair_rhs_eq_m1_83) : (i1, i1) -> i1
    %pair_not_ub_83 = "arith.xori"(%pair_ub_83, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_83 = "arith.andi"(%pair_rhs_nz_83, %pair_not_ub_83) : (i1, i1) -> i1
    %pair_val_83 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_83 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_83 = "transfer.cmp"(%pair_rem_83, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_83 = "arith.andi"(%pair_valid_sdiv_83, %pair_exact_83) : (i1, i1) -> i1
    %pair_val0_83 = "transfer.xor"(%pair_val_83, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_83 = "transfer.select"(%pair_valid_83, %pair_val0_83, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_83 = "transfer.select"(%pair_valid_83, %pair_val_83, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_83 = "transfer.and"(%pair_acc0_82, %pair_sel0_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_83 = "transfer.and"(%pair_acc1_82, %pair_sel1_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_83 = "arith.ori"(%pair_any_82, %pair_valid_83) : (i1, i1) -> i1
    %pair_rhs_nz_84 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_84 = "transfer.select"(%pair_rhs_nz_84, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_84 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_84 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_84 = "arith.andi"(%pair_lhs_eq_smin_84, %pair_rhs_eq_m1_84) : (i1, i1) -> i1
    %pair_not_ub_84 = "arith.xori"(%pair_ub_84, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_84 = "arith.andi"(%pair_rhs_nz_84, %pair_not_ub_84) : (i1, i1) -> i1
    %pair_val_84 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_84 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_84 = "transfer.cmp"(%pair_rem_84, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_84 = "arith.andi"(%pair_valid_sdiv_84, %pair_exact_84) : (i1, i1) -> i1
    %pair_val0_84 = "transfer.xor"(%pair_val_84, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_84 = "transfer.select"(%pair_valid_84, %pair_val0_84, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_84 = "transfer.select"(%pair_valid_84, %pair_val_84, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_84 = "transfer.and"(%pair_acc0_83, %pair_sel0_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_84 = "transfer.and"(%pair_acc1_83, %pair_sel1_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_84 = "arith.ori"(%pair_any_83, %pair_valid_84) : (i1, i1) -> i1
    %pair_rhs_nz_85 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_85 = "transfer.select"(%pair_rhs_nz_85, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_85 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_85 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_85 = "arith.andi"(%pair_lhs_eq_smin_85, %pair_rhs_eq_m1_85) : (i1, i1) -> i1
    %pair_not_ub_85 = "arith.xori"(%pair_ub_85, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_85 = "arith.andi"(%pair_rhs_nz_85, %pair_not_ub_85) : (i1, i1) -> i1
    %pair_val_85 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_85 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_85 = "transfer.cmp"(%pair_rem_85, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_85 = "arith.andi"(%pair_valid_sdiv_85, %pair_exact_85) : (i1, i1) -> i1
    %pair_val0_85 = "transfer.xor"(%pair_val_85, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_85 = "transfer.select"(%pair_valid_85, %pair_val0_85, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_85 = "transfer.select"(%pair_valid_85, %pair_val_85, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_85 = "transfer.and"(%pair_acc0_84, %pair_sel0_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_85 = "transfer.and"(%pair_acc1_84, %pair_sel1_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_85 = "arith.ori"(%pair_any_84, %pair_valid_85) : (i1, i1) -> i1
    %pair_rhs_nz_86 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_86 = "transfer.select"(%pair_rhs_nz_86, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_86 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_86 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_86 = "arith.andi"(%pair_lhs_eq_smin_86, %pair_rhs_eq_m1_86) : (i1, i1) -> i1
    %pair_not_ub_86 = "arith.xori"(%pair_ub_86, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_86 = "arith.andi"(%pair_rhs_nz_86, %pair_not_ub_86) : (i1, i1) -> i1
    %pair_val_86 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_86 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_86 = "transfer.cmp"(%pair_rem_86, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_86 = "arith.andi"(%pair_valid_sdiv_86, %pair_exact_86) : (i1, i1) -> i1
    %pair_val0_86 = "transfer.xor"(%pair_val_86, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_86 = "transfer.select"(%pair_valid_86, %pair_val0_86, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_86 = "transfer.select"(%pair_valid_86, %pair_val_86, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_86 = "transfer.and"(%pair_acc0_85, %pair_sel0_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_86 = "transfer.and"(%pair_acc1_85, %pair_sel1_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_86 = "arith.ori"(%pair_any_85, %pair_valid_86) : (i1, i1) -> i1
    %pair_rhs_nz_87 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_87 = "transfer.select"(%pair_rhs_nz_87, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_87 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_87 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_87 = "arith.andi"(%pair_lhs_eq_smin_87, %pair_rhs_eq_m1_87) : (i1, i1) -> i1
    %pair_not_ub_87 = "arith.xori"(%pair_ub_87, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_87 = "arith.andi"(%pair_rhs_nz_87, %pair_not_ub_87) : (i1, i1) -> i1
    %pair_val_87 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_87 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_87 = "transfer.cmp"(%pair_rem_87, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_87 = "arith.andi"(%pair_valid_sdiv_87, %pair_exact_87) : (i1, i1) -> i1
    %pair_val0_87 = "transfer.xor"(%pair_val_87, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_87 = "transfer.select"(%pair_valid_87, %pair_val0_87, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_87 = "transfer.select"(%pair_valid_87, %pair_val_87, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_87 = "transfer.and"(%pair_acc0_86, %pair_sel0_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_87 = "transfer.and"(%pair_acc1_86, %pair_sel1_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_87 = "arith.ori"(%pair_any_86, %pair_valid_87) : (i1, i1) -> i1
    %pair_rhs_nz_88 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_88 = "transfer.select"(%pair_rhs_nz_88, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_88 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_88 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_88 = "arith.andi"(%pair_lhs_eq_smin_88, %pair_rhs_eq_m1_88) : (i1, i1) -> i1
    %pair_not_ub_88 = "arith.xori"(%pair_ub_88, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_88 = "arith.andi"(%pair_rhs_nz_88, %pair_not_ub_88) : (i1, i1) -> i1
    %pair_val_88 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_88 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_88 = "transfer.cmp"(%pair_rem_88, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_88 = "arith.andi"(%pair_valid_sdiv_88, %pair_exact_88) : (i1, i1) -> i1
    %pair_val0_88 = "transfer.xor"(%pair_val_88, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_88 = "transfer.select"(%pair_valid_88, %pair_val0_88, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_88 = "transfer.select"(%pair_valid_88, %pair_val_88, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_88 = "transfer.and"(%pair_acc0_87, %pair_sel0_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_88 = "transfer.and"(%pair_acc1_87, %pair_sel1_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_88 = "arith.ori"(%pair_any_87, %pair_valid_88) : (i1, i1) -> i1
    %pair_rhs_nz_89 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_89 = "transfer.select"(%pair_rhs_nz_89, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_89 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_89 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_89 = "arith.andi"(%pair_lhs_eq_smin_89, %pair_rhs_eq_m1_89) : (i1, i1) -> i1
    %pair_not_ub_89 = "arith.xori"(%pair_ub_89, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_89 = "arith.andi"(%pair_rhs_nz_89, %pair_not_ub_89) : (i1, i1) -> i1
    %pair_val_89 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_89 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_89 = "transfer.cmp"(%pair_rem_89, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_89 = "arith.andi"(%pair_valid_sdiv_89, %pair_exact_89) : (i1, i1) -> i1
    %pair_val0_89 = "transfer.xor"(%pair_val_89, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_89 = "transfer.select"(%pair_valid_89, %pair_val0_89, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_89 = "transfer.select"(%pair_valid_89, %pair_val_89, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_89 = "transfer.and"(%pair_acc0_88, %pair_sel0_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_89 = "transfer.and"(%pair_acc1_88, %pair_sel1_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_89 = "arith.ori"(%pair_any_88, %pair_valid_89) : (i1, i1) -> i1
    %pair_rhs_nz_90 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_90 = "transfer.select"(%pair_rhs_nz_90, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_90 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_90 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_90 = "arith.andi"(%pair_lhs_eq_smin_90, %pair_rhs_eq_m1_90) : (i1, i1) -> i1
    %pair_not_ub_90 = "arith.xori"(%pair_ub_90, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_90 = "arith.andi"(%pair_rhs_nz_90, %pair_not_ub_90) : (i1, i1) -> i1
    %pair_val_90 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_90 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_90 = "transfer.cmp"(%pair_rem_90, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_90 = "arith.andi"(%pair_valid_sdiv_90, %pair_exact_90) : (i1, i1) -> i1
    %pair_val0_90 = "transfer.xor"(%pair_val_90, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_90 = "transfer.select"(%pair_valid_90, %pair_val0_90, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_90 = "transfer.select"(%pair_valid_90, %pair_val_90, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_90 = "transfer.and"(%pair_acc0_89, %pair_sel0_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_90 = "transfer.and"(%pair_acc1_89, %pair_sel1_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_90 = "arith.ori"(%pair_any_89, %pair_valid_90) : (i1, i1) -> i1
    %pair_rhs_nz_91 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_91 = "transfer.select"(%pair_rhs_nz_91, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_91 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_91 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_91 = "arith.andi"(%pair_lhs_eq_smin_91, %pair_rhs_eq_m1_91) : (i1, i1) -> i1
    %pair_not_ub_91 = "arith.xori"(%pair_ub_91, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_91 = "arith.andi"(%pair_rhs_nz_91, %pair_not_ub_91) : (i1, i1) -> i1
    %pair_val_91 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_91 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_91 = "transfer.cmp"(%pair_rem_91, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_91 = "arith.andi"(%pair_valid_sdiv_91, %pair_exact_91) : (i1, i1) -> i1
    %pair_val0_91 = "transfer.xor"(%pair_val_91, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_91 = "transfer.select"(%pair_valid_91, %pair_val0_91, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_91 = "transfer.select"(%pair_valid_91, %pair_val_91, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_91 = "transfer.and"(%pair_acc0_90, %pair_sel0_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_91 = "transfer.and"(%pair_acc1_90, %pair_sel1_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_91 = "arith.ori"(%pair_any_90, %pair_valid_91) : (i1, i1) -> i1
    %pair_rhs_nz_92 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_92 = "transfer.select"(%pair_rhs_nz_92, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_92 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_92 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_92 = "arith.andi"(%pair_lhs_eq_smin_92, %pair_rhs_eq_m1_92) : (i1, i1) -> i1
    %pair_not_ub_92 = "arith.xori"(%pair_ub_92, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_92 = "arith.andi"(%pair_rhs_nz_92, %pair_not_ub_92) : (i1, i1) -> i1
    %pair_val_92 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_92 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_92 = "transfer.cmp"(%pair_rem_92, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_92 = "arith.andi"(%pair_valid_sdiv_92, %pair_exact_92) : (i1, i1) -> i1
    %pair_val0_92 = "transfer.xor"(%pair_val_92, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_92 = "transfer.select"(%pair_valid_92, %pair_val0_92, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_92 = "transfer.select"(%pair_valid_92, %pair_val_92, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_92 = "transfer.and"(%pair_acc0_91, %pair_sel0_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_92 = "transfer.and"(%pair_acc1_91, %pair_sel1_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_92 = "arith.ori"(%pair_any_91, %pair_valid_92) : (i1, i1) -> i1
    %pair_rhs_nz_93 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_93 = "transfer.select"(%pair_rhs_nz_93, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_93 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_93 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_93 = "arith.andi"(%pair_lhs_eq_smin_93, %pair_rhs_eq_m1_93) : (i1, i1) -> i1
    %pair_not_ub_93 = "arith.xori"(%pair_ub_93, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_93 = "arith.andi"(%pair_rhs_nz_93, %pair_not_ub_93) : (i1, i1) -> i1
    %pair_val_93 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_93 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_93 = "transfer.cmp"(%pair_rem_93, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_93 = "arith.andi"(%pair_valid_sdiv_93, %pair_exact_93) : (i1, i1) -> i1
    %pair_val0_93 = "transfer.xor"(%pair_val_93, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_93 = "transfer.select"(%pair_valid_93, %pair_val0_93, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_93 = "transfer.select"(%pair_valid_93, %pair_val_93, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_93 = "transfer.and"(%pair_acc0_92, %pair_sel0_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_93 = "transfer.and"(%pair_acc1_92, %pair_sel1_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_93 = "arith.ori"(%pair_any_92, %pair_valid_93) : (i1, i1) -> i1
    %pair_rhs_nz_94 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_94 = "transfer.select"(%pair_rhs_nz_94, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_94 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_94 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_94 = "arith.andi"(%pair_lhs_eq_smin_94, %pair_rhs_eq_m1_94) : (i1, i1) -> i1
    %pair_not_ub_94 = "arith.xori"(%pair_ub_94, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_94 = "arith.andi"(%pair_rhs_nz_94, %pair_not_ub_94) : (i1, i1) -> i1
    %pair_val_94 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_94 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_94 = "transfer.cmp"(%pair_rem_94, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_94 = "arith.andi"(%pair_valid_sdiv_94, %pair_exact_94) : (i1, i1) -> i1
    %pair_val0_94 = "transfer.xor"(%pair_val_94, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_94 = "transfer.select"(%pair_valid_94, %pair_val0_94, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_94 = "transfer.select"(%pair_valid_94, %pair_val_94, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_94 = "transfer.and"(%pair_acc0_93, %pair_sel0_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_94 = "transfer.and"(%pair_acc1_93, %pair_sel1_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_94 = "arith.ori"(%pair_any_93, %pair_valid_94) : (i1, i1) -> i1
    %pair_rhs_nz_95 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_95 = "transfer.select"(%pair_rhs_nz_95, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_95 = "transfer.cmp"(%lhsu_v5, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_95 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_95 = "arith.andi"(%pair_lhs_eq_smin_95, %pair_rhs_eq_m1_95) : (i1, i1) -> i1
    %pair_not_ub_95 = "arith.xori"(%pair_ub_95, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_95 = "arith.andi"(%pair_rhs_nz_95, %pair_not_ub_95) : (i1, i1) -> i1
    %pair_val_95 = "transfer.sdiv"(%lhsu_v5, %pair_rhs_safe_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_95 = "transfer.srem"(%lhsu_v5, %pair_rhs_safe_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_95 = "transfer.cmp"(%pair_rem_95, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_95 = "arith.andi"(%pair_valid_sdiv_95, %pair_exact_95) : (i1, i1) -> i1
    %pair_val0_95 = "transfer.xor"(%pair_val_95, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_95 = "transfer.select"(%pair_valid_95, %pair_val0_95, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_95 = "transfer.select"(%pair_valid_95, %pair_val_95, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_95 = "transfer.and"(%pair_acc0_94, %pair_sel0_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_95 = "transfer.and"(%pair_acc1_94, %pair_sel1_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_95 = "arith.ori"(%pair_any_94, %pair_valid_95) : (i1, i1) -> i1
    %pair_rhs_nz_96 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_96 = "transfer.select"(%pair_rhs_nz_96, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_96 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_96 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_96 = "arith.andi"(%pair_lhs_eq_smin_96, %pair_rhs_eq_m1_96) : (i1, i1) -> i1
    %pair_not_ub_96 = "arith.xori"(%pair_ub_96, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_96 = "arith.andi"(%pair_rhs_nz_96, %pair_not_ub_96) : (i1, i1) -> i1
    %pair_val_96 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_96 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_96 = "transfer.cmp"(%pair_rem_96, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_96 = "arith.andi"(%pair_valid_sdiv_96, %pair_exact_96) : (i1, i1) -> i1
    %pair_val0_96 = "transfer.xor"(%pair_val_96, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_96 = "transfer.select"(%pair_valid_96, %pair_val0_96, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_96 = "transfer.select"(%pair_valid_96, %pair_val_96, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_96 = "transfer.and"(%pair_acc0_95, %pair_sel0_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_96 = "transfer.and"(%pair_acc1_95, %pair_sel1_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_96 = "arith.ori"(%pair_any_95, %pair_valid_96) : (i1, i1) -> i1
    %pair_rhs_nz_97 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_97 = "transfer.select"(%pair_rhs_nz_97, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_97 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_97 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_97 = "arith.andi"(%pair_lhs_eq_smin_97, %pair_rhs_eq_m1_97) : (i1, i1) -> i1
    %pair_not_ub_97 = "arith.xori"(%pair_ub_97, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_97 = "arith.andi"(%pair_rhs_nz_97, %pair_not_ub_97) : (i1, i1) -> i1
    %pair_val_97 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_97 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_97 = "transfer.cmp"(%pair_rem_97, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_97 = "arith.andi"(%pair_valid_sdiv_97, %pair_exact_97) : (i1, i1) -> i1
    %pair_val0_97 = "transfer.xor"(%pair_val_97, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_97 = "transfer.select"(%pair_valid_97, %pair_val0_97, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_97 = "transfer.select"(%pair_valid_97, %pair_val_97, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_97 = "transfer.and"(%pair_acc0_96, %pair_sel0_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_97 = "transfer.and"(%pair_acc1_96, %pair_sel1_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_97 = "arith.ori"(%pair_any_96, %pair_valid_97) : (i1, i1) -> i1
    %pair_rhs_nz_98 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_98 = "transfer.select"(%pair_rhs_nz_98, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_98 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_98 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_98 = "arith.andi"(%pair_lhs_eq_smin_98, %pair_rhs_eq_m1_98) : (i1, i1) -> i1
    %pair_not_ub_98 = "arith.xori"(%pair_ub_98, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_98 = "arith.andi"(%pair_rhs_nz_98, %pair_not_ub_98) : (i1, i1) -> i1
    %pair_val_98 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_98 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_98 = "transfer.cmp"(%pair_rem_98, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_98 = "arith.andi"(%pair_valid_sdiv_98, %pair_exact_98) : (i1, i1) -> i1
    %pair_val0_98 = "transfer.xor"(%pair_val_98, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_98 = "transfer.select"(%pair_valid_98, %pair_val0_98, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_98 = "transfer.select"(%pair_valid_98, %pair_val_98, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_98 = "transfer.and"(%pair_acc0_97, %pair_sel0_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_98 = "transfer.and"(%pair_acc1_97, %pair_sel1_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_98 = "arith.ori"(%pair_any_97, %pair_valid_98) : (i1, i1) -> i1
    %pair_rhs_nz_99 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_99 = "transfer.select"(%pair_rhs_nz_99, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_99 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_99 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_99 = "arith.andi"(%pair_lhs_eq_smin_99, %pair_rhs_eq_m1_99) : (i1, i1) -> i1
    %pair_not_ub_99 = "arith.xori"(%pair_ub_99, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_99 = "arith.andi"(%pair_rhs_nz_99, %pair_not_ub_99) : (i1, i1) -> i1
    %pair_val_99 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_99 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_99 = "transfer.cmp"(%pair_rem_99, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_99 = "arith.andi"(%pair_valid_sdiv_99, %pair_exact_99) : (i1, i1) -> i1
    %pair_val0_99 = "transfer.xor"(%pair_val_99, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_99 = "transfer.select"(%pair_valid_99, %pair_val0_99, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_99 = "transfer.select"(%pair_valid_99, %pair_val_99, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_99 = "transfer.and"(%pair_acc0_98, %pair_sel0_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_99 = "transfer.and"(%pair_acc1_98, %pair_sel1_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_99 = "arith.ori"(%pair_any_98, %pair_valid_99) : (i1, i1) -> i1
    %pair_rhs_nz_100 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_100 = "transfer.select"(%pair_rhs_nz_100, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_100 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_100 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_100 = "arith.andi"(%pair_lhs_eq_smin_100, %pair_rhs_eq_m1_100) : (i1, i1) -> i1
    %pair_not_ub_100 = "arith.xori"(%pair_ub_100, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_100 = "arith.andi"(%pair_rhs_nz_100, %pair_not_ub_100) : (i1, i1) -> i1
    %pair_val_100 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_100 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_100 = "transfer.cmp"(%pair_rem_100, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_100 = "arith.andi"(%pair_valid_sdiv_100, %pair_exact_100) : (i1, i1) -> i1
    %pair_val0_100 = "transfer.xor"(%pair_val_100, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_100 = "transfer.select"(%pair_valid_100, %pair_val0_100, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_100 = "transfer.select"(%pair_valid_100, %pair_val_100, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_100 = "transfer.and"(%pair_acc0_99, %pair_sel0_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_100 = "transfer.and"(%pair_acc1_99, %pair_sel1_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_100 = "arith.ori"(%pair_any_99, %pair_valid_100) : (i1, i1) -> i1
    %pair_rhs_nz_101 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_101 = "transfer.select"(%pair_rhs_nz_101, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_101 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_101 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_101 = "arith.andi"(%pair_lhs_eq_smin_101, %pair_rhs_eq_m1_101) : (i1, i1) -> i1
    %pair_not_ub_101 = "arith.xori"(%pair_ub_101, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_101 = "arith.andi"(%pair_rhs_nz_101, %pair_not_ub_101) : (i1, i1) -> i1
    %pair_val_101 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_101 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_101 = "transfer.cmp"(%pair_rem_101, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_101 = "arith.andi"(%pair_valid_sdiv_101, %pair_exact_101) : (i1, i1) -> i1
    %pair_val0_101 = "transfer.xor"(%pair_val_101, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_101 = "transfer.select"(%pair_valid_101, %pair_val0_101, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_101 = "transfer.select"(%pair_valid_101, %pair_val_101, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_101 = "transfer.and"(%pair_acc0_100, %pair_sel0_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_101 = "transfer.and"(%pair_acc1_100, %pair_sel1_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_101 = "arith.ori"(%pair_any_100, %pair_valid_101) : (i1, i1) -> i1
    %pair_rhs_nz_102 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_102 = "transfer.select"(%pair_rhs_nz_102, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_102 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_102 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_102 = "arith.andi"(%pair_lhs_eq_smin_102, %pair_rhs_eq_m1_102) : (i1, i1) -> i1
    %pair_not_ub_102 = "arith.xori"(%pair_ub_102, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_102 = "arith.andi"(%pair_rhs_nz_102, %pair_not_ub_102) : (i1, i1) -> i1
    %pair_val_102 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_102 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_102 = "transfer.cmp"(%pair_rem_102, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_102 = "arith.andi"(%pair_valid_sdiv_102, %pair_exact_102) : (i1, i1) -> i1
    %pair_val0_102 = "transfer.xor"(%pair_val_102, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_102 = "transfer.select"(%pair_valid_102, %pair_val0_102, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_102 = "transfer.select"(%pair_valid_102, %pair_val_102, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_102 = "transfer.and"(%pair_acc0_101, %pair_sel0_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_102 = "transfer.and"(%pair_acc1_101, %pair_sel1_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_102 = "arith.ori"(%pair_any_101, %pair_valid_102) : (i1, i1) -> i1
    %pair_rhs_nz_103 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_103 = "transfer.select"(%pair_rhs_nz_103, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_103 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_103 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_103 = "arith.andi"(%pair_lhs_eq_smin_103, %pair_rhs_eq_m1_103) : (i1, i1) -> i1
    %pair_not_ub_103 = "arith.xori"(%pair_ub_103, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_103 = "arith.andi"(%pair_rhs_nz_103, %pair_not_ub_103) : (i1, i1) -> i1
    %pair_val_103 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_103 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_103 = "transfer.cmp"(%pair_rem_103, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_103 = "arith.andi"(%pair_valid_sdiv_103, %pair_exact_103) : (i1, i1) -> i1
    %pair_val0_103 = "transfer.xor"(%pair_val_103, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_103 = "transfer.select"(%pair_valid_103, %pair_val0_103, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_103 = "transfer.select"(%pair_valid_103, %pair_val_103, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_103 = "transfer.and"(%pair_acc0_102, %pair_sel0_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_103 = "transfer.and"(%pair_acc1_102, %pair_sel1_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_103 = "arith.ori"(%pair_any_102, %pair_valid_103) : (i1, i1) -> i1
    %pair_rhs_nz_104 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_104 = "transfer.select"(%pair_rhs_nz_104, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_104 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_104 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_104 = "arith.andi"(%pair_lhs_eq_smin_104, %pair_rhs_eq_m1_104) : (i1, i1) -> i1
    %pair_not_ub_104 = "arith.xori"(%pair_ub_104, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_104 = "arith.andi"(%pair_rhs_nz_104, %pair_not_ub_104) : (i1, i1) -> i1
    %pair_val_104 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_104 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_104 = "transfer.cmp"(%pair_rem_104, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_104 = "arith.andi"(%pair_valid_sdiv_104, %pair_exact_104) : (i1, i1) -> i1
    %pair_val0_104 = "transfer.xor"(%pair_val_104, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_104 = "transfer.select"(%pair_valid_104, %pair_val0_104, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_104 = "transfer.select"(%pair_valid_104, %pair_val_104, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_104 = "transfer.and"(%pair_acc0_103, %pair_sel0_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_104 = "transfer.and"(%pair_acc1_103, %pair_sel1_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_104 = "arith.ori"(%pair_any_103, %pair_valid_104) : (i1, i1) -> i1
    %pair_rhs_nz_105 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_105 = "transfer.select"(%pair_rhs_nz_105, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_105 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_105 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_105 = "arith.andi"(%pair_lhs_eq_smin_105, %pair_rhs_eq_m1_105) : (i1, i1) -> i1
    %pair_not_ub_105 = "arith.xori"(%pair_ub_105, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_105 = "arith.andi"(%pair_rhs_nz_105, %pair_not_ub_105) : (i1, i1) -> i1
    %pair_val_105 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_105 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_105 = "transfer.cmp"(%pair_rem_105, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_105 = "arith.andi"(%pair_valid_sdiv_105, %pair_exact_105) : (i1, i1) -> i1
    %pair_val0_105 = "transfer.xor"(%pair_val_105, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_105 = "transfer.select"(%pair_valid_105, %pair_val0_105, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_105 = "transfer.select"(%pair_valid_105, %pair_val_105, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_105 = "transfer.and"(%pair_acc0_104, %pair_sel0_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_105 = "transfer.and"(%pair_acc1_104, %pair_sel1_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_105 = "arith.ori"(%pair_any_104, %pair_valid_105) : (i1, i1) -> i1
    %pair_rhs_nz_106 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_106 = "transfer.select"(%pair_rhs_nz_106, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_106 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_106 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_106 = "arith.andi"(%pair_lhs_eq_smin_106, %pair_rhs_eq_m1_106) : (i1, i1) -> i1
    %pair_not_ub_106 = "arith.xori"(%pair_ub_106, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_106 = "arith.andi"(%pair_rhs_nz_106, %pair_not_ub_106) : (i1, i1) -> i1
    %pair_val_106 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_106 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_106 = "transfer.cmp"(%pair_rem_106, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_106 = "arith.andi"(%pair_valid_sdiv_106, %pair_exact_106) : (i1, i1) -> i1
    %pair_val0_106 = "transfer.xor"(%pair_val_106, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_106 = "transfer.select"(%pair_valid_106, %pair_val0_106, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_106 = "transfer.select"(%pair_valid_106, %pair_val_106, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_106 = "transfer.and"(%pair_acc0_105, %pair_sel0_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_106 = "transfer.and"(%pair_acc1_105, %pair_sel1_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_106 = "arith.ori"(%pair_any_105, %pair_valid_106) : (i1, i1) -> i1
    %pair_rhs_nz_107 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_107 = "transfer.select"(%pair_rhs_nz_107, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_107 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_107 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_107 = "arith.andi"(%pair_lhs_eq_smin_107, %pair_rhs_eq_m1_107) : (i1, i1) -> i1
    %pair_not_ub_107 = "arith.xori"(%pair_ub_107, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_107 = "arith.andi"(%pair_rhs_nz_107, %pair_not_ub_107) : (i1, i1) -> i1
    %pair_val_107 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_107 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_107 = "transfer.cmp"(%pair_rem_107, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_107 = "arith.andi"(%pair_valid_sdiv_107, %pair_exact_107) : (i1, i1) -> i1
    %pair_val0_107 = "transfer.xor"(%pair_val_107, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_107 = "transfer.select"(%pair_valid_107, %pair_val0_107, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_107 = "transfer.select"(%pair_valid_107, %pair_val_107, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_107 = "transfer.and"(%pair_acc0_106, %pair_sel0_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_107 = "transfer.and"(%pair_acc1_106, %pair_sel1_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_107 = "arith.ori"(%pair_any_106, %pair_valid_107) : (i1, i1) -> i1
    %pair_rhs_nz_108 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_108 = "transfer.select"(%pair_rhs_nz_108, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_108 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_108 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_108 = "arith.andi"(%pair_lhs_eq_smin_108, %pair_rhs_eq_m1_108) : (i1, i1) -> i1
    %pair_not_ub_108 = "arith.xori"(%pair_ub_108, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_108 = "arith.andi"(%pair_rhs_nz_108, %pair_not_ub_108) : (i1, i1) -> i1
    %pair_val_108 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_108 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_108 = "transfer.cmp"(%pair_rem_108, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_108 = "arith.andi"(%pair_valid_sdiv_108, %pair_exact_108) : (i1, i1) -> i1
    %pair_val0_108 = "transfer.xor"(%pair_val_108, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_108 = "transfer.select"(%pair_valid_108, %pair_val0_108, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_108 = "transfer.select"(%pair_valid_108, %pair_val_108, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_108 = "transfer.and"(%pair_acc0_107, %pair_sel0_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_108 = "transfer.and"(%pair_acc1_107, %pair_sel1_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_108 = "arith.ori"(%pair_any_107, %pair_valid_108) : (i1, i1) -> i1
    %pair_rhs_nz_109 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_109 = "transfer.select"(%pair_rhs_nz_109, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_109 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_109 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_109 = "arith.andi"(%pair_lhs_eq_smin_109, %pair_rhs_eq_m1_109) : (i1, i1) -> i1
    %pair_not_ub_109 = "arith.xori"(%pair_ub_109, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_109 = "arith.andi"(%pair_rhs_nz_109, %pair_not_ub_109) : (i1, i1) -> i1
    %pair_val_109 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_109 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_109 = "transfer.cmp"(%pair_rem_109, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_109 = "arith.andi"(%pair_valid_sdiv_109, %pair_exact_109) : (i1, i1) -> i1
    %pair_val0_109 = "transfer.xor"(%pair_val_109, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_109 = "transfer.select"(%pair_valid_109, %pair_val0_109, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_109 = "transfer.select"(%pair_valid_109, %pair_val_109, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_109 = "transfer.and"(%pair_acc0_108, %pair_sel0_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_109 = "transfer.and"(%pair_acc1_108, %pair_sel1_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_109 = "arith.ori"(%pair_any_108, %pair_valid_109) : (i1, i1) -> i1
    %pair_rhs_nz_110 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_110 = "transfer.select"(%pair_rhs_nz_110, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_110 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_110 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_110 = "arith.andi"(%pair_lhs_eq_smin_110, %pair_rhs_eq_m1_110) : (i1, i1) -> i1
    %pair_not_ub_110 = "arith.xori"(%pair_ub_110, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_110 = "arith.andi"(%pair_rhs_nz_110, %pair_not_ub_110) : (i1, i1) -> i1
    %pair_val_110 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_110 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_110 = "transfer.cmp"(%pair_rem_110, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_110 = "arith.andi"(%pair_valid_sdiv_110, %pair_exact_110) : (i1, i1) -> i1
    %pair_val0_110 = "transfer.xor"(%pair_val_110, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_110 = "transfer.select"(%pair_valid_110, %pair_val0_110, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_110 = "transfer.select"(%pair_valid_110, %pair_val_110, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_110 = "transfer.and"(%pair_acc0_109, %pair_sel0_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_110 = "transfer.and"(%pair_acc1_109, %pair_sel1_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_110 = "arith.ori"(%pair_any_109, %pair_valid_110) : (i1, i1) -> i1
    %pair_rhs_nz_111 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_111 = "transfer.select"(%pair_rhs_nz_111, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_111 = "transfer.cmp"(%lhsu_v6, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_111 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_111 = "arith.andi"(%pair_lhs_eq_smin_111, %pair_rhs_eq_m1_111) : (i1, i1) -> i1
    %pair_not_ub_111 = "arith.xori"(%pair_ub_111, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_111 = "arith.andi"(%pair_rhs_nz_111, %pair_not_ub_111) : (i1, i1) -> i1
    %pair_val_111 = "transfer.sdiv"(%lhsu_v6, %pair_rhs_safe_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_111 = "transfer.srem"(%lhsu_v6, %pair_rhs_safe_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_111 = "transfer.cmp"(%pair_rem_111, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_111 = "arith.andi"(%pair_valid_sdiv_111, %pair_exact_111) : (i1, i1) -> i1
    %pair_val0_111 = "transfer.xor"(%pair_val_111, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_111 = "transfer.select"(%pair_valid_111, %pair_val0_111, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_111 = "transfer.select"(%pair_valid_111, %pair_val_111, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_111 = "transfer.and"(%pair_acc0_110, %pair_sel0_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_111 = "transfer.and"(%pair_acc1_110, %pair_sel1_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_111 = "arith.ori"(%pair_any_110, %pair_valid_111) : (i1, i1) -> i1
    %pair_rhs_nz_112 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_112 = "transfer.select"(%pair_rhs_nz_112, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_112 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_112 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_112 = "arith.andi"(%pair_lhs_eq_smin_112, %pair_rhs_eq_m1_112) : (i1, i1) -> i1
    %pair_not_ub_112 = "arith.xori"(%pair_ub_112, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_112 = "arith.andi"(%pair_rhs_nz_112, %pair_not_ub_112) : (i1, i1) -> i1
    %pair_val_112 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_112 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_112 = "transfer.cmp"(%pair_rem_112, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_112 = "arith.andi"(%pair_valid_sdiv_112, %pair_exact_112) : (i1, i1) -> i1
    %pair_val0_112 = "transfer.xor"(%pair_val_112, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_112 = "transfer.select"(%pair_valid_112, %pair_val0_112, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_112 = "transfer.select"(%pair_valid_112, %pair_val_112, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_112 = "transfer.and"(%pair_acc0_111, %pair_sel0_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_112 = "transfer.and"(%pair_acc1_111, %pair_sel1_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_112 = "arith.ori"(%pair_any_111, %pair_valid_112) : (i1, i1) -> i1
    %pair_rhs_nz_113 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_113 = "transfer.select"(%pair_rhs_nz_113, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_113 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_113 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_113 = "arith.andi"(%pair_lhs_eq_smin_113, %pair_rhs_eq_m1_113) : (i1, i1) -> i1
    %pair_not_ub_113 = "arith.xori"(%pair_ub_113, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_113 = "arith.andi"(%pair_rhs_nz_113, %pair_not_ub_113) : (i1, i1) -> i1
    %pair_val_113 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_113 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_113 = "transfer.cmp"(%pair_rem_113, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_113 = "arith.andi"(%pair_valid_sdiv_113, %pair_exact_113) : (i1, i1) -> i1
    %pair_val0_113 = "transfer.xor"(%pair_val_113, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_113 = "transfer.select"(%pair_valid_113, %pair_val0_113, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_113 = "transfer.select"(%pair_valid_113, %pair_val_113, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_113 = "transfer.and"(%pair_acc0_112, %pair_sel0_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_113 = "transfer.and"(%pair_acc1_112, %pair_sel1_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_113 = "arith.ori"(%pair_any_112, %pair_valid_113) : (i1, i1) -> i1
    %pair_rhs_nz_114 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_114 = "transfer.select"(%pair_rhs_nz_114, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_114 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_114 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_114 = "arith.andi"(%pair_lhs_eq_smin_114, %pair_rhs_eq_m1_114) : (i1, i1) -> i1
    %pair_not_ub_114 = "arith.xori"(%pair_ub_114, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_114 = "arith.andi"(%pair_rhs_nz_114, %pair_not_ub_114) : (i1, i1) -> i1
    %pair_val_114 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_114 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_114 = "transfer.cmp"(%pair_rem_114, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_114 = "arith.andi"(%pair_valid_sdiv_114, %pair_exact_114) : (i1, i1) -> i1
    %pair_val0_114 = "transfer.xor"(%pair_val_114, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_114 = "transfer.select"(%pair_valid_114, %pair_val0_114, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_114 = "transfer.select"(%pair_valid_114, %pair_val_114, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_114 = "transfer.and"(%pair_acc0_113, %pair_sel0_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_114 = "transfer.and"(%pair_acc1_113, %pair_sel1_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_114 = "arith.ori"(%pair_any_113, %pair_valid_114) : (i1, i1) -> i1
    %pair_rhs_nz_115 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_115 = "transfer.select"(%pair_rhs_nz_115, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_115 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_115 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_115 = "arith.andi"(%pair_lhs_eq_smin_115, %pair_rhs_eq_m1_115) : (i1, i1) -> i1
    %pair_not_ub_115 = "arith.xori"(%pair_ub_115, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_115 = "arith.andi"(%pair_rhs_nz_115, %pair_not_ub_115) : (i1, i1) -> i1
    %pair_val_115 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_115 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_115 = "transfer.cmp"(%pair_rem_115, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_115 = "arith.andi"(%pair_valid_sdiv_115, %pair_exact_115) : (i1, i1) -> i1
    %pair_val0_115 = "transfer.xor"(%pair_val_115, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_115 = "transfer.select"(%pair_valid_115, %pair_val0_115, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_115 = "transfer.select"(%pair_valid_115, %pair_val_115, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_115 = "transfer.and"(%pair_acc0_114, %pair_sel0_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_115 = "transfer.and"(%pair_acc1_114, %pair_sel1_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_115 = "arith.ori"(%pair_any_114, %pair_valid_115) : (i1, i1) -> i1
    %pair_rhs_nz_116 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_116 = "transfer.select"(%pair_rhs_nz_116, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_116 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_116 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_116 = "arith.andi"(%pair_lhs_eq_smin_116, %pair_rhs_eq_m1_116) : (i1, i1) -> i1
    %pair_not_ub_116 = "arith.xori"(%pair_ub_116, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_116 = "arith.andi"(%pair_rhs_nz_116, %pair_not_ub_116) : (i1, i1) -> i1
    %pair_val_116 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_116 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_116 = "transfer.cmp"(%pair_rem_116, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_116 = "arith.andi"(%pair_valid_sdiv_116, %pair_exact_116) : (i1, i1) -> i1
    %pair_val0_116 = "transfer.xor"(%pair_val_116, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_116 = "transfer.select"(%pair_valid_116, %pair_val0_116, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_116 = "transfer.select"(%pair_valid_116, %pair_val_116, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_116 = "transfer.and"(%pair_acc0_115, %pair_sel0_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_116 = "transfer.and"(%pair_acc1_115, %pair_sel1_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_116 = "arith.ori"(%pair_any_115, %pair_valid_116) : (i1, i1) -> i1
    %pair_rhs_nz_117 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_117 = "transfer.select"(%pair_rhs_nz_117, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_117 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_117 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_117 = "arith.andi"(%pair_lhs_eq_smin_117, %pair_rhs_eq_m1_117) : (i1, i1) -> i1
    %pair_not_ub_117 = "arith.xori"(%pair_ub_117, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_117 = "arith.andi"(%pair_rhs_nz_117, %pair_not_ub_117) : (i1, i1) -> i1
    %pair_val_117 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_117 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_117 = "transfer.cmp"(%pair_rem_117, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_117 = "arith.andi"(%pair_valid_sdiv_117, %pair_exact_117) : (i1, i1) -> i1
    %pair_val0_117 = "transfer.xor"(%pair_val_117, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_117 = "transfer.select"(%pair_valid_117, %pair_val0_117, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_117 = "transfer.select"(%pair_valid_117, %pair_val_117, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_117 = "transfer.and"(%pair_acc0_116, %pair_sel0_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_117 = "transfer.and"(%pair_acc1_116, %pair_sel1_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_117 = "arith.ori"(%pair_any_116, %pair_valid_117) : (i1, i1) -> i1
    %pair_rhs_nz_118 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_118 = "transfer.select"(%pair_rhs_nz_118, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_118 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_118 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_118 = "arith.andi"(%pair_lhs_eq_smin_118, %pair_rhs_eq_m1_118) : (i1, i1) -> i1
    %pair_not_ub_118 = "arith.xori"(%pair_ub_118, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_118 = "arith.andi"(%pair_rhs_nz_118, %pair_not_ub_118) : (i1, i1) -> i1
    %pair_val_118 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_118 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_118 = "transfer.cmp"(%pair_rem_118, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_118 = "arith.andi"(%pair_valid_sdiv_118, %pair_exact_118) : (i1, i1) -> i1
    %pair_val0_118 = "transfer.xor"(%pair_val_118, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_118 = "transfer.select"(%pair_valid_118, %pair_val0_118, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_118 = "transfer.select"(%pair_valid_118, %pair_val_118, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_118 = "transfer.and"(%pair_acc0_117, %pair_sel0_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_118 = "transfer.and"(%pair_acc1_117, %pair_sel1_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_118 = "arith.ori"(%pair_any_117, %pair_valid_118) : (i1, i1) -> i1
    %pair_rhs_nz_119 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_119 = "transfer.select"(%pair_rhs_nz_119, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_119 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_119 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_119 = "arith.andi"(%pair_lhs_eq_smin_119, %pair_rhs_eq_m1_119) : (i1, i1) -> i1
    %pair_not_ub_119 = "arith.xori"(%pair_ub_119, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_119 = "arith.andi"(%pair_rhs_nz_119, %pair_not_ub_119) : (i1, i1) -> i1
    %pair_val_119 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_119 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_119 = "transfer.cmp"(%pair_rem_119, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_119 = "arith.andi"(%pair_valid_sdiv_119, %pair_exact_119) : (i1, i1) -> i1
    %pair_val0_119 = "transfer.xor"(%pair_val_119, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_119 = "transfer.select"(%pair_valid_119, %pair_val0_119, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_119 = "transfer.select"(%pair_valid_119, %pair_val_119, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_119 = "transfer.and"(%pair_acc0_118, %pair_sel0_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_119 = "transfer.and"(%pair_acc1_118, %pair_sel1_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_119 = "arith.ori"(%pair_any_118, %pair_valid_119) : (i1, i1) -> i1
    %pair_rhs_nz_120 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_120 = "transfer.select"(%pair_rhs_nz_120, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_120 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_120 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_120 = "arith.andi"(%pair_lhs_eq_smin_120, %pair_rhs_eq_m1_120) : (i1, i1) -> i1
    %pair_not_ub_120 = "arith.xori"(%pair_ub_120, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_120 = "arith.andi"(%pair_rhs_nz_120, %pair_not_ub_120) : (i1, i1) -> i1
    %pair_val_120 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_120 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_120 = "transfer.cmp"(%pair_rem_120, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_120 = "arith.andi"(%pair_valid_sdiv_120, %pair_exact_120) : (i1, i1) -> i1
    %pair_val0_120 = "transfer.xor"(%pair_val_120, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_120 = "transfer.select"(%pair_valid_120, %pair_val0_120, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_120 = "transfer.select"(%pair_valid_120, %pair_val_120, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_120 = "transfer.and"(%pair_acc0_119, %pair_sel0_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_120 = "transfer.and"(%pair_acc1_119, %pair_sel1_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_120 = "arith.ori"(%pair_any_119, %pair_valid_120) : (i1, i1) -> i1
    %pair_rhs_nz_121 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_121 = "transfer.select"(%pair_rhs_nz_121, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_121 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_121 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_121 = "arith.andi"(%pair_lhs_eq_smin_121, %pair_rhs_eq_m1_121) : (i1, i1) -> i1
    %pair_not_ub_121 = "arith.xori"(%pair_ub_121, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_121 = "arith.andi"(%pair_rhs_nz_121, %pair_not_ub_121) : (i1, i1) -> i1
    %pair_val_121 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_121 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_121 = "transfer.cmp"(%pair_rem_121, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_121 = "arith.andi"(%pair_valid_sdiv_121, %pair_exact_121) : (i1, i1) -> i1
    %pair_val0_121 = "transfer.xor"(%pair_val_121, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_121 = "transfer.select"(%pair_valid_121, %pair_val0_121, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_121 = "transfer.select"(%pair_valid_121, %pair_val_121, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_121 = "transfer.and"(%pair_acc0_120, %pair_sel0_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_121 = "transfer.and"(%pair_acc1_120, %pair_sel1_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_121 = "arith.ori"(%pair_any_120, %pair_valid_121) : (i1, i1) -> i1
    %pair_rhs_nz_122 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_122 = "transfer.select"(%pair_rhs_nz_122, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_122 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_122 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_122 = "arith.andi"(%pair_lhs_eq_smin_122, %pair_rhs_eq_m1_122) : (i1, i1) -> i1
    %pair_not_ub_122 = "arith.xori"(%pair_ub_122, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_122 = "arith.andi"(%pair_rhs_nz_122, %pair_not_ub_122) : (i1, i1) -> i1
    %pair_val_122 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_122 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_122 = "transfer.cmp"(%pair_rem_122, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_122 = "arith.andi"(%pair_valid_sdiv_122, %pair_exact_122) : (i1, i1) -> i1
    %pair_val0_122 = "transfer.xor"(%pair_val_122, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_122 = "transfer.select"(%pair_valid_122, %pair_val0_122, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_122 = "transfer.select"(%pair_valid_122, %pair_val_122, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_122 = "transfer.and"(%pair_acc0_121, %pair_sel0_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_122 = "transfer.and"(%pair_acc1_121, %pair_sel1_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_122 = "arith.ori"(%pair_any_121, %pair_valid_122) : (i1, i1) -> i1
    %pair_rhs_nz_123 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_123 = "transfer.select"(%pair_rhs_nz_123, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_123 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_123 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_123 = "arith.andi"(%pair_lhs_eq_smin_123, %pair_rhs_eq_m1_123) : (i1, i1) -> i1
    %pair_not_ub_123 = "arith.xori"(%pair_ub_123, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_123 = "arith.andi"(%pair_rhs_nz_123, %pair_not_ub_123) : (i1, i1) -> i1
    %pair_val_123 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_123 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_123 = "transfer.cmp"(%pair_rem_123, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_123 = "arith.andi"(%pair_valid_sdiv_123, %pair_exact_123) : (i1, i1) -> i1
    %pair_val0_123 = "transfer.xor"(%pair_val_123, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_123 = "transfer.select"(%pair_valid_123, %pair_val0_123, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_123 = "transfer.select"(%pair_valid_123, %pair_val_123, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_123 = "transfer.and"(%pair_acc0_122, %pair_sel0_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_123 = "transfer.and"(%pair_acc1_122, %pair_sel1_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_123 = "arith.ori"(%pair_any_122, %pair_valid_123) : (i1, i1) -> i1
    %pair_rhs_nz_124 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_124 = "transfer.select"(%pair_rhs_nz_124, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_124 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_124 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_124 = "arith.andi"(%pair_lhs_eq_smin_124, %pair_rhs_eq_m1_124) : (i1, i1) -> i1
    %pair_not_ub_124 = "arith.xori"(%pair_ub_124, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_124 = "arith.andi"(%pair_rhs_nz_124, %pair_not_ub_124) : (i1, i1) -> i1
    %pair_val_124 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_124 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_124 = "transfer.cmp"(%pair_rem_124, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_124 = "arith.andi"(%pair_valid_sdiv_124, %pair_exact_124) : (i1, i1) -> i1
    %pair_val0_124 = "transfer.xor"(%pair_val_124, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_124 = "transfer.select"(%pair_valid_124, %pair_val0_124, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_124 = "transfer.select"(%pair_valid_124, %pair_val_124, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_124 = "transfer.and"(%pair_acc0_123, %pair_sel0_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_124 = "transfer.and"(%pair_acc1_123, %pair_sel1_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_124 = "arith.ori"(%pair_any_123, %pair_valid_124) : (i1, i1) -> i1
    %pair_rhs_nz_125 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_125 = "transfer.select"(%pair_rhs_nz_125, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_125 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_125 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_125 = "arith.andi"(%pair_lhs_eq_smin_125, %pair_rhs_eq_m1_125) : (i1, i1) -> i1
    %pair_not_ub_125 = "arith.xori"(%pair_ub_125, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_125 = "arith.andi"(%pair_rhs_nz_125, %pair_not_ub_125) : (i1, i1) -> i1
    %pair_val_125 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_125 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_125 = "transfer.cmp"(%pair_rem_125, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_125 = "arith.andi"(%pair_valid_sdiv_125, %pair_exact_125) : (i1, i1) -> i1
    %pair_val0_125 = "transfer.xor"(%pair_val_125, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_125 = "transfer.select"(%pair_valid_125, %pair_val0_125, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_125 = "transfer.select"(%pair_valid_125, %pair_val_125, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_125 = "transfer.and"(%pair_acc0_124, %pair_sel0_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_125 = "transfer.and"(%pair_acc1_124, %pair_sel1_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_125 = "arith.ori"(%pair_any_124, %pair_valid_125) : (i1, i1) -> i1
    %pair_rhs_nz_126 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_126 = "transfer.select"(%pair_rhs_nz_126, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_126 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_126 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_126 = "arith.andi"(%pair_lhs_eq_smin_126, %pair_rhs_eq_m1_126) : (i1, i1) -> i1
    %pair_not_ub_126 = "arith.xori"(%pair_ub_126, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_126 = "arith.andi"(%pair_rhs_nz_126, %pair_not_ub_126) : (i1, i1) -> i1
    %pair_val_126 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_126 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_126 = "transfer.cmp"(%pair_rem_126, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_126 = "arith.andi"(%pair_valid_sdiv_126, %pair_exact_126) : (i1, i1) -> i1
    %pair_val0_126 = "transfer.xor"(%pair_val_126, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_126 = "transfer.select"(%pair_valid_126, %pair_val0_126, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_126 = "transfer.select"(%pair_valid_126, %pair_val_126, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_126 = "transfer.and"(%pair_acc0_125, %pair_sel0_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_126 = "transfer.and"(%pair_acc1_125, %pair_sel1_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_126 = "arith.ori"(%pair_any_125, %pair_valid_126) : (i1, i1) -> i1
    %pair_rhs_nz_127 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_127 = "transfer.select"(%pair_rhs_nz_127, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_127 = "transfer.cmp"(%lhsu_v7, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_127 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_127 = "arith.andi"(%pair_lhs_eq_smin_127, %pair_rhs_eq_m1_127) : (i1, i1) -> i1
    %pair_not_ub_127 = "arith.xori"(%pair_ub_127, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_127 = "arith.andi"(%pair_rhs_nz_127, %pair_not_ub_127) : (i1, i1) -> i1
    %pair_val_127 = "transfer.sdiv"(%lhsu_v7, %pair_rhs_safe_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_127 = "transfer.srem"(%lhsu_v7, %pair_rhs_safe_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_127 = "transfer.cmp"(%pair_rem_127, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_127 = "arith.andi"(%pair_valid_sdiv_127, %pair_exact_127) : (i1, i1) -> i1
    %pair_val0_127 = "transfer.xor"(%pair_val_127, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_127 = "transfer.select"(%pair_valid_127, %pair_val0_127, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_127 = "transfer.select"(%pair_valid_127, %pair_val_127, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_127 = "transfer.and"(%pair_acc0_126, %pair_sel0_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_127 = "transfer.and"(%pair_acc1_126, %pair_sel1_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_127 = "arith.ori"(%pair_any_126, %pair_valid_127) : (i1, i1) -> i1
    %pair_rhs_nz_128 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_128 = "transfer.select"(%pair_rhs_nz_128, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_128 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_128 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_128 = "arith.andi"(%pair_lhs_eq_smin_128, %pair_rhs_eq_m1_128) : (i1, i1) -> i1
    %pair_not_ub_128 = "arith.xori"(%pair_ub_128, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_128 = "arith.andi"(%pair_rhs_nz_128, %pair_not_ub_128) : (i1, i1) -> i1
    %pair_val_128 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_128 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_128 = "transfer.cmp"(%pair_rem_128, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_128 = "arith.andi"(%pair_valid_sdiv_128, %pair_exact_128) : (i1, i1) -> i1
    %pair_val0_128 = "transfer.xor"(%pair_val_128, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_128 = "transfer.select"(%pair_valid_128, %pair_val0_128, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_128 = "transfer.select"(%pair_valid_128, %pair_val_128, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_128 = "transfer.and"(%pair_acc0_127, %pair_sel0_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_128 = "transfer.and"(%pair_acc1_127, %pair_sel1_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_128 = "arith.ori"(%pair_any_127, %pair_valid_128) : (i1, i1) -> i1
    %pair_rhs_nz_129 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_129 = "transfer.select"(%pair_rhs_nz_129, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_129 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_129 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_129 = "arith.andi"(%pair_lhs_eq_smin_129, %pair_rhs_eq_m1_129) : (i1, i1) -> i1
    %pair_not_ub_129 = "arith.xori"(%pair_ub_129, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_129 = "arith.andi"(%pair_rhs_nz_129, %pair_not_ub_129) : (i1, i1) -> i1
    %pair_val_129 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_129 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_129 = "transfer.cmp"(%pair_rem_129, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_129 = "arith.andi"(%pair_valid_sdiv_129, %pair_exact_129) : (i1, i1) -> i1
    %pair_val0_129 = "transfer.xor"(%pair_val_129, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_129 = "transfer.select"(%pair_valid_129, %pair_val0_129, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_129 = "transfer.select"(%pair_valid_129, %pair_val_129, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_129 = "transfer.and"(%pair_acc0_128, %pair_sel0_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_129 = "transfer.and"(%pair_acc1_128, %pair_sel1_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_129 = "arith.ori"(%pair_any_128, %pair_valid_129) : (i1, i1) -> i1
    %pair_rhs_nz_130 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_130 = "transfer.select"(%pair_rhs_nz_130, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_130 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_130 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_130 = "arith.andi"(%pair_lhs_eq_smin_130, %pair_rhs_eq_m1_130) : (i1, i1) -> i1
    %pair_not_ub_130 = "arith.xori"(%pair_ub_130, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_130 = "arith.andi"(%pair_rhs_nz_130, %pair_not_ub_130) : (i1, i1) -> i1
    %pair_val_130 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_130 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_130 = "transfer.cmp"(%pair_rem_130, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_130 = "arith.andi"(%pair_valid_sdiv_130, %pair_exact_130) : (i1, i1) -> i1
    %pair_val0_130 = "transfer.xor"(%pair_val_130, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_130 = "transfer.select"(%pair_valid_130, %pair_val0_130, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_130 = "transfer.select"(%pair_valid_130, %pair_val_130, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_130 = "transfer.and"(%pair_acc0_129, %pair_sel0_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_130 = "transfer.and"(%pair_acc1_129, %pair_sel1_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_130 = "arith.ori"(%pair_any_129, %pair_valid_130) : (i1, i1) -> i1
    %pair_rhs_nz_131 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_131 = "transfer.select"(%pair_rhs_nz_131, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_131 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_131 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_131 = "arith.andi"(%pair_lhs_eq_smin_131, %pair_rhs_eq_m1_131) : (i1, i1) -> i1
    %pair_not_ub_131 = "arith.xori"(%pair_ub_131, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_131 = "arith.andi"(%pair_rhs_nz_131, %pair_not_ub_131) : (i1, i1) -> i1
    %pair_val_131 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_131 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_131 = "transfer.cmp"(%pair_rem_131, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_131 = "arith.andi"(%pair_valid_sdiv_131, %pair_exact_131) : (i1, i1) -> i1
    %pair_val0_131 = "transfer.xor"(%pair_val_131, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_131 = "transfer.select"(%pair_valid_131, %pair_val0_131, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_131 = "transfer.select"(%pair_valid_131, %pair_val_131, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_131 = "transfer.and"(%pair_acc0_130, %pair_sel0_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_131 = "transfer.and"(%pair_acc1_130, %pair_sel1_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_131 = "arith.ori"(%pair_any_130, %pair_valid_131) : (i1, i1) -> i1
    %pair_rhs_nz_132 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_132 = "transfer.select"(%pair_rhs_nz_132, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_132 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_132 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_132 = "arith.andi"(%pair_lhs_eq_smin_132, %pair_rhs_eq_m1_132) : (i1, i1) -> i1
    %pair_not_ub_132 = "arith.xori"(%pair_ub_132, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_132 = "arith.andi"(%pair_rhs_nz_132, %pair_not_ub_132) : (i1, i1) -> i1
    %pair_val_132 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_132 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_132 = "transfer.cmp"(%pair_rem_132, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_132 = "arith.andi"(%pair_valid_sdiv_132, %pair_exact_132) : (i1, i1) -> i1
    %pair_val0_132 = "transfer.xor"(%pair_val_132, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_132 = "transfer.select"(%pair_valid_132, %pair_val0_132, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_132 = "transfer.select"(%pair_valid_132, %pair_val_132, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_132 = "transfer.and"(%pair_acc0_131, %pair_sel0_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_132 = "transfer.and"(%pair_acc1_131, %pair_sel1_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_132 = "arith.ori"(%pair_any_131, %pair_valid_132) : (i1, i1) -> i1
    %pair_rhs_nz_133 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_133 = "transfer.select"(%pair_rhs_nz_133, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_133 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_133 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_133 = "arith.andi"(%pair_lhs_eq_smin_133, %pair_rhs_eq_m1_133) : (i1, i1) -> i1
    %pair_not_ub_133 = "arith.xori"(%pair_ub_133, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_133 = "arith.andi"(%pair_rhs_nz_133, %pair_not_ub_133) : (i1, i1) -> i1
    %pair_val_133 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_133 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_133 = "transfer.cmp"(%pair_rem_133, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_133 = "arith.andi"(%pair_valid_sdiv_133, %pair_exact_133) : (i1, i1) -> i1
    %pair_val0_133 = "transfer.xor"(%pair_val_133, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_133 = "transfer.select"(%pair_valid_133, %pair_val0_133, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_133 = "transfer.select"(%pair_valid_133, %pair_val_133, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_133 = "transfer.and"(%pair_acc0_132, %pair_sel0_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_133 = "transfer.and"(%pair_acc1_132, %pair_sel1_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_133 = "arith.ori"(%pair_any_132, %pair_valid_133) : (i1, i1) -> i1
    %pair_rhs_nz_134 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_134 = "transfer.select"(%pair_rhs_nz_134, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_134 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_134 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_134 = "arith.andi"(%pair_lhs_eq_smin_134, %pair_rhs_eq_m1_134) : (i1, i1) -> i1
    %pair_not_ub_134 = "arith.xori"(%pair_ub_134, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_134 = "arith.andi"(%pair_rhs_nz_134, %pair_not_ub_134) : (i1, i1) -> i1
    %pair_val_134 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_134 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_134 = "transfer.cmp"(%pair_rem_134, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_134 = "arith.andi"(%pair_valid_sdiv_134, %pair_exact_134) : (i1, i1) -> i1
    %pair_val0_134 = "transfer.xor"(%pair_val_134, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_134 = "transfer.select"(%pair_valid_134, %pair_val0_134, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_134 = "transfer.select"(%pair_valid_134, %pair_val_134, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_134 = "transfer.and"(%pair_acc0_133, %pair_sel0_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_134 = "transfer.and"(%pair_acc1_133, %pair_sel1_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_134 = "arith.ori"(%pair_any_133, %pair_valid_134) : (i1, i1) -> i1
    %pair_rhs_nz_135 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_135 = "transfer.select"(%pair_rhs_nz_135, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_135 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_135 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_135 = "arith.andi"(%pair_lhs_eq_smin_135, %pair_rhs_eq_m1_135) : (i1, i1) -> i1
    %pair_not_ub_135 = "arith.xori"(%pair_ub_135, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_135 = "arith.andi"(%pair_rhs_nz_135, %pair_not_ub_135) : (i1, i1) -> i1
    %pair_val_135 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_135 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_135 = "transfer.cmp"(%pair_rem_135, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_135 = "arith.andi"(%pair_valid_sdiv_135, %pair_exact_135) : (i1, i1) -> i1
    %pair_val0_135 = "transfer.xor"(%pair_val_135, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_135 = "transfer.select"(%pair_valid_135, %pair_val0_135, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_135 = "transfer.select"(%pair_valid_135, %pair_val_135, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_135 = "transfer.and"(%pair_acc0_134, %pair_sel0_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_135 = "transfer.and"(%pair_acc1_134, %pair_sel1_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_135 = "arith.ori"(%pair_any_134, %pair_valid_135) : (i1, i1) -> i1
    %pair_rhs_nz_136 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_136 = "transfer.select"(%pair_rhs_nz_136, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_136 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_136 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_136 = "arith.andi"(%pair_lhs_eq_smin_136, %pair_rhs_eq_m1_136) : (i1, i1) -> i1
    %pair_not_ub_136 = "arith.xori"(%pair_ub_136, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_136 = "arith.andi"(%pair_rhs_nz_136, %pair_not_ub_136) : (i1, i1) -> i1
    %pair_val_136 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_136 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_136 = "transfer.cmp"(%pair_rem_136, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_136 = "arith.andi"(%pair_valid_sdiv_136, %pair_exact_136) : (i1, i1) -> i1
    %pair_val0_136 = "transfer.xor"(%pair_val_136, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_136 = "transfer.select"(%pair_valid_136, %pair_val0_136, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_136 = "transfer.select"(%pair_valid_136, %pair_val_136, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_136 = "transfer.and"(%pair_acc0_135, %pair_sel0_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_136 = "transfer.and"(%pair_acc1_135, %pair_sel1_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_136 = "arith.ori"(%pair_any_135, %pair_valid_136) : (i1, i1) -> i1
    %pair_rhs_nz_137 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_137 = "transfer.select"(%pair_rhs_nz_137, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_137 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_137 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_137 = "arith.andi"(%pair_lhs_eq_smin_137, %pair_rhs_eq_m1_137) : (i1, i1) -> i1
    %pair_not_ub_137 = "arith.xori"(%pair_ub_137, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_137 = "arith.andi"(%pair_rhs_nz_137, %pair_not_ub_137) : (i1, i1) -> i1
    %pair_val_137 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_137 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_137 = "transfer.cmp"(%pair_rem_137, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_137 = "arith.andi"(%pair_valid_sdiv_137, %pair_exact_137) : (i1, i1) -> i1
    %pair_val0_137 = "transfer.xor"(%pair_val_137, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_137 = "transfer.select"(%pair_valid_137, %pair_val0_137, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_137 = "transfer.select"(%pair_valid_137, %pair_val_137, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_137 = "transfer.and"(%pair_acc0_136, %pair_sel0_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_137 = "transfer.and"(%pair_acc1_136, %pair_sel1_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_137 = "arith.ori"(%pair_any_136, %pair_valid_137) : (i1, i1) -> i1
    %pair_rhs_nz_138 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_138 = "transfer.select"(%pair_rhs_nz_138, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_138 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_138 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_138 = "arith.andi"(%pair_lhs_eq_smin_138, %pair_rhs_eq_m1_138) : (i1, i1) -> i1
    %pair_not_ub_138 = "arith.xori"(%pair_ub_138, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_138 = "arith.andi"(%pair_rhs_nz_138, %pair_not_ub_138) : (i1, i1) -> i1
    %pair_val_138 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_138 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_138 = "transfer.cmp"(%pair_rem_138, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_138 = "arith.andi"(%pair_valid_sdiv_138, %pair_exact_138) : (i1, i1) -> i1
    %pair_val0_138 = "transfer.xor"(%pair_val_138, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_138 = "transfer.select"(%pair_valid_138, %pair_val0_138, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_138 = "transfer.select"(%pair_valid_138, %pair_val_138, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_138 = "transfer.and"(%pair_acc0_137, %pair_sel0_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_138 = "transfer.and"(%pair_acc1_137, %pair_sel1_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_138 = "arith.ori"(%pair_any_137, %pair_valid_138) : (i1, i1) -> i1
    %pair_rhs_nz_139 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_139 = "transfer.select"(%pair_rhs_nz_139, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_139 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_139 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_139 = "arith.andi"(%pair_lhs_eq_smin_139, %pair_rhs_eq_m1_139) : (i1, i1) -> i1
    %pair_not_ub_139 = "arith.xori"(%pair_ub_139, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_139 = "arith.andi"(%pair_rhs_nz_139, %pair_not_ub_139) : (i1, i1) -> i1
    %pair_val_139 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_139 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_139 = "transfer.cmp"(%pair_rem_139, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_139 = "arith.andi"(%pair_valid_sdiv_139, %pair_exact_139) : (i1, i1) -> i1
    %pair_val0_139 = "transfer.xor"(%pair_val_139, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_139 = "transfer.select"(%pair_valid_139, %pair_val0_139, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_139 = "transfer.select"(%pair_valid_139, %pair_val_139, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_139 = "transfer.and"(%pair_acc0_138, %pair_sel0_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_139 = "transfer.and"(%pair_acc1_138, %pair_sel1_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_139 = "arith.ori"(%pair_any_138, %pair_valid_139) : (i1, i1) -> i1
    %pair_rhs_nz_140 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_140 = "transfer.select"(%pair_rhs_nz_140, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_140 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_140 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_140 = "arith.andi"(%pair_lhs_eq_smin_140, %pair_rhs_eq_m1_140) : (i1, i1) -> i1
    %pair_not_ub_140 = "arith.xori"(%pair_ub_140, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_140 = "arith.andi"(%pair_rhs_nz_140, %pair_not_ub_140) : (i1, i1) -> i1
    %pair_val_140 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_140 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_140 = "transfer.cmp"(%pair_rem_140, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_140 = "arith.andi"(%pair_valid_sdiv_140, %pair_exact_140) : (i1, i1) -> i1
    %pair_val0_140 = "transfer.xor"(%pair_val_140, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_140 = "transfer.select"(%pair_valid_140, %pair_val0_140, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_140 = "transfer.select"(%pair_valid_140, %pair_val_140, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_140 = "transfer.and"(%pair_acc0_139, %pair_sel0_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_140 = "transfer.and"(%pair_acc1_139, %pair_sel1_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_140 = "arith.ori"(%pair_any_139, %pair_valid_140) : (i1, i1) -> i1
    %pair_rhs_nz_141 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_141 = "transfer.select"(%pair_rhs_nz_141, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_141 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_141 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_141 = "arith.andi"(%pair_lhs_eq_smin_141, %pair_rhs_eq_m1_141) : (i1, i1) -> i1
    %pair_not_ub_141 = "arith.xori"(%pair_ub_141, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_141 = "arith.andi"(%pair_rhs_nz_141, %pair_not_ub_141) : (i1, i1) -> i1
    %pair_val_141 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_141 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_141 = "transfer.cmp"(%pair_rem_141, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_141 = "arith.andi"(%pair_valid_sdiv_141, %pair_exact_141) : (i1, i1) -> i1
    %pair_val0_141 = "transfer.xor"(%pair_val_141, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_141 = "transfer.select"(%pair_valid_141, %pair_val0_141, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_141 = "transfer.select"(%pair_valid_141, %pair_val_141, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_141 = "transfer.and"(%pair_acc0_140, %pair_sel0_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_141 = "transfer.and"(%pair_acc1_140, %pair_sel1_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_141 = "arith.ori"(%pair_any_140, %pair_valid_141) : (i1, i1) -> i1
    %pair_rhs_nz_142 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_142 = "transfer.select"(%pair_rhs_nz_142, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_142 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_142 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_142 = "arith.andi"(%pair_lhs_eq_smin_142, %pair_rhs_eq_m1_142) : (i1, i1) -> i1
    %pair_not_ub_142 = "arith.xori"(%pair_ub_142, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_142 = "arith.andi"(%pair_rhs_nz_142, %pair_not_ub_142) : (i1, i1) -> i1
    %pair_val_142 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_142 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_142 = "transfer.cmp"(%pair_rem_142, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_142 = "arith.andi"(%pair_valid_sdiv_142, %pair_exact_142) : (i1, i1) -> i1
    %pair_val0_142 = "transfer.xor"(%pair_val_142, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_142 = "transfer.select"(%pair_valid_142, %pair_val0_142, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_142 = "transfer.select"(%pair_valid_142, %pair_val_142, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_142 = "transfer.and"(%pair_acc0_141, %pair_sel0_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_142 = "transfer.and"(%pair_acc1_141, %pair_sel1_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_142 = "arith.ori"(%pair_any_141, %pair_valid_142) : (i1, i1) -> i1
    %pair_rhs_nz_143 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_143 = "transfer.select"(%pair_rhs_nz_143, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_143 = "transfer.cmp"(%lhsu_v8, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_143 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_143 = "arith.andi"(%pair_lhs_eq_smin_143, %pair_rhs_eq_m1_143) : (i1, i1) -> i1
    %pair_not_ub_143 = "arith.xori"(%pair_ub_143, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_143 = "arith.andi"(%pair_rhs_nz_143, %pair_not_ub_143) : (i1, i1) -> i1
    %pair_val_143 = "transfer.sdiv"(%lhsu_v8, %pair_rhs_safe_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_143 = "transfer.srem"(%lhsu_v8, %pair_rhs_safe_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_143 = "transfer.cmp"(%pair_rem_143, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_143 = "arith.andi"(%pair_valid_sdiv_143, %pair_exact_143) : (i1, i1) -> i1
    %pair_val0_143 = "transfer.xor"(%pair_val_143, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_143 = "transfer.select"(%pair_valid_143, %pair_val0_143, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_143 = "transfer.select"(%pair_valid_143, %pair_val_143, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_143 = "transfer.and"(%pair_acc0_142, %pair_sel0_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_143 = "transfer.and"(%pair_acc1_142, %pair_sel1_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_143 = "arith.ori"(%pair_any_142, %pair_valid_143) : (i1, i1) -> i1
    %pair_rhs_nz_144 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_144 = "transfer.select"(%pair_rhs_nz_144, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_144 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_144 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_144 = "arith.andi"(%pair_lhs_eq_smin_144, %pair_rhs_eq_m1_144) : (i1, i1) -> i1
    %pair_not_ub_144 = "arith.xori"(%pair_ub_144, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_144 = "arith.andi"(%pair_rhs_nz_144, %pair_not_ub_144) : (i1, i1) -> i1
    %pair_val_144 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_144 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_144 = "transfer.cmp"(%pair_rem_144, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_144 = "arith.andi"(%pair_valid_sdiv_144, %pair_exact_144) : (i1, i1) -> i1
    %pair_val0_144 = "transfer.xor"(%pair_val_144, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_144 = "transfer.select"(%pair_valid_144, %pair_val0_144, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_144 = "transfer.select"(%pair_valid_144, %pair_val_144, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_144 = "transfer.and"(%pair_acc0_143, %pair_sel0_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_144 = "transfer.and"(%pair_acc1_143, %pair_sel1_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_144 = "arith.ori"(%pair_any_143, %pair_valid_144) : (i1, i1) -> i1
    %pair_rhs_nz_145 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_145 = "transfer.select"(%pair_rhs_nz_145, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_145 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_145 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_145 = "arith.andi"(%pair_lhs_eq_smin_145, %pair_rhs_eq_m1_145) : (i1, i1) -> i1
    %pair_not_ub_145 = "arith.xori"(%pair_ub_145, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_145 = "arith.andi"(%pair_rhs_nz_145, %pair_not_ub_145) : (i1, i1) -> i1
    %pair_val_145 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_145 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_145 = "transfer.cmp"(%pair_rem_145, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_145 = "arith.andi"(%pair_valid_sdiv_145, %pair_exact_145) : (i1, i1) -> i1
    %pair_val0_145 = "transfer.xor"(%pair_val_145, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_145 = "transfer.select"(%pair_valid_145, %pair_val0_145, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_145 = "transfer.select"(%pair_valid_145, %pair_val_145, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_145 = "transfer.and"(%pair_acc0_144, %pair_sel0_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_145 = "transfer.and"(%pair_acc1_144, %pair_sel1_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_145 = "arith.ori"(%pair_any_144, %pair_valid_145) : (i1, i1) -> i1
    %pair_rhs_nz_146 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_146 = "transfer.select"(%pair_rhs_nz_146, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_146 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_146 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_146 = "arith.andi"(%pair_lhs_eq_smin_146, %pair_rhs_eq_m1_146) : (i1, i1) -> i1
    %pair_not_ub_146 = "arith.xori"(%pair_ub_146, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_146 = "arith.andi"(%pair_rhs_nz_146, %pair_not_ub_146) : (i1, i1) -> i1
    %pair_val_146 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_146 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_146 = "transfer.cmp"(%pair_rem_146, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_146 = "arith.andi"(%pair_valid_sdiv_146, %pair_exact_146) : (i1, i1) -> i1
    %pair_val0_146 = "transfer.xor"(%pair_val_146, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_146 = "transfer.select"(%pair_valid_146, %pair_val0_146, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_146 = "transfer.select"(%pair_valid_146, %pair_val_146, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_146 = "transfer.and"(%pair_acc0_145, %pair_sel0_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_146 = "transfer.and"(%pair_acc1_145, %pair_sel1_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_146 = "arith.ori"(%pair_any_145, %pair_valid_146) : (i1, i1) -> i1
    %pair_rhs_nz_147 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_147 = "transfer.select"(%pair_rhs_nz_147, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_147 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_147 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_147 = "arith.andi"(%pair_lhs_eq_smin_147, %pair_rhs_eq_m1_147) : (i1, i1) -> i1
    %pair_not_ub_147 = "arith.xori"(%pair_ub_147, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_147 = "arith.andi"(%pair_rhs_nz_147, %pair_not_ub_147) : (i1, i1) -> i1
    %pair_val_147 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_147 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_147 = "transfer.cmp"(%pair_rem_147, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_147 = "arith.andi"(%pair_valid_sdiv_147, %pair_exact_147) : (i1, i1) -> i1
    %pair_val0_147 = "transfer.xor"(%pair_val_147, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_147 = "transfer.select"(%pair_valid_147, %pair_val0_147, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_147 = "transfer.select"(%pair_valid_147, %pair_val_147, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_147 = "transfer.and"(%pair_acc0_146, %pair_sel0_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_147 = "transfer.and"(%pair_acc1_146, %pair_sel1_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_147 = "arith.ori"(%pair_any_146, %pair_valid_147) : (i1, i1) -> i1
    %pair_rhs_nz_148 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_148 = "transfer.select"(%pair_rhs_nz_148, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_148 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_148 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_148 = "arith.andi"(%pair_lhs_eq_smin_148, %pair_rhs_eq_m1_148) : (i1, i1) -> i1
    %pair_not_ub_148 = "arith.xori"(%pair_ub_148, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_148 = "arith.andi"(%pair_rhs_nz_148, %pair_not_ub_148) : (i1, i1) -> i1
    %pair_val_148 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_148 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_148 = "transfer.cmp"(%pair_rem_148, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_148 = "arith.andi"(%pair_valid_sdiv_148, %pair_exact_148) : (i1, i1) -> i1
    %pair_val0_148 = "transfer.xor"(%pair_val_148, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_148 = "transfer.select"(%pair_valid_148, %pair_val0_148, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_148 = "transfer.select"(%pair_valid_148, %pair_val_148, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_148 = "transfer.and"(%pair_acc0_147, %pair_sel0_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_148 = "transfer.and"(%pair_acc1_147, %pair_sel1_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_148 = "arith.ori"(%pair_any_147, %pair_valid_148) : (i1, i1) -> i1
    %pair_rhs_nz_149 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_149 = "transfer.select"(%pair_rhs_nz_149, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_149 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_149 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_149 = "arith.andi"(%pair_lhs_eq_smin_149, %pair_rhs_eq_m1_149) : (i1, i1) -> i1
    %pair_not_ub_149 = "arith.xori"(%pair_ub_149, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_149 = "arith.andi"(%pair_rhs_nz_149, %pair_not_ub_149) : (i1, i1) -> i1
    %pair_val_149 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_149 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_149 = "transfer.cmp"(%pair_rem_149, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_149 = "arith.andi"(%pair_valid_sdiv_149, %pair_exact_149) : (i1, i1) -> i1
    %pair_val0_149 = "transfer.xor"(%pair_val_149, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_149 = "transfer.select"(%pair_valid_149, %pair_val0_149, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_149 = "transfer.select"(%pair_valid_149, %pair_val_149, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_149 = "transfer.and"(%pair_acc0_148, %pair_sel0_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_149 = "transfer.and"(%pair_acc1_148, %pair_sel1_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_149 = "arith.ori"(%pair_any_148, %pair_valid_149) : (i1, i1) -> i1
    %pair_rhs_nz_150 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_150 = "transfer.select"(%pair_rhs_nz_150, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_150 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_150 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_150 = "arith.andi"(%pair_lhs_eq_smin_150, %pair_rhs_eq_m1_150) : (i1, i1) -> i1
    %pair_not_ub_150 = "arith.xori"(%pair_ub_150, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_150 = "arith.andi"(%pair_rhs_nz_150, %pair_not_ub_150) : (i1, i1) -> i1
    %pair_val_150 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_150 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_150 = "transfer.cmp"(%pair_rem_150, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_150 = "arith.andi"(%pair_valid_sdiv_150, %pair_exact_150) : (i1, i1) -> i1
    %pair_val0_150 = "transfer.xor"(%pair_val_150, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_150 = "transfer.select"(%pair_valid_150, %pair_val0_150, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_150 = "transfer.select"(%pair_valid_150, %pair_val_150, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_150 = "transfer.and"(%pair_acc0_149, %pair_sel0_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_150 = "transfer.and"(%pair_acc1_149, %pair_sel1_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_150 = "arith.ori"(%pair_any_149, %pair_valid_150) : (i1, i1) -> i1
    %pair_rhs_nz_151 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_151 = "transfer.select"(%pair_rhs_nz_151, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_151 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_151 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_151 = "arith.andi"(%pair_lhs_eq_smin_151, %pair_rhs_eq_m1_151) : (i1, i1) -> i1
    %pair_not_ub_151 = "arith.xori"(%pair_ub_151, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_151 = "arith.andi"(%pair_rhs_nz_151, %pair_not_ub_151) : (i1, i1) -> i1
    %pair_val_151 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_151 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_151 = "transfer.cmp"(%pair_rem_151, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_151 = "arith.andi"(%pair_valid_sdiv_151, %pair_exact_151) : (i1, i1) -> i1
    %pair_val0_151 = "transfer.xor"(%pair_val_151, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_151 = "transfer.select"(%pair_valid_151, %pair_val0_151, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_151 = "transfer.select"(%pair_valid_151, %pair_val_151, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_151 = "transfer.and"(%pair_acc0_150, %pair_sel0_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_151 = "transfer.and"(%pair_acc1_150, %pair_sel1_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_151 = "arith.ori"(%pair_any_150, %pair_valid_151) : (i1, i1) -> i1
    %pair_rhs_nz_152 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_152 = "transfer.select"(%pair_rhs_nz_152, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_152 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_152 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_152 = "arith.andi"(%pair_lhs_eq_smin_152, %pair_rhs_eq_m1_152) : (i1, i1) -> i1
    %pair_not_ub_152 = "arith.xori"(%pair_ub_152, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_152 = "arith.andi"(%pair_rhs_nz_152, %pair_not_ub_152) : (i1, i1) -> i1
    %pair_val_152 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_152 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_152 = "transfer.cmp"(%pair_rem_152, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_152 = "arith.andi"(%pair_valid_sdiv_152, %pair_exact_152) : (i1, i1) -> i1
    %pair_val0_152 = "transfer.xor"(%pair_val_152, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_152 = "transfer.select"(%pair_valid_152, %pair_val0_152, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_152 = "transfer.select"(%pair_valid_152, %pair_val_152, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_152 = "transfer.and"(%pair_acc0_151, %pair_sel0_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_152 = "transfer.and"(%pair_acc1_151, %pair_sel1_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_152 = "arith.ori"(%pair_any_151, %pair_valid_152) : (i1, i1) -> i1
    %pair_rhs_nz_153 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_153 = "transfer.select"(%pair_rhs_nz_153, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_153 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_153 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_153 = "arith.andi"(%pair_lhs_eq_smin_153, %pair_rhs_eq_m1_153) : (i1, i1) -> i1
    %pair_not_ub_153 = "arith.xori"(%pair_ub_153, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_153 = "arith.andi"(%pair_rhs_nz_153, %pair_not_ub_153) : (i1, i1) -> i1
    %pair_val_153 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_153 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_153 = "transfer.cmp"(%pair_rem_153, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_153 = "arith.andi"(%pair_valid_sdiv_153, %pair_exact_153) : (i1, i1) -> i1
    %pair_val0_153 = "transfer.xor"(%pair_val_153, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_153 = "transfer.select"(%pair_valid_153, %pair_val0_153, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_153 = "transfer.select"(%pair_valid_153, %pair_val_153, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_153 = "transfer.and"(%pair_acc0_152, %pair_sel0_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_153 = "transfer.and"(%pair_acc1_152, %pair_sel1_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_153 = "arith.ori"(%pair_any_152, %pair_valid_153) : (i1, i1) -> i1
    %pair_rhs_nz_154 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_154 = "transfer.select"(%pair_rhs_nz_154, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_154 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_154 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_154 = "arith.andi"(%pair_lhs_eq_smin_154, %pair_rhs_eq_m1_154) : (i1, i1) -> i1
    %pair_not_ub_154 = "arith.xori"(%pair_ub_154, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_154 = "arith.andi"(%pair_rhs_nz_154, %pair_not_ub_154) : (i1, i1) -> i1
    %pair_val_154 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_154 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_154 = "transfer.cmp"(%pair_rem_154, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_154 = "arith.andi"(%pair_valid_sdiv_154, %pair_exact_154) : (i1, i1) -> i1
    %pair_val0_154 = "transfer.xor"(%pair_val_154, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_154 = "transfer.select"(%pair_valid_154, %pair_val0_154, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_154 = "transfer.select"(%pair_valid_154, %pair_val_154, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_154 = "transfer.and"(%pair_acc0_153, %pair_sel0_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_154 = "transfer.and"(%pair_acc1_153, %pair_sel1_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_154 = "arith.ori"(%pair_any_153, %pair_valid_154) : (i1, i1) -> i1
    %pair_rhs_nz_155 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_155 = "transfer.select"(%pair_rhs_nz_155, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_155 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_155 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_155 = "arith.andi"(%pair_lhs_eq_smin_155, %pair_rhs_eq_m1_155) : (i1, i1) -> i1
    %pair_not_ub_155 = "arith.xori"(%pair_ub_155, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_155 = "arith.andi"(%pair_rhs_nz_155, %pair_not_ub_155) : (i1, i1) -> i1
    %pair_val_155 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_155 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_155 = "transfer.cmp"(%pair_rem_155, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_155 = "arith.andi"(%pair_valid_sdiv_155, %pair_exact_155) : (i1, i1) -> i1
    %pair_val0_155 = "transfer.xor"(%pair_val_155, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_155 = "transfer.select"(%pair_valid_155, %pair_val0_155, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_155 = "transfer.select"(%pair_valid_155, %pair_val_155, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_155 = "transfer.and"(%pair_acc0_154, %pair_sel0_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_155 = "transfer.and"(%pair_acc1_154, %pair_sel1_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_155 = "arith.ori"(%pair_any_154, %pair_valid_155) : (i1, i1) -> i1
    %pair_rhs_nz_156 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_156 = "transfer.select"(%pair_rhs_nz_156, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_156 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_156 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_156 = "arith.andi"(%pair_lhs_eq_smin_156, %pair_rhs_eq_m1_156) : (i1, i1) -> i1
    %pair_not_ub_156 = "arith.xori"(%pair_ub_156, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_156 = "arith.andi"(%pair_rhs_nz_156, %pair_not_ub_156) : (i1, i1) -> i1
    %pair_val_156 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_156 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_156 = "transfer.cmp"(%pair_rem_156, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_156 = "arith.andi"(%pair_valid_sdiv_156, %pair_exact_156) : (i1, i1) -> i1
    %pair_val0_156 = "transfer.xor"(%pair_val_156, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_156 = "transfer.select"(%pair_valid_156, %pair_val0_156, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_156 = "transfer.select"(%pair_valid_156, %pair_val_156, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_156 = "transfer.and"(%pair_acc0_155, %pair_sel0_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_156 = "transfer.and"(%pair_acc1_155, %pair_sel1_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_156 = "arith.ori"(%pair_any_155, %pair_valid_156) : (i1, i1) -> i1
    %pair_rhs_nz_157 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_157 = "transfer.select"(%pair_rhs_nz_157, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_157 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_157 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_157 = "arith.andi"(%pair_lhs_eq_smin_157, %pair_rhs_eq_m1_157) : (i1, i1) -> i1
    %pair_not_ub_157 = "arith.xori"(%pair_ub_157, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_157 = "arith.andi"(%pair_rhs_nz_157, %pair_not_ub_157) : (i1, i1) -> i1
    %pair_val_157 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_157 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_157 = "transfer.cmp"(%pair_rem_157, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_157 = "arith.andi"(%pair_valid_sdiv_157, %pair_exact_157) : (i1, i1) -> i1
    %pair_val0_157 = "transfer.xor"(%pair_val_157, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_157 = "transfer.select"(%pair_valid_157, %pair_val0_157, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_157 = "transfer.select"(%pair_valid_157, %pair_val_157, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_157 = "transfer.and"(%pair_acc0_156, %pair_sel0_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_157 = "transfer.and"(%pair_acc1_156, %pair_sel1_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_157 = "arith.ori"(%pair_any_156, %pair_valid_157) : (i1, i1) -> i1
    %pair_rhs_nz_158 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_158 = "transfer.select"(%pair_rhs_nz_158, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_158 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_158 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_158 = "arith.andi"(%pair_lhs_eq_smin_158, %pair_rhs_eq_m1_158) : (i1, i1) -> i1
    %pair_not_ub_158 = "arith.xori"(%pair_ub_158, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_158 = "arith.andi"(%pair_rhs_nz_158, %pair_not_ub_158) : (i1, i1) -> i1
    %pair_val_158 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_158 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_158 = "transfer.cmp"(%pair_rem_158, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_158 = "arith.andi"(%pair_valid_sdiv_158, %pair_exact_158) : (i1, i1) -> i1
    %pair_val0_158 = "transfer.xor"(%pair_val_158, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_158 = "transfer.select"(%pair_valid_158, %pair_val0_158, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_158 = "transfer.select"(%pair_valid_158, %pair_val_158, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_158 = "transfer.and"(%pair_acc0_157, %pair_sel0_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_158 = "transfer.and"(%pair_acc1_157, %pair_sel1_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_158 = "arith.ori"(%pair_any_157, %pair_valid_158) : (i1, i1) -> i1
    %pair_rhs_nz_159 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_159 = "transfer.select"(%pair_rhs_nz_159, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_159 = "transfer.cmp"(%lhsu_v9, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_159 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_159 = "arith.andi"(%pair_lhs_eq_smin_159, %pair_rhs_eq_m1_159) : (i1, i1) -> i1
    %pair_not_ub_159 = "arith.xori"(%pair_ub_159, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_159 = "arith.andi"(%pair_rhs_nz_159, %pair_not_ub_159) : (i1, i1) -> i1
    %pair_val_159 = "transfer.sdiv"(%lhsu_v9, %pair_rhs_safe_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_159 = "transfer.srem"(%lhsu_v9, %pair_rhs_safe_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_159 = "transfer.cmp"(%pair_rem_159, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_159 = "arith.andi"(%pair_valid_sdiv_159, %pair_exact_159) : (i1, i1) -> i1
    %pair_val0_159 = "transfer.xor"(%pair_val_159, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_159 = "transfer.select"(%pair_valid_159, %pair_val0_159, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_159 = "transfer.select"(%pair_valid_159, %pair_val_159, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_159 = "transfer.and"(%pair_acc0_158, %pair_sel0_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_159 = "transfer.and"(%pair_acc1_158, %pair_sel1_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_159 = "arith.ori"(%pair_any_158, %pair_valid_159) : (i1, i1) -> i1
    %pair_rhs_nz_160 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_160 = "transfer.select"(%pair_rhs_nz_160, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_160 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_160 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_160 = "arith.andi"(%pair_lhs_eq_smin_160, %pair_rhs_eq_m1_160) : (i1, i1) -> i1
    %pair_not_ub_160 = "arith.xori"(%pair_ub_160, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_160 = "arith.andi"(%pair_rhs_nz_160, %pair_not_ub_160) : (i1, i1) -> i1
    %pair_val_160 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_160 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_160 = "transfer.cmp"(%pair_rem_160, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_160 = "arith.andi"(%pair_valid_sdiv_160, %pair_exact_160) : (i1, i1) -> i1
    %pair_val0_160 = "transfer.xor"(%pair_val_160, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_160 = "transfer.select"(%pair_valid_160, %pair_val0_160, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_160 = "transfer.select"(%pair_valid_160, %pair_val_160, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_160 = "transfer.and"(%pair_acc0_159, %pair_sel0_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_160 = "transfer.and"(%pair_acc1_159, %pair_sel1_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_160 = "arith.ori"(%pair_any_159, %pair_valid_160) : (i1, i1) -> i1
    %pair_rhs_nz_161 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_161 = "transfer.select"(%pair_rhs_nz_161, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_161 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_161 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_161 = "arith.andi"(%pair_lhs_eq_smin_161, %pair_rhs_eq_m1_161) : (i1, i1) -> i1
    %pair_not_ub_161 = "arith.xori"(%pair_ub_161, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_161 = "arith.andi"(%pair_rhs_nz_161, %pair_not_ub_161) : (i1, i1) -> i1
    %pair_val_161 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_161 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_161 = "transfer.cmp"(%pair_rem_161, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_161 = "arith.andi"(%pair_valid_sdiv_161, %pair_exact_161) : (i1, i1) -> i1
    %pair_val0_161 = "transfer.xor"(%pair_val_161, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_161 = "transfer.select"(%pair_valid_161, %pair_val0_161, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_161 = "transfer.select"(%pair_valid_161, %pair_val_161, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_161 = "transfer.and"(%pair_acc0_160, %pair_sel0_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_161 = "transfer.and"(%pair_acc1_160, %pair_sel1_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_161 = "arith.ori"(%pair_any_160, %pair_valid_161) : (i1, i1) -> i1
    %pair_rhs_nz_162 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_162 = "transfer.select"(%pair_rhs_nz_162, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_162 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_162 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_162 = "arith.andi"(%pair_lhs_eq_smin_162, %pair_rhs_eq_m1_162) : (i1, i1) -> i1
    %pair_not_ub_162 = "arith.xori"(%pair_ub_162, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_162 = "arith.andi"(%pair_rhs_nz_162, %pair_not_ub_162) : (i1, i1) -> i1
    %pair_val_162 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_162 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_162 = "transfer.cmp"(%pair_rem_162, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_162 = "arith.andi"(%pair_valid_sdiv_162, %pair_exact_162) : (i1, i1) -> i1
    %pair_val0_162 = "transfer.xor"(%pair_val_162, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_162 = "transfer.select"(%pair_valid_162, %pair_val0_162, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_162 = "transfer.select"(%pair_valid_162, %pair_val_162, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_162 = "transfer.and"(%pair_acc0_161, %pair_sel0_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_162 = "transfer.and"(%pair_acc1_161, %pair_sel1_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_162 = "arith.ori"(%pair_any_161, %pair_valid_162) : (i1, i1) -> i1
    %pair_rhs_nz_163 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_163 = "transfer.select"(%pair_rhs_nz_163, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_163 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_163 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_163 = "arith.andi"(%pair_lhs_eq_smin_163, %pair_rhs_eq_m1_163) : (i1, i1) -> i1
    %pair_not_ub_163 = "arith.xori"(%pair_ub_163, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_163 = "arith.andi"(%pair_rhs_nz_163, %pair_not_ub_163) : (i1, i1) -> i1
    %pair_val_163 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_163 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_163 = "transfer.cmp"(%pair_rem_163, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_163 = "arith.andi"(%pair_valid_sdiv_163, %pair_exact_163) : (i1, i1) -> i1
    %pair_val0_163 = "transfer.xor"(%pair_val_163, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_163 = "transfer.select"(%pair_valid_163, %pair_val0_163, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_163 = "transfer.select"(%pair_valid_163, %pair_val_163, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_163 = "transfer.and"(%pair_acc0_162, %pair_sel0_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_163 = "transfer.and"(%pair_acc1_162, %pair_sel1_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_163 = "arith.ori"(%pair_any_162, %pair_valid_163) : (i1, i1) -> i1
    %pair_rhs_nz_164 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_164 = "transfer.select"(%pair_rhs_nz_164, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_164 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_164 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_164 = "arith.andi"(%pair_lhs_eq_smin_164, %pair_rhs_eq_m1_164) : (i1, i1) -> i1
    %pair_not_ub_164 = "arith.xori"(%pair_ub_164, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_164 = "arith.andi"(%pair_rhs_nz_164, %pair_not_ub_164) : (i1, i1) -> i1
    %pair_val_164 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_164 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_164 = "transfer.cmp"(%pair_rem_164, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_164 = "arith.andi"(%pair_valid_sdiv_164, %pair_exact_164) : (i1, i1) -> i1
    %pair_val0_164 = "transfer.xor"(%pair_val_164, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_164 = "transfer.select"(%pair_valid_164, %pair_val0_164, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_164 = "transfer.select"(%pair_valid_164, %pair_val_164, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_164 = "transfer.and"(%pair_acc0_163, %pair_sel0_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_164 = "transfer.and"(%pair_acc1_163, %pair_sel1_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_164 = "arith.ori"(%pair_any_163, %pair_valid_164) : (i1, i1) -> i1
    %pair_rhs_nz_165 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_165 = "transfer.select"(%pair_rhs_nz_165, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_165 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_165 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_165 = "arith.andi"(%pair_lhs_eq_smin_165, %pair_rhs_eq_m1_165) : (i1, i1) -> i1
    %pair_not_ub_165 = "arith.xori"(%pair_ub_165, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_165 = "arith.andi"(%pair_rhs_nz_165, %pair_not_ub_165) : (i1, i1) -> i1
    %pair_val_165 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_165 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_165 = "transfer.cmp"(%pair_rem_165, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_165 = "arith.andi"(%pair_valid_sdiv_165, %pair_exact_165) : (i1, i1) -> i1
    %pair_val0_165 = "transfer.xor"(%pair_val_165, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_165 = "transfer.select"(%pair_valid_165, %pair_val0_165, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_165 = "transfer.select"(%pair_valid_165, %pair_val_165, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_165 = "transfer.and"(%pair_acc0_164, %pair_sel0_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_165 = "transfer.and"(%pair_acc1_164, %pair_sel1_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_165 = "arith.ori"(%pair_any_164, %pair_valid_165) : (i1, i1) -> i1
    %pair_rhs_nz_166 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_166 = "transfer.select"(%pair_rhs_nz_166, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_166 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_166 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_166 = "arith.andi"(%pair_lhs_eq_smin_166, %pair_rhs_eq_m1_166) : (i1, i1) -> i1
    %pair_not_ub_166 = "arith.xori"(%pair_ub_166, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_166 = "arith.andi"(%pair_rhs_nz_166, %pair_not_ub_166) : (i1, i1) -> i1
    %pair_val_166 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_166 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_166 = "transfer.cmp"(%pair_rem_166, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_166 = "arith.andi"(%pair_valid_sdiv_166, %pair_exact_166) : (i1, i1) -> i1
    %pair_val0_166 = "transfer.xor"(%pair_val_166, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_166 = "transfer.select"(%pair_valid_166, %pair_val0_166, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_166 = "transfer.select"(%pair_valid_166, %pair_val_166, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_166 = "transfer.and"(%pair_acc0_165, %pair_sel0_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_166 = "transfer.and"(%pair_acc1_165, %pair_sel1_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_166 = "arith.ori"(%pair_any_165, %pair_valid_166) : (i1, i1) -> i1
    %pair_rhs_nz_167 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_167 = "transfer.select"(%pair_rhs_nz_167, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_167 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_167 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_167 = "arith.andi"(%pair_lhs_eq_smin_167, %pair_rhs_eq_m1_167) : (i1, i1) -> i1
    %pair_not_ub_167 = "arith.xori"(%pair_ub_167, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_167 = "arith.andi"(%pair_rhs_nz_167, %pair_not_ub_167) : (i1, i1) -> i1
    %pair_val_167 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_167 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_167 = "transfer.cmp"(%pair_rem_167, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_167 = "arith.andi"(%pair_valid_sdiv_167, %pair_exact_167) : (i1, i1) -> i1
    %pair_val0_167 = "transfer.xor"(%pair_val_167, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_167 = "transfer.select"(%pair_valid_167, %pair_val0_167, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_167 = "transfer.select"(%pair_valid_167, %pair_val_167, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_167 = "transfer.and"(%pair_acc0_166, %pair_sel0_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_167 = "transfer.and"(%pair_acc1_166, %pair_sel1_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_167 = "arith.ori"(%pair_any_166, %pair_valid_167) : (i1, i1) -> i1
    %pair_rhs_nz_168 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_168 = "transfer.select"(%pair_rhs_nz_168, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_168 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_168 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_168 = "arith.andi"(%pair_lhs_eq_smin_168, %pair_rhs_eq_m1_168) : (i1, i1) -> i1
    %pair_not_ub_168 = "arith.xori"(%pair_ub_168, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_168 = "arith.andi"(%pair_rhs_nz_168, %pair_not_ub_168) : (i1, i1) -> i1
    %pair_val_168 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_168 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_168 = "transfer.cmp"(%pair_rem_168, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_168 = "arith.andi"(%pair_valid_sdiv_168, %pair_exact_168) : (i1, i1) -> i1
    %pair_val0_168 = "transfer.xor"(%pair_val_168, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_168 = "transfer.select"(%pair_valid_168, %pair_val0_168, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_168 = "transfer.select"(%pair_valid_168, %pair_val_168, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_168 = "transfer.and"(%pair_acc0_167, %pair_sel0_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_168 = "transfer.and"(%pair_acc1_167, %pair_sel1_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_168 = "arith.ori"(%pair_any_167, %pair_valid_168) : (i1, i1) -> i1
    %pair_rhs_nz_169 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_169 = "transfer.select"(%pair_rhs_nz_169, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_169 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_169 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_169 = "arith.andi"(%pair_lhs_eq_smin_169, %pair_rhs_eq_m1_169) : (i1, i1) -> i1
    %pair_not_ub_169 = "arith.xori"(%pair_ub_169, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_169 = "arith.andi"(%pair_rhs_nz_169, %pair_not_ub_169) : (i1, i1) -> i1
    %pair_val_169 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_169 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_169 = "transfer.cmp"(%pair_rem_169, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_169 = "arith.andi"(%pair_valid_sdiv_169, %pair_exact_169) : (i1, i1) -> i1
    %pair_val0_169 = "transfer.xor"(%pair_val_169, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_169 = "transfer.select"(%pair_valid_169, %pair_val0_169, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_169 = "transfer.select"(%pair_valid_169, %pair_val_169, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_169 = "transfer.and"(%pair_acc0_168, %pair_sel0_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_169 = "transfer.and"(%pair_acc1_168, %pair_sel1_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_169 = "arith.ori"(%pair_any_168, %pair_valid_169) : (i1, i1) -> i1
    %pair_rhs_nz_170 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_170 = "transfer.select"(%pair_rhs_nz_170, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_170 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_170 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_170 = "arith.andi"(%pair_lhs_eq_smin_170, %pair_rhs_eq_m1_170) : (i1, i1) -> i1
    %pair_not_ub_170 = "arith.xori"(%pair_ub_170, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_170 = "arith.andi"(%pair_rhs_nz_170, %pair_not_ub_170) : (i1, i1) -> i1
    %pair_val_170 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_170 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_170 = "transfer.cmp"(%pair_rem_170, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_170 = "arith.andi"(%pair_valid_sdiv_170, %pair_exact_170) : (i1, i1) -> i1
    %pair_val0_170 = "transfer.xor"(%pair_val_170, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_170 = "transfer.select"(%pair_valid_170, %pair_val0_170, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_170 = "transfer.select"(%pair_valid_170, %pair_val_170, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_170 = "transfer.and"(%pair_acc0_169, %pair_sel0_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_170 = "transfer.and"(%pair_acc1_169, %pair_sel1_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_170 = "arith.ori"(%pair_any_169, %pair_valid_170) : (i1, i1) -> i1
    %pair_rhs_nz_171 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_171 = "transfer.select"(%pair_rhs_nz_171, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_171 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_171 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_171 = "arith.andi"(%pair_lhs_eq_smin_171, %pair_rhs_eq_m1_171) : (i1, i1) -> i1
    %pair_not_ub_171 = "arith.xori"(%pair_ub_171, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_171 = "arith.andi"(%pair_rhs_nz_171, %pair_not_ub_171) : (i1, i1) -> i1
    %pair_val_171 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_171 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_171 = "transfer.cmp"(%pair_rem_171, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_171 = "arith.andi"(%pair_valid_sdiv_171, %pair_exact_171) : (i1, i1) -> i1
    %pair_val0_171 = "transfer.xor"(%pair_val_171, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_171 = "transfer.select"(%pair_valid_171, %pair_val0_171, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_171 = "transfer.select"(%pair_valid_171, %pair_val_171, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_171 = "transfer.and"(%pair_acc0_170, %pair_sel0_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_171 = "transfer.and"(%pair_acc1_170, %pair_sel1_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_171 = "arith.ori"(%pair_any_170, %pair_valid_171) : (i1, i1) -> i1
    %pair_rhs_nz_172 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_172 = "transfer.select"(%pair_rhs_nz_172, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_172 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_172 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_172 = "arith.andi"(%pair_lhs_eq_smin_172, %pair_rhs_eq_m1_172) : (i1, i1) -> i1
    %pair_not_ub_172 = "arith.xori"(%pair_ub_172, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_172 = "arith.andi"(%pair_rhs_nz_172, %pair_not_ub_172) : (i1, i1) -> i1
    %pair_val_172 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_172 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_172 = "transfer.cmp"(%pair_rem_172, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_172 = "arith.andi"(%pair_valid_sdiv_172, %pair_exact_172) : (i1, i1) -> i1
    %pair_val0_172 = "transfer.xor"(%pair_val_172, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_172 = "transfer.select"(%pair_valid_172, %pair_val0_172, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_172 = "transfer.select"(%pair_valid_172, %pair_val_172, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_172 = "transfer.and"(%pair_acc0_171, %pair_sel0_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_172 = "transfer.and"(%pair_acc1_171, %pair_sel1_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_172 = "arith.ori"(%pair_any_171, %pair_valid_172) : (i1, i1) -> i1
    %pair_rhs_nz_173 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_173 = "transfer.select"(%pair_rhs_nz_173, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_173 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_173 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_173 = "arith.andi"(%pair_lhs_eq_smin_173, %pair_rhs_eq_m1_173) : (i1, i1) -> i1
    %pair_not_ub_173 = "arith.xori"(%pair_ub_173, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_173 = "arith.andi"(%pair_rhs_nz_173, %pair_not_ub_173) : (i1, i1) -> i1
    %pair_val_173 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_173 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_173 = "transfer.cmp"(%pair_rem_173, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_173 = "arith.andi"(%pair_valid_sdiv_173, %pair_exact_173) : (i1, i1) -> i1
    %pair_val0_173 = "transfer.xor"(%pair_val_173, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_173 = "transfer.select"(%pair_valid_173, %pair_val0_173, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_173 = "transfer.select"(%pair_valid_173, %pair_val_173, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_173 = "transfer.and"(%pair_acc0_172, %pair_sel0_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_173 = "transfer.and"(%pair_acc1_172, %pair_sel1_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_173 = "arith.ori"(%pair_any_172, %pair_valid_173) : (i1, i1) -> i1
    %pair_rhs_nz_174 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_174 = "transfer.select"(%pair_rhs_nz_174, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_174 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_174 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_174 = "arith.andi"(%pair_lhs_eq_smin_174, %pair_rhs_eq_m1_174) : (i1, i1) -> i1
    %pair_not_ub_174 = "arith.xori"(%pair_ub_174, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_174 = "arith.andi"(%pair_rhs_nz_174, %pair_not_ub_174) : (i1, i1) -> i1
    %pair_val_174 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_174 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_174 = "transfer.cmp"(%pair_rem_174, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_174 = "arith.andi"(%pair_valid_sdiv_174, %pair_exact_174) : (i1, i1) -> i1
    %pair_val0_174 = "transfer.xor"(%pair_val_174, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_174 = "transfer.select"(%pair_valid_174, %pair_val0_174, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_174 = "transfer.select"(%pair_valid_174, %pair_val_174, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_174 = "transfer.and"(%pair_acc0_173, %pair_sel0_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_174 = "transfer.and"(%pair_acc1_173, %pair_sel1_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_174 = "arith.ori"(%pair_any_173, %pair_valid_174) : (i1, i1) -> i1
    %pair_rhs_nz_175 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_175 = "transfer.select"(%pair_rhs_nz_175, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_175 = "transfer.cmp"(%lhsu_v10, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_175 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_175 = "arith.andi"(%pair_lhs_eq_smin_175, %pair_rhs_eq_m1_175) : (i1, i1) -> i1
    %pair_not_ub_175 = "arith.xori"(%pair_ub_175, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_175 = "arith.andi"(%pair_rhs_nz_175, %pair_not_ub_175) : (i1, i1) -> i1
    %pair_val_175 = "transfer.sdiv"(%lhsu_v10, %pair_rhs_safe_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_175 = "transfer.srem"(%lhsu_v10, %pair_rhs_safe_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_175 = "transfer.cmp"(%pair_rem_175, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_175 = "arith.andi"(%pair_valid_sdiv_175, %pair_exact_175) : (i1, i1) -> i1
    %pair_val0_175 = "transfer.xor"(%pair_val_175, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_175 = "transfer.select"(%pair_valid_175, %pair_val0_175, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_175 = "transfer.select"(%pair_valid_175, %pair_val_175, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_175 = "transfer.and"(%pair_acc0_174, %pair_sel0_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_175 = "transfer.and"(%pair_acc1_174, %pair_sel1_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_175 = "arith.ori"(%pair_any_174, %pair_valid_175) : (i1, i1) -> i1
    %pair_rhs_nz_176 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_176 = "transfer.select"(%pair_rhs_nz_176, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_176 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_176 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_176 = "arith.andi"(%pair_lhs_eq_smin_176, %pair_rhs_eq_m1_176) : (i1, i1) -> i1
    %pair_not_ub_176 = "arith.xori"(%pair_ub_176, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_176 = "arith.andi"(%pair_rhs_nz_176, %pair_not_ub_176) : (i1, i1) -> i1
    %pair_val_176 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_176 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_176 = "transfer.cmp"(%pair_rem_176, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_176 = "arith.andi"(%pair_valid_sdiv_176, %pair_exact_176) : (i1, i1) -> i1
    %pair_val0_176 = "transfer.xor"(%pair_val_176, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_176 = "transfer.select"(%pair_valid_176, %pair_val0_176, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_176 = "transfer.select"(%pair_valid_176, %pair_val_176, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_176 = "transfer.and"(%pair_acc0_175, %pair_sel0_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_176 = "transfer.and"(%pair_acc1_175, %pair_sel1_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_176 = "arith.ori"(%pair_any_175, %pair_valid_176) : (i1, i1) -> i1
    %pair_rhs_nz_177 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_177 = "transfer.select"(%pair_rhs_nz_177, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_177 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_177 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_177 = "arith.andi"(%pair_lhs_eq_smin_177, %pair_rhs_eq_m1_177) : (i1, i1) -> i1
    %pair_not_ub_177 = "arith.xori"(%pair_ub_177, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_177 = "arith.andi"(%pair_rhs_nz_177, %pair_not_ub_177) : (i1, i1) -> i1
    %pair_val_177 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_177 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_177 = "transfer.cmp"(%pair_rem_177, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_177 = "arith.andi"(%pair_valid_sdiv_177, %pair_exact_177) : (i1, i1) -> i1
    %pair_val0_177 = "transfer.xor"(%pair_val_177, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_177 = "transfer.select"(%pair_valid_177, %pair_val0_177, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_177 = "transfer.select"(%pair_valid_177, %pair_val_177, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_177 = "transfer.and"(%pair_acc0_176, %pair_sel0_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_177 = "transfer.and"(%pair_acc1_176, %pair_sel1_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_177 = "arith.ori"(%pair_any_176, %pair_valid_177) : (i1, i1) -> i1
    %pair_rhs_nz_178 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_178 = "transfer.select"(%pair_rhs_nz_178, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_178 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_178 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_178 = "arith.andi"(%pair_lhs_eq_smin_178, %pair_rhs_eq_m1_178) : (i1, i1) -> i1
    %pair_not_ub_178 = "arith.xori"(%pair_ub_178, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_178 = "arith.andi"(%pair_rhs_nz_178, %pair_not_ub_178) : (i1, i1) -> i1
    %pair_val_178 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_178 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_178 = "transfer.cmp"(%pair_rem_178, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_178 = "arith.andi"(%pair_valid_sdiv_178, %pair_exact_178) : (i1, i1) -> i1
    %pair_val0_178 = "transfer.xor"(%pair_val_178, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_178 = "transfer.select"(%pair_valid_178, %pair_val0_178, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_178 = "transfer.select"(%pair_valid_178, %pair_val_178, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_178 = "transfer.and"(%pair_acc0_177, %pair_sel0_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_178 = "transfer.and"(%pair_acc1_177, %pair_sel1_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_178 = "arith.ori"(%pair_any_177, %pair_valid_178) : (i1, i1) -> i1
    %pair_rhs_nz_179 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_179 = "transfer.select"(%pair_rhs_nz_179, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_179 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_179 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_179 = "arith.andi"(%pair_lhs_eq_smin_179, %pair_rhs_eq_m1_179) : (i1, i1) -> i1
    %pair_not_ub_179 = "arith.xori"(%pair_ub_179, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_179 = "arith.andi"(%pair_rhs_nz_179, %pair_not_ub_179) : (i1, i1) -> i1
    %pair_val_179 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_179 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_179 = "transfer.cmp"(%pair_rem_179, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_179 = "arith.andi"(%pair_valid_sdiv_179, %pair_exact_179) : (i1, i1) -> i1
    %pair_val0_179 = "transfer.xor"(%pair_val_179, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_179 = "transfer.select"(%pair_valid_179, %pair_val0_179, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_179 = "transfer.select"(%pair_valid_179, %pair_val_179, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_179 = "transfer.and"(%pair_acc0_178, %pair_sel0_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_179 = "transfer.and"(%pair_acc1_178, %pair_sel1_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_179 = "arith.ori"(%pair_any_178, %pair_valid_179) : (i1, i1) -> i1
    %pair_rhs_nz_180 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_180 = "transfer.select"(%pair_rhs_nz_180, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_180 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_180 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_180 = "arith.andi"(%pair_lhs_eq_smin_180, %pair_rhs_eq_m1_180) : (i1, i1) -> i1
    %pair_not_ub_180 = "arith.xori"(%pair_ub_180, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_180 = "arith.andi"(%pair_rhs_nz_180, %pair_not_ub_180) : (i1, i1) -> i1
    %pair_val_180 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_180 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_180 = "transfer.cmp"(%pair_rem_180, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_180 = "arith.andi"(%pair_valid_sdiv_180, %pair_exact_180) : (i1, i1) -> i1
    %pair_val0_180 = "transfer.xor"(%pair_val_180, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_180 = "transfer.select"(%pair_valid_180, %pair_val0_180, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_180 = "transfer.select"(%pair_valid_180, %pair_val_180, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_180 = "transfer.and"(%pair_acc0_179, %pair_sel0_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_180 = "transfer.and"(%pair_acc1_179, %pair_sel1_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_180 = "arith.ori"(%pair_any_179, %pair_valid_180) : (i1, i1) -> i1
    %pair_rhs_nz_181 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_181 = "transfer.select"(%pair_rhs_nz_181, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_181 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_181 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_181 = "arith.andi"(%pair_lhs_eq_smin_181, %pair_rhs_eq_m1_181) : (i1, i1) -> i1
    %pair_not_ub_181 = "arith.xori"(%pair_ub_181, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_181 = "arith.andi"(%pair_rhs_nz_181, %pair_not_ub_181) : (i1, i1) -> i1
    %pair_val_181 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_181 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_181 = "transfer.cmp"(%pair_rem_181, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_181 = "arith.andi"(%pair_valid_sdiv_181, %pair_exact_181) : (i1, i1) -> i1
    %pair_val0_181 = "transfer.xor"(%pair_val_181, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_181 = "transfer.select"(%pair_valid_181, %pair_val0_181, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_181 = "transfer.select"(%pair_valid_181, %pair_val_181, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_181 = "transfer.and"(%pair_acc0_180, %pair_sel0_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_181 = "transfer.and"(%pair_acc1_180, %pair_sel1_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_181 = "arith.ori"(%pair_any_180, %pair_valid_181) : (i1, i1) -> i1
    %pair_rhs_nz_182 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_182 = "transfer.select"(%pair_rhs_nz_182, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_182 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_182 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_182 = "arith.andi"(%pair_lhs_eq_smin_182, %pair_rhs_eq_m1_182) : (i1, i1) -> i1
    %pair_not_ub_182 = "arith.xori"(%pair_ub_182, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_182 = "arith.andi"(%pair_rhs_nz_182, %pair_not_ub_182) : (i1, i1) -> i1
    %pair_val_182 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_182 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_182 = "transfer.cmp"(%pair_rem_182, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_182 = "arith.andi"(%pair_valid_sdiv_182, %pair_exact_182) : (i1, i1) -> i1
    %pair_val0_182 = "transfer.xor"(%pair_val_182, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_182 = "transfer.select"(%pair_valid_182, %pair_val0_182, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_182 = "transfer.select"(%pair_valid_182, %pair_val_182, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_182 = "transfer.and"(%pair_acc0_181, %pair_sel0_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_182 = "transfer.and"(%pair_acc1_181, %pair_sel1_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_182 = "arith.ori"(%pair_any_181, %pair_valid_182) : (i1, i1) -> i1
    %pair_rhs_nz_183 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_183 = "transfer.select"(%pair_rhs_nz_183, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_183 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_183 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_183 = "arith.andi"(%pair_lhs_eq_smin_183, %pair_rhs_eq_m1_183) : (i1, i1) -> i1
    %pair_not_ub_183 = "arith.xori"(%pair_ub_183, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_183 = "arith.andi"(%pair_rhs_nz_183, %pair_not_ub_183) : (i1, i1) -> i1
    %pair_val_183 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_183 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_183 = "transfer.cmp"(%pair_rem_183, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_183 = "arith.andi"(%pair_valid_sdiv_183, %pair_exact_183) : (i1, i1) -> i1
    %pair_val0_183 = "transfer.xor"(%pair_val_183, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_183 = "transfer.select"(%pair_valid_183, %pair_val0_183, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_183 = "transfer.select"(%pair_valid_183, %pair_val_183, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_183 = "transfer.and"(%pair_acc0_182, %pair_sel0_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_183 = "transfer.and"(%pair_acc1_182, %pair_sel1_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_183 = "arith.ori"(%pair_any_182, %pair_valid_183) : (i1, i1) -> i1
    %pair_rhs_nz_184 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_184 = "transfer.select"(%pair_rhs_nz_184, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_184 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_184 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_184 = "arith.andi"(%pair_lhs_eq_smin_184, %pair_rhs_eq_m1_184) : (i1, i1) -> i1
    %pair_not_ub_184 = "arith.xori"(%pair_ub_184, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_184 = "arith.andi"(%pair_rhs_nz_184, %pair_not_ub_184) : (i1, i1) -> i1
    %pair_val_184 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_184 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_184 = "transfer.cmp"(%pair_rem_184, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_184 = "arith.andi"(%pair_valid_sdiv_184, %pair_exact_184) : (i1, i1) -> i1
    %pair_val0_184 = "transfer.xor"(%pair_val_184, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_184 = "transfer.select"(%pair_valid_184, %pair_val0_184, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_184 = "transfer.select"(%pair_valid_184, %pair_val_184, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_184 = "transfer.and"(%pair_acc0_183, %pair_sel0_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_184 = "transfer.and"(%pair_acc1_183, %pair_sel1_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_184 = "arith.ori"(%pair_any_183, %pair_valid_184) : (i1, i1) -> i1
    %pair_rhs_nz_185 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_185 = "transfer.select"(%pair_rhs_nz_185, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_185 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_185 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_185 = "arith.andi"(%pair_lhs_eq_smin_185, %pair_rhs_eq_m1_185) : (i1, i1) -> i1
    %pair_not_ub_185 = "arith.xori"(%pair_ub_185, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_185 = "arith.andi"(%pair_rhs_nz_185, %pair_not_ub_185) : (i1, i1) -> i1
    %pair_val_185 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_185 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_185 = "transfer.cmp"(%pair_rem_185, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_185 = "arith.andi"(%pair_valid_sdiv_185, %pair_exact_185) : (i1, i1) -> i1
    %pair_val0_185 = "transfer.xor"(%pair_val_185, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_185 = "transfer.select"(%pair_valid_185, %pair_val0_185, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_185 = "transfer.select"(%pair_valid_185, %pair_val_185, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_185 = "transfer.and"(%pair_acc0_184, %pair_sel0_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_185 = "transfer.and"(%pair_acc1_184, %pair_sel1_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_185 = "arith.ori"(%pair_any_184, %pair_valid_185) : (i1, i1) -> i1
    %pair_rhs_nz_186 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_186 = "transfer.select"(%pair_rhs_nz_186, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_186 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_186 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_186 = "arith.andi"(%pair_lhs_eq_smin_186, %pair_rhs_eq_m1_186) : (i1, i1) -> i1
    %pair_not_ub_186 = "arith.xori"(%pair_ub_186, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_186 = "arith.andi"(%pair_rhs_nz_186, %pair_not_ub_186) : (i1, i1) -> i1
    %pair_val_186 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_186 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_186 = "transfer.cmp"(%pair_rem_186, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_186 = "arith.andi"(%pair_valid_sdiv_186, %pair_exact_186) : (i1, i1) -> i1
    %pair_val0_186 = "transfer.xor"(%pair_val_186, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_186 = "transfer.select"(%pair_valid_186, %pair_val0_186, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_186 = "transfer.select"(%pair_valid_186, %pair_val_186, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_186 = "transfer.and"(%pair_acc0_185, %pair_sel0_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_186 = "transfer.and"(%pair_acc1_185, %pair_sel1_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_186 = "arith.ori"(%pair_any_185, %pair_valid_186) : (i1, i1) -> i1
    %pair_rhs_nz_187 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_187 = "transfer.select"(%pair_rhs_nz_187, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_187 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_187 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_187 = "arith.andi"(%pair_lhs_eq_smin_187, %pair_rhs_eq_m1_187) : (i1, i1) -> i1
    %pair_not_ub_187 = "arith.xori"(%pair_ub_187, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_187 = "arith.andi"(%pair_rhs_nz_187, %pair_not_ub_187) : (i1, i1) -> i1
    %pair_val_187 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_187 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_187 = "transfer.cmp"(%pair_rem_187, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_187 = "arith.andi"(%pair_valid_sdiv_187, %pair_exact_187) : (i1, i1) -> i1
    %pair_val0_187 = "transfer.xor"(%pair_val_187, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_187 = "transfer.select"(%pair_valid_187, %pair_val0_187, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_187 = "transfer.select"(%pair_valid_187, %pair_val_187, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_187 = "transfer.and"(%pair_acc0_186, %pair_sel0_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_187 = "transfer.and"(%pair_acc1_186, %pair_sel1_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_187 = "arith.ori"(%pair_any_186, %pair_valid_187) : (i1, i1) -> i1
    %pair_rhs_nz_188 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_188 = "transfer.select"(%pair_rhs_nz_188, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_188 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_188 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_188 = "arith.andi"(%pair_lhs_eq_smin_188, %pair_rhs_eq_m1_188) : (i1, i1) -> i1
    %pair_not_ub_188 = "arith.xori"(%pair_ub_188, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_188 = "arith.andi"(%pair_rhs_nz_188, %pair_not_ub_188) : (i1, i1) -> i1
    %pair_val_188 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_188 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_188 = "transfer.cmp"(%pair_rem_188, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_188 = "arith.andi"(%pair_valid_sdiv_188, %pair_exact_188) : (i1, i1) -> i1
    %pair_val0_188 = "transfer.xor"(%pair_val_188, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_188 = "transfer.select"(%pair_valid_188, %pair_val0_188, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_188 = "transfer.select"(%pair_valid_188, %pair_val_188, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_188 = "transfer.and"(%pair_acc0_187, %pair_sel0_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_188 = "transfer.and"(%pair_acc1_187, %pair_sel1_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_188 = "arith.ori"(%pair_any_187, %pair_valid_188) : (i1, i1) -> i1
    %pair_rhs_nz_189 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_189 = "transfer.select"(%pair_rhs_nz_189, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_189 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_189 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_189 = "arith.andi"(%pair_lhs_eq_smin_189, %pair_rhs_eq_m1_189) : (i1, i1) -> i1
    %pair_not_ub_189 = "arith.xori"(%pair_ub_189, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_189 = "arith.andi"(%pair_rhs_nz_189, %pair_not_ub_189) : (i1, i1) -> i1
    %pair_val_189 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_189 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_189 = "transfer.cmp"(%pair_rem_189, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_189 = "arith.andi"(%pair_valid_sdiv_189, %pair_exact_189) : (i1, i1) -> i1
    %pair_val0_189 = "transfer.xor"(%pair_val_189, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_189 = "transfer.select"(%pair_valid_189, %pair_val0_189, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_189 = "transfer.select"(%pair_valid_189, %pair_val_189, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_189 = "transfer.and"(%pair_acc0_188, %pair_sel0_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_189 = "transfer.and"(%pair_acc1_188, %pair_sel1_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_189 = "arith.ori"(%pair_any_188, %pair_valid_189) : (i1, i1) -> i1
    %pair_rhs_nz_190 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_190 = "transfer.select"(%pair_rhs_nz_190, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_190 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_190 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_190 = "arith.andi"(%pair_lhs_eq_smin_190, %pair_rhs_eq_m1_190) : (i1, i1) -> i1
    %pair_not_ub_190 = "arith.xori"(%pair_ub_190, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_190 = "arith.andi"(%pair_rhs_nz_190, %pair_not_ub_190) : (i1, i1) -> i1
    %pair_val_190 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_190 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_190 = "transfer.cmp"(%pair_rem_190, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_190 = "arith.andi"(%pair_valid_sdiv_190, %pair_exact_190) : (i1, i1) -> i1
    %pair_val0_190 = "transfer.xor"(%pair_val_190, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_190 = "transfer.select"(%pair_valid_190, %pair_val0_190, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_190 = "transfer.select"(%pair_valid_190, %pair_val_190, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_190 = "transfer.and"(%pair_acc0_189, %pair_sel0_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_190 = "transfer.and"(%pair_acc1_189, %pair_sel1_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_190 = "arith.ori"(%pair_any_189, %pair_valid_190) : (i1, i1) -> i1
    %pair_rhs_nz_191 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_191 = "transfer.select"(%pair_rhs_nz_191, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_191 = "transfer.cmp"(%lhsu_v11, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_191 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_191 = "arith.andi"(%pair_lhs_eq_smin_191, %pair_rhs_eq_m1_191) : (i1, i1) -> i1
    %pair_not_ub_191 = "arith.xori"(%pair_ub_191, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_191 = "arith.andi"(%pair_rhs_nz_191, %pair_not_ub_191) : (i1, i1) -> i1
    %pair_val_191 = "transfer.sdiv"(%lhsu_v11, %pair_rhs_safe_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_191 = "transfer.srem"(%lhsu_v11, %pair_rhs_safe_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_191 = "transfer.cmp"(%pair_rem_191, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_191 = "arith.andi"(%pair_valid_sdiv_191, %pair_exact_191) : (i1, i1) -> i1
    %pair_val0_191 = "transfer.xor"(%pair_val_191, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_191 = "transfer.select"(%pair_valid_191, %pair_val0_191, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_191 = "transfer.select"(%pair_valid_191, %pair_val_191, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_191 = "transfer.and"(%pair_acc0_190, %pair_sel0_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_191 = "transfer.and"(%pair_acc1_190, %pair_sel1_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_191 = "arith.ori"(%pair_any_190, %pair_valid_191) : (i1, i1) -> i1
    %pair_rhs_nz_192 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_192 = "transfer.select"(%pair_rhs_nz_192, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_192 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_192 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_192 = "arith.andi"(%pair_lhs_eq_smin_192, %pair_rhs_eq_m1_192) : (i1, i1) -> i1
    %pair_not_ub_192 = "arith.xori"(%pair_ub_192, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_192 = "arith.andi"(%pair_rhs_nz_192, %pair_not_ub_192) : (i1, i1) -> i1
    %pair_val_192 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_192 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_192 = "transfer.cmp"(%pair_rem_192, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_192 = "arith.andi"(%pair_valid_sdiv_192, %pair_exact_192) : (i1, i1) -> i1
    %pair_val0_192 = "transfer.xor"(%pair_val_192, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_192 = "transfer.select"(%pair_valid_192, %pair_val0_192, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_192 = "transfer.select"(%pair_valid_192, %pair_val_192, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_192 = "transfer.and"(%pair_acc0_191, %pair_sel0_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_192 = "transfer.and"(%pair_acc1_191, %pair_sel1_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_192 = "arith.ori"(%pair_any_191, %pair_valid_192) : (i1, i1) -> i1
    %pair_rhs_nz_193 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_193 = "transfer.select"(%pair_rhs_nz_193, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_193 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_193 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_193 = "arith.andi"(%pair_lhs_eq_smin_193, %pair_rhs_eq_m1_193) : (i1, i1) -> i1
    %pair_not_ub_193 = "arith.xori"(%pair_ub_193, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_193 = "arith.andi"(%pair_rhs_nz_193, %pair_not_ub_193) : (i1, i1) -> i1
    %pair_val_193 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_193 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_193 = "transfer.cmp"(%pair_rem_193, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_193 = "arith.andi"(%pair_valid_sdiv_193, %pair_exact_193) : (i1, i1) -> i1
    %pair_val0_193 = "transfer.xor"(%pair_val_193, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_193 = "transfer.select"(%pair_valid_193, %pair_val0_193, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_193 = "transfer.select"(%pair_valid_193, %pair_val_193, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_193 = "transfer.and"(%pair_acc0_192, %pair_sel0_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_193 = "transfer.and"(%pair_acc1_192, %pair_sel1_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_193 = "arith.ori"(%pair_any_192, %pair_valid_193) : (i1, i1) -> i1
    %pair_rhs_nz_194 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_194 = "transfer.select"(%pair_rhs_nz_194, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_194 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_194 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_194 = "arith.andi"(%pair_lhs_eq_smin_194, %pair_rhs_eq_m1_194) : (i1, i1) -> i1
    %pair_not_ub_194 = "arith.xori"(%pair_ub_194, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_194 = "arith.andi"(%pair_rhs_nz_194, %pair_not_ub_194) : (i1, i1) -> i1
    %pair_val_194 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_194 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_194 = "transfer.cmp"(%pair_rem_194, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_194 = "arith.andi"(%pair_valid_sdiv_194, %pair_exact_194) : (i1, i1) -> i1
    %pair_val0_194 = "transfer.xor"(%pair_val_194, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_194 = "transfer.select"(%pair_valid_194, %pair_val0_194, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_194 = "transfer.select"(%pair_valid_194, %pair_val_194, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_194 = "transfer.and"(%pair_acc0_193, %pair_sel0_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_194 = "transfer.and"(%pair_acc1_193, %pair_sel1_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_194 = "arith.ori"(%pair_any_193, %pair_valid_194) : (i1, i1) -> i1
    %pair_rhs_nz_195 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_195 = "transfer.select"(%pair_rhs_nz_195, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_195 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_195 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_195 = "arith.andi"(%pair_lhs_eq_smin_195, %pair_rhs_eq_m1_195) : (i1, i1) -> i1
    %pair_not_ub_195 = "arith.xori"(%pair_ub_195, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_195 = "arith.andi"(%pair_rhs_nz_195, %pair_not_ub_195) : (i1, i1) -> i1
    %pair_val_195 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_195 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_195 = "transfer.cmp"(%pair_rem_195, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_195 = "arith.andi"(%pair_valid_sdiv_195, %pair_exact_195) : (i1, i1) -> i1
    %pair_val0_195 = "transfer.xor"(%pair_val_195, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_195 = "transfer.select"(%pair_valid_195, %pair_val0_195, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_195 = "transfer.select"(%pair_valid_195, %pair_val_195, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_195 = "transfer.and"(%pair_acc0_194, %pair_sel0_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_195 = "transfer.and"(%pair_acc1_194, %pair_sel1_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_195 = "arith.ori"(%pair_any_194, %pair_valid_195) : (i1, i1) -> i1
    %pair_rhs_nz_196 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_196 = "transfer.select"(%pair_rhs_nz_196, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_196 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_196 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_196 = "arith.andi"(%pair_lhs_eq_smin_196, %pair_rhs_eq_m1_196) : (i1, i1) -> i1
    %pair_not_ub_196 = "arith.xori"(%pair_ub_196, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_196 = "arith.andi"(%pair_rhs_nz_196, %pair_not_ub_196) : (i1, i1) -> i1
    %pair_val_196 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_196 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_196 = "transfer.cmp"(%pair_rem_196, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_196 = "arith.andi"(%pair_valid_sdiv_196, %pair_exact_196) : (i1, i1) -> i1
    %pair_val0_196 = "transfer.xor"(%pair_val_196, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_196 = "transfer.select"(%pair_valid_196, %pair_val0_196, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_196 = "transfer.select"(%pair_valid_196, %pair_val_196, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_196 = "transfer.and"(%pair_acc0_195, %pair_sel0_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_196 = "transfer.and"(%pair_acc1_195, %pair_sel1_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_196 = "arith.ori"(%pair_any_195, %pair_valid_196) : (i1, i1) -> i1
    %pair_rhs_nz_197 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_197 = "transfer.select"(%pair_rhs_nz_197, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_197 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_197 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_197 = "arith.andi"(%pair_lhs_eq_smin_197, %pair_rhs_eq_m1_197) : (i1, i1) -> i1
    %pair_not_ub_197 = "arith.xori"(%pair_ub_197, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_197 = "arith.andi"(%pair_rhs_nz_197, %pair_not_ub_197) : (i1, i1) -> i1
    %pair_val_197 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_197 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_197 = "transfer.cmp"(%pair_rem_197, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_197 = "arith.andi"(%pair_valid_sdiv_197, %pair_exact_197) : (i1, i1) -> i1
    %pair_val0_197 = "transfer.xor"(%pair_val_197, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_197 = "transfer.select"(%pair_valid_197, %pair_val0_197, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_197 = "transfer.select"(%pair_valid_197, %pair_val_197, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_197 = "transfer.and"(%pair_acc0_196, %pair_sel0_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_197 = "transfer.and"(%pair_acc1_196, %pair_sel1_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_197 = "arith.ori"(%pair_any_196, %pair_valid_197) : (i1, i1) -> i1
    %pair_rhs_nz_198 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_198 = "transfer.select"(%pair_rhs_nz_198, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_198 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_198 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_198 = "arith.andi"(%pair_lhs_eq_smin_198, %pair_rhs_eq_m1_198) : (i1, i1) -> i1
    %pair_not_ub_198 = "arith.xori"(%pair_ub_198, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_198 = "arith.andi"(%pair_rhs_nz_198, %pair_not_ub_198) : (i1, i1) -> i1
    %pair_val_198 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_198 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_198 = "transfer.cmp"(%pair_rem_198, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_198 = "arith.andi"(%pair_valid_sdiv_198, %pair_exact_198) : (i1, i1) -> i1
    %pair_val0_198 = "transfer.xor"(%pair_val_198, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_198 = "transfer.select"(%pair_valid_198, %pair_val0_198, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_198 = "transfer.select"(%pair_valid_198, %pair_val_198, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_198 = "transfer.and"(%pair_acc0_197, %pair_sel0_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_198 = "transfer.and"(%pair_acc1_197, %pair_sel1_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_198 = "arith.ori"(%pair_any_197, %pair_valid_198) : (i1, i1) -> i1
    %pair_rhs_nz_199 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_199 = "transfer.select"(%pair_rhs_nz_199, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_199 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_199 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_199 = "arith.andi"(%pair_lhs_eq_smin_199, %pair_rhs_eq_m1_199) : (i1, i1) -> i1
    %pair_not_ub_199 = "arith.xori"(%pair_ub_199, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_199 = "arith.andi"(%pair_rhs_nz_199, %pair_not_ub_199) : (i1, i1) -> i1
    %pair_val_199 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_199 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_199 = "transfer.cmp"(%pair_rem_199, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_199 = "arith.andi"(%pair_valid_sdiv_199, %pair_exact_199) : (i1, i1) -> i1
    %pair_val0_199 = "transfer.xor"(%pair_val_199, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_199 = "transfer.select"(%pair_valid_199, %pair_val0_199, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_199 = "transfer.select"(%pair_valid_199, %pair_val_199, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_199 = "transfer.and"(%pair_acc0_198, %pair_sel0_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_199 = "transfer.and"(%pair_acc1_198, %pair_sel1_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_199 = "arith.ori"(%pair_any_198, %pair_valid_199) : (i1, i1) -> i1
    %pair_rhs_nz_200 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_200 = "transfer.select"(%pair_rhs_nz_200, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_200 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_200 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_200 = "arith.andi"(%pair_lhs_eq_smin_200, %pair_rhs_eq_m1_200) : (i1, i1) -> i1
    %pair_not_ub_200 = "arith.xori"(%pair_ub_200, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_200 = "arith.andi"(%pair_rhs_nz_200, %pair_not_ub_200) : (i1, i1) -> i1
    %pair_val_200 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_200 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_200 = "transfer.cmp"(%pair_rem_200, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_200 = "arith.andi"(%pair_valid_sdiv_200, %pair_exact_200) : (i1, i1) -> i1
    %pair_val0_200 = "transfer.xor"(%pair_val_200, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_200 = "transfer.select"(%pair_valid_200, %pair_val0_200, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_200 = "transfer.select"(%pair_valid_200, %pair_val_200, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_200 = "transfer.and"(%pair_acc0_199, %pair_sel0_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_200 = "transfer.and"(%pair_acc1_199, %pair_sel1_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_200 = "arith.ori"(%pair_any_199, %pair_valid_200) : (i1, i1) -> i1
    %pair_rhs_nz_201 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_201 = "transfer.select"(%pair_rhs_nz_201, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_201 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_201 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_201 = "arith.andi"(%pair_lhs_eq_smin_201, %pair_rhs_eq_m1_201) : (i1, i1) -> i1
    %pair_not_ub_201 = "arith.xori"(%pair_ub_201, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_201 = "arith.andi"(%pair_rhs_nz_201, %pair_not_ub_201) : (i1, i1) -> i1
    %pair_val_201 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_201 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_201 = "transfer.cmp"(%pair_rem_201, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_201 = "arith.andi"(%pair_valid_sdiv_201, %pair_exact_201) : (i1, i1) -> i1
    %pair_val0_201 = "transfer.xor"(%pair_val_201, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_201 = "transfer.select"(%pair_valid_201, %pair_val0_201, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_201 = "transfer.select"(%pair_valid_201, %pair_val_201, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_201 = "transfer.and"(%pair_acc0_200, %pair_sel0_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_201 = "transfer.and"(%pair_acc1_200, %pair_sel1_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_201 = "arith.ori"(%pair_any_200, %pair_valid_201) : (i1, i1) -> i1
    %pair_rhs_nz_202 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_202 = "transfer.select"(%pair_rhs_nz_202, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_202 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_202 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_202 = "arith.andi"(%pair_lhs_eq_smin_202, %pair_rhs_eq_m1_202) : (i1, i1) -> i1
    %pair_not_ub_202 = "arith.xori"(%pair_ub_202, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_202 = "arith.andi"(%pair_rhs_nz_202, %pair_not_ub_202) : (i1, i1) -> i1
    %pair_val_202 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_202 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_202 = "transfer.cmp"(%pair_rem_202, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_202 = "arith.andi"(%pair_valid_sdiv_202, %pair_exact_202) : (i1, i1) -> i1
    %pair_val0_202 = "transfer.xor"(%pair_val_202, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_202 = "transfer.select"(%pair_valid_202, %pair_val0_202, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_202 = "transfer.select"(%pair_valid_202, %pair_val_202, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_202 = "transfer.and"(%pair_acc0_201, %pair_sel0_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_202 = "transfer.and"(%pair_acc1_201, %pair_sel1_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_202 = "arith.ori"(%pair_any_201, %pair_valid_202) : (i1, i1) -> i1
    %pair_rhs_nz_203 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_203 = "transfer.select"(%pair_rhs_nz_203, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_203 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_203 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_203 = "arith.andi"(%pair_lhs_eq_smin_203, %pair_rhs_eq_m1_203) : (i1, i1) -> i1
    %pair_not_ub_203 = "arith.xori"(%pair_ub_203, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_203 = "arith.andi"(%pair_rhs_nz_203, %pair_not_ub_203) : (i1, i1) -> i1
    %pair_val_203 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_203 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_203 = "transfer.cmp"(%pair_rem_203, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_203 = "arith.andi"(%pair_valid_sdiv_203, %pair_exact_203) : (i1, i1) -> i1
    %pair_val0_203 = "transfer.xor"(%pair_val_203, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_203 = "transfer.select"(%pair_valid_203, %pair_val0_203, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_203 = "transfer.select"(%pair_valid_203, %pair_val_203, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_203 = "transfer.and"(%pair_acc0_202, %pair_sel0_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_203 = "transfer.and"(%pair_acc1_202, %pair_sel1_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_203 = "arith.ori"(%pair_any_202, %pair_valid_203) : (i1, i1) -> i1
    %pair_rhs_nz_204 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_204 = "transfer.select"(%pair_rhs_nz_204, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_204 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_204 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_204 = "arith.andi"(%pair_lhs_eq_smin_204, %pair_rhs_eq_m1_204) : (i1, i1) -> i1
    %pair_not_ub_204 = "arith.xori"(%pair_ub_204, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_204 = "arith.andi"(%pair_rhs_nz_204, %pair_not_ub_204) : (i1, i1) -> i1
    %pair_val_204 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_204 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_204 = "transfer.cmp"(%pair_rem_204, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_204 = "arith.andi"(%pair_valid_sdiv_204, %pair_exact_204) : (i1, i1) -> i1
    %pair_val0_204 = "transfer.xor"(%pair_val_204, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_204 = "transfer.select"(%pair_valid_204, %pair_val0_204, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_204 = "transfer.select"(%pair_valid_204, %pair_val_204, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_204 = "transfer.and"(%pair_acc0_203, %pair_sel0_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_204 = "transfer.and"(%pair_acc1_203, %pair_sel1_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_204 = "arith.ori"(%pair_any_203, %pair_valid_204) : (i1, i1) -> i1
    %pair_rhs_nz_205 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_205 = "transfer.select"(%pair_rhs_nz_205, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_205 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_205 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_205 = "arith.andi"(%pair_lhs_eq_smin_205, %pair_rhs_eq_m1_205) : (i1, i1) -> i1
    %pair_not_ub_205 = "arith.xori"(%pair_ub_205, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_205 = "arith.andi"(%pair_rhs_nz_205, %pair_not_ub_205) : (i1, i1) -> i1
    %pair_val_205 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_205 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_205 = "transfer.cmp"(%pair_rem_205, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_205 = "arith.andi"(%pair_valid_sdiv_205, %pair_exact_205) : (i1, i1) -> i1
    %pair_val0_205 = "transfer.xor"(%pair_val_205, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_205 = "transfer.select"(%pair_valid_205, %pair_val0_205, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_205 = "transfer.select"(%pair_valid_205, %pair_val_205, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_205 = "transfer.and"(%pair_acc0_204, %pair_sel0_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_205 = "transfer.and"(%pair_acc1_204, %pair_sel1_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_205 = "arith.ori"(%pair_any_204, %pair_valid_205) : (i1, i1) -> i1
    %pair_rhs_nz_206 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_206 = "transfer.select"(%pair_rhs_nz_206, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_206 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_206 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_206 = "arith.andi"(%pair_lhs_eq_smin_206, %pair_rhs_eq_m1_206) : (i1, i1) -> i1
    %pair_not_ub_206 = "arith.xori"(%pair_ub_206, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_206 = "arith.andi"(%pair_rhs_nz_206, %pair_not_ub_206) : (i1, i1) -> i1
    %pair_val_206 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_206 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_206 = "transfer.cmp"(%pair_rem_206, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_206 = "arith.andi"(%pair_valid_sdiv_206, %pair_exact_206) : (i1, i1) -> i1
    %pair_val0_206 = "transfer.xor"(%pair_val_206, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_206 = "transfer.select"(%pair_valid_206, %pair_val0_206, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_206 = "transfer.select"(%pair_valid_206, %pair_val_206, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_206 = "transfer.and"(%pair_acc0_205, %pair_sel0_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_206 = "transfer.and"(%pair_acc1_205, %pair_sel1_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_206 = "arith.ori"(%pair_any_205, %pair_valid_206) : (i1, i1) -> i1
    %pair_rhs_nz_207 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_207 = "transfer.select"(%pair_rhs_nz_207, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_207 = "transfer.cmp"(%lhsu_v12, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_207 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_207 = "arith.andi"(%pair_lhs_eq_smin_207, %pair_rhs_eq_m1_207) : (i1, i1) -> i1
    %pair_not_ub_207 = "arith.xori"(%pair_ub_207, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_207 = "arith.andi"(%pair_rhs_nz_207, %pair_not_ub_207) : (i1, i1) -> i1
    %pair_val_207 = "transfer.sdiv"(%lhsu_v12, %pair_rhs_safe_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_207 = "transfer.srem"(%lhsu_v12, %pair_rhs_safe_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_207 = "transfer.cmp"(%pair_rem_207, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_207 = "arith.andi"(%pair_valid_sdiv_207, %pair_exact_207) : (i1, i1) -> i1
    %pair_val0_207 = "transfer.xor"(%pair_val_207, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_207 = "transfer.select"(%pair_valid_207, %pair_val0_207, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_207 = "transfer.select"(%pair_valid_207, %pair_val_207, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_207 = "transfer.and"(%pair_acc0_206, %pair_sel0_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_207 = "transfer.and"(%pair_acc1_206, %pair_sel1_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_207 = "arith.ori"(%pair_any_206, %pair_valid_207) : (i1, i1) -> i1
    %pair_rhs_nz_208 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_208 = "transfer.select"(%pair_rhs_nz_208, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_208 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_208 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_208 = "arith.andi"(%pair_lhs_eq_smin_208, %pair_rhs_eq_m1_208) : (i1, i1) -> i1
    %pair_not_ub_208 = "arith.xori"(%pair_ub_208, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_208 = "arith.andi"(%pair_rhs_nz_208, %pair_not_ub_208) : (i1, i1) -> i1
    %pair_val_208 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_208 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_208 = "transfer.cmp"(%pair_rem_208, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_208 = "arith.andi"(%pair_valid_sdiv_208, %pair_exact_208) : (i1, i1) -> i1
    %pair_val0_208 = "transfer.xor"(%pair_val_208, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_208 = "transfer.select"(%pair_valid_208, %pair_val0_208, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_208 = "transfer.select"(%pair_valid_208, %pair_val_208, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_208 = "transfer.and"(%pair_acc0_207, %pair_sel0_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_208 = "transfer.and"(%pair_acc1_207, %pair_sel1_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_208 = "arith.ori"(%pair_any_207, %pair_valid_208) : (i1, i1) -> i1
    %pair_rhs_nz_209 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_209 = "transfer.select"(%pair_rhs_nz_209, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_209 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_209 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_209 = "arith.andi"(%pair_lhs_eq_smin_209, %pair_rhs_eq_m1_209) : (i1, i1) -> i1
    %pair_not_ub_209 = "arith.xori"(%pair_ub_209, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_209 = "arith.andi"(%pair_rhs_nz_209, %pair_not_ub_209) : (i1, i1) -> i1
    %pair_val_209 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_209 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_209 = "transfer.cmp"(%pair_rem_209, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_209 = "arith.andi"(%pair_valid_sdiv_209, %pair_exact_209) : (i1, i1) -> i1
    %pair_val0_209 = "transfer.xor"(%pair_val_209, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_209 = "transfer.select"(%pair_valid_209, %pair_val0_209, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_209 = "transfer.select"(%pair_valid_209, %pair_val_209, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_209 = "transfer.and"(%pair_acc0_208, %pair_sel0_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_209 = "transfer.and"(%pair_acc1_208, %pair_sel1_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_209 = "arith.ori"(%pair_any_208, %pair_valid_209) : (i1, i1) -> i1
    %pair_rhs_nz_210 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_210 = "transfer.select"(%pair_rhs_nz_210, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_210 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_210 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_210 = "arith.andi"(%pair_lhs_eq_smin_210, %pair_rhs_eq_m1_210) : (i1, i1) -> i1
    %pair_not_ub_210 = "arith.xori"(%pair_ub_210, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_210 = "arith.andi"(%pair_rhs_nz_210, %pair_not_ub_210) : (i1, i1) -> i1
    %pair_val_210 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_210 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_210 = "transfer.cmp"(%pair_rem_210, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_210 = "arith.andi"(%pair_valid_sdiv_210, %pair_exact_210) : (i1, i1) -> i1
    %pair_val0_210 = "transfer.xor"(%pair_val_210, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_210 = "transfer.select"(%pair_valid_210, %pair_val0_210, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_210 = "transfer.select"(%pair_valid_210, %pair_val_210, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_210 = "transfer.and"(%pair_acc0_209, %pair_sel0_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_210 = "transfer.and"(%pair_acc1_209, %pair_sel1_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_210 = "arith.ori"(%pair_any_209, %pair_valid_210) : (i1, i1) -> i1
    %pair_rhs_nz_211 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_211 = "transfer.select"(%pair_rhs_nz_211, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_211 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_211 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_211 = "arith.andi"(%pair_lhs_eq_smin_211, %pair_rhs_eq_m1_211) : (i1, i1) -> i1
    %pair_not_ub_211 = "arith.xori"(%pair_ub_211, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_211 = "arith.andi"(%pair_rhs_nz_211, %pair_not_ub_211) : (i1, i1) -> i1
    %pair_val_211 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_211 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_211 = "transfer.cmp"(%pair_rem_211, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_211 = "arith.andi"(%pair_valid_sdiv_211, %pair_exact_211) : (i1, i1) -> i1
    %pair_val0_211 = "transfer.xor"(%pair_val_211, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_211 = "transfer.select"(%pair_valid_211, %pair_val0_211, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_211 = "transfer.select"(%pair_valid_211, %pair_val_211, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_211 = "transfer.and"(%pair_acc0_210, %pair_sel0_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_211 = "transfer.and"(%pair_acc1_210, %pair_sel1_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_211 = "arith.ori"(%pair_any_210, %pair_valid_211) : (i1, i1) -> i1
    %pair_rhs_nz_212 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_212 = "transfer.select"(%pair_rhs_nz_212, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_212 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_212 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_212 = "arith.andi"(%pair_lhs_eq_smin_212, %pair_rhs_eq_m1_212) : (i1, i1) -> i1
    %pair_not_ub_212 = "arith.xori"(%pair_ub_212, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_212 = "arith.andi"(%pair_rhs_nz_212, %pair_not_ub_212) : (i1, i1) -> i1
    %pair_val_212 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_212 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_212 = "transfer.cmp"(%pair_rem_212, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_212 = "arith.andi"(%pair_valid_sdiv_212, %pair_exact_212) : (i1, i1) -> i1
    %pair_val0_212 = "transfer.xor"(%pair_val_212, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_212 = "transfer.select"(%pair_valid_212, %pair_val0_212, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_212 = "transfer.select"(%pair_valid_212, %pair_val_212, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_212 = "transfer.and"(%pair_acc0_211, %pair_sel0_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_212 = "transfer.and"(%pair_acc1_211, %pair_sel1_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_212 = "arith.ori"(%pair_any_211, %pair_valid_212) : (i1, i1) -> i1
    %pair_rhs_nz_213 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_213 = "transfer.select"(%pair_rhs_nz_213, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_213 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_213 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_213 = "arith.andi"(%pair_lhs_eq_smin_213, %pair_rhs_eq_m1_213) : (i1, i1) -> i1
    %pair_not_ub_213 = "arith.xori"(%pair_ub_213, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_213 = "arith.andi"(%pair_rhs_nz_213, %pair_not_ub_213) : (i1, i1) -> i1
    %pair_val_213 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_213 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_213 = "transfer.cmp"(%pair_rem_213, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_213 = "arith.andi"(%pair_valid_sdiv_213, %pair_exact_213) : (i1, i1) -> i1
    %pair_val0_213 = "transfer.xor"(%pair_val_213, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_213 = "transfer.select"(%pair_valid_213, %pair_val0_213, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_213 = "transfer.select"(%pair_valid_213, %pair_val_213, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_213 = "transfer.and"(%pair_acc0_212, %pair_sel0_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_213 = "transfer.and"(%pair_acc1_212, %pair_sel1_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_213 = "arith.ori"(%pair_any_212, %pair_valid_213) : (i1, i1) -> i1
    %pair_rhs_nz_214 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_214 = "transfer.select"(%pair_rhs_nz_214, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_214 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_214 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_214 = "arith.andi"(%pair_lhs_eq_smin_214, %pair_rhs_eq_m1_214) : (i1, i1) -> i1
    %pair_not_ub_214 = "arith.xori"(%pair_ub_214, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_214 = "arith.andi"(%pair_rhs_nz_214, %pair_not_ub_214) : (i1, i1) -> i1
    %pair_val_214 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_214 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_214 = "transfer.cmp"(%pair_rem_214, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_214 = "arith.andi"(%pair_valid_sdiv_214, %pair_exact_214) : (i1, i1) -> i1
    %pair_val0_214 = "transfer.xor"(%pair_val_214, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_214 = "transfer.select"(%pair_valid_214, %pair_val0_214, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_214 = "transfer.select"(%pair_valid_214, %pair_val_214, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_214 = "transfer.and"(%pair_acc0_213, %pair_sel0_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_214 = "transfer.and"(%pair_acc1_213, %pair_sel1_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_214 = "arith.ori"(%pair_any_213, %pair_valid_214) : (i1, i1) -> i1
    %pair_rhs_nz_215 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_215 = "transfer.select"(%pair_rhs_nz_215, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_215 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_215 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_215 = "arith.andi"(%pair_lhs_eq_smin_215, %pair_rhs_eq_m1_215) : (i1, i1) -> i1
    %pair_not_ub_215 = "arith.xori"(%pair_ub_215, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_215 = "arith.andi"(%pair_rhs_nz_215, %pair_not_ub_215) : (i1, i1) -> i1
    %pair_val_215 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_215 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_215 = "transfer.cmp"(%pair_rem_215, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_215 = "arith.andi"(%pair_valid_sdiv_215, %pair_exact_215) : (i1, i1) -> i1
    %pair_val0_215 = "transfer.xor"(%pair_val_215, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_215 = "transfer.select"(%pair_valid_215, %pair_val0_215, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_215 = "transfer.select"(%pair_valid_215, %pair_val_215, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_215 = "transfer.and"(%pair_acc0_214, %pair_sel0_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_215 = "transfer.and"(%pair_acc1_214, %pair_sel1_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_215 = "arith.ori"(%pair_any_214, %pair_valid_215) : (i1, i1) -> i1
    %pair_rhs_nz_216 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_216 = "transfer.select"(%pair_rhs_nz_216, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_216 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_216 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_216 = "arith.andi"(%pair_lhs_eq_smin_216, %pair_rhs_eq_m1_216) : (i1, i1) -> i1
    %pair_not_ub_216 = "arith.xori"(%pair_ub_216, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_216 = "arith.andi"(%pair_rhs_nz_216, %pair_not_ub_216) : (i1, i1) -> i1
    %pair_val_216 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_216 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_216 = "transfer.cmp"(%pair_rem_216, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_216 = "arith.andi"(%pair_valid_sdiv_216, %pair_exact_216) : (i1, i1) -> i1
    %pair_val0_216 = "transfer.xor"(%pair_val_216, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_216 = "transfer.select"(%pair_valid_216, %pair_val0_216, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_216 = "transfer.select"(%pair_valid_216, %pair_val_216, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_216 = "transfer.and"(%pair_acc0_215, %pair_sel0_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_216 = "transfer.and"(%pair_acc1_215, %pair_sel1_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_216 = "arith.ori"(%pair_any_215, %pair_valid_216) : (i1, i1) -> i1
    %pair_rhs_nz_217 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_217 = "transfer.select"(%pair_rhs_nz_217, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_217 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_217 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_217 = "arith.andi"(%pair_lhs_eq_smin_217, %pair_rhs_eq_m1_217) : (i1, i1) -> i1
    %pair_not_ub_217 = "arith.xori"(%pair_ub_217, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_217 = "arith.andi"(%pair_rhs_nz_217, %pair_not_ub_217) : (i1, i1) -> i1
    %pair_val_217 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_217 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_217 = "transfer.cmp"(%pair_rem_217, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_217 = "arith.andi"(%pair_valid_sdiv_217, %pair_exact_217) : (i1, i1) -> i1
    %pair_val0_217 = "transfer.xor"(%pair_val_217, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_217 = "transfer.select"(%pair_valid_217, %pair_val0_217, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_217 = "transfer.select"(%pair_valid_217, %pair_val_217, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_217 = "transfer.and"(%pair_acc0_216, %pair_sel0_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_217 = "transfer.and"(%pair_acc1_216, %pair_sel1_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_217 = "arith.ori"(%pair_any_216, %pair_valid_217) : (i1, i1) -> i1
    %pair_rhs_nz_218 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_218 = "transfer.select"(%pair_rhs_nz_218, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_218 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_218 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_218 = "arith.andi"(%pair_lhs_eq_smin_218, %pair_rhs_eq_m1_218) : (i1, i1) -> i1
    %pair_not_ub_218 = "arith.xori"(%pair_ub_218, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_218 = "arith.andi"(%pair_rhs_nz_218, %pair_not_ub_218) : (i1, i1) -> i1
    %pair_val_218 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_218 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_218 = "transfer.cmp"(%pair_rem_218, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_218 = "arith.andi"(%pair_valid_sdiv_218, %pair_exact_218) : (i1, i1) -> i1
    %pair_val0_218 = "transfer.xor"(%pair_val_218, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_218 = "transfer.select"(%pair_valid_218, %pair_val0_218, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_218 = "transfer.select"(%pair_valid_218, %pair_val_218, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_218 = "transfer.and"(%pair_acc0_217, %pair_sel0_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_218 = "transfer.and"(%pair_acc1_217, %pair_sel1_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_218 = "arith.ori"(%pair_any_217, %pair_valid_218) : (i1, i1) -> i1
    %pair_rhs_nz_219 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_219 = "transfer.select"(%pair_rhs_nz_219, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_219 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_219 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_219 = "arith.andi"(%pair_lhs_eq_smin_219, %pair_rhs_eq_m1_219) : (i1, i1) -> i1
    %pair_not_ub_219 = "arith.xori"(%pair_ub_219, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_219 = "arith.andi"(%pair_rhs_nz_219, %pair_not_ub_219) : (i1, i1) -> i1
    %pair_val_219 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_219 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_219 = "transfer.cmp"(%pair_rem_219, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_219 = "arith.andi"(%pair_valid_sdiv_219, %pair_exact_219) : (i1, i1) -> i1
    %pair_val0_219 = "transfer.xor"(%pair_val_219, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_219 = "transfer.select"(%pair_valid_219, %pair_val0_219, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_219 = "transfer.select"(%pair_valid_219, %pair_val_219, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_219 = "transfer.and"(%pair_acc0_218, %pair_sel0_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_219 = "transfer.and"(%pair_acc1_218, %pair_sel1_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_219 = "arith.ori"(%pair_any_218, %pair_valid_219) : (i1, i1) -> i1
    %pair_rhs_nz_220 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_220 = "transfer.select"(%pair_rhs_nz_220, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_220 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_220 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_220 = "arith.andi"(%pair_lhs_eq_smin_220, %pair_rhs_eq_m1_220) : (i1, i1) -> i1
    %pair_not_ub_220 = "arith.xori"(%pair_ub_220, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_220 = "arith.andi"(%pair_rhs_nz_220, %pair_not_ub_220) : (i1, i1) -> i1
    %pair_val_220 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_220 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_220 = "transfer.cmp"(%pair_rem_220, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_220 = "arith.andi"(%pair_valid_sdiv_220, %pair_exact_220) : (i1, i1) -> i1
    %pair_val0_220 = "transfer.xor"(%pair_val_220, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_220 = "transfer.select"(%pair_valid_220, %pair_val0_220, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_220 = "transfer.select"(%pair_valid_220, %pair_val_220, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_220 = "transfer.and"(%pair_acc0_219, %pair_sel0_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_220 = "transfer.and"(%pair_acc1_219, %pair_sel1_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_220 = "arith.ori"(%pair_any_219, %pair_valid_220) : (i1, i1) -> i1
    %pair_rhs_nz_221 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_221 = "transfer.select"(%pair_rhs_nz_221, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_221 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_221 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_221 = "arith.andi"(%pair_lhs_eq_smin_221, %pair_rhs_eq_m1_221) : (i1, i1) -> i1
    %pair_not_ub_221 = "arith.xori"(%pair_ub_221, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_221 = "arith.andi"(%pair_rhs_nz_221, %pair_not_ub_221) : (i1, i1) -> i1
    %pair_val_221 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_221 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_221 = "transfer.cmp"(%pair_rem_221, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_221 = "arith.andi"(%pair_valid_sdiv_221, %pair_exact_221) : (i1, i1) -> i1
    %pair_val0_221 = "transfer.xor"(%pair_val_221, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_221 = "transfer.select"(%pair_valid_221, %pair_val0_221, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_221 = "transfer.select"(%pair_valid_221, %pair_val_221, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_221 = "transfer.and"(%pair_acc0_220, %pair_sel0_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_221 = "transfer.and"(%pair_acc1_220, %pair_sel1_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_221 = "arith.ori"(%pair_any_220, %pair_valid_221) : (i1, i1) -> i1
    %pair_rhs_nz_222 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_222 = "transfer.select"(%pair_rhs_nz_222, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_222 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_222 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_222 = "arith.andi"(%pair_lhs_eq_smin_222, %pair_rhs_eq_m1_222) : (i1, i1) -> i1
    %pair_not_ub_222 = "arith.xori"(%pair_ub_222, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_222 = "arith.andi"(%pair_rhs_nz_222, %pair_not_ub_222) : (i1, i1) -> i1
    %pair_val_222 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_222 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_222 = "transfer.cmp"(%pair_rem_222, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_222 = "arith.andi"(%pair_valid_sdiv_222, %pair_exact_222) : (i1, i1) -> i1
    %pair_val0_222 = "transfer.xor"(%pair_val_222, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_222 = "transfer.select"(%pair_valid_222, %pair_val0_222, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_222 = "transfer.select"(%pair_valid_222, %pair_val_222, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_222 = "transfer.and"(%pair_acc0_221, %pair_sel0_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_222 = "transfer.and"(%pair_acc1_221, %pair_sel1_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_222 = "arith.ori"(%pair_any_221, %pair_valid_222) : (i1, i1) -> i1
    %pair_rhs_nz_223 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_223 = "transfer.select"(%pair_rhs_nz_223, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_223 = "transfer.cmp"(%lhsu_v13, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_223 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_223 = "arith.andi"(%pair_lhs_eq_smin_223, %pair_rhs_eq_m1_223) : (i1, i1) -> i1
    %pair_not_ub_223 = "arith.xori"(%pair_ub_223, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_223 = "arith.andi"(%pair_rhs_nz_223, %pair_not_ub_223) : (i1, i1) -> i1
    %pair_val_223 = "transfer.sdiv"(%lhsu_v13, %pair_rhs_safe_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_223 = "transfer.srem"(%lhsu_v13, %pair_rhs_safe_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_223 = "transfer.cmp"(%pair_rem_223, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_223 = "arith.andi"(%pair_valid_sdiv_223, %pair_exact_223) : (i1, i1) -> i1
    %pair_val0_223 = "transfer.xor"(%pair_val_223, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_223 = "transfer.select"(%pair_valid_223, %pair_val0_223, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_223 = "transfer.select"(%pair_valid_223, %pair_val_223, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_223 = "transfer.and"(%pair_acc0_222, %pair_sel0_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_223 = "transfer.and"(%pair_acc1_222, %pair_sel1_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_223 = "arith.ori"(%pair_any_222, %pair_valid_223) : (i1, i1) -> i1
    %pair_rhs_nz_224 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_224 = "transfer.select"(%pair_rhs_nz_224, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_224 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_224 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_224 = "arith.andi"(%pair_lhs_eq_smin_224, %pair_rhs_eq_m1_224) : (i1, i1) -> i1
    %pair_not_ub_224 = "arith.xori"(%pair_ub_224, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_224 = "arith.andi"(%pair_rhs_nz_224, %pair_not_ub_224) : (i1, i1) -> i1
    %pair_val_224 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_224 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_224 = "transfer.cmp"(%pair_rem_224, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_224 = "arith.andi"(%pair_valid_sdiv_224, %pair_exact_224) : (i1, i1) -> i1
    %pair_val0_224 = "transfer.xor"(%pair_val_224, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_224 = "transfer.select"(%pair_valid_224, %pair_val0_224, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_224 = "transfer.select"(%pair_valid_224, %pair_val_224, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_224 = "transfer.and"(%pair_acc0_223, %pair_sel0_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_224 = "transfer.and"(%pair_acc1_223, %pair_sel1_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_224 = "arith.ori"(%pair_any_223, %pair_valid_224) : (i1, i1) -> i1
    %pair_rhs_nz_225 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_225 = "transfer.select"(%pair_rhs_nz_225, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_225 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_225 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_225 = "arith.andi"(%pair_lhs_eq_smin_225, %pair_rhs_eq_m1_225) : (i1, i1) -> i1
    %pair_not_ub_225 = "arith.xori"(%pair_ub_225, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_225 = "arith.andi"(%pair_rhs_nz_225, %pair_not_ub_225) : (i1, i1) -> i1
    %pair_val_225 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_225 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_225 = "transfer.cmp"(%pair_rem_225, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_225 = "arith.andi"(%pair_valid_sdiv_225, %pair_exact_225) : (i1, i1) -> i1
    %pair_val0_225 = "transfer.xor"(%pair_val_225, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_225 = "transfer.select"(%pair_valid_225, %pair_val0_225, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_225 = "transfer.select"(%pair_valid_225, %pair_val_225, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_225 = "transfer.and"(%pair_acc0_224, %pair_sel0_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_225 = "transfer.and"(%pair_acc1_224, %pair_sel1_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_225 = "arith.ori"(%pair_any_224, %pair_valid_225) : (i1, i1) -> i1
    %pair_rhs_nz_226 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_226 = "transfer.select"(%pair_rhs_nz_226, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_226 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_226 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_226 = "arith.andi"(%pair_lhs_eq_smin_226, %pair_rhs_eq_m1_226) : (i1, i1) -> i1
    %pair_not_ub_226 = "arith.xori"(%pair_ub_226, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_226 = "arith.andi"(%pair_rhs_nz_226, %pair_not_ub_226) : (i1, i1) -> i1
    %pair_val_226 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_226 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_226 = "transfer.cmp"(%pair_rem_226, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_226 = "arith.andi"(%pair_valid_sdiv_226, %pair_exact_226) : (i1, i1) -> i1
    %pair_val0_226 = "transfer.xor"(%pair_val_226, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_226 = "transfer.select"(%pair_valid_226, %pair_val0_226, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_226 = "transfer.select"(%pair_valid_226, %pair_val_226, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_226 = "transfer.and"(%pair_acc0_225, %pair_sel0_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_226 = "transfer.and"(%pair_acc1_225, %pair_sel1_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_226 = "arith.ori"(%pair_any_225, %pair_valid_226) : (i1, i1) -> i1
    %pair_rhs_nz_227 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_227 = "transfer.select"(%pair_rhs_nz_227, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_227 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_227 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_227 = "arith.andi"(%pair_lhs_eq_smin_227, %pair_rhs_eq_m1_227) : (i1, i1) -> i1
    %pair_not_ub_227 = "arith.xori"(%pair_ub_227, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_227 = "arith.andi"(%pair_rhs_nz_227, %pair_not_ub_227) : (i1, i1) -> i1
    %pair_val_227 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_227 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_227 = "transfer.cmp"(%pair_rem_227, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_227 = "arith.andi"(%pair_valid_sdiv_227, %pair_exact_227) : (i1, i1) -> i1
    %pair_val0_227 = "transfer.xor"(%pair_val_227, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_227 = "transfer.select"(%pair_valid_227, %pair_val0_227, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_227 = "transfer.select"(%pair_valid_227, %pair_val_227, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_227 = "transfer.and"(%pair_acc0_226, %pair_sel0_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_227 = "transfer.and"(%pair_acc1_226, %pair_sel1_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_227 = "arith.ori"(%pair_any_226, %pair_valid_227) : (i1, i1) -> i1
    %pair_rhs_nz_228 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_228 = "transfer.select"(%pair_rhs_nz_228, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_228 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_228 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_228 = "arith.andi"(%pair_lhs_eq_smin_228, %pair_rhs_eq_m1_228) : (i1, i1) -> i1
    %pair_not_ub_228 = "arith.xori"(%pair_ub_228, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_228 = "arith.andi"(%pair_rhs_nz_228, %pair_not_ub_228) : (i1, i1) -> i1
    %pair_val_228 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_228 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_228 = "transfer.cmp"(%pair_rem_228, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_228 = "arith.andi"(%pair_valid_sdiv_228, %pair_exact_228) : (i1, i1) -> i1
    %pair_val0_228 = "transfer.xor"(%pair_val_228, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_228 = "transfer.select"(%pair_valid_228, %pair_val0_228, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_228 = "transfer.select"(%pair_valid_228, %pair_val_228, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_228 = "transfer.and"(%pair_acc0_227, %pair_sel0_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_228 = "transfer.and"(%pair_acc1_227, %pair_sel1_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_228 = "arith.ori"(%pair_any_227, %pair_valid_228) : (i1, i1) -> i1
    %pair_rhs_nz_229 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_229 = "transfer.select"(%pair_rhs_nz_229, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_229 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_229 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_229 = "arith.andi"(%pair_lhs_eq_smin_229, %pair_rhs_eq_m1_229) : (i1, i1) -> i1
    %pair_not_ub_229 = "arith.xori"(%pair_ub_229, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_229 = "arith.andi"(%pair_rhs_nz_229, %pair_not_ub_229) : (i1, i1) -> i1
    %pair_val_229 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_229 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_229 = "transfer.cmp"(%pair_rem_229, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_229 = "arith.andi"(%pair_valid_sdiv_229, %pair_exact_229) : (i1, i1) -> i1
    %pair_val0_229 = "transfer.xor"(%pair_val_229, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_229 = "transfer.select"(%pair_valid_229, %pair_val0_229, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_229 = "transfer.select"(%pair_valid_229, %pair_val_229, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_229 = "transfer.and"(%pair_acc0_228, %pair_sel0_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_229 = "transfer.and"(%pair_acc1_228, %pair_sel1_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_229 = "arith.ori"(%pair_any_228, %pair_valid_229) : (i1, i1) -> i1
    %pair_rhs_nz_230 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_230 = "transfer.select"(%pair_rhs_nz_230, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_230 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_230 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_230 = "arith.andi"(%pair_lhs_eq_smin_230, %pair_rhs_eq_m1_230) : (i1, i1) -> i1
    %pair_not_ub_230 = "arith.xori"(%pair_ub_230, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_230 = "arith.andi"(%pair_rhs_nz_230, %pair_not_ub_230) : (i1, i1) -> i1
    %pair_val_230 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_230 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_230 = "transfer.cmp"(%pair_rem_230, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_230 = "arith.andi"(%pair_valid_sdiv_230, %pair_exact_230) : (i1, i1) -> i1
    %pair_val0_230 = "transfer.xor"(%pair_val_230, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_230 = "transfer.select"(%pair_valid_230, %pair_val0_230, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_230 = "transfer.select"(%pair_valid_230, %pair_val_230, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_230 = "transfer.and"(%pair_acc0_229, %pair_sel0_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_230 = "transfer.and"(%pair_acc1_229, %pair_sel1_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_230 = "arith.ori"(%pair_any_229, %pair_valid_230) : (i1, i1) -> i1
    %pair_rhs_nz_231 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_231 = "transfer.select"(%pair_rhs_nz_231, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_231 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_231 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_231 = "arith.andi"(%pair_lhs_eq_smin_231, %pair_rhs_eq_m1_231) : (i1, i1) -> i1
    %pair_not_ub_231 = "arith.xori"(%pair_ub_231, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_231 = "arith.andi"(%pair_rhs_nz_231, %pair_not_ub_231) : (i1, i1) -> i1
    %pair_val_231 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_231 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_231 = "transfer.cmp"(%pair_rem_231, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_231 = "arith.andi"(%pair_valid_sdiv_231, %pair_exact_231) : (i1, i1) -> i1
    %pair_val0_231 = "transfer.xor"(%pair_val_231, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_231 = "transfer.select"(%pair_valid_231, %pair_val0_231, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_231 = "transfer.select"(%pair_valid_231, %pair_val_231, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_231 = "transfer.and"(%pair_acc0_230, %pair_sel0_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_231 = "transfer.and"(%pair_acc1_230, %pair_sel1_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_231 = "arith.ori"(%pair_any_230, %pair_valid_231) : (i1, i1) -> i1
    %pair_rhs_nz_232 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_232 = "transfer.select"(%pair_rhs_nz_232, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_232 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_232 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_232 = "arith.andi"(%pair_lhs_eq_smin_232, %pair_rhs_eq_m1_232) : (i1, i1) -> i1
    %pair_not_ub_232 = "arith.xori"(%pair_ub_232, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_232 = "arith.andi"(%pair_rhs_nz_232, %pair_not_ub_232) : (i1, i1) -> i1
    %pair_val_232 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_232 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_232 = "transfer.cmp"(%pair_rem_232, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_232 = "arith.andi"(%pair_valid_sdiv_232, %pair_exact_232) : (i1, i1) -> i1
    %pair_val0_232 = "transfer.xor"(%pair_val_232, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_232 = "transfer.select"(%pair_valid_232, %pair_val0_232, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_232 = "transfer.select"(%pair_valid_232, %pair_val_232, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_232 = "transfer.and"(%pair_acc0_231, %pair_sel0_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_232 = "transfer.and"(%pair_acc1_231, %pair_sel1_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_232 = "arith.ori"(%pair_any_231, %pair_valid_232) : (i1, i1) -> i1
    %pair_rhs_nz_233 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_233 = "transfer.select"(%pair_rhs_nz_233, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_233 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_233 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_233 = "arith.andi"(%pair_lhs_eq_smin_233, %pair_rhs_eq_m1_233) : (i1, i1) -> i1
    %pair_not_ub_233 = "arith.xori"(%pair_ub_233, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_233 = "arith.andi"(%pair_rhs_nz_233, %pair_not_ub_233) : (i1, i1) -> i1
    %pair_val_233 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_233 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_233 = "transfer.cmp"(%pair_rem_233, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_233 = "arith.andi"(%pair_valid_sdiv_233, %pair_exact_233) : (i1, i1) -> i1
    %pair_val0_233 = "transfer.xor"(%pair_val_233, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_233 = "transfer.select"(%pair_valid_233, %pair_val0_233, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_233 = "transfer.select"(%pair_valid_233, %pair_val_233, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_233 = "transfer.and"(%pair_acc0_232, %pair_sel0_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_233 = "transfer.and"(%pair_acc1_232, %pair_sel1_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_233 = "arith.ori"(%pair_any_232, %pair_valid_233) : (i1, i1) -> i1
    %pair_rhs_nz_234 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_234 = "transfer.select"(%pair_rhs_nz_234, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_234 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_234 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_234 = "arith.andi"(%pair_lhs_eq_smin_234, %pair_rhs_eq_m1_234) : (i1, i1) -> i1
    %pair_not_ub_234 = "arith.xori"(%pair_ub_234, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_234 = "arith.andi"(%pair_rhs_nz_234, %pair_not_ub_234) : (i1, i1) -> i1
    %pair_val_234 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_234 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_234 = "transfer.cmp"(%pair_rem_234, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_234 = "arith.andi"(%pair_valid_sdiv_234, %pair_exact_234) : (i1, i1) -> i1
    %pair_val0_234 = "transfer.xor"(%pair_val_234, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_234 = "transfer.select"(%pair_valid_234, %pair_val0_234, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_234 = "transfer.select"(%pair_valid_234, %pair_val_234, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_234 = "transfer.and"(%pair_acc0_233, %pair_sel0_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_234 = "transfer.and"(%pair_acc1_233, %pair_sel1_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_234 = "arith.ori"(%pair_any_233, %pair_valid_234) : (i1, i1) -> i1
    %pair_rhs_nz_235 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_235 = "transfer.select"(%pair_rhs_nz_235, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_235 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_235 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_235 = "arith.andi"(%pair_lhs_eq_smin_235, %pair_rhs_eq_m1_235) : (i1, i1) -> i1
    %pair_not_ub_235 = "arith.xori"(%pair_ub_235, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_235 = "arith.andi"(%pair_rhs_nz_235, %pair_not_ub_235) : (i1, i1) -> i1
    %pair_val_235 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_235 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_235 = "transfer.cmp"(%pair_rem_235, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_235 = "arith.andi"(%pair_valid_sdiv_235, %pair_exact_235) : (i1, i1) -> i1
    %pair_val0_235 = "transfer.xor"(%pair_val_235, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_235 = "transfer.select"(%pair_valid_235, %pair_val0_235, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_235 = "transfer.select"(%pair_valid_235, %pair_val_235, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_235 = "transfer.and"(%pair_acc0_234, %pair_sel0_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_235 = "transfer.and"(%pair_acc1_234, %pair_sel1_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_235 = "arith.ori"(%pair_any_234, %pair_valid_235) : (i1, i1) -> i1
    %pair_rhs_nz_236 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_236 = "transfer.select"(%pair_rhs_nz_236, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_236 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_236 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_236 = "arith.andi"(%pair_lhs_eq_smin_236, %pair_rhs_eq_m1_236) : (i1, i1) -> i1
    %pair_not_ub_236 = "arith.xori"(%pair_ub_236, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_236 = "arith.andi"(%pair_rhs_nz_236, %pair_not_ub_236) : (i1, i1) -> i1
    %pair_val_236 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_236 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_236 = "transfer.cmp"(%pair_rem_236, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_236 = "arith.andi"(%pair_valid_sdiv_236, %pair_exact_236) : (i1, i1) -> i1
    %pair_val0_236 = "transfer.xor"(%pair_val_236, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_236 = "transfer.select"(%pair_valid_236, %pair_val0_236, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_236 = "transfer.select"(%pair_valid_236, %pair_val_236, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_236 = "transfer.and"(%pair_acc0_235, %pair_sel0_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_236 = "transfer.and"(%pair_acc1_235, %pair_sel1_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_236 = "arith.ori"(%pair_any_235, %pair_valid_236) : (i1, i1) -> i1
    %pair_rhs_nz_237 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_237 = "transfer.select"(%pair_rhs_nz_237, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_237 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_237 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_237 = "arith.andi"(%pair_lhs_eq_smin_237, %pair_rhs_eq_m1_237) : (i1, i1) -> i1
    %pair_not_ub_237 = "arith.xori"(%pair_ub_237, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_237 = "arith.andi"(%pair_rhs_nz_237, %pair_not_ub_237) : (i1, i1) -> i1
    %pair_val_237 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_237 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_237 = "transfer.cmp"(%pair_rem_237, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_237 = "arith.andi"(%pair_valid_sdiv_237, %pair_exact_237) : (i1, i1) -> i1
    %pair_val0_237 = "transfer.xor"(%pair_val_237, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_237 = "transfer.select"(%pair_valid_237, %pair_val0_237, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_237 = "transfer.select"(%pair_valid_237, %pair_val_237, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_237 = "transfer.and"(%pair_acc0_236, %pair_sel0_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_237 = "transfer.and"(%pair_acc1_236, %pair_sel1_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_237 = "arith.ori"(%pair_any_236, %pair_valid_237) : (i1, i1) -> i1
    %pair_rhs_nz_238 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_238 = "transfer.select"(%pair_rhs_nz_238, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_238 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_238 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_238 = "arith.andi"(%pair_lhs_eq_smin_238, %pair_rhs_eq_m1_238) : (i1, i1) -> i1
    %pair_not_ub_238 = "arith.xori"(%pair_ub_238, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_238 = "arith.andi"(%pair_rhs_nz_238, %pair_not_ub_238) : (i1, i1) -> i1
    %pair_val_238 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_238 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_238 = "transfer.cmp"(%pair_rem_238, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_238 = "arith.andi"(%pair_valid_sdiv_238, %pair_exact_238) : (i1, i1) -> i1
    %pair_val0_238 = "transfer.xor"(%pair_val_238, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_238 = "transfer.select"(%pair_valid_238, %pair_val0_238, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_238 = "transfer.select"(%pair_valid_238, %pair_val_238, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_238 = "transfer.and"(%pair_acc0_237, %pair_sel0_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_238 = "transfer.and"(%pair_acc1_237, %pair_sel1_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_238 = "arith.ori"(%pair_any_237, %pair_valid_238) : (i1, i1) -> i1
    %pair_rhs_nz_239 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_239 = "transfer.select"(%pair_rhs_nz_239, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_239 = "transfer.cmp"(%lhsu_v14, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_239 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_239 = "arith.andi"(%pair_lhs_eq_smin_239, %pair_rhs_eq_m1_239) : (i1, i1) -> i1
    %pair_not_ub_239 = "arith.xori"(%pair_ub_239, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_239 = "arith.andi"(%pair_rhs_nz_239, %pair_not_ub_239) : (i1, i1) -> i1
    %pair_val_239 = "transfer.sdiv"(%lhsu_v14, %pair_rhs_safe_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_239 = "transfer.srem"(%lhsu_v14, %pair_rhs_safe_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_239 = "transfer.cmp"(%pair_rem_239, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_239 = "arith.andi"(%pair_valid_sdiv_239, %pair_exact_239) : (i1, i1) -> i1
    %pair_val0_239 = "transfer.xor"(%pair_val_239, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_239 = "transfer.select"(%pair_valid_239, %pair_val0_239, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_239 = "transfer.select"(%pair_valid_239, %pair_val_239, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_239 = "transfer.and"(%pair_acc0_238, %pair_sel0_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_239 = "transfer.and"(%pair_acc1_238, %pair_sel1_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_239 = "arith.ori"(%pair_any_238, %pair_valid_239) : (i1, i1) -> i1
    %pair_rhs_nz_240 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_240 = "transfer.select"(%pair_rhs_nz_240, %rhsu_v0, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_240 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_240 = "transfer.cmp"(%rhsu_v0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_240 = "arith.andi"(%pair_lhs_eq_smin_240, %pair_rhs_eq_m1_240) : (i1, i1) -> i1
    %pair_not_ub_240 = "arith.xori"(%pair_ub_240, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_240 = "arith.andi"(%pair_rhs_nz_240, %pair_not_ub_240) : (i1, i1) -> i1
    %pair_val_240 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_240 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_240 = "transfer.cmp"(%pair_rem_240, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_240 = "arith.andi"(%pair_valid_sdiv_240, %pair_exact_240) : (i1, i1) -> i1
    %pair_val0_240 = "transfer.xor"(%pair_val_240, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_240 = "transfer.select"(%pair_valid_240, %pair_val0_240, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_240 = "transfer.select"(%pair_valid_240, %pair_val_240, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_240 = "transfer.and"(%pair_acc0_239, %pair_sel0_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_240 = "transfer.and"(%pair_acc1_239, %pair_sel1_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_240 = "arith.ori"(%pair_any_239, %pair_valid_240) : (i1, i1) -> i1
    %pair_rhs_nz_241 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_241 = "transfer.select"(%pair_rhs_nz_241, %rhsu_v1, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_241 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_241 = "transfer.cmp"(%rhsu_v1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_241 = "arith.andi"(%pair_lhs_eq_smin_241, %pair_rhs_eq_m1_241) : (i1, i1) -> i1
    %pair_not_ub_241 = "arith.xori"(%pair_ub_241, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_241 = "arith.andi"(%pair_rhs_nz_241, %pair_not_ub_241) : (i1, i1) -> i1
    %pair_val_241 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_241 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_241 = "transfer.cmp"(%pair_rem_241, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_241 = "arith.andi"(%pair_valid_sdiv_241, %pair_exact_241) : (i1, i1) -> i1
    %pair_val0_241 = "transfer.xor"(%pair_val_241, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_241 = "transfer.select"(%pair_valid_241, %pair_val0_241, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_241 = "transfer.select"(%pair_valid_241, %pair_val_241, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_241 = "transfer.and"(%pair_acc0_240, %pair_sel0_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_241 = "transfer.and"(%pair_acc1_240, %pair_sel1_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_241 = "arith.ori"(%pair_any_240, %pair_valid_241) : (i1, i1) -> i1
    %pair_rhs_nz_242 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_242 = "transfer.select"(%pair_rhs_nz_242, %rhsu_v2, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_242 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_242 = "transfer.cmp"(%rhsu_v2, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_242 = "arith.andi"(%pair_lhs_eq_smin_242, %pair_rhs_eq_m1_242) : (i1, i1) -> i1
    %pair_not_ub_242 = "arith.xori"(%pair_ub_242, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_242 = "arith.andi"(%pair_rhs_nz_242, %pair_not_ub_242) : (i1, i1) -> i1
    %pair_val_242 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_242 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_242 = "transfer.cmp"(%pair_rem_242, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_242 = "arith.andi"(%pair_valid_sdiv_242, %pair_exact_242) : (i1, i1) -> i1
    %pair_val0_242 = "transfer.xor"(%pair_val_242, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_242 = "transfer.select"(%pair_valid_242, %pair_val0_242, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_242 = "transfer.select"(%pair_valid_242, %pair_val_242, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_242 = "transfer.and"(%pair_acc0_241, %pair_sel0_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_242 = "transfer.and"(%pair_acc1_241, %pair_sel1_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_242 = "arith.ori"(%pair_any_241, %pair_valid_242) : (i1, i1) -> i1
    %pair_rhs_nz_243 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_243 = "transfer.select"(%pair_rhs_nz_243, %rhsu_v3, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_243 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_243 = "transfer.cmp"(%rhsu_v3, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_243 = "arith.andi"(%pair_lhs_eq_smin_243, %pair_rhs_eq_m1_243) : (i1, i1) -> i1
    %pair_not_ub_243 = "arith.xori"(%pair_ub_243, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_243 = "arith.andi"(%pair_rhs_nz_243, %pair_not_ub_243) : (i1, i1) -> i1
    %pair_val_243 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_243 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_243 = "transfer.cmp"(%pair_rem_243, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_243 = "arith.andi"(%pair_valid_sdiv_243, %pair_exact_243) : (i1, i1) -> i1
    %pair_val0_243 = "transfer.xor"(%pair_val_243, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_243 = "transfer.select"(%pair_valid_243, %pair_val0_243, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_243 = "transfer.select"(%pair_valid_243, %pair_val_243, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_243 = "transfer.and"(%pair_acc0_242, %pair_sel0_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_243 = "transfer.and"(%pair_acc1_242, %pair_sel1_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_243 = "arith.ori"(%pair_any_242, %pair_valid_243) : (i1, i1) -> i1
    %pair_rhs_nz_244 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_244 = "transfer.select"(%pair_rhs_nz_244, %rhsu_v4, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_244 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_244 = "transfer.cmp"(%rhsu_v4, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_244 = "arith.andi"(%pair_lhs_eq_smin_244, %pair_rhs_eq_m1_244) : (i1, i1) -> i1
    %pair_not_ub_244 = "arith.xori"(%pair_ub_244, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_244 = "arith.andi"(%pair_rhs_nz_244, %pair_not_ub_244) : (i1, i1) -> i1
    %pair_val_244 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_244 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_244 = "transfer.cmp"(%pair_rem_244, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_244 = "arith.andi"(%pair_valid_sdiv_244, %pair_exact_244) : (i1, i1) -> i1
    %pair_val0_244 = "transfer.xor"(%pair_val_244, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_244 = "transfer.select"(%pair_valid_244, %pair_val0_244, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_244 = "transfer.select"(%pair_valid_244, %pair_val_244, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_244 = "transfer.and"(%pair_acc0_243, %pair_sel0_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_244 = "transfer.and"(%pair_acc1_243, %pair_sel1_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_244 = "arith.ori"(%pair_any_243, %pair_valid_244) : (i1, i1) -> i1
    %pair_rhs_nz_245 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_245 = "transfer.select"(%pair_rhs_nz_245, %rhsu_v5, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_245 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_245 = "transfer.cmp"(%rhsu_v5, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_245 = "arith.andi"(%pair_lhs_eq_smin_245, %pair_rhs_eq_m1_245) : (i1, i1) -> i1
    %pair_not_ub_245 = "arith.xori"(%pair_ub_245, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_245 = "arith.andi"(%pair_rhs_nz_245, %pair_not_ub_245) : (i1, i1) -> i1
    %pair_val_245 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_245 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_245 = "transfer.cmp"(%pair_rem_245, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_245 = "arith.andi"(%pair_valid_sdiv_245, %pair_exact_245) : (i1, i1) -> i1
    %pair_val0_245 = "transfer.xor"(%pair_val_245, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_245 = "transfer.select"(%pair_valid_245, %pair_val0_245, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_245 = "transfer.select"(%pair_valid_245, %pair_val_245, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_245 = "transfer.and"(%pair_acc0_244, %pair_sel0_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_245 = "transfer.and"(%pair_acc1_244, %pair_sel1_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_245 = "arith.ori"(%pair_any_244, %pair_valid_245) : (i1, i1) -> i1
    %pair_rhs_nz_246 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_246 = "transfer.select"(%pair_rhs_nz_246, %rhsu_v6, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_246 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_246 = "transfer.cmp"(%rhsu_v6, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_246 = "arith.andi"(%pair_lhs_eq_smin_246, %pair_rhs_eq_m1_246) : (i1, i1) -> i1
    %pair_not_ub_246 = "arith.xori"(%pair_ub_246, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_246 = "arith.andi"(%pair_rhs_nz_246, %pair_not_ub_246) : (i1, i1) -> i1
    %pair_val_246 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_246 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_246 = "transfer.cmp"(%pair_rem_246, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_246 = "arith.andi"(%pair_valid_sdiv_246, %pair_exact_246) : (i1, i1) -> i1
    %pair_val0_246 = "transfer.xor"(%pair_val_246, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_246 = "transfer.select"(%pair_valid_246, %pair_val0_246, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_246 = "transfer.select"(%pair_valid_246, %pair_val_246, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_246 = "transfer.and"(%pair_acc0_245, %pair_sel0_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_246 = "transfer.and"(%pair_acc1_245, %pair_sel1_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_246 = "arith.ori"(%pair_any_245, %pair_valid_246) : (i1, i1) -> i1
    %pair_rhs_nz_247 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_247 = "transfer.select"(%pair_rhs_nz_247, %rhsu_v7, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_247 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_247 = "transfer.cmp"(%rhsu_v7, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_247 = "arith.andi"(%pair_lhs_eq_smin_247, %pair_rhs_eq_m1_247) : (i1, i1) -> i1
    %pair_not_ub_247 = "arith.xori"(%pair_ub_247, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_247 = "arith.andi"(%pair_rhs_nz_247, %pair_not_ub_247) : (i1, i1) -> i1
    %pair_val_247 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_247 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_247 = "transfer.cmp"(%pair_rem_247, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_247 = "arith.andi"(%pair_valid_sdiv_247, %pair_exact_247) : (i1, i1) -> i1
    %pair_val0_247 = "transfer.xor"(%pair_val_247, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_247 = "transfer.select"(%pair_valid_247, %pair_val0_247, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_247 = "transfer.select"(%pair_valid_247, %pair_val_247, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_247 = "transfer.and"(%pair_acc0_246, %pair_sel0_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_247 = "transfer.and"(%pair_acc1_246, %pair_sel1_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_247 = "arith.ori"(%pair_any_246, %pair_valid_247) : (i1, i1) -> i1
    %pair_rhs_nz_248 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_248 = "transfer.select"(%pair_rhs_nz_248, %rhsu_v8, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_248 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_248 = "transfer.cmp"(%rhsu_v8, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_248 = "arith.andi"(%pair_lhs_eq_smin_248, %pair_rhs_eq_m1_248) : (i1, i1) -> i1
    %pair_not_ub_248 = "arith.xori"(%pair_ub_248, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_248 = "arith.andi"(%pair_rhs_nz_248, %pair_not_ub_248) : (i1, i1) -> i1
    %pair_val_248 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_248 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_248 = "transfer.cmp"(%pair_rem_248, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_248 = "arith.andi"(%pair_valid_sdiv_248, %pair_exact_248) : (i1, i1) -> i1
    %pair_val0_248 = "transfer.xor"(%pair_val_248, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_248 = "transfer.select"(%pair_valid_248, %pair_val0_248, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_248 = "transfer.select"(%pair_valid_248, %pair_val_248, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_248 = "transfer.and"(%pair_acc0_247, %pair_sel0_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_248 = "transfer.and"(%pair_acc1_247, %pair_sel1_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_248 = "arith.ori"(%pair_any_247, %pair_valid_248) : (i1, i1) -> i1
    %pair_rhs_nz_249 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_249 = "transfer.select"(%pair_rhs_nz_249, %rhsu_v9, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_249 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_249 = "transfer.cmp"(%rhsu_v9, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_249 = "arith.andi"(%pair_lhs_eq_smin_249, %pair_rhs_eq_m1_249) : (i1, i1) -> i1
    %pair_not_ub_249 = "arith.xori"(%pair_ub_249, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_249 = "arith.andi"(%pair_rhs_nz_249, %pair_not_ub_249) : (i1, i1) -> i1
    %pair_val_249 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_249 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_249 = "transfer.cmp"(%pair_rem_249, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_249 = "arith.andi"(%pair_valid_sdiv_249, %pair_exact_249) : (i1, i1) -> i1
    %pair_val0_249 = "transfer.xor"(%pair_val_249, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_249 = "transfer.select"(%pair_valid_249, %pair_val0_249, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_249 = "transfer.select"(%pair_valid_249, %pair_val_249, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_249 = "transfer.and"(%pair_acc0_248, %pair_sel0_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_249 = "transfer.and"(%pair_acc1_248, %pair_sel1_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_249 = "arith.ori"(%pair_any_248, %pair_valid_249) : (i1, i1) -> i1
    %pair_rhs_nz_250 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_250 = "transfer.select"(%pair_rhs_nz_250, %rhsu_v10, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_250 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_250 = "transfer.cmp"(%rhsu_v10, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_250 = "arith.andi"(%pair_lhs_eq_smin_250, %pair_rhs_eq_m1_250) : (i1, i1) -> i1
    %pair_not_ub_250 = "arith.xori"(%pair_ub_250, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_250 = "arith.andi"(%pair_rhs_nz_250, %pair_not_ub_250) : (i1, i1) -> i1
    %pair_val_250 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_250 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_250 = "transfer.cmp"(%pair_rem_250, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_250 = "arith.andi"(%pair_valid_sdiv_250, %pair_exact_250) : (i1, i1) -> i1
    %pair_val0_250 = "transfer.xor"(%pair_val_250, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_250 = "transfer.select"(%pair_valid_250, %pair_val0_250, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_250 = "transfer.select"(%pair_valid_250, %pair_val_250, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_250 = "transfer.and"(%pair_acc0_249, %pair_sel0_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_250 = "transfer.and"(%pair_acc1_249, %pair_sel1_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_250 = "arith.ori"(%pair_any_249, %pair_valid_250) : (i1, i1) -> i1
    %pair_rhs_nz_251 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_251 = "transfer.select"(%pair_rhs_nz_251, %rhsu_v11, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_251 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_251 = "transfer.cmp"(%rhsu_v11, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_251 = "arith.andi"(%pair_lhs_eq_smin_251, %pair_rhs_eq_m1_251) : (i1, i1) -> i1
    %pair_not_ub_251 = "arith.xori"(%pair_ub_251, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_251 = "arith.andi"(%pair_rhs_nz_251, %pair_not_ub_251) : (i1, i1) -> i1
    %pair_val_251 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_251 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_251 = "transfer.cmp"(%pair_rem_251, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_251 = "arith.andi"(%pair_valid_sdiv_251, %pair_exact_251) : (i1, i1) -> i1
    %pair_val0_251 = "transfer.xor"(%pair_val_251, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_251 = "transfer.select"(%pair_valid_251, %pair_val0_251, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_251 = "transfer.select"(%pair_valid_251, %pair_val_251, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_251 = "transfer.and"(%pair_acc0_250, %pair_sel0_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_251 = "transfer.and"(%pair_acc1_250, %pair_sel1_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_251 = "arith.ori"(%pair_any_250, %pair_valid_251) : (i1, i1) -> i1
    %pair_rhs_nz_252 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_252 = "transfer.select"(%pair_rhs_nz_252, %rhsu_v12, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_252 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_252 = "transfer.cmp"(%rhsu_v12, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_252 = "arith.andi"(%pair_lhs_eq_smin_252, %pair_rhs_eq_m1_252) : (i1, i1) -> i1
    %pair_not_ub_252 = "arith.xori"(%pair_ub_252, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_252 = "arith.andi"(%pair_rhs_nz_252, %pair_not_ub_252) : (i1, i1) -> i1
    %pair_val_252 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_252 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_252 = "transfer.cmp"(%pair_rem_252, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_252 = "arith.andi"(%pair_valid_sdiv_252, %pair_exact_252) : (i1, i1) -> i1
    %pair_val0_252 = "transfer.xor"(%pair_val_252, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_252 = "transfer.select"(%pair_valid_252, %pair_val0_252, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_252 = "transfer.select"(%pair_valid_252, %pair_val_252, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_252 = "transfer.and"(%pair_acc0_251, %pair_sel0_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_252 = "transfer.and"(%pair_acc1_251, %pair_sel1_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_252 = "arith.ori"(%pair_any_251, %pair_valid_252) : (i1, i1) -> i1
    %pair_rhs_nz_253 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_253 = "transfer.select"(%pair_rhs_nz_253, %rhsu_v13, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_253 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_253 = "transfer.cmp"(%rhsu_v13, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_253 = "arith.andi"(%pair_lhs_eq_smin_253, %pair_rhs_eq_m1_253) : (i1, i1) -> i1
    %pair_not_ub_253 = "arith.xori"(%pair_ub_253, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_253 = "arith.andi"(%pair_rhs_nz_253, %pair_not_ub_253) : (i1, i1) -> i1
    %pair_val_253 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_253 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_253 = "transfer.cmp"(%pair_rem_253, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_253 = "arith.andi"(%pair_valid_sdiv_253, %pair_exact_253) : (i1, i1) -> i1
    %pair_val0_253 = "transfer.xor"(%pair_val_253, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_253 = "transfer.select"(%pair_valid_253, %pair_val0_253, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_253 = "transfer.select"(%pair_valid_253, %pair_val_253, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_253 = "transfer.and"(%pair_acc0_252, %pair_sel0_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_253 = "transfer.and"(%pair_acc1_252, %pair_sel1_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_253 = "arith.ori"(%pair_any_252, %pair_valid_253) : (i1, i1) -> i1
    %pair_rhs_nz_254 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_254 = "transfer.select"(%pair_rhs_nz_254, %rhsu_v14, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_254 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_254 = "transfer.cmp"(%rhsu_v14, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_254 = "arith.andi"(%pair_lhs_eq_smin_254, %pair_rhs_eq_m1_254) : (i1, i1) -> i1
    %pair_not_ub_254 = "arith.xori"(%pair_ub_254, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_254 = "arith.andi"(%pair_rhs_nz_254, %pair_not_ub_254) : (i1, i1) -> i1
    %pair_val_254 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_254 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_254 = "transfer.cmp"(%pair_rem_254, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_254 = "arith.andi"(%pair_valid_sdiv_254, %pair_exact_254) : (i1, i1) -> i1
    %pair_val0_254 = "transfer.xor"(%pair_val_254, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_254 = "transfer.select"(%pair_valid_254, %pair_val0_254, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_254 = "transfer.select"(%pair_valid_254, %pair_val_254, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_254 = "transfer.and"(%pair_acc0_253, %pair_sel0_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_254 = "transfer.and"(%pair_acc1_253, %pair_sel1_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_254 = "arith.ori"(%pair_any_253, %pair_valid_254) : (i1, i1) -> i1
    %pair_rhs_nz_255 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_safe_255 = "transfer.select"(%pair_rhs_nz_255, %rhsu_v15, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_lhs_eq_smin_255 = "transfer.cmp"(%lhsu_v15, %signed_min) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_eq_m1_255 = "transfer.cmp"(%rhsu_v15, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_ub_255 = "arith.andi"(%pair_lhs_eq_smin_255, %pair_rhs_eq_m1_255) : (i1, i1) -> i1
    %pair_not_ub_255 = "arith.xori"(%pair_ub_255, %const_true) : (i1, i1) -> i1
    %pair_valid_sdiv_255 = "arith.andi"(%pair_rhs_nz_255, %pair_not_ub_255) : (i1, i1) -> i1
    %pair_val_255 = "transfer.sdiv"(%lhsu_v15, %pair_rhs_safe_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_rem_255 = "transfer.srem"(%lhsu_v15, %pair_rhs_safe_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_exact_255 = "transfer.cmp"(%pair_rem_255, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_valid_255 = "arith.andi"(%pair_valid_sdiv_255, %pair_exact_255) : (i1, i1) -> i1
    %pair_val0_255 = "transfer.xor"(%pair_val_255, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_255 = "transfer.select"(%pair_valid_255, %pair_val0_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_255 = "transfer.select"(%pair_valid_255, %pair_val_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_255 = "transfer.and"(%pair_acc0_254, %pair_sel0_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_255 = "transfer.and"(%pair_acc1_254, %pair_sel1_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_255 = "arith.ori"(%pair_any_254, %pair_valid_255) : (i1, i1) -> i1
    %res0_exact = "transfer.select"(%pair_any_255, %pair_acc0_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_exact = "transfer.select"(%pair_any_255, %pair_acc1_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%exact_on, %res0_exact, %res0_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%exact_on, %res1_exact, %res1_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_sdivexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
