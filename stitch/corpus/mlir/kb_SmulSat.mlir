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
    %signed_max = "transfer.get_signed_max_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
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
    %pair_mul_0 = "transfer.mul"(%lhsu_v0, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_0 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_0 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_0 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_0 = "arith.xori"(%pair_lhs_neg_0, %pair_rhs_neg_0) : (i1, i1) -> i1
    %pair_sat_0 = "transfer.select"(%pair_res_neg_0, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_0 = "transfer.select"(%pair_ov_0, %pair_sat_0, %pair_mul_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_0 = "transfer.xor"(%pair_val_0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_0 = "transfer.select"(%const_true, %pair_val0_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_0 = "transfer.select"(%const_true, %pair_val_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_0 = "transfer.and"(%all_ones, %pair_sel0_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_0 = "transfer.and"(%all_ones, %pair_sel1_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_0 = "arith.ori"(%const_false, %const_true) : (i1, i1) -> i1
    %pair_mul_1 = "transfer.mul"(%lhsu_v0, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_1 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_1 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_1 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_1 = "arith.xori"(%pair_lhs_neg_1, %pair_rhs_neg_1) : (i1, i1) -> i1
    %pair_sat_1 = "transfer.select"(%pair_res_neg_1, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_1 = "transfer.select"(%pair_ov_1, %pair_sat_1, %pair_mul_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_1 = "transfer.xor"(%pair_val_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_1 = "transfer.select"(%const_true, %pair_val0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_1 = "transfer.select"(%const_true, %pair_val_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_1 = "transfer.and"(%pair_acc0_0, %pair_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_1 = "transfer.and"(%pair_acc1_0, %pair_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_1 = "arith.ori"(%pair_any_0, %const_true) : (i1, i1) -> i1
    %pair_mul_2 = "transfer.mul"(%lhsu_v0, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_2 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_2 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_2 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_2 = "arith.xori"(%pair_lhs_neg_2, %pair_rhs_neg_2) : (i1, i1) -> i1
    %pair_sat_2 = "transfer.select"(%pair_res_neg_2, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_2 = "transfer.select"(%pair_ov_2, %pair_sat_2, %pair_mul_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_2 = "transfer.xor"(%pair_val_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_2 = "transfer.select"(%const_true, %pair_val0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_2 = "transfer.select"(%const_true, %pair_val_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_2 = "transfer.and"(%pair_acc0_1, %pair_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_2 = "transfer.and"(%pair_acc1_1, %pair_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_2 = "arith.ori"(%pair_any_1, %const_true) : (i1, i1) -> i1
    %pair_mul_3 = "transfer.mul"(%lhsu_v0, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_3 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_3 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_3 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_3 = "arith.xori"(%pair_lhs_neg_3, %pair_rhs_neg_3) : (i1, i1) -> i1
    %pair_sat_3 = "transfer.select"(%pair_res_neg_3, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_3 = "transfer.select"(%pair_ov_3, %pair_sat_3, %pair_mul_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_3 = "transfer.xor"(%pair_val_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_3 = "transfer.select"(%const_true, %pair_val0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_3 = "transfer.select"(%const_true, %pair_val_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_3 = "transfer.and"(%pair_acc0_2, %pair_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_3 = "transfer.and"(%pair_acc1_2, %pair_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_3 = "arith.ori"(%pair_any_2, %const_true) : (i1, i1) -> i1
    %pair_mul_4 = "transfer.mul"(%lhsu_v0, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_4 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_4 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_4 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_4 = "arith.xori"(%pair_lhs_neg_4, %pair_rhs_neg_4) : (i1, i1) -> i1
    %pair_sat_4 = "transfer.select"(%pair_res_neg_4, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_4 = "transfer.select"(%pair_ov_4, %pair_sat_4, %pair_mul_4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_4 = "transfer.xor"(%pair_val_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_4 = "transfer.select"(%const_true, %pair_val0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_4 = "transfer.select"(%const_true, %pair_val_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_4 = "transfer.and"(%pair_acc0_3, %pair_sel0_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_4 = "transfer.and"(%pair_acc1_3, %pair_sel1_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_4 = "arith.ori"(%pair_any_3, %const_true) : (i1, i1) -> i1
    %pair_mul_5 = "transfer.mul"(%lhsu_v0, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_5 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_5 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_5 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_5 = "arith.xori"(%pair_lhs_neg_5, %pair_rhs_neg_5) : (i1, i1) -> i1
    %pair_sat_5 = "transfer.select"(%pair_res_neg_5, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_5 = "transfer.select"(%pair_ov_5, %pair_sat_5, %pair_mul_5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_5 = "transfer.xor"(%pair_val_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_5 = "transfer.select"(%const_true, %pair_val0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_5 = "transfer.select"(%const_true, %pair_val_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_5 = "transfer.and"(%pair_acc0_4, %pair_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_5 = "transfer.and"(%pair_acc1_4, %pair_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_5 = "arith.ori"(%pair_any_4, %const_true) : (i1, i1) -> i1
    %pair_mul_6 = "transfer.mul"(%lhsu_v0, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_6 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_6 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_6 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_6 = "arith.xori"(%pair_lhs_neg_6, %pair_rhs_neg_6) : (i1, i1) -> i1
    %pair_sat_6 = "transfer.select"(%pair_res_neg_6, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_6 = "transfer.select"(%pair_ov_6, %pair_sat_6, %pair_mul_6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_6 = "transfer.xor"(%pair_val_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_6 = "transfer.select"(%const_true, %pair_val0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_6 = "transfer.select"(%const_true, %pair_val_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_6 = "transfer.and"(%pair_acc0_5, %pair_sel0_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_6 = "transfer.and"(%pair_acc1_5, %pair_sel1_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_6 = "arith.ori"(%pair_any_5, %const_true) : (i1, i1) -> i1
    %pair_mul_7 = "transfer.mul"(%lhsu_v0, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_7 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_7 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_7 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_7 = "arith.xori"(%pair_lhs_neg_7, %pair_rhs_neg_7) : (i1, i1) -> i1
    %pair_sat_7 = "transfer.select"(%pair_res_neg_7, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_7 = "transfer.select"(%pair_ov_7, %pair_sat_7, %pair_mul_7) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_7 = "transfer.xor"(%pair_val_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_7 = "transfer.select"(%const_true, %pair_val0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_7 = "transfer.select"(%const_true, %pair_val_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_7 = "transfer.and"(%pair_acc0_6, %pair_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_7 = "transfer.and"(%pair_acc1_6, %pair_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_7 = "arith.ori"(%pair_any_6, %const_true) : (i1, i1) -> i1
    %pair_mul_8 = "transfer.mul"(%lhsu_v0, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_8 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_8 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_8 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_8 = "arith.xori"(%pair_lhs_neg_8, %pair_rhs_neg_8) : (i1, i1) -> i1
    %pair_sat_8 = "transfer.select"(%pair_res_neg_8, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_8 = "transfer.select"(%pair_ov_8, %pair_sat_8, %pair_mul_8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_8 = "transfer.xor"(%pair_val_8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_8 = "transfer.select"(%const_true, %pair_val0_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_8 = "transfer.select"(%const_true, %pair_val_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_8 = "transfer.and"(%pair_acc0_7, %pair_sel0_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_8 = "transfer.and"(%pair_acc1_7, %pair_sel1_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_8 = "arith.ori"(%pair_any_7, %const_true) : (i1, i1) -> i1
    %pair_mul_9 = "transfer.mul"(%lhsu_v0, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_9 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_9 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_9 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_9 = "arith.xori"(%pair_lhs_neg_9, %pair_rhs_neg_9) : (i1, i1) -> i1
    %pair_sat_9 = "transfer.select"(%pair_res_neg_9, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_9 = "transfer.select"(%pair_ov_9, %pair_sat_9, %pair_mul_9) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_9 = "transfer.xor"(%pair_val_9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_9 = "transfer.select"(%const_true, %pair_val0_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_9 = "transfer.select"(%const_true, %pair_val_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_9 = "transfer.and"(%pair_acc0_8, %pair_sel0_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_9 = "transfer.and"(%pair_acc1_8, %pair_sel1_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_9 = "arith.ori"(%pair_any_8, %const_true) : (i1, i1) -> i1
    %pair_mul_10 = "transfer.mul"(%lhsu_v0, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_10 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_10 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_10 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_10 = "arith.xori"(%pair_lhs_neg_10, %pair_rhs_neg_10) : (i1, i1) -> i1
    %pair_sat_10 = "transfer.select"(%pair_res_neg_10, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_10 = "transfer.select"(%pair_ov_10, %pair_sat_10, %pair_mul_10) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_10 = "transfer.xor"(%pair_val_10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_10 = "transfer.select"(%const_true, %pair_val0_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_10 = "transfer.select"(%const_true, %pair_val_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_10 = "transfer.and"(%pair_acc0_9, %pair_sel0_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_10 = "transfer.and"(%pair_acc1_9, %pair_sel1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_10 = "arith.ori"(%pair_any_9, %const_true) : (i1, i1) -> i1
    %pair_mul_11 = "transfer.mul"(%lhsu_v0, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_11 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_11 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_11 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_11 = "arith.xori"(%pair_lhs_neg_11, %pair_rhs_neg_11) : (i1, i1) -> i1
    %pair_sat_11 = "transfer.select"(%pair_res_neg_11, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_11 = "transfer.select"(%pair_ov_11, %pair_sat_11, %pair_mul_11) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_11 = "transfer.xor"(%pair_val_11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_11 = "transfer.select"(%const_true, %pair_val0_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_11 = "transfer.select"(%const_true, %pair_val_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_11 = "transfer.and"(%pair_acc0_10, %pair_sel0_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_11 = "transfer.and"(%pair_acc1_10, %pair_sel1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_11 = "arith.ori"(%pair_any_10, %const_true) : (i1, i1) -> i1
    %pair_mul_12 = "transfer.mul"(%lhsu_v0, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_12 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_12 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_12 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_12 = "arith.xori"(%pair_lhs_neg_12, %pair_rhs_neg_12) : (i1, i1) -> i1
    %pair_sat_12 = "transfer.select"(%pair_res_neg_12, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_12 = "transfer.select"(%pair_ov_12, %pair_sat_12, %pair_mul_12) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_12 = "transfer.xor"(%pair_val_12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_12 = "transfer.select"(%const_true, %pair_val0_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_12 = "transfer.select"(%const_true, %pair_val_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_12 = "transfer.and"(%pair_acc0_11, %pair_sel0_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_12 = "transfer.and"(%pair_acc1_11, %pair_sel1_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_12 = "arith.ori"(%pair_any_11, %const_true) : (i1, i1) -> i1
    %pair_mul_13 = "transfer.mul"(%lhsu_v0, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_13 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_13 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_13 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_13 = "arith.xori"(%pair_lhs_neg_13, %pair_rhs_neg_13) : (i1, i1) -> i1
    %pair_sat_13 = "transfer.select"(%pair_res_neg_13, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_13 = "transfer.select"(%pair_ov_13, %pair_sat_13, %pair_mul_13) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_13 = "transfer.xor"(%pair_val_13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_13 = "transfer.select"(%const_true, %pair_val0_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_13 = "transfer.select"(%const_true, %pair_val_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_13 = "transfer.and"(%pair_acc0_12, %pair_sel0_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_13 = "transfer.and"(%pair_acc1_12, %pair_sel1_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_13 = "arith.ori"(%pair_any_12, %const_true) : (i1, i1) -> i1
    %pair_mul_14 = "transfer.mul"(%lhsu_v0, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_14 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_14 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_14 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_14 = "arith.xori"(%pair_lhs_neg_14, %pair_rhs_neg_14) : (i1, i1) -> i1
    %pair_sat_14 = "transfer.select"(%pair_res_neg_14, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_14 = "transfer.select"(%pair_ov_14, %pair_sat_14, %pair_mul_14) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_14 = "transfer.xor"(%pair_val_14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_14 = "transfer.select"(%const_true, %pair_val0_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_14 = "transfer.select"(%const_true, %pair_val_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_14 = "transfer.and"(%pair_acc0_13, %pair_sel0_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_14 = "transfer.and"(%pair_acc1_13, %pair_sel1_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_14 = "arith.ori"(%pair_any_13, %const_true) : (i1, i1) -> i1
    %pair_mul_15 = "transfer.mul"(%lhsu_v0, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_15 = "transfer.smul_overflow"(%lhsu_v0, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_15 = "transfer.cmp"(%lhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_15 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_15 = "arith.xori"(%pair_lhs_neg_15, %pair_rhs_neg_15) : (i1, i1) -> i1
    %pair_sat_15 = "transfer.select"(%pair_res_neg_15, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_15 = "transfer.select"(%pair_ov_15, %pair_sat_15, %pair_mul_15) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_15 = "transfer.xor"(%pair_val_15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_15 = "transfer.select"(%const_true, %pair_val0_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_15 = "transfer.select"(%const_true, %pair_val_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_15 = "transfer.and"(%pair_acc0_14, %pair_sel0_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_15 = "transfer.and"(%pair_acc1_14, %pair_sel1_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_15 = "arith.ori"(%pair_any_14, %const_true) : (i1, i1) -> i1
    %pair_mul_16 = "transfer.mul"(%lhsu_v1, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_16 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_16 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_16 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_16 = "arith.xori"(%pair_lhs_neg_16, %pair_rhs_neg_16) : (i1, i1) -> i1
    %pair_sat_16 = "transfer.select"(%pair_res_neg_16, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_16 = "transfer.select"(%pair_ov_16, %pair_sat_16, %pair_mul_16) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_16 = "transfer.xor"(%pair_val_16, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_16 = "transfer.select"(%const_true, %pair_val0_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_16 = "transfer.select"(%const_true, %pair_val_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_16 = "transfer.and"(%pair_acc0_15, %pair_sel0_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_16 = "transfer.and"(%pair_acc1_15, %pair_sel1_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_16 = "arith.ori"(%pair_any_15, %const_true) : (i1, i1) -> i1
    %pair_mul_17 = "transfer.mul"(%lhsu_v1, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_17 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_17 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_17 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_17 = "arith.xori"(%pair_lhs_neg_17, %pair_rhs_neg_17) : (i1, i1) -> i1
    %pair_sat_17 = "transfer.select"(%pair_res_neg_17, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_17 = "transfer.select"(%pair_ov_17, %pair_sat_17, %pair_mul_17) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_17 = "transfer.xor"(%pair_val_17, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_17 = "transfer.select"(%const_true, %pair_val0_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_17 = "transfer.select"(%const_true, %pair_val_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_17 = "transfer.and"(%pair_acc0_16, %pair_sel0_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_17 = "transfer.and"(%pair_acc1_16, %pair_sel1_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_17 = "arith.ori"(%pair_any_16, %const_true) : (i1, i1) -> i1
    %pair_mul_18 = "transfer.mul"(%lhsu_v1, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_18 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_18 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_18 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_18 = "arith.xori"(%pair_lhs_neg_18, %pair_rhs_neg_18) : (i1, i1) -> i1
    %pair_sat_18 = "transfer.select"(%pair_res_neg_18, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_18 = "transfer.select"(%pair_ov_18, %pair_sat_18, %pair_mul_18) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_18 = "transfer.xor"(%pair_val_18, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_18 = "transfer.select"(%const_true, %pair_val0_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_18 = "transfer.select"(%const_true, %pair_val_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_18 = "transfer.and"(%pair_acc0_17, %pair_sel0_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_18 = "transfer.and"(%pair_acc1_17, %pair_sel1_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_18 = "arith.ori"(%pair_any_17, %const_true) : (i1, i1) -> i1
    %pair_mul_19 = "transfer.mul"(%lhsu_v1, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_19 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_19 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_19 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_19 = "arith.xori"(%pair_lhs_neg_19, %pair_rhs_neg_19) : (i1, i1) -> i1
    %pair_sat_19 = "transfer.select"(%pair_res_neg_19, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_19 = "transfer.select"(%pair_ov_19, %pair_sat_19, %pair_mul_19) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_19 = "transfer.xor"(%pair_val_19, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_19 = "transfer.select"(%const_true, %pair_val0_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_19 = "transfer.select"(%const_true, %pair_val_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_19 = "transfer.and"(%pair_acc0_18, %pair_sel0_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_19 = "transfer.and"(%pair_acc1_18, %pair_sel1_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_19 = "arith.ori"(%pair_any_18, %const_true) : (i1, i1) -> i1
    %pair_mul_20 = "transfer.mul"(%lhsu_v1, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_20 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_20 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_20 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_20 = "arith.xori"(%pair_lhs_neg_20, %pair_rhs_neg_20) : (i1, i1) -> i1
    %pair_sat_20 = "transfer.select"(%pair_res_neg_20, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_20 = "transfer.select"(%pair_ov_20, %pair_sat_20, %pair_mul_20) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_20 = "transfer.xor"(%pair_val_20, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_20 = "transfer.select"(%const_true, %pair_val0_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_20 = "transfer.select"(%const_true, %pair_val_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_20 = "transfer.and"(%pair_acc0_19, %pair_sel0_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_20 = "transfer.and"(%pair_acc1_19, %pair_sel1_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_20 = "arith.ori"(%pair_any_19, %const_true) : (i1, i1) -> i1
    %pair_mul_21 = "transfer.mul"(%lhsu_v1, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_21 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_21 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_21 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_21 = "arith.xori"(%pair_lhs_neg_21, %pair_rhs_neg_21) : (i1, i1) -> i1
    %pair_sat_21 = "transfer.select"(%pair_res_neg_21, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_21 = "transfer.select"(%pair_ov_21, %pair_sat_21, %pair_mul_21) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_21 = "transfer.xor"(%pair_val_21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_21 = "transfer.select"(%const_true, %pair_val0_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_21 = "transfer.select"(%const_true, %pair_val_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_21 = "transfer.and"(%pair_acc0_20, %pair_sel0_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_21 = "transfer.and"(%pair_acc1_20, %pair_sel1_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_21 = "arith.ori"(%pair_any_20, %const_true) : (i1, i1) -> i1
    %pair_mul_22 = "transfer.mul"(%lhsu_v1, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_22 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_22 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_22 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_22 = "arith.xori"(%pair_lhs_neg_22, %pair_rhs_neg_22) : (i1, i1) -> i1
    %pair_sat_22 = "transfer.select"(%pair_res_neg_22, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_22 = "transfer.select"(%pair_ov_22, %pair_sat_22, %pair_mul_22) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_22 = "transfer.xor"(%pair_val_22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_22 = "transfer.select"(%const_true, %pair_val0_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_22 = "transfer.select"(%const_true, %pair_val_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_22 = "transfer.and"(%pair_acc0_21, %pair_sel0_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_22 = "transfer.and"(%pair_acc1_21, %pair_sel1_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_22 = "arith.ori"(%pair_any_21, %const_true) : (i1, i1) -> i1
    %pair_mul_23 = "transfer.mul"(%lhsu_v1, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_23 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_23 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_23 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_23 = "arith.xori"(%pair_lhs_neg_23, %pair_rhs_neg_23) : (i1, i1) -> i1
    %pair_sat_23 = "transfer.select"(%pair_res_neg_23, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_23 = "transfer.select"(%pair_ov_23, %pair_sat_23, %pair_mul_23) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_23 = "transfer.xor"(%pair_val_23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_23 = "transfer.select"(%const_true, %pair_val0_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_23 = "transfer.select"(%const_true, %pair_val_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_23 = "transfer.and"(%pair_acc0_22, %pair_sel0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_23 = "transfer.and"(%pair_acc1_22, %pair_sel1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_23 = "arith.ori"(%pair_any_22, %const_true) : (i1, i1) -> i1
    %pair_mul_24 = "transfer.mul"(%lhsu_v1, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_24 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_24 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_24 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_24 = "arith.xori"(%pair_lhs_neg_24, %pair_rhs_neg_24) : (i1, i1) -> i1
    %pair_sat_24 = "transfer.select"(%pair_res_neg_24, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_24 = "transfer.select"(%pair_ov_24, %pair_sat_24, %pair_mul_24) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_24 = "transfer.xor"(%pair_val_24, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_24 = "transfer.select"(%const_true, %pair_val0_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_24 = "transfer.select"(%const_true, %pair_val_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_24 = "transfer.and"(%pair_acc0_23, %pair_sel0_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_24 = "transfer.and"(%pair_acc1_23, %pair_sel1_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_24 = "arith.ori"(%pair_any_23, %const_true) : (i1, i1) -> i1
    %pair_mul_25 = "transfer.mul"(%lhsu_v1, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_25 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_25 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_25 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_25 = "arith.xori"(%pair_lhs_neg_25, %pair_rhs_neg_25) : (i1, i1) -> i1
    %pair_sat_25 = "transfer.select"(%pair_res_neg_25, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_25 = "transfer.select"(%pair_ov_25, %pair_sat_25, %pair_mul_25) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_25 = "transfer.xor"(%pair_val_25, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_25 = "transfer.select"(%const_true, %pair_val0_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_25 = "transfer.select"(%const_true, %pair_val_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_25 = "transfer.and"(%pair_acc0_24, %pair_sel0_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_25 = "transfer.and"(%pair_acc1_24, %pair_sel1_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_25 = "arith.ori"(%pair_any_24, %const_true) : (i1, i1) -> i1
    %pair_mul_26 = "transfer.mul"(%lhsu_v1, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_26 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_26 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_26 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_26 = "arith.xori"(%pair_lhs_neg_26, %pair_rhs_neg_26) : (i1, i1) -> i1
    %pair_sat_26 = "transfer.select"(%pair_res_neg_26, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_26 = "transfer.select"(%pair_ov_26, %pair_sat_26, %pair_mul_26) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_26 = "transfer.xor"(%pair_val_26, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_26 = "transfer.select"(%const_true, %pair_val0_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_26 = "transfer.select"(%const_true, %pair_val_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_26 = "transfer.and"(%pair_acc0_25, %pair_sel0_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_26 = "transfer.and"(%pair_acc1_25, %pair_sel1_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_26 = "arith.ori"(%pair_any_25, %const_true) : (i1, i1) -> i1
    %pair_mul_27 = "transfer.mul"(%lhsu_v1, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_27 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_27 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_27 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_27 = "arith.xori"(%pair_lhs_neg_27, %pair_rhs_neg_27) : (i1, i1) -> i1
    %pair_sat_27 = "transfer.select"(%pair_res_neg_27, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_27 = "transfer.select"(%pair_ov_27, %pair_sat_27, %pair_mul_27) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_27 = "transfer.xor"(%pair_val_27, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_27 = "transfer.select"(%const_true, %pair_val0_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_27 = "transfer.select"(%const_true, %pair_val_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_27 = "transfer.and"(%pair_acc0_26, %pair_sel0_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_27 = "transfer.and"(%pair_acc1_26, %pair_sel1_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_27 = "arith.ori"(%pair_any_26, %const_true) : (i1, i1) -> i1
    %pair_mul_28 = "transfer.mul"(%lhsu_v1, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_28 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_28 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_28 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_28 = "arith.xori"(%pair_lhs_neg_28, %pair_rhs_neg_28) : (i1, i1) -> i1
    %pair_sat_28 = "transfer.select"(%pair_res_neg_28, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_28 = "transfer.select"(%pair_ov_28, %pair_sat_28, %pair_mul_28) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_28 = "transfer.xor"(%pair_val_28, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_28 = "transfer.select"(%const_true, %pair_val0_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_28 = "transfer.select"(%const_true, %pair_val_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_28 = "transfer.and"(%pair_acc0_27, %pair_sel0_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_28 = "transfer.and"(%pair_acc1_27, %pair_sel1_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_28 = "arith.ori"(%pair_any_27, %const_true) : (i1, i1) -> i1
    %pair_mul_29 = "transfer.mul"(%lhsu_v1, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_29 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_29 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_29 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_29 = "arith.xori"(%pair_lhs_neg_29, %pair_rhs_neg_29) : (i1, i1) -> i1
    %pair_sat_29 = "transfer.select"(%pair_res_neg_29, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_29 = "transfer.select"(%pair_ov_29, %pair_sat_29, %pair_mul_29) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_29 = "transfer.xor"(%pair_val_29, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_29 = "transfer.select"(%const_true, %pair_val0_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_29 = "transfer.select"(%const_true, %pair_val_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_29 = "transfer.and"(%pair_acc0_28, %pair_sel0_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_29 = "transfer.and"(%pair_acc1_28, %pair_sel1_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_29 = "arith.ori"(%pair_any_28, %const_true) : (i1, i1) -> i1
    %pair_mul_30 = "transfer.mul"(%lhsu_v1, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_30 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_30 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_30 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_30 = "arith.xori"(%pair_lhs_neg_30, %pair_rhs_neg_30) : (i1, i1) -> i1
    %pair_sat_30 = "transfer.select"(%pair_res_neg_30, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_30 = "transfer.select"(%pair_ov_30, %pair_sat_30, %pair_mul_30) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_30 = "transfer.xor"(%pair_val_30, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_30 = "transfer.select"(%const_true, %pair_val0_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_30 = "transfer.select"(%const_true, %pair_val_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_30 = "transfer.and"(%pair_acc0_29, %pair_sel0_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_30 = "transfer.and"(%pair_acc1_29, %pair_sel1_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_30 = "arith.ori"(%pair_any_29, %const_true) : (i1, i1) -> i1
    %pair_mul_31 = "transfer.mul"(%lhsu_v1, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_31 = "transfer.smul_overflow"(%lhsu_v1, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_31 = "transfer.cmp"(%lhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_31 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_31 = "arith.xori"(%pair_lhs_neg_31, %pair_rhs_neg_31) : (i1, i1) -> i1
    %pair_sat_31 = "transfer.select"(%pair_res_neg_31, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_31 = "transfer.select"(%pair_ov_31, %pair_sat_31, %pair_mul_31) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_31 = "transfer.xor"(%pair_val_31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_31 = "transfer.select"(%const_true, %pair_val0_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_31 = "transfer.select"(%const_true, %pair_val_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_31 = "transfer.and"(%pair_acc0_30, %pair_sel0_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_31 = "transfer.and"(%pair_acc1_30, %pair_sel1_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_31 = "arith.ori"(%pair_any_30, %const_true) : (i1, i1) -> i1
    %pair_mul_32 = "transfer.mul"(%lhsu_v2, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_32 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_32 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_32 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_32 = "arith.xori"(%pair_lhs_neg_32, %pair_rhs_neg_32) : (i1, i1) -> i1
    %pair_sat_32 = "transfer.select"(%pair_res_neg_32, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_32 = "transfer.select"(%pair_ov_32, %pair_sat_32, %pair_mul_32) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_32 = "transfer.xor"(%pair_val_32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_32 = "transfer.select"(%const_true, %pair_val0_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_32 = "transfer.select"(%const_true, %pair_val_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_32 = "transfer.and"(%pair_acc0_31, %pair_sel0_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_32 = "transfer.and"(%pair_acc1_31, %pair_sel1_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_32 = "arith.ori"(%pair_any_31, %const_true) : (i1, i1) -> i1
    %pair_mul_33 = "transfer.mul"(%lhsu_v2, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_33 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_33 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_33 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_33 = "arith.xori"(%pair_lhs_neg_33, %pair_rhs_neg_33) : (i1, i1) -> i1
    %pair_sat_33 = "transfer.select"(%pair_res_neg_33, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_33 = "transfer.select"(%pair_ov_33, %pair_sat_33, %pair_mul_33) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_33 = "transfer.xor"(%pair_val_33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_33 = "transfer.select"(%const_true, %pair_val0_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_33 = "transfer.select"(%const_true, %pair_val_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_33 = "transfer.and"(%pair_acc0_32, %pair_sel0_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_33 = "transfer.and"(%pair_acc1_32, %pair_sel1_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_33 = "arith.ori"(%pair_any_32, %const_true) : (i1, i1) -> i1
    %pair_mul_34 = "transfer.mul"(%lhsu_v2, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_34 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_34 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_34 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_34 = "arith.xori"(%pair_lhs_neg_34, %pair_rhs_neg_34) : (i1, i1) -> i1
    %pair_sat_34 = "transfer.select"(%pair_res_neg_34, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_34 = "transfer.select"(%pair_ov_34, %pair_sat_34, %pair_mul_34) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_34 = "transfer.xor"(%pair_val_34, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_34 = "transfer.select"(%const_true, %pair_val0_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_34 = "transfer.select"(%const_true, %pair_val_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_34 = "transfer.and"(%pair_acc0_33, %pair_sel0_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_34 = "transfer.and"(%pair_acc1_33, %pair_sel1_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_34 = "arith.ori"(%pair_any_33, %const_true) : (i1, i1) -> i1
    %pair_mul_35 = "transfer.mul"(%lhsu_v2, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_35 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_35 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_35 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_35 = "arith.xori"(%pair_lhs_neg_35, %pair_rhs_neg_35) : (i1, i1) -> i1
    %pair_sat_35 = "transfer.select"(%pair_res_neg_35, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_35 = "transfer.select"(%pair_ov_35, %pair_sat_35, %pair_mul_35) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_35 = "transfer.xor"(%pair_val_35, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_35 = "transfer.select"(%const_true, %pair_val0_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_35 = "transfer.select"(%const_true, %pair_val_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_35 = "transfer.and"(%pair_acc0_34, %pair_sel0_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_35 = "transfer.and"(%pair_acc1_34, %pair_sel1_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_35 = "arith.ori"(%pair_any_34, %const_true) : (i1, i1) -> i1
    %pair_mul_36 = "transfer.mul"(%lhsu_v2, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_36 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_36 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_36 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_36 = "arith.xori"(%pair_lhs_neg_36, %pair_rhs_neg_36) : (i1, i1) -> i1
    %pair_sat_36 = "transfer.select"(%pair_res_neg_36, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_36 = "transfer.select"(%pair_ov_36, %pair_sat_36, %pair_mul_36) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_36 = "transfer.xor"(%pair_val_36, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_36 = "transfer.select"(%const_true, %pair_val0_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_36 = "transfer.select"(%const_true, %pair_val_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_36 = "transfer.and"(%pair_acc0_35, %pair_sel0_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_36 = "transfer.and"(%pair_acc1_35, %pair_sel1_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_36 = "arith.ori"(%pair_any_35, %const_true) : (i1, i1) -> i1
    %pair_mul_37 = "transfer.mul"(%lhsu_v2, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_37 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_37 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_37 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_37 = "arith.xori"(%pair_lhs_neg_37, %pair_rhs_neg_37) : (i1, i1) -> i1
    %pair_sat_37 = "transfer.select"(%pair_res_neg_37, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_37 = "transfer.select"(%pair_ov_37, %pair_sat_37, %pair_mul_37) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_37 = "transfer.xor"(%pair_val_37, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_37 = "transfer.select"(%const_true, %pair_val0_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_37 = "transfer.select"(%const_true, %pair_val_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_37 = "transfer.and"(%pair_acc0_36, %pair_sel0_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_37 = "transfer.and"(%pair_acc1_36, %pair_sel1_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_37 = "arith.ori"(%pair_any_36, %const_true) : (i1, i1) -> i1
    %pair_mul_38 = "transfer.mul"(%lhsu_v2, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_38 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_38 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_38 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_38 = "arith.xori"(%pair_lhs_neg_38, %pair_rhs_neg_38) : (i1, i1) -> i1
    %pair_sat_38 = "transfer.select"(%pair_res_neg_38, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_38 = "transfer.select"(%pair_ov_38, %pair_sat_38, %pair_mul_38) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_38 = "transfer.xor"(%pair_val_38, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_38 = "transfer.select"(%const_true, %pair_val0_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_38 = "transfer.select"(%const_true, %pair_val_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_38 = "transfer.and"(%pair_acc0_37, %pair_sel0_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_38 = "transfer.and"(%pair_acc1_37, %pair_sel1_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_38 = "arith.ori"(%pair_any_37, %const_true) : (i1, i1) -> i1
    %pair_mul_39 = "transfer.mul"(%lhsu_v2, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_39 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_39 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_39 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_39 = "arith.xori"(%pair_lhs_neg_39, %pair_rhs_neg_39) : (i1, i1) -> i1
    %pair_sat_39 = "transfer.select"(%pair_res_neg_39, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_39 = "transfer.select"(%pair_ov_39, %pair_sat_39, %pair_mul_39) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_39 = "transfer.xor"(%pair_val_39, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_39 = "transfer.select"(%const_true, %pair_val0_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_39 = "transfer.select"(%const_true, %pair_val_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_39 = "transfer.and"(%pair_acc0_38, %pair_sel0_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_39 = "transfer.and"(%pair_acc1_38, %pair_sel1_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_39 = "arith.ori"(%pair_any_38, %const_true) : (i1, i1) -> i1
    %pair_mul_40 = "transfer.mul"(%lhsu_v2, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_40 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_40 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_40 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_40 = "arith.xori"(%pair_lhs_neg_40, %pair_rhs_neg_40) : (i1, i1) -> i1
    %pair_sat_40 = "transfer.select"(%pair_res_neg_40, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_40 = "transfer.select"(%pair_ov_40, %pair_sat_40, %pair_mul_40) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_40 = "transfer.xor"(%pair_val_40, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_40 = "transfer.select"(%const_true, %pair_val0_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_40 = "transfer.select"(%const_true, %pair_val_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_40 = "transfer.and"(%pair_acc0_39, %pair_sel0_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_40 = "transfer.and"(%pair_acc1_39, %pair_sel1_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_40 = "arith.ori"(%pair_any_39, %const_true) : (i1, i1) -> i1
    %pair_mul_41 = "transfer.mul"(%lhsu_v2, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_41 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_41 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_41 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_41 = "arith.xori"(%pair_lhs_neg_41, %pair_rhs_neg_41) : (i1, i1) -> i1
    %pair_sat_41 = "transfer.select"(%pair_res_neg_41, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_41 = "transfer.select"(%pair_ov_41, %pair_sat_41, %pair_mul_41) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_41 = "transfer.xor"(%pair_val_41, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_41 = "transfer.select"(%const_true, %pair_val0_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_41 = "transfer.select"(%const_true, %pair_val_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_41 = "transfer.and"(%pair_acc0_40, %pair_sel0_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_41 = "transfer.and"(%pair_acc1_40, %pair_sel1_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_41 = "arith.ori"(%pair_any_40, %const_true) : (i1, i1) -> i1
    %pair_mul_42 = "transfer.mul"(%lhsu_v2, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_42 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_42 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_42 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_42 = "arith.xori"(%pair_lhs_neg_42, %pair_rhs_neg_42) : (i1, i1) -> i1
    %pair_sat_42 = "transfer.select"(%pair_res_neg_42, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_42 = "transfer.select"(%pair_ov_42, %pair_sat_42, %pair_mul_42) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_42 = "transfer.xor"(%pair_val_42, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_42 = "transfer.select"(%const_true, %pair_val0_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_42 = "transfer.select"(%const_true, %pair_val_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_42 = "transfer.and"(%pair_acc0_41, %pair_sel0_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_42 = "transfer.and"(%pair_acc1_41, %pair_sel1_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_42 = "arith.ori"(%pair_any_41, %const_true) : (i1, i1) -> i1
    %pair_mul_43 = "transfer.mul"(%lhsu_v2, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_43 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_43 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_43 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_43 = "arith.xori"(%pair_lhs_neg_43, %pair_rhs_neg_43) : (i1, i1) -> i1
    %pair_sat_43 = "transfer.select"(%pair_res_neg_43, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_43 = "transfer.select"(%pair_ov_43, %pair_sat_43, %pair_mul_43) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_43 = "transfer.xor"(%pair_val_43, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_43 = "transfer.select"(%const_true, %pair_val0_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_43 = "transfer.select"(%const_true, %pair_val_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_43 = "transfer.and"(%pair_acc0_42, %pair_sel0_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_43 = "transfer.and"(%pair_acc1_42, %pair_sel1_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_43 = "arith.ori"(%pair_any_42, %const_true) : (i1, i1) -> i1
    %pair_mul_44 = "transfer.mul"(%lhsu_v2, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_44 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_44 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_44 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_44 = "arith.xori"(%pair_lhs_neg_44, %pair_rhs_neg_44) : (i1, i1) -> i1
    %pair_sat_44 = "transfer.select"(%pair_res_neg_44, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_44 = "transfer.select"(%pair_ov_44, %pair_sat_44, %pair_mul_44) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_44 = "transfer.xor"(%pair_val_44, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_44 = "transfer.select"(%const_true, %pair_val0_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_44 = "transfer.select"(%const_true, %pair_val_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_44 = "transfer.and"(%pair_acc0_43, %pair_sel0_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_44 = "transfer.and"(%pair_acc1_43, %pair_sel1_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_44 = "arith.ori"(%pair_any_43, %const_true) : (i1, i1) -> i1
    %pair_mul_45 = "transfer.mul"(%lhsu_v2, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_45 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_45 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_45 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_45 = "arith.xori"(%pair_lhs_neg_45, %pair_rhs_neg_45) : (i1, i1) -> i1
    %pair_sat_45 = "transfer.select"(%pair_res_neg_45, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_45 = "transfer.select"(%pair_ov_45, %pair_sat_45, %pair_mul_45) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_45 = "transfer.xor"(%pair_val_45, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_45 = "transfer.select"(%const_true, %pair_val0_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_45 = "transfer.select"(%const_true, %pair_val_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_45 = "transfer.and"(%pair_acc0_44, %pair_sel0_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_45 = "transfer.and"(%pair_acc1_44, %pair_sel1_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_45 = "arith.ori"(%pair_any_44, %const_true) : (i1, i1) -> i1
    %pair_mul_46 = "transfer.mul"(%lhsu_v2, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_46 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_46 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_46 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_46 = "arith.xori"(%pair_lhs_neg_46, %pair_rhs_neg_46) : (i1, i1) -> i1
    %pair_sat_46 = "transfer.select"(%pair_res_neg_46, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_46 = "transfer.select"(%pair_ov_46, %pair_sat_46, %pair_mul_46) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_46 = "transfer.xor"(%pair_val_46, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_46 = "transfer.select"(%const_true, %pair_val0_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_46 = "transfer.select"(%const_true, %pair_val_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_46 = "transfer.and"(%pair_acc0_45, %pair_sel0_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_46 = "transfer.and"(%pair_acc1_45, %pair_sel1_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_46 = "arith.ori"(%pair_any_45, %const_true) : (i1, i1) -> i1
    %pair_mul_47 = "transfer.mul"(%lhsu_v2, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_47 = "transfer.smul_overflow"(%lhsu_v2, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_47 = "transfer.cmp"(%lhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_47 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_47 = "arith.xori"(%pair_lhs_neg_47, %pair_rhs_neg_47) : (i1, i1) -> i1
    %pair_sat_47 = "transfer.select"(%pair_res_neg_47, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_47 = "transfer.select"(%pair_ov_47, %pair_sat_47, %pair_mul_47) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_47 = "transfer.xor"(%pair_val_47, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_47 = "transfer.select"(%const_true, %pair_val0_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_47 = "transfer.select"(%const_true, %pair_val_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_47 = "transfer.and"(%pair_acc0_46, %pair_sel0_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_47 = "transfer.and"(%pair_acc1_46, %pair_sel1_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_47 = "arith.ori"(%pair_any_46, %const_true) : (i1, i1) -> i1
    %pair_mul_48 = "transfer.mul"(%lhsu_v3, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_48 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_48 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_48 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_48 = "arith.xori"(%pair_lhs_neg_48, %pair_rhs_neg_48) : (i1, i1) -> i1
    %pair_sat_48 = "transfer.select"(%pair_res_neg_48, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_48 = "transfer.select"(%pair_ov_48, %pair_sat_48, %pair_mul_48) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_48 = "transfer.xor"(%pair_val_48, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_48 = "transfer.select"(%const_true, %pair_val0_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_48 = "transfer.select"(%const_true, %pair_val_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_48 = "transfer.and"(%pair_acc0_47, %pair_sel0_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_48 = "transfer.and"(%pair_acc1_47, %pair_sel1_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_48 = "arith.ori"(%pair_any_47, %const_true) : (i1, i1) -> i1
    %pair_mul_49 = "transfer.mul"(%lhsu_v3, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_49 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_49 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_49 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_49 = "arith.xori"(%pair_lhs_neg_49, %pair_rhs_neg_49) : (i1, i1) -> i1
    %pair_sat_49 = "transfer.select"(%pair_res_neg_49, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_49 = "transfer.select"(%pair_ov_49, %pair_sat_49, %pair_mul_49) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_49 = "transfer.xor"(%pair_val_49, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_49 = "transfer.select"(%const_true, %pair_val0_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_49 = "transfer.select"(%const_true, %pair_val_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_49 = "transfer.and"(%pair_acc0_48, %pair_sel0_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_49 = "transfer.and"(%pair_acc1_48, %pair_sel1_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_49 = "arith.ori"(%pair_any_48, %const_true) : (i1, i1) -> i1
    %pair_mul_50 = "transfer.mul"(%lhsu_v3, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_50 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_50 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_50 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_50 = "arith.xori"(%pair_lhs_neg_50, %pair_rhs_neg_50) : (i1, i1) -> i1
    %pair_sat_50 = "transfer.select"(%pair_res_neg_50, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_50 = "transfer.select"(%pair_ov_50, %pair_sat_50, %pair_mul_50) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_50 = "transfer.xor"(%pair_val_50, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_50 = "transfer.select"(%const_true, %pair_val0_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_50 = "transfer.select"(%const_true, %pair_val_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_50 = "transfer.and"(%pair_acc0_49, %pair_sel0_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_50 = "transfer.and"(%pair_acc1_49, %pair_sel1_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_50 = "arith.ori"(%pair_any_49, %const_true) : (i1, i1) -> i1
    %pair_mul_51 = "transfer.mul"(%lhsu_v3, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_51 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_51 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_51 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_51 = "arith.xori"(%pair_lhs_neg_51, %pair_rhs_neg_51) : (i1, i1) -> i1
    %pair_sat_51 = "transfer.select"(%pair_res_neg_51, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_51 = "transfer.select"(%pair_ov_51, %pair_sat_51, %pair_mul_51) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_51 = "transfer.xor"(%pair_val_51, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_51 = "transfer.select"(%const_true, %pair_val0_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_51 = "transfer.select"(%const_true, %pair_val_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_51 = "transfer.and"(%pair_acc0_50, %pair_sel0_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_51 = "transfer.and"(%pair_acc1_50, %pair_sel1_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_51 = "arith.ori"(%pair_any_50, %const_true) : (i1, i1) -> i1
    %pair_mul_52 = "transfer.mul"(%lhsu_v3, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_52 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_52 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_52 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_52 = "arith.xori"(%pair_lhs_neg_52, %pair_rhs_neg_52) : (i1, i1) -> i1
    %pair_sat_52 = "transfer.select"(%pair_res_neg_52, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_52 = "transfer.select"(%pair_ov_52, %pair_sat_52, %pair_mul_52) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_52 = "transfer.xor"(%pair_val_52, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_52 = "transfer.select"(%const_true, %pair_val0_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_52 = "transfer.select"(%const_true, %pair_val_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_52 = "transfer.and"(%pair_acc0_51, %pair_sel0_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_52 = "transfer.and"(%pair_acc1_51, %pair_sel1_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_52 = "arith.ori"(%pair_any_51, %const_true) : (i1, i1) -> i1
    %pair_mul_53 = "transfer.mul"(%lhsu_v3, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_53 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_53 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_53 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_53 = "arith.xori"(%pair_lhs_neg_53, %pair_rhs_neg_53) : (i1, i1) -> i1
    %pair_sat_53 = "transfer.select"(%pair_res_neg_53, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_53 = "transfer.select"(%pair_ov_53, %pair_sat_53, %pair_mul_53) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_53 = "transfer.xor"(%pair_val_53, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_53 = "transfer.select"(%const_true, %pair_val0_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_53 = "transfer.select"(%const_true, %pair_val_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_53 = "transfer.and"(%pair_acc0_52, %pair_sel0_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_53 = "transfer.and"(%pair_acc1_52, %pair_sel1_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_53 = "arith.ori"(%pair_any_52, %const_true) : (i1, i1) -> i1
    %pair_mul_54 = "transfer.mul"(%lhsu_v3, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_54 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_54 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_54 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_54 = "arith.xori"(%pair_lhs_neg_54, %pair_rhs_neg_54) : (i1, i1) -> i1
    %pair_sat_54 = "transfer.select"(%pair_res_neg_54, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_54 = "transfer.select"(%pair_ov_54, %pair_sat_54, %pair_mul_54) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_54 = "transfer.xor"(%pair_val_54, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_54 = "transfer.select"(%const_true, %pair_val0_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_54 = "transfer.select"(%const_true, %pair_val_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_54 = "transfer.and"(%pair_acc0_53, %pair_sel0_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_54 = "transfer.and"(%pair_acc1_53, %pair_sel1_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_54 = "arith.ori"(%pair_any_53, %const_true) : (i1, i1) -> i1
    %pair_mul_55 = "transfer.mul"(%lhsu_v3, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_55 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_55 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_55 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_55 = "arith.xori"(%pair_lhs_neg_55, %pair_rhs_neg_55) : (i1, i1) -> i1
    %pair_sat_55 = "transfer.select"(%pair_res_neg_55, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_55 = "transfer.select"(%pair_ov_55, %pair_sat_55, %pair_mul_55) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_55 = "transfer.xor"(%pair_val_55, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_55 = "transfer.select"(%const_true, %pair_val0_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_55 = "transfer.select"(%const_true, %pair_val_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_55 = "transfer.and"(%pair_acc0_54, %pair_sel0_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_55 = "transfer.and"(%pair_acc1_54, %pair_sel1_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_55 = "arith.ori"(%pair_any_54, %const_true) : (i1, i1) -> i1
    %pair_mul_56 = "transfer.mul"(%lhsu_v3, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_56 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_56 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_56 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_56 = "arith.xori"(%pair_lhs_neg_56, %pair_rhs_neg_56) : (i1, i1) -> i1
    %pair_sat_56 = "transfer.select"(%pair_res_neg_56, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_56 = "transfer.select"(%pair_ov_56, %pair_sat_56, %pair_mul_56) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_56 = "transfer.xor"(%pair_val_56, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_56 = "transfer.select"(%const_true, %pair_val0_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_56 = "transfer.select"(%const_true, %pair_val_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_56 = "transfer.and"(%pair_acc0_55, %pair_sel0_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_56 = "transfer.and"(%pair_acc1_55, %pair_sel1_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_56 = "arith.ori"(%pair_any_55, %const_true) : (i1, i1) -> i1
    %pair_mul_57 = "transfer.mul"(%lhsu_v3, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_57 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_57 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_57 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_57 = "arith.xori"(%pair_lhs_neg_57, %pair_rhs_neg_57) : (i1, i1) -> i1
    %pair_sat_57 = "transfer.select"(%pair_res_neg_57, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_57 = "transfer.select"(%pair_ov_57, %pair_sat_57, %pair_mul_57) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_57 = "transfer.xor"(%pair_val_57, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_57 = "transfer.select"(%const_true, %pair_val0_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_57 = "transfer.select"(%const_true, %pair_val_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_57 = "transfer.and"(%pair_acc0_56, %pair_sel0_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_57 = "transfer.and"(%pair_acc1_56, %pair_sel1_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_57 = "arith.ori"(%pair_any_56, %const_true) : (i1, i1) -> i1
    %pair_mul_58 = "transfer.mul"(%lhsu_v3, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_58 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_58 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_58 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_58 = "arith.xori"(%pair_lhs_neg_58, %pair_rhs_neg_58) : (i1, i1) -> i1
    %pair_sat_58 = "transfer.select"(%pair_res_neg_58, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_58 = "transfer.select"(%pair_ov_58, %pair_sat_58, %pair_mul_58) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_58 = "transfer.xor"(%pair_val_58, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_58 = "transfer.select"(%const_true, %pair_val0_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_58 = "transfer.select"(%const_true, %pair_val_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_58 = "transfer.and"(%pair_acc0_57, %pair_sel0_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_58 = "transfer.and"(%pair_acc1_57, %pair_sel1_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_58 = "arith.ori"(%pair_any_57, %const_true) : (i1, i1) -> i1
    %pair_mul_59 = "transfer.mul"(%lhsu_v3, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_59 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_59 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_59 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_59 = "arith.xori"(%pair_lhs_neg_59, %pair_rhs_neg_59) : (i1, i1) -> i1
    %pair_sat_59 = "transfer.select"(%pair_res_neg_59, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_59 = "transfer.select"(%pair_ov_59, %pair_sat_59, %pair_mul_59) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_59 = "transfer.xor"(%pair_val_59, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_59 = "transfer.select"(%const_true, %pair_val0_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_59 = "transfer.select"(%const_true, %pair_val_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_59 = "transfer.and"(%pair_acc0_58, %pair_sel0_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_59 = "transfer.and"(%pair_acc1_58, %pair_sel1_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_59 = "arith.ori"(%pair_any_58, %const_true) : (i1, i1) -> i1
    %pair_mul_60 = "transfer.mul"(%lhsu_v3, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_60 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_60 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_60 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_60 = "arith.xori"(%pair_lhs_neg_60, %pair_rhs_neg_60) : (i1, i1) -> i1
    %pair_sat_60 = "transfer.select"(%pair_res_neg_60, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_60 = "transfer.select"(%pair_ov_60, %pair_sat_60, %pair_mul_60) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_60 = "transfer.xor"(%pair_val_60, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_60 = "transfer.select"(%const_true, %pair_val0_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_60 = "transfer.select"(%const_true, %pair_val_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_60 = "transfer.and"(%pair_acc0_59, %pair_sel0_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_60 = "transfer.and"(%pair_acc1_59, %pair_sel1_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_60 = "arith.ori"(%pair_any_59, %const_true) : (i1, i1) -> i1
    %pair_mul_61 = "transfer.mul"(%lhsu_v3, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_61 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_61 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_61 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_61 = "arith.xori"(%pair_lhs_neg_61, %pair_rhs_neg_61) : (i1, i1) -> i1
    %pair_sat_61 = "transfer.select"(%pair_res_neg_61, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_61 = "transfer.select"(%pair_ov_61, %pair_sat_61, %pair_mul_61) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_61 = "transfer.xor"(%pair_val_61, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_61 = "transfer.select"(%const_true, %pair_val0_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_61 = "transfer.select"(%const_true, %pair_val_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_61 = "transfer.and"(%pair_acc0_60, %pair_sel0_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_61 = "transfer.and"(%pair_acc1_60, %pair_sel1_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_61 = "arith.ori"(%pair_any_60, %const_true) : (i1, i1) -> i1
    %pair_mul_62 = "transfer.mul"(%lhsu_v3, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_62 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_62 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_62 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_62 = "arith.xori"(%pair_lhs_neg_62, %pair_rhs_neg_62) : (i1, i1) -> i1
    %pair_sat_62 = "transfer.select"(%pair_res_neg_62, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_62 = "transfer.select"(%pair_ov_62, %pair_sat_62, %pair_mul_62) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_62 = "transfer.xor"(%pair_val_62, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_62 = "transfer.select"(%const_true, %pair_val0_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_62 = "transfer.select"(%const_true, %pair_val_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_62 = "transfer.and"(%pair_acc0_61, %pair_sel0_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_62 = "transfer.and"(%pair_acc1_61, %pair_sel1_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_62 = "arith.ori"(%pair_any_61, %const_true) : (i1, i1) -> i1
    %pair_mul_63 = "transfer.mul"(%lhsu_v3, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_63 = "transfer.smul_overflow"(%lhsu_v3, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_63 = "transfer.cmp"(%lhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_63 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_63 = "arith.xori"(%pair_lhs_neg_63, %pair_rhs_neg_63) : (i1, i1) -> i1
    %pair_sat_63 = "transfer.select"(%pair_res_neg_63, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_63 = "transfer.select"(%pair_ov_63, %pair_sat_63, %pair_mul_63) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_63 = "transfer.xor"(%pair_val_63, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_63 = "transfer.select"(%const_true, %pair_val0_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_63 = "transfer.select"(%const_true, %pair_val_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_63 = "transfer.and"(%pair_acc0_62, %pair_sel0_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_63 = "transfer.and"(%pair_acc1_62, %pair_sel1_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_63 = "arith.ori"(%pair_any_62, %const_true) : (i1, i1) -> i1
    %pair_mul_64 = "transfer.mul"(%lhsu_v4, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_64 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_64 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_64 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_64 = "arith.xori"(%pair_lhs_neg_64, %pair_rhs_neg_64) : (i1, i1) -> i1
    %pair_sat_64 = "transfer.select"(%pair_res_neg_64, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_64 = "transfer.select"(%pair_ov_64, %pair_sat_64, %pair_mul_64) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_64 = "transfer.xor"(%pair_val_64, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_64 = "transfer.select"(%const_true, %pair_val0_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_64 = "transfer.select"(%const_true, %pair_val_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_64 = "transfer.and"(%pair_acc0_63, %pair_sel0_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_64 = "transfer.and"(%pair_acc1_63, %pair_sel1_64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_64 = "arith.ori"(%pair_any_63, %const_true) : (i1, i1) -> i1
    %pair_mul_65 = "transfer.mul"(%lhsu_v4, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_65 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_65 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_65 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_65 = "arith.xori"(%pair_lhs_neg_65, %pair_rhs_neg_65) : (i1, i1) -> i1
    %pair_sat_65 = "transfer.select"(%pair_res_neg_65, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_65 = "transfer.select"(%pair_ov_65, %pair_sat_65, %pair_mul_65) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_65 = "transfer.xor"(%pair_val_65, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_65 = "transfer.select"(%const_true, %pair_val0_65, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_65 = "transfer.select"(%const_true, %pair_val_65, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_65 = "transfer.and"(%pair_acc0_64, %pair_sel0_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_65 = "transfer.and"(%pair_acc1_64, %pair_sel1_65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_65 = "arith.ori"(%pair_any_64, %const_true) : (i1, i1) -> i1
    %pair_mul_66 = "transfer.mul"(%lhsu_v4, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_66 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_66 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_66 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_66 = "arith.xori"(%pair_lhs_neg_66, %pair_rhs_neg_66) : (i1, i1) -> i1
    %pair_sat_66 = "transfer.select"(%pair_res_neg_66, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_66 = "transfer.select"(%pair_ov_66, %pair_sat_66, %pair_mul_66) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_66 = "transfer.xor"(%pair_val_66, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_66 = "transfer.select"(%const_true, %pair_val0_66, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_66 = "transfer.select"(%const_true, %pair_val_66, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_66 = "transfer.and"(%pair_acc0_65, %pair_sel0_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_66 = "transfer.and"(%pair_acc1_65, %pair_sel1_66) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_66 = "arith.ori"(%pair_any_65, %const_true) : (i1, i1) -> i1
    %pair_mul_67 = "transfer.mul"(%lhsu_v4, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_67 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_67 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_67 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_67 = "arith.xori"(%pair_lhs_neg_67, %pair_rhs_neg_67) : (i1, i1) -> i1
    %pair_sat_67 = "transfer.select"(%pair_res_neg_67, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_67 = "transfer.select"(%pair_ov_67, %pair_sat_67, %pair_mul_67) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_67 = "transfer.xor"(%pair_val_67, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_67 = "transfer.select"(%const_true, %pair_val0_67, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_67 = "transfer.select"(%const_true, %pair_val_67, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_67 = "transfer.and"(%pair_acc0_66, %pair_sel0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_67 = "transfer.and"(%pair_acc1_66, %pair_sel1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_67 = "arith.ori"(%pair_any_66, %const_true) : (i1, i1) -> i1
    %pair_mul_68 = "transfer.mul"(%lhsu_v4, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_68 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_68 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_68 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_68 = "arith.xori"(%pair_lhs_neg_68, %pair_rhs_neg_68) : (i1, i1) -> i1
    %pair_sat_68 = "transfer.select"(%pair_res_neg_68, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_68 = "transfer.select"(%pair_ov_68, %pair_sat_68, %pair_mul_68) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_68 = "transfer.xor"(%pair_val_68, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_68 = "transfer.select"(%const_true, %pair_val0_68, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_68 = "transfer.select"(%const_true, %pair_val_68, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_68 = "transfer.and"(%pair_acc0_67, %pair_sel0_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_68 = "transfer.and"(%pair_acc1_67, %pair_sel1_68) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_68 = "arith.ori"(%pair_any_67, %const_true) : (i1, i1) -> i1
    %pair_mul_69 = "transfer.mul"(%lhsu_v4, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_69 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_69 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_69 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_69 = "arith.xori"(%pair_lhs_neg_69, %pair_rhs_neg_69) : (i1, i1) -> i1
    %pair_sat_69 = "transfer.select"(%pair_res_neg_69, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_69 = "transfer.select"(%pair_ov_69, %pair_sat_69, %pair_mul_69) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_69 = "transfer.xor"(%pair_val_69, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_69 = "transfer.select"(%const_true, %pair_val0_69, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_69 = "transfer.select"(%const_true, %pair_val_69, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_69 = "transfer.and"(%pair_acc0_68, %pair_sel0_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_69 = "transfer.and"(%pair_acc1_68, %pair_sel1_69) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_69 = "arith.ori"(%pair_any_68, %const_true) : (i1, i1) -> i1
    %pair_mul_70 = "transfer.mul"(%lhsu_v4, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_70 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_70 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_70 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_70 = "arith.xori"(%pair_lhs_neg_70, %pair_rhs_neg_70) : (i1, i1) -> i1
    %pair_sat_70 = "transfer.select"(%pair_res_neg_70, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_70 = "transfer.select"(%pair_ov_70, %pair_sat_70, %pair_mul_70) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_70 = "transfer.xor"(%pair_val_70, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_70 = "transfer.select"(%const_true, %pair_val0_70, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_70 = "transfer.select"(%const_true, %pair_val_70, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_70 = "transfer.and"(%pair_acc0_69, %pair_sel0_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_70 = "transfer.and"(%pair_acc1_69, %pair_sel1_70) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_70 = "arith.ori"(%pair_any_69, %const_true) : (i1, i1) -> i1
    %pair_mul_71 = "transfer.mul"(%lhsu_v4, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_71 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_71 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_71 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_71 = "arith.xori"(%pair_lhs_neg_71, %pair_rhs_neg_71) : (i1, i1) -> i1
    %pair_sat_71 = "transfer.select"(%pair_res_neg_71, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_71 = "transfer.select"(%pair_ov_71, %pair_sat_71, %pair_mul_71) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_71 = "transfer.xor"(%pair_val_71, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_71 = "transfer.select"(%const_true, %pair_val0_71, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_71 = "transfer.select"(%const_true, %pair_val_71, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_71 = "transfer.and"(%pair_acc0_70, %pair_sel0_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_71 = "transfer.and"(%pair_acc1_70, %pair_sel1_71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_71 = "arith.ori"(%pair_any_70, %const_true) : (i1, i1) -> i1
    %pair_mul_72 = "transfer.mul"(%lhsu_v4, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_72 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_72 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_72 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_72 = "arith.xori"(%pair_lhs_neg_72, %pair_rhs_neg_72) : (i1, i1) -> i1
    %pair_sat_72 = "transfer.select"(%pair_res_neg_72, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_72 = "transfer.select"(%pair_ov_72, %pair_sat_72, %pair_mul_72) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_72 = "transfer.xor"(%pair_val_72, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_72 = "transfer.select"(%const_true, %pair_val0_72, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_72 = "transfer.select"(%const_true, %pair_val_72, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_72 = "transfer.and"(%pair_acc0_71, %pair_sel0_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_72 = "transfer.and"(%pair_acc1_71, %pair_sel1_72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_72 = "arith.ori"(%pair_any_71, %const_true) : (i1, i1) -> i1
    %pair_mul_73 = "transfer.mul"(%lhsu_v4, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_73 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_73 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_73 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_73 = "arith.xori"(%pair_lhs_neg_73, %pair_rhs_neg_73) : (i1, i1) -> i1
    %pair_sat_73 = "transfer.select"(%pair_res_neg_73, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_73 = "transfer.select"(%pair_ov_73, %pair_sat_73, %pair_mul_73) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_73 = "transfer.xor"(%pair_val_73, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_73 = "transfer.select"(%const_true, %pair_val0_73, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_73 = "transfer.select"(%const_true, %pair_val_73, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_73 = "transfer.and"(%pair_acc0_72, %pair_sel0_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_73 = "transfer.and"(%pair_acc1_72, %pair_sel1_73) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_73 = "arith.ori"(%pair_any_72, %const_true) : (i1, i1) -> i1
    %pair_mul_74 = "transfer.mul"(%lhsu_v4, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_74 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_74 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_74 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_74 = "arith.xori"(%pair_lhs_neg_74, %pair_rhs_neg_74) : (i1, i1) -> i1
    %pair_sat_74 = "transfer.select"(%pair_res_neg_74, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_74 = "transfer.select"(%pair_ov_74, %pair_sat_74, %pair_mul_74) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_74 = "transfer.xor"(%pair_val_74, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_74 = "transfer.select"(%const_true, %pair_val0_74, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_74 = "transfer.select"(%const_true, %pair_val_74, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_74 = "transfer.and"(%pair_acc0_73, %pair_sel0_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_74 = "transfer.and"(%pair_acc1_73, %pair_sel1_74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_74 = "arith.ori"(%pair_any_73, %const_true) : (i1, i1) -> i1
    %pair_mul_75 = "transfer.mul"(%lhsu_v4, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_75 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_75 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_75 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_75 = "arith.xori"(%pair_lhs_neg_75, %pair_rhs_neg_75) : (i1, i1) -> i1
    %pair_sat_75 = "transfer.select"(%pair_res_neg_75, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_75 = "transfer.select"(%pair_ov_75, %pair_sat_75, %pair_mul_75) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_75 = "transfer.xor"(%pair_val_75, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_75 = "transfer.select"(%const_true, %pair_val0_75, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_75 = "transfer.select"(%const_true, %pair_val_75, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_75 = "transfer.and"(%pair_acc0_74, %pair_sel0_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_75 = "transfer.and"(%pair_acc1_74, %pair_sel1_75) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_75 = "arith.ori"(%pair_any_74, %const_true) : (i1, i1) -> i1
    %pair_mul_76 = "transfer.mul"(%lhsu_v4, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_76 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_76 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_76 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_76 = "arith.xori"(%pair_lhs_neg_76, %pair_rhs_neg_76) : (i1, i1) -> i1
    %pair_sat_76 = "transfer.select"(%pair_res_neg_76, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_76 = "transfer.select"(%pair_ov_76, %pair_sat_76, %pair_mul_76) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_76 = "transfer.xor"(%pair_val_76, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_76 = "transfer.select"(%const_true, %pair_val0_76, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_76 = "transfer.select"(%const_true, %pair_val_76, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_76 = "transfer.and"(%pair_acc0_75, %pair_sel0_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_76 = "transfer.and"(%pair_acc1_75, %pair_sel1_76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_76 = "arith.ori"(%pair_any_75, %const_true) : (i1, i1) -> i1
    %pair_mul_77 = "transfer.mul"(%lhsu_v4, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_77 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_77 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_77 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_77 = "arith.xori"(%pair_lhs_neg_77, %pair_rhs_neg_77) : (i1, i1) -> i1
    %pair_sat_77 = "transfer.select"(%pair_res_neg_77, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_77 = "transfer.select"(%pair_ov_77, %pair_sat_77, %pair_mul_77) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_77 = "transfer.xor"(%pair_val_77, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_77 = "transfer.select"(%const_true, %pair_val0_77, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_77 = "transfer.select"(%const_true, %pair_val_77, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_77 = "transfer.and"(%pair_acc0_76, %pair_sel0_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_77 = "transfer.and"(%pair_acc1_76, %pair_sel1_77) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_77 = "arith.ori"(%pair_any_76, %const_true) : (i1, i1) -> i1
    %pair_mul_78 = "transfer.mul"(%lhsu_v4, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_78 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_78 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_78 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_78 = "arith.xori"(%pair_lhs_neg_78, %pair_rhs_neg_78) : (i1, i1) -> i1
    %pair_sat_78 = "transfer.select"(%pair_res_neg_78, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_78 = "transfer.select"(%pair_ov_78, %pair_sat_78, %pair_mul_78) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_78 = "transfer.xor"(%pair_val_78, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_78 = "transfer.select"(%const_true, %pair_val0_78, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_78 = "transfer.select"(%const_true, %pair_val_78, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_78 = "transfer.and"(%pair_acc0_77, %pair_sel0_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_78 = "transfer.and"(%pair_acc1_77, %pair_sel1_78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_78 = "arith.ori"(%pair_any_77, %const_true) : (i1, i1) -> i1
    %pair_mul_79 = "transfer.mul"(%lhsu_v4, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_79 = "transfer.smul_overflow"(%lhsu_v4, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_79 = "transfer.cmp"(%lhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_79 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_79 = "arith.xori"(%pair_lhs_neg_79, %pair_rhs_neg_79) : (i1, i1) -> i1
    %pair_sat_79 = "transfer.select"(%pair_res_neg_79, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_79 = "transfer.select"(%pair_ov_79, %pair_sat_79, %pair_mul_79) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_79 = "transfer.xor"(%pair_val_79, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_79 = "transfer.select"(%const_true, %pair_val0_79, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_79 = "transfer.select"(%const_true, %pair_val_79, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_79 = "transfer.and"(%pair_acc0_78, %pair_sel0_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_79 = "transfer.and"(%pair_acc1_78, %pair_sel1_79) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_79 = "arith.ori"(%pair_any_78, %const_true) : (i1, i1) -> i1
    %pair_mul_80 = "transfer.mul"(%lhsu_v5, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_80 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_80 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_80 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_80 = "arith.xori"(%pair_lhs_neg_80, %pair_rhs_neg_80) : (i1, i1) -> i1
    %pair_sat_80 = "transfer.select"(%pair_res_neg_80, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_80 = "transfer.select"(%pair_ov_80, %pair_sat_80, %pair_mul_80) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_80 = "transfer.xor"(%pair_val_80, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_80 = "transfer.select"(%const_true, %pair_val0_80, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_80 = "transfer.select"(%const_true, %pair_val_80, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_80 = "transfer.and"(%pair_acc0_79, %pair_sel0_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_80 = "transfer.and"(%pair_acc1_79, %pair_sel1_80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_80 = "arith.ori"(%pair_any_79, %const_true) : (i1, i1) -> i1
    %pair_mul_81 = "transfer.mul"(%lhsu_v5, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_81 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_81 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_81 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_81 = "arith.xori"(%pair_lhs_neg_81, %pair_rhs_neg_81) : (i1, i1) -> i1
    %pair_sat_81 = "transfer.select"(%pair_res_neg_81, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_81 = "transfer.select"(%pair_ov_81, %pair_sat_81, %pair_mul_81) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_81 = "transfer.xor"(%pair_val_81, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_81 = "transfer.select"(%const_true, %pair_val0_81, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_81 = "transfer.select"(%const_true, %pair_val_81, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_81 = "transfer.and"(%pair_acc0_80, %pair_sel0_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_81 = "transfer.and"(%pair_acc1_80, %pair_sel1_81) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_81 = "arith.ori"(%pair_any_80, %const_true) : (i1, i1) -> i1
    %pair_mul_82 = "transfer.mul"(%lhsu_v5, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_82 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_82 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_82 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_82 = "arith.xori"(%pair_lhs_neg_82, %pair_rhs_neg_82) : (i1, i1) -> i1
    %pair_sat_82 = "transfer.select"(%pair_res_neg_82, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_82 = "transfer.select"(%pair_ov_82, %pair_sat_82, %pair_mul_82) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_82 = "transfer.xor"(%pair_val_82, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_82 = "transfer.select"(%const_true, %pair_val0_82, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_82 = "transfer.select"(%const_true, %pair_val_82, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_82 = "transfer.and"(%pair_acc0_81, %pair_sel0_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_82 = "transfer.and"(%pair_acc1_81, %pair_sel1_82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_82 = "arith.ori"(%pair_any_81, %const_true) : (i1, i1) -> i1
    %pair_mul_83 = "transfer.mul"(%lhsu_v5, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_83 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_83 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_83 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_83 = "arith.xori"(%pair_lhs_neg_83, %pair_rhs_neg_83) : (i1, i1) -> i1
    %pair_sat_83 = "transfer.select"(%pair_res_neg_83, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_83 = "transfer.select"(%pair_ov_83, %pair_sat_83, %pair_mul_83) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_83 = "transfer.xor"(%pair_val_83, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_83 = "transfer.select"(%const_true, %pair_val0_83, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_83 = "transfer.select"(%const_true, %pair_val_83, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_83 = "transfer.and"(%pair_acc0_82, %pair_sel0_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_83 = "transfer.and"(%pair_acc1_82, %pair_sel1_83) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_83 = "arith.ori"(%pair_any_82, %const_true) : (i1, i1) -> i1
    %pair_mul_84 = "transfer.mul"(%lhsu_v5, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_84 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_84 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_84 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_84 = "arith.xori"(%pair_lhs_neg_84, %pair_rhs_neg_84) : (i1, i1) -> i1
    %pair_sat_84 = "transfer.select"(%pair_res_neg_84, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_84 = "transfer.select"(%pair_ov_84, %pair_sat_84, %pair_mul_84) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_84 = "transfer.xor"(%pair_val_84, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_84 = "transfer.select"(%const_true, %pair_val0_84, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_84 = "transfer.select"(%const_true, %pair_val_84, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_84 = "transfer.and"(%pair_acc0_83, %pair_sel0_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_84 = "transfer.and"(%pair_acc1_83, %pair_sel1_84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_84 = "arith.ori"(%pair_any_83, %const_true) : (i1, i1) -> i1
    %pair_mul_85 = "transfer.mul"(%lhsu_v5, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_85 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_85 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_85 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_85 = "arith.xori"(%pair_lhs_neg_85, %pair_rhs_neg_85) : (i1, i1) -> i1
    %pair_sat_85 = "transfer.select"(%pair_res_neg_85, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_85 = "transfer.select"(%pair_ov_85, %pair_sat_85, %pair_mul_85) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_85 = "transfer.xor"(%pair_val_85, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_85 = "transfer.select"(%const_true, %pair_val0_85, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_85 = "transfer.select"(%const_true, %pair_val_85, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_85 = "transfer.and"(%pair_acc0_84, %pair_sel0_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_85 = "transfer.and"(%pair_acc1_84, %pair_sel1_85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_85 = "arith.ori"(%pair_any_84, %const_true) : (i1, i1) -> i1
    %pair_mul_86 = "transfer.mul"(%lhsu_v5, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_86 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_86 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_86 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_86 = "arith.xori"(%pair_lhs_neg_86, %pair_rhs_neg_86) : (i1, i1) -> i1
    %pair_sat_86 = "transfer.select"(%pair_res_neg_86, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_86 = "transfer.select"(%pair_ov_86, %pair_sat_86, %pair_mul_86) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_86 = "transfer.xor"(%pair_val_86, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_86 = "transfer.select"(%const_true, %pair_val0_86, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_86 = "transfer.select"(%const_true, %pair_val_86, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_86 = "transfer.and"(%pair_acc0_85, %pair_sel0_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_86 = "transfer.and"(%pair_acc1_85, %pair_sel1_86) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_86 = "arith.ori"(%pair_any_85, %const_true) : (i1, i1) -> i1
    %pair_mul_87 = "transfer.mul"(%lhsu_v5, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_87 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_87 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_87 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_87 = "arith.xori"(%pair_lhs_neg_87, %pair_rhs_neg_87) : (i1, i1) -> i1
    %pair_sat_87 = "transfer.select"(%pair_res_neg_87, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_87 = "transfer.select"(%pair_ov_87, %pair_sat_87, %pair_mul_87) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_87 = "transfer.xor"(%pair_val_87, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_87 = "transfer.select"(%const_true, %pair_val0_87, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_87 = "transfer.select"(%const_true, %pair_val_87, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_87 = "transfer.and"(%pair_acc0_86, %pair_sel0_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_87 = "transfer.and"(%pair_acc1_86, %pair_sel1_87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_87 = "arith.ori"(%pair_any_86, %const_true) : (i1, i1) -> i1
    %pair_mul_88 = "transfer.mul"(%lhsu_v5, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_88 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_88 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_88 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_88 = "arith.xori"(%pair_lhs_neg_88, %pair_rhs_neg_88) : (i1, i1) -> i1
    %pair_sat_88 = "transfer.select"(%pair_res_neg_88, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_88 = "transfer.select"(%pair_ov_88, %pair_sat_88, %pair_mul_88) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_88 = "transfer.xor"(%pair_val_88, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_88 = "transfer.select"(%const_true, %pair_val0_88, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_88 = "transfer.select"(%const_true, %pair_val_88, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_88 = "transfer.and"(%pair_acc0_87, %pair_sel0_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_88 = "transfer.and"(%pair_acc1_87, %pair_sel1_88) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_88 = "arith.ori"(%pair_any_87, %const_true) : (i1, i1) -> i1
    %pair_mul_89 = "transfer.mul"(%lhsu_v5, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_89 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_89 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_89 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_89 = "arith.xori"(%pair_lhs_neg_89, %pair_rhs_neg_89) : (i1, i1) -> i1
    %pair_sat_89 = "transfer.select"(%pair_res_neg_89, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_89 = "transfer.select"(%pair_ov_89, %pair_sat_89, %pair_mul_89) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_89 = "transfer.xor"(%pair_val_89, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_89 = "transfer.select"(%const_true, %pair_val0_89, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_89 = "transfer.select"(%const_true, %pair_val_89, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_89 = "transfer.and"(%pair_acc0_88, %pair_sel0_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_89 = "transfer.and"(%pair_acc1_88, %pair_sel1_89) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_89 = "arith.ori"(%pair_any_88, %const_true) : (i1, i1) -> i1
    %pair_mul_90 = "transfer.mul"(%lhsu_v5, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_90 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_90 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_90 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_90 = "arith.xori"(%pair_lhs_neg_90, %pair_rhs_neg_90) : (i1, i1) -> i1
    %pair_sat_90 = "transfer.select"(%pair_res_neg_90, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_90 = "transfer.select"(%pair_ov_90, %pair_sat_90, %pair_mul_90) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_90 = "transfer.xor"(%pair_val_90, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_90 = "transfer.select"(%const_true, %pair_val0_90, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_90 = "transfer.select"(%const_true, %pair_val_90, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_90 = "transfer.and"(%pair_acc0_89, %pair_sel0_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_90 = "transfer.and"(%pair_acc1_89, %pair_sel1_90) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_90 = "arith.ori"(%pair_any_89, %const_true) : (i1, i1) -> i1
    %pair_mul_91 = "transfer.mul"(%lhsu_v5, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_91 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_91 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_91 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_91 = "arith.xori"(%pair_lhs_neg_91, %pair_rhs_neg_91) : (i1, i1) -> i1
    %pair_sat_91 = "transfer.select"(%pair_res_neg_91, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_91 = "transfer.select"(%pair_ov_91, %pair_sat_91, %pair_mul_91) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_91 = "transfer.xor"(%pair_val_91, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_91 = "transfer.select"(%const_true, %pair_val0_91, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_91 = "transfer.select"(%const_true, %pair_val_91, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_91 = "transfer.and"(%pair_acc0_90, %pair_sel0_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_91 = "transfer.and"(%pair_acc1_90, %pair_sel1_91) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_91 = "arith.ori"(%pair_any_90, %const_true) : (i1, i1) -> i1
    %pair_mul_92 = "transfer.mul"(%lhsu_v5, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_92 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_92 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_92 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_92 = "arith.xori"(%pair_lhs_neg_92, %pair_rhs_neg_92) : (i1, i1) -> i1
    %pair_sat_92 = "transfer.select"(%pair_res_neg_92, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_92 = "transfer.select"(%pair_ov_92, %pair_sat_92, %pair_mul_92) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_92 = "transfer.xor"(%pair_val_92, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_92 = "transfer.select"(%const_true, %pair_val0_92, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_92 = "transfer.select"(%const_true, %pair_val_92, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_92 = "transfer.and"(%pair_acc0_91, %pair_sel0_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_92 = "transfer.and"(%pair_acc1_91, %pair_sel1_92) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_92 = "arith.ori"(%pair_any_91, %const_true) : (i1, i1) -> i1
    %pair_mul_93 = "transfer.mul"(%lhsu_v5, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_93 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_93 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_93 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_93 = "arith.xori"(%pair_lhs_neg_93, %pair_rhs_neg_93) : (i1, i1) -> i1
    %pair_sat_93 = "transfer.select"(%pair_res_neg_93, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_93 = "transfer.select"(%pair_ov_93, %pair_sat_93, %pair_mul_93) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_93 = "transfer.xor"(%pair_val_93, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_93 = "transfer.select"(%const_true, %pair_val0_93, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_93 = "transfer.select"(%const_true, %pair_val_93, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_93 = "transfer.and"(%pair_acc0_92, %pair_sel0_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_93 = "transfer.and"(%pair_acc1_92, %pair_sel1_93) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_93 = "arith.ori"(%pair_any_92, %const_true) : (i1, i1) -> i1
    %pair_mul_94 = "transfer.mul"(%lhsu_v5, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_94 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_94 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_94 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_94 = "arith.xori"(%pair_lhs_neg_94, %pair_rhs_neg_94) : (i1, i1) -> i1
    %pair_sat_94 = "transfer.select"(%pair_res_neg_94, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_94 = "transfer.select"(%pair_ov_94, %pair_sat_94, %pair_mul_94) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_94 = "transfer.xor"(%pair_val_94, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_94 = "transfer.select"(%const_true, %pair_val0_94, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_94 = "transfer.select"(%const_true, %pair_val_94, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_94 = "transfer.and"(%pair_acc0_93, %pair_sel0_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_94 = "transfer.and"(%pair_acc1_93, %pair_sel1_94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_94 = "arith.ori"(%pair_any_93, %const_true) : (i1, i1) -> i1
    %pair_mul_95 = "transfer.mul"(%lhsu_v5, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_95 = "transfer.smul_overflow"(%lhsu_v5, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_95 = "transfer.cmp"(%lhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_95 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_95 = "arith.xori"(%pair_lhs_neg_95, %pair_rhs_neg_95) : (i1, i1) -> i1
    %pair_sat_95 = "transfer.select"(%pair_res_neg_95, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_95 = "transfer.select"(%pair_ov_95, %pair_sat_95, %pair_mul_95) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_95 = "transfer.xor"(%pair_val_95, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_95 = "transfer.select"(%const_true, %pair_val0_95, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_95 = "transfer.select"(%const_true, %pair_val_95, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_95 = "transfer.and"(%pair_acc0_94, %pair_sel0_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_95 = "transfer.and"(%pair_acc1_94, %pair_sel1_95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_95 = "arith.ori"(%pair_any_94, %const_true) : (i1, i1) -> i1
    %pair_mul_96 = "transfer.mul"(%lhsu_v6, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_96 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_96 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_96 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_96 = "arith.xori"(%pair_lhs_neg_96, %pair_rhs_neg_96) : (i1, i1) -> i1
    %pair_sat_96 = "transfer.select"(%pair_res_neg_96, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_96 = "transfer.select"(%pair_ov_96, %pair_sat_96, %pair_mul_96) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_96 = "transfer.xor"(%pair_val_96, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_96 = "transfer.select"(%const_true, %pair_val0_96, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_96 = "transfer.select"(%const_true, %pair_val_96, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_96 = "transfer.and"(%pair_acc0_95, %pair_sel0_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_96 = "transfer.and"(%pair_acc1_95, %pair_sel1_96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_96 = "arith.ori"(%pair_any_95, %const_true) : (i1, i1) -> i1
    %pair_mul_97 = "transfer.mul"(%lhsu_v6, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_97 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_97 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_97 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_97 = "arith.xori"(%pair_lhs_neg_97, %pair_rhs_neg_97) : (i1, i1) -> i1
    %pair_sat_97 = "transfer.select"(%pair_res_neg_97, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_97 = "transfer.select"(%pair_ov_97, %pair_sat_97, %pair_mul_97) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_97 = "transfer.xor"(%pair_val_97, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_97 = "transfer.select"(%const_true, %pair_val0_97, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_97 = "transfer.select"(%const_true, %pair_val_97, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_97 = "transfer.and"(%pair_acc0_96, %pair_sel0_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_97 = "transfer.and"(%pair_acc1_96, %pair_sel1_97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_97 = "arith.ori"(%pair_any_96, %const_true) : (i1, i1) -> i1
    %pair_mul_98 = "transfer.mul"(%lhsu_v6, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_98 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_98 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_98 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_98 = "arith.xori"(%pair_lhs_neg_98, %pair_rhs_neg_98) : (i1, i1) -> i1
    %pair_sat_98 = "transfer.select"(%pair_res_neg_98, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_98 = "transfer.select"(%pair_ov_98, %pair_sat_98, %pair_mul_98) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_98 = "transfer.xor"(%pair_val_98, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_98 = "transfer.select"(%const_true, %pair_val0_98, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_98 = "transfer.select"(%const_true, %pair_val_98, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_98 = "transfer.and"(%pair_acc0_97, %pair_sel0_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_98 = "transfer.and"(%pair_acc1_97, %pair_sel1_98) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_98 = "arith.ori"(%pair_any_97, %const_true) : (i1, i1) -> i1
    %pair_mul_99 = "transfer.mul"(%lhsu_v6, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_99 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_99 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_99 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_99 = "arith.xori"(%pair_lhs_neg_99, %pair_rhs_neg_99) : (i1, i1) -> i1
    %pair_sat_99 = "transfer.select"(%pair_res_neg_99, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_99 = "transfer.select"(%pair_ov_99, %pair_sat_99, %pair_mul_99) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_99 = "transfer.xor"(%pair_val_99, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_99 = "transfer.select"(%const_true, %pair_val0_99, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_99 = "transfer.select"(%const_true, %pair_val_99, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_99 = "transfer.and"(%pair_acc0_98, %pair_sel0_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_99 = "transfer.and"(%pair_acc1_98, %pair_sel1_99) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_99 = "arith.ori"(%pair_any_98, %const_true) : (i1, i1) -> i1
    %pair_mul_100 = "transfer.mul"(%lhsu_v6, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_100 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_100 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_100 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_100 = "arith.xori"(%pair_lhs_neg_100, %pair_rhs_neg_100) : (i1, i1) -> i1
    %pair_sat_100 = "transfer.select"(%pair_res_neg_100, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_100 = "transfer.select"(%pair_ov_100, %pair_sat_100, %pair_mul_100) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_100 = "transfer.xor"(%pair_val_100, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_100 = "transfer.select"(%const_true, %pair_val0_100, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_100 = "transfer.select"(%const_true, %pair_val_100, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_100 = "transfer.and"(%pair_acc0_99, %pair_sel0_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_100 = "transfer.and"(%pair_acc1_99, %pair_sel1_100) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_100 = "arith.ori"(%pair_any_99, %const_true) : (i1, i1) -> i1
    %pair_mul_101 = "transfer.mul"(%lhsu_v6, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_101 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_101 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_101 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_101 = "arith.xori"(%pair_lhs_neg_101, %pair_rhs_neg_101) : (i1, i1) -> i1
    %pair_sat_101 = "transfer.select"(%pair_res_neg_101, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_101 = "transfer.select"(%pair_ov_101, %pair_sat_101, %pair_mul_101) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_101 = "transfer.xor"(%pair_val_101, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_101 = "transfer.select"(%const_true, %pair_val0_101, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_101 = "transfer.select"(%const_true, %pair_val_101, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_101 = "transfer.and"(%pair_acc0_100, %pair_sel0_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_101 = "transfer.and"(%pair_acc1_100, %pair_sel1_101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_101 = "arith.ori"(%pair_any_100, %const_true) : (i1, i1) -> i1
    %pair_mul_102 = "transfer.mul"(%lhsu_v6, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_102 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_102 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_102 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_102 = "arith.xori"(%pair_lhs_neg_102, %pair_rhs_neg_102) : (i1, i1) -> i1
    %pair_sat_102 = "transfer.select"(%pair_res_neg_102, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_102 = "transfer.select"(%pair_ov_102, %pair_sat_102, %pair_mul_102) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_102 = "transfer.xor"(%pair_val_102, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_102 = "transfer.select"(%const_true, %pair_val0_102, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_102 = "transfer.select"(%const_true, %pair_val_102, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_102 = "transfer.and"(%pair_acc0_101, %pair_sel0_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_102 = "transfer.and"(%pair_acc1_101, %pair_sel1_102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_102 = "arith.ori"(%pair_any_101, %const_true) : (i1, i1) -> i1
    %pair_mul_103 = "transfer.mul"(%lhsu_v6, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_103 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_103 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_103 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_103 = "arith.xori"(%pair_lhs_neg_103, %pair_rhs_neg_103) : (i1, i1) -> i1
    %pair_sat_103 = "transfer.select"(%pair_res_neg_103, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_103 = "transfer.select"(%pair_ov_103, %pair_sat_103, %pair_mul_103) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_103 = "transfer.xor"(%pair_val_103, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_103 = "transfer.select"(%const_true, %pair_val0_103, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_103 = "transfer.select"(%const_true, %pair_val_103, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_103 = "transfer.and"(%pair_acc0_102, %pair_sel0_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_103 = "transfer.and"(%pair_acc1_102, %pair_sel1_103) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_103 = "arith.ori"(%pair_any_102, %const_true) : (i1, i1) -> i1
    %pair_mul_104 = "transfer.mul"(%lhsu_v6, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_104 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_104 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_104 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_104 = "arith.xori"(%pair_lhs_neg_104, %pair_rhs_neg_104) : (i1, i1) -> i1
    %pair_sat_104 = "transfer.select"(%pair_res_neg_104, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_104 = "transfer.select"(%pair_ov_104, %pair_sat_104, %pair_mul_104) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_104 = "transfer.xor"(%pair_val_104, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_104 = "transfer.select"(%const_true, %pair_val0_104, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_104 = "transfer.select"(%const_true, %pair_val_104, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_104 = "transfer.and"(%pair_acc0_103, %pair_sel0_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_104 = "transfer.and"(%pair_acc1_103, %pair_sel1_104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_104 = "arith.ori"(%pair_any_103, %const_true) : (i1, i1) -> i1
    %pair_mul_105 = "transfer.mul"(%lhsu_v6, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_105 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_105 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_105 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_105 = "arith.xori"(%pair_lhs_neg_105, %pair_rhs_neg_105) : (i1, i1) -> i1
    %pair_sat_105 = "transfer.select"(%pair_res_neg_105, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_105 = "transfer.select"(%pair_ov_105, %pair_sat_105, %pair_mul_105) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_105 = "transfer.xor"(%pair_val_105, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_105 = "transfer.select"(%const_true, %pair_val0_105, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_105 = "transfer.select"(%const_true, %pair_val_105, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_105 = "transfer.and"(%pair_acc0_104, %pair_sel0_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_105 = "transfer.and"(%pair_acc1_104, %pair_sel1_105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_105 = "arith.ori"(%pair_any_104, %const_true) : (i1, i1) -> i1
    %pair_mul_106 = "transfer.mul"(%lhsu_v6, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_106 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_106 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_106 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_106 = "arith.xori"(%pair_lhs_neg_106, %pair_rhs_neg_106) : (i1, i1) -> i1
    %pair_sat_106 = "transfer.select"(%pair_res_neg_106, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_106 = "transfer.select"(%pair_ov_106, %pair_sat_106, %pair_mul_106) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_106 = "transfer.xor"(%pair_val_106, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_106 = "transfer.select"(%const_true, %pair_val0_106, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_106 = "transfer.select"(%const_true, %pair_val_106, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_106 = "transfer.and"(%pair_acc0_105, %pair_sel0_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_106 = "transfer.and"(%pair_acc1_105, %pair_sel1_106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_106 = "arith.ori"(%pair_any_105, %const_true) : (i1, i1) -> i1
    %pair_mul_107 = "transfer.mul"(%lhsu_v6, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_107 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_107 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_107 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_107 = "arith.xori"(%pair_lhs_neg_107, %pair_rhs_neg_107) : (i1, i1) -> i1
    %pair_sat_107 = "transfer.select"(%pair_res_neg_107, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_107 = "transfer.select"(%pair_ov_107, %pair_sat_107, %pair_mul_107) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_107 = "transfer.xor"(%pair_val_107, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_107 = "transfer.select"(%const_true, %pair_val0_107, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_107 = "transfer.select"(%const_true, %pair_val_107, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_107 = "transfer.and"(%pair_acc0_106, %pair_sel0_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_107 = "transfer.and"(%pair_acc1_106, %pair_sel1_107) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_107 = "arith.ori"(%pair_any_106, %const_true) : (i1, i1) -> i1
    %pair_mul_108 = "transfer.mul"(%lhsu_v6, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_108 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_108 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_108 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_108 = "arith.xori"(%pair_lhs_neg_108, %pair_rhs_neg_108) : (i1, i1) -> i1
    %pair_sat_108 = "transfer.select"(%pair_res_neg_108, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_108 = "transfer.select"(%pair_ov_108, %pair_sat_108, %pair_mul_108) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_108 = "transfer.xor"(%pair_val_108, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_108 = "transfer.select"(%const_true, %pair_val0_108, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_108 = "transfer.select"(%const_true, %pair_val_108, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_108 = "transfer.and"(%pair_acc0_107, %pair_sel0_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_108 = "transfer.and"(%pair_acc1_107, %pair_sel1_108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_108 = "arith.ori"(%pair_any_107, %const_true) : (i1, i1) -> i1
    %pair_mul_109 = "transfer.mul"(%lhsu_v6, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_109 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_109 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_109 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_109 = "arith.xori"(%pair_lhs_neg_109, %pair_rhs_neg_109) : (i1, i1) -> i1
    %pair_sat_109 = "transfer.select"(%pair_res_neg_109, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_109 = "transfer.select"(%pair_ov_109, %pair_sat_109, %pair_mul_109) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_109 = "transfer.xor"(%pair_val_109, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_109 = "transfer.select"(%const_true, %pair_val0_109, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_109 = "transfer.select"(%const_true, %pair_val_109, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_109 = "transfer.and"(%pair_acc0_108, %pair_sel0_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_109 = "transfer.and"(%pair_acc1_108, %pair_sel1_109) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_109 = "arith.ori"(%pair_any_108, %const_true) : (i1, i1) -> i1
    %pair_mul_110 = "transfer.mul"(%lhsu_v6, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_110 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_110 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_110 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_110 = "arith.xori"(%pair_lhs_neg_110, %pair_rhs_neg_110) : (i1, i1) -> i1
    %pair_sat_110 = "transfer.select"(%pair_res_neg_110, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_110 = "transfer.select"(%pair_ov_110, %pair_sat_110, %pair_mul_110) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_110 = "transfer.xor"(%pair_val_110, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_110 = "transfer.select"(%const_true, %pair_val0_110, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_110 = "transfer.select"(%const_true, %pair_val_110, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_110 = "transfer.and"(%pair_acc0_109, %pair_sel0_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_110 = "transfer.and"(%pair_acc1_109, %pair_sel1_110) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_110 = "arith.ori"(%pair_any_109, %const_true) : (i1, i1) -> i1
    %pair_mul_111 = "transfer.mul"(%lhsu_v6, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_111 = "transfer.smul_overflow"(%lhsu_v6, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_111 = "transfer.cmp"(%lhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_111 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_111 = "arith.xori"(%pair_lhs_neg_111, %pair_rhs_neg_111) : (i1, i1) -> i1
    %pair_sat_111 = "transfer.select"(%pair_res_neg_111, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_111 = "transfer.select"(%pair_ov_111, %pair_sat_111, %pair_mul_111) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_111 = "transfer.xor"(%pair_val_111, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_111 = "transfer.select"(%const_true, %pair_val0_111, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_111 = "transfer.select"(%const_true, %pair_val_111, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_111 = "transfer.and"(%pair_acc0_110, %pair_sel0_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_111 = "transfer.and"(%pair_acc1_110, %pair_sel1_111) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_111 = "arith.ori"(%pair_any_110, %const_true) : (i1, i1) -> i1
    %pair_mul_112 = "transfer.mul"(%lhsu_v7, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_112 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_112 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_112 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_112 = "arith.xori"(%pair_lhs_neg_112, %pair_rhs_neg_112) : (i1, i1) -> i1
    %pair_sat_112 = "transfer.select"(%pair_res_neg_112, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_112 = "transfer.select"(%pair_ov_112, %pair_sat_112, %pair_mul_112) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_112 = "transfer.xor"(%pair_val_112, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_112 = "transfer.select"(%const_true, %pair_val0_112, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_112 = "transfer.select"(%const_true, %pair_val_112, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_112 = "transfer.and"(%pair_acc0_111, %pair_sel0_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_112 = "transfer.and"(%pair_acc1_111, %pair_sel1_112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_112 = "arith.ori"(%pair_any_111, %const_true) : (i1, i1) -> i1
    %pair_mul_113 = "transfer.mul"(%lhsu_v7, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_113 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_113 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_113 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_113 = "arith.xori"(%pair_lhs_neg_113, %pair_rhs_neg_113) : (i1, i1) -> i1
    %pair_sat_113 = "transfer.select"(%pair_res_neg_113, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_113 = "transfer.select"(%pair_ov_113, %pair_sat_113, %pair_mul_113) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_113 = "transfer.xor"(%pair_val_113, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_113 = "transfer.select"(%const_true, %pair_val0_113, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_113 = "transfer.select"(%const_true, %pair_val_113, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_113 = "transfer.and"(%pair_acc0_112, %pair_sel0_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_113 = "transfer.and"(%pair_acc1_112, %pair_sel1_113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_113 = "arith.ori"(%pair_any_112, %const_true) : (i1, i1) -> i1
    %pair_mul_114 = "transfer.mul"(%lhsu_v7, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_114 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_114 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_114 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_114 = "arith.xori"(%pair_lhs_neg_114, %pair_rhs_neg_114) : (i1, i1) -> i1
    %pair_sat_114 = "transfer.select"(%pair_res_neg_114, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_114 = "transfer.select"(%pair_ov_114, %pair_sat_114, %pair_mul_114) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_114 = "transfer.xor"(%pair_val_114, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_114 = "transfer.select"(%const_true, %pair_val0_114, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_114 = "transfer.select"(%const_true, %pair_val_114, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_114 = "transfer.and"(%pair_acc0_113, %pair_sel0_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_114 = "transfer.and"(%pair_acc1_113, %pair_sel1_114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_114 = "arith.ori"(%pair_any_113, %const_true) : (i1, i1) -> i1
    %pair_mul_115 = "transfer.mul"(%lhsu_v7, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_115 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_115 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_115 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_115 = "arith.xori"(%pair_lhs_neg_115, %pair_rhs_neg_115) : (i1, i1) -> i1
    %pair_sat_115 = "transfer.select"(%pair_res_neg_115, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_115 = "transfer.select"(%pair_ov_115, %pair_sat_115, %pair_mul_115) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_115 = "transfer.xor"(%pair_val_115, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_115 = "transfer.select"(%const_true, %pair_val0_115, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_115 = "transfer.select"(%const_true, %pair_val_115, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_115 = "transfer.and"(%pair_acc0_114, %pair_sel0_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_115 = "transfer.and"(%pair_acc1_114, %pair_sel1_115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_115 = "arith.ori"(%pair_any_114, %const_true) : (i1, i1) -> i1
    %pair_mul_116 = "transfer.mul"(%lhsu_v7, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_116 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_116 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_116 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_116 = "arith.xori"(%pair_lhs_neg_116, %pair_rhs_neg_116) : (i1, i1) -> i1
    %pair_sat_116 = "transfer.select"(%pair_res_neg_116, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_116 = "transfer.select"(%pair_ov_116, %pair_sat_116, %pair_mul_116) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_116 = "transfer.xor"(%pair_val_116, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_116 = "transfer.select"(%const_true, %pair_val0_116, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_116 = "transfer.select"(%const_true, %pair_val_116, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_116 = "transfer.and"(%pair_acc0_115, %pair_sel0_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_116 = "transfer.and"(%pair_acc1_115, %pair_sel1_116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_116 = "arith.ori"(%pair_any_115, %const_true) : (i1, i1) -> i1
    %pair_mul_117 = "transfer.mul"(%lhsu_v7, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_117 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_117 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_117 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_117 = "arith.xori"(%pair_lhs_neg_117, %pair_rhs_neg_117) : (i1, i1) -> i1
    %pair_sat_117 = "transfer.select"(%pair_res_neg_117, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_117 = "transfer.select"(%pair_ov_117, %pair_sat_117, %pair_mul_117) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_117 = "transfer.xor"(%pair_val_117, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_117 = "transfer.select"(%const_true, %pair_val0_117, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_117 = "transfer.select"(%const_true, %pair_val_117, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_117 = "transfer.and"(%pair_acc0_116, %pair_sel0_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_117 = "transfer.and"(%pair_acc1_116, %pair_sel1_117) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_117 = "arith.ori"(%pair_any_116, %const_true) : (i1, i1) -> i1
    %pair_mul_118 = "transfer.mul"(%lhsu_v7, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_118 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_118 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_118 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_118 = "arith.xori"(%pair_lhs_neg_118, %pair_rhs_neg_118) : (i1, i1) -> i1
    %pair_sat_118 = "transfer.select"(%pair_res_neg_118, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_118 = "transfer.select"(%pair_ov_118, %pair_sat_118, %pair_mul_118) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_118 = "transfer.xor"(%pair_val_118, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_118 = "transfer.select"(%const_true, %pair_val0_118, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_118 = "transfer.select"(%const_true, %pair_val_118, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_118 = "transfer.and"(%pair_acc0_117, %pair_sel0_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_118 = "transfer.and"(%pair_acc1_117, %pair_sel1_118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_118 = "arith.ori"(%pair_any_117, %const_true) : (i1, i1) -> i1
    %pair_mul_119 = "transfer.mul"(%lhsu_v7, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_119 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_119 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_119 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_119 = "arith.xori"(%pair_lhs_neg_119, %pair_rhs_neg_119) : (i1, i1) -> i1
    %pair_sat_119 = "transfer.select"(%pair_res_neg_119, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_119 = "transfer.select"(%pair_ov_119, %pair_sat_119, %pair_mul_119) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_119 = "transfer.xor"(%pair_val_119, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_119 = "transfer.select"(%const_true, %pair_val0_119, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_119 = "transfer.select"(%const_true, %pair_val_119, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_119 = "transfer.and"(%pair_acc0_118, %pair_sel0_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_119 = "transfer.and"(%pair_acc1_118, %pair_sel1_119) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_119 = "arith.ori"(%pair_any_118, %const_true) : (i1, i1) -> i1
    %pair_mul_120 = "transfer.mul"(%lhsu_v7, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_120 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_120 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_120 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_120 = "arith.xori"(%pair_lhs_neg_120, %pair_rhs_neg_120) : (i1, i1) -> i1
    %pair_sat_120 = "transfer.select"(%pair_res_neg_120, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_120 = "transfer.select"(%pair_ov_120, %pair_sat_120, %pair_mul_120) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_120 = "transfer.xor"(%pair_val_120, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_120 = "transfer.select"(%const_true, %pair_val0_120, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_120 = "transfer.select"(%const_true, %pair_val_120, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_120 = "transfer.and"(%pair_acc0_119, %pair_sel0_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_120 = "transfer.and"(%pair_acc1_119, %pair_sel1_120) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_120 = "arith.ori"(%pair_any_119, %const_true) : (i1, i1) -> i1
    %pair_mul_121 = "transfer.mul"(%lhsu_v7, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_121 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_121 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_121 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_121 = "arith.xori"(%pair_lhs_neg_121, %pair_rhs_neg_121) : (i1, i1) -> i1
    %pair_sat_121 = "transfer.select"(%pair_res_neg_121, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_121 = "transfer.select"(%pair_ov_121, %pair_sat_121, %pair_mul_121) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_121 = "transfer.xor"(%pair_val_121, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_121 = "transfer.select"(%const_true, %pair_val0_121, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_121 = "transfer.select"(%const_true, %pair_val_121, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_121 = "transfer.and"(%pair_acc0_120, %pair_sel0_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_121 = "transfer.and"(%pair_acc1_120, %pair_sel1_121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_121 = "arith.ori"(%pair_any_120, %const_true) : (i1, i1) -> i1
    %pair_mul_122 = "transfer.mul"(%lhsu_v7, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_122 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_122 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_122 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_122 = "arith.xori"(%pair_lhs_neg_122, %pair_rhs_neg_122) : (i1, i1) -> i1
    %pair_sat_122 = "transfer.select"(%pair_res_neg_122, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_122 = "transfer.select"(%pair_ov_122, %pair_sat_122, %pair_mul_122) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_122 = "transfer.xor"(%pair_val_122, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_122 = "transfer.select"(%const_true, %pair_val0_122, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_122 = "transfer.select"(%const_true, %pair_val_122, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_122 = "transfer.and"(%pair_acc0_121, %pair_sel0_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_122 = "transfer.and"(%pair_acc1_121, %pair_sel1_122) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_122 = "arith.ori"(%pair_any_121, %const_true) : (i1, i1) -> i1
    %pair_mul_123 = "transfer.mul"(%lhsu_v7, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_123 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_123 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_123 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_123 = "arith.xori"(%pair_lhs_neg_123, %pair_rhs_neg_123) : (i1, i1) -> i1
    %pair_sat_123 = "transfer.select"(%pair_res_neg_123, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_123 = "transfer.select"(%pair_ov_123, %pair_sat_123, %pair_mul_123) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_123 = "transfer.xor"(%pair_val_123, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_123 = "transfer.select"(%const_true, %pair_val0_123, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_123 = "transfer.select"(%const_true, %pair_val_123, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_123 = "transfer.and"(%pair_acc0_122, %pair_sel0_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_123 = "transfer.and"(%pair_acc1_122, %pair_sel1_123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_123 = "arith.ori"(%pair_any_122, %const_true) : (i1, i1) -> i1
    %pair_mul_124 = "transfer.mul"(%lhsu_v7, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_124 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_124 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_124 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_124 = "arith.xori"(%pair_lhs_neg_124, %pair_rhs_neg_124) : (i1, i1) -> i1
    %pair_sat_124 = "transfer.select"(%pair_res_neg_124, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_124 = "transfer.select"(%pair_ov_124, %pair_sat_124, %pair_mul_124) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_124 = "transfer.xor"(%pair_val_124, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_124 = "transfer.select"(%const_true, %pair_val0_124, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_124 = "transfer.select"(%const_true, %pair_val_124, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_124 = "transfer.and"(%pair_acc0_123, %pair_sel0_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_124 = "transfer.and"(%pair_acc1_123, %pair_sel1_124) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_124 = "arith.ori"(%pair_any_123, %const_true) : (i1, i1) -> i1
    %pair_mul_125 = "transfer.mul"(%lhsu_v7, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_125 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_125 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_125 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_125 = "arith.xori"(%pair_lhs_neg_125, %pair_rhs_neg_125) : (i1, i1) -> i1
    %pair_sat_125 = "transfer.select"(%pair_res_neg_125, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_125 = "transfer.select"(%pair_ov_125, %pair_sat_125, %pair_mul_125) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_125 = "transfer.xor"(%pair_val_125, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_125 = "transfer.select"(%const_true, %pair_val0_125, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_125 = "transfer.select"(%const_true, %pair_val_125, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_125 = "transfer.and"(%pair_acc0_124, %pair_sel0_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_125 = "transfer.and"(%pair_acc1_124, %pair_sel1_125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_125 = "arith.ori"(%pair_any_124, %const_true) : (i1, i1) -> i1
    %pair_mul_126 = "transfer.mul"(%lhsu_v7, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_126 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_126 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_126 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_126 = "arith.xori"(%pair_lhs_neg_126, %pair_rhs_neg_126) : (i1, i1) -> i1
    %pair_sat_126 = "transfer.select"(%pair_res_neg_126, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_126 = "transfer.select"(%pair_ov_126, %pair_sat_126, %pair_mul_126) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_126 = "transfer.xor"(%pair_val_126, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_126 = "transfer.select"(%const_true, %pair_val0_126, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_126 = "transfer.select"(%const_true, %pair_val_126, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_126 = "transfer.and"(%pair_acc0_125, %pair_sel0_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_126 = "transfer.and"(%pair_acc1_125, %pair_sel1_126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_126 = "arith.ori"(%pair_any_125, %const_true) : (i1, i1) -> i1
    %pair_mul_127 = "transfer.mul"(%lhsu_v7, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_127 = "transfer.smul_overflow"(%lhsu_v7, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_127 = "transfer.cmp"(%lhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_127 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_127 = "arith.xori"(%pair_lhs_neg_127, %pair_rhs_neg_127) : (i1, i1) -> i1
    %pair_sat_127 = "transfer.select"(%pair_res_neg_127, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_127 = "transfer.select"(%pair_ov_127, %pair_sat_127, %pair_mul_127) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_127 = "transfer.xor"(%pair_val_127, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_127 = "transfer.select"(%const_true, %pair_val0_127, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_127 = "transfer.select"(%const_true, %pair_val_127, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_127 = "transfer.and"(%pair_acc0_126, %pair_sel0_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_127 = "transfer.and"(%pair_acc1_126, %pair_sel1_127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_127 = "arith.ori"(%pair_any_126, %const_true) : (i1, i1) -> i1
    %pair_mul_128 = "transfer.mul"(%lhsu_v8, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_128 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_128 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_128 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_128 = "arith.xori"(%pair_lhs_neg_128, %pair_rhs_neg_128) : (i1, i1) -> i1
    %pair_sat_128 = "transfer.select"(%pair_res_neg_128, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_128 = "transfer.select"(%pair_ov_128, %pair_sat_128, %pair_mul_128) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_128 = "transfer.xor"(%pair_val_128, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_128 = "transfer.select"(%const_true, %pair_val0_128, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_128 = "transfer.select"(%const_true, %pair_val_128, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_128 = "transfer.and"(%pair_acc0_127, %pair_sel0_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_128 = "transfer.and"(%pair_acc1_127, %pair_sel1_128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_128 = "arith.ori"(%pair_any_127, %const_true) : (i1, i1) -> i1
    %pair_mul_129 = "transfer.mul"(%lhsu_v8, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_129 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_129 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_129 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_129 = "arith.xori"(%pair_lhs_neg_129, %pair_rhs_neg_129) : (i1, i1) -> i1
    %pair_sat_129 = "transfer.select"(%pair_res_neg_129, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_129 = "transfer.select"(%pair_ov_129, %pair_sat_129, %pair_mul_129) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_129 = "transfer.xor"(%pair_val_129, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_129 = "transfer.select"(%const_true, %pair_val0_129, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_129 = "transfer.select"(%const_true, %pair_val_129, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_129 = "transfer.and"(%pair_acc0_128, %pair_sel0_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_129 = "transfer.and"(%pair_acc1_128, %pair_sel1_129) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_129 = "arith.ori"(%pair_any_128, %const_true) : (i1, i1) -> i1
    %pair_mul_130 = "transfer.mul"(%lhsu_v8, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_130 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_130 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_130 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_130 = "arith.xori"(%pair_lhs_neg_130, %pair_rhs_neg_130) : (i1, i1) -> i1
    %pair_sat_130 = "transfer.select"(%pair_res_neg_130, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_130 = "transfer.select"(%pair_ov_130, %pair_sat_130, %pair_mul_130) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_130 = "transfer.xor"(%pair_val_130, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_130 = "transfer.select"(%const_true, %pair_val0_130, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_130 = "transfer.select"(%const_true, %pair_val_130, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_130 = "transfer.and"(%pair_acc0_129, %pair_sel0_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_130 = "transfer.and"(%pair_acc1_129, %pair_sel1_130) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_130 = "arith.ori"(%pair_any_129, %const_true) : (i1, i1) -> i1
    %pair_mul_131 = "transfer.mul"(%lhsu_v8, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_131 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_131 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_131 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_131 = "arith.xori"(%pair_lhs_neg_131, %pair_rhs_neg_131) : (i1, i1) -> i1
    %pair_sat_131 = "transfer.select"(%pair_res_neg_131, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_131 = "transfer.select"(%pair_ov_131, %pair_sat_131, %pair_mul_131) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_131 = "transfer.xor"(%pair_val_131, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_131 = "transfer.select"(%const_true, %pair_val0_131, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_131 = "transfer.select"(%const_true, %pair_val_131, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_131 = "transfer.and"(%pair_acc0_130, %pair_sel0_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_131 = "transfer.and"(%pair_acc1_130, %pair_sel1_131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_131 = "arith.ori"(%pair_any_130, %const_true) : (i1, i1) -> i1
    %pair_mul_132 = "transfer.mul"(%lhsu_v8, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_132 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_132 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_132 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_132 = "arith.xori"(%pair_lhs_neg_132, %pair_rhs_neg_132) : (i1, i1) -> i1
    %pair_sat_132 = "transfer.select"(%pair_res_neg_132, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_132 = "transfer.select"(%pair_ov_132, %pair_sat_132, %pair_mul_132) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_132 = "transfer.xor"(%pair_val_132, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_132 = "transfer.select"(%const_true, %pair_val0_132, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_132 = "transfer.select"(%const_true, %pair_val_132, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_132 = "transfer.and"(%pair_acc0_131, %pair_sel0_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_132 = "transfer.and"(%pair_acc1_131, %pair_sel1_132) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_132 = "arith.ori"(%pair_any_131, %const_true) : (i1, i1) -> i1
    %pair_mul_133 = "transfer.mul"(%lhsu_v8, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_133 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_133 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_133 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_133 = "arith.xori"(%pair_lhs_neg_133, %pair_rhs_neg_133) : (i1, i1) -> i1
    %pair_sat_133 = "transfer.select"(%pair_res_neg_133, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_133 = "transfer.select"(%pair_ov_133, %pair_sat_133, %pair_mul_133) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_133 = "transfer.xor"(%pair_val_133, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_133 = "transfer.select"(%const_true, %pair_val0_133, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_133 = "transfer.select"(%const_true, %pair_val_133, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_133 = "transfer.and"(%pair_acc0_132, %pair_sel0_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_133 = "transfer.and"(%pair_acc1_132, %pair_sel1_133) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_133 = "arith.ori"(%pair_any_132, %const_true) : (i1, i1) -> i1
    %pair_mul_134 = "transfer.mul"(%lhsu_v8, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_134 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_134 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_134 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_134 = "arith.xori"(%pair_lhs_neg_134, %pair_rhs_neg_134) : (i1, i1) -> i1
    %pair_sat_134 = "transfer.select"(%pair_res_neg_134, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_134 = "transfer.select"(%pair_ov_134, %pair_sat_134, %pair_mul_134) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_134 = "transfer.xor"(%pair_val_134, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_134 = "transfer.select"(%const_true, %pair_val0_134, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_134 = "transfer.select"(%const_true, %pair_val_134, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_134 = "transfer.and"(%pair_acc0_133, %pair_sel0_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_134 = "transfer.and"(%pair_acc1_133, %pair_sel1_134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_134 = "arith.ori"(%pair_any_133, %const_true) : (i1, i1) -> i1
    %pair_mul_135 = "transfer.mul"(%lhsu_v8, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_135 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_135 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_135 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_135 = "arith.xori"(%pair_lhs_neg_135, %pair_rhs_neg_135) : (i1, i1) -> i1
    %pair_sat_135 = "transfer.select"(%pair_res_neg_135, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_135 = "transfer.select"(%pair_ov_135, %pair_sat_135, %pair_mul_135) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_135 = "transfer.xor"(%pair_val_135, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_135 = "transfer.select"(%const_true, %pair_val0_135, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_135 = "transfer.select"(%const_true, %pair_val_135, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_135 = "transfer.and"(%pair_acc0_134, %pair_sel0_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_135 = "transfer.and"(%pair_acc1_134, %pair_sel1_135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_135 = "arith.ori"(%pair_any_134, %const_true) : (i1, i1) -> i1
    %pair_mul_136 = "transfer.mul"(%lhsu_v8, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_136 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_136 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_136 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_136 = "arith.xori"(%pair_lhs_neg_136, %pair_rhs_neg_136) : (i1, i1) -> i1
    %pair_sat_136 = "transfer.select"(%pair_res_neg_136, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_136 = "transfer.select"(%pair_ov_136, %pair_sat_136, %pair_mul_136) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_136 = "transfer.xor"(%pair_val_136, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_136 = "transfer.select"(%const_true, %pair_val0_136, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_136 = "transfer.select"(%const_true, %pair_val_136, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_136 = "transfer.and"(%pair_acc0_135, %pair_sel0_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_136 = "transfer.and"(%pair_acc1_135, %pair_sel1_136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_136 = "arith.ori"(%pair_any_135, %const_true) : (i1, i1) -> i1
    %pair_mul_137 = "transfer.mul"(%lhsu_v8, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_137 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_137 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_137 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_137 = "arith.xori"(%pair_lhs_neg_137, %pair_rhs_neg_137) : (i1, i1) -> i1
    %pair_sat_137 = "transfer.select"(%pair_res_neg_137, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_137 = "transfer.select"(%pair_ov_137, %pair_sat_137, %pair_mul_137) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_137 = "transfer.xor"(%pair_val_137, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_137 = "transfer.select"(%const_true, %pair_val0_137, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_137 = "transfer.select"(%const_true, %pair_val_137, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_137 = "transfer.and"(%pair_acc0_136, %pair_sel0_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_137 = "transfer.and"(%pair_acc1_136, %pair_sel1_137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_137 = "arith.ori"(%pair_any_136, %const_true) : (i1, i1) -> i1
    %pair_mul_138 = "transfer.mul"(%lhsu_v8, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_138 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_138 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_138 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_138 = "arith.xori"(%pair_lhs_neg_138, %pair_rhs_neg_138) : (i1, i1) -> i1
    %pair_sat_138 = "transfer.select"(%pair_res_neg_138, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_138 = "transfer.select"(%pair_ov_138, %pair_sat_138, %pair_mul_138) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_138 = "transfer.xor"(%pair_val_138, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_138 = "transfer.select"(%const_true, %pair_val0_138, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_138 = "transfer.select"(%const_true, %pair_val_138, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_138 = "transfer.and"(%pair_acc0_137, %pair_sel0_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_138 = "transfer.and"(%pair_acc1_137, %pair_sel1_138) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_138 = "arith.ori"(%pair_any_137, %const_true) : (i1, i1) -> i1
    %pair_mul_139 = "transfer.mul"(%lhsu_v8, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_139 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_139 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_139 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_139 = "arith.xori"(%pair_lhs_neg_139, %pair_rhs_neg_139) : (i1, i1) -> i1
    %pair_sat_139 = "transfer.select"(%pair_res_neg_139, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_139 = "transfer.select"(%pair_ov_139, %pair_sat_139, %pair_mul_139) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_139 = "transfer.xor"(%pair_val_139, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_139 = "transfer.select"(%const_true, %pair_val0_139, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_139 = "transfer.select"(%const_true, %pair_val_139, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_139 = "transfer.and"(%pair_acc0_138, %pair_sel0_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_139 = "transfer.and"(%pair_acc1_138, %pair_sel1_139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_139 = "arith.ori"(%pair_any_138, %const_true) : (i1, i1) -> i1
    %pair_mul_140 = "transfer.mul"(%lhsu_v8, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_140 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_140 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_140 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_140 = "arith.xori"(%pair_lhs_neg_140, %pair_rhs_neg_140) : (i1, i1) -> i1
    %pair_sat_140 = "transfer.select"(%pair_res_neg_140, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_140 = "transfer.select"(%pair_ov_140, %pair_sat_140, %pair_mul_140) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_140 = "transfer.xor"(%pair_val_140, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_140 = "transfer.select"(%const_true, %pair_val0_140, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_140 = "transfer.select"(%const_true, %pair_val_140, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_140 = "transfer.and"(%pair_acc0_139, %pair_sel0_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_140 = "transfer.and"(%pair_acc1_139, %pair_sel1_140) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_140 = "arith.ori"(%pair_any_139, %const_true) : (i1, i1) -> i1
    %pair_mul_141 = "transfer.mul"(%lhsu_v8, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_141 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_141 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_141 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_141 = "arith.xori"(%pair_lhs_neg_141, %pair_rhs_neg_141) : (i1, i1) -> i1
    %pair_sat_141 = "transfer.select"(%pair_res_neg_141, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_141 = "transfer.select"(%pair_ov_141, %pair_sat_141, %pair_mul_141) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_141 = "transfer.xor"(%pair_val_141, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_141 = "transfer.select"(%const_true, %pair_val0_141, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_141 = "transfer.select"(%const_true, %pair_val_141, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_141 = "transfer.and"(%pair_acc0_140, %pair_sel0_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_141 = "transfer.and"(%pair_acc1_140, %pair_sel1_141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_141 = "arith.ori"(%pair_any_140, %const_true) : (i1, i1) -> i1
    %pair_mul_142 = "transfer.mul"(%lhsu_v8, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_142 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_142 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_142 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_142 = "arith.xori"(%pair_lhs_neg_142, %pair_rhs_neg_142) : (i1, i1) -> i1
    %pair_sat_142 = "transfer.select"(%pair_res_neg_142, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_142 = "transfer.select"(%pair_ov_142, %pair_sat_142, %pair_mul_142) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_142 = "transfer.xor"(%pair_val_142, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_142 = "transfer.select"(%const_true, %pair_val0_142, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_142 = "transfer.select"(%const_true, %pair_val_142, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_142 = "transfer.and"(%pair_acc0_141, %pair_sel0_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_142 = "transfer.and"(%pair_acc1_141, %pair_sel1_142) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_142 = "arith.ori"(%pair_any_141, %const_true) : (i1, i1) -> i1
    %pair_mul_143 = "transfer.mul"(%lhsu_v8, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_143 = "transfer.smul_overflow"(%lhsu_v8, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_143 = "transfer.cmp"(%lhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_143 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_143 = "arith.xori"(%pair_lhs_neg_143, %pair_rhs_neg_143) : (i1, i1) -> i1
    %pair_sat_143 = "transfer.select"(%pair_res_neg_143, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_143 = "transfer.select"(%pair_ov_143, %pair_sat_143, %pair_mul_143) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_143 = "transfer.xor"(%pair_val_143, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_143 = "transfer.select"(%const_true, %pair_val0_143, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_143 = "transfer.select"(%const_true, %pair_val_143, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_143 = "transfer.and"(%pair_acc0_142, %pair_sel0_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_143 = "transfer.and"(%pair_acc1_142, %pair_sel1_143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_143 = "arith.ori"(%pair_any_142, %const_true) : (i1, i1) -> i1
    %pair_mul_144 = "transfer.mul"(%lhsu_v9, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_144 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_144 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_144 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_144 = "arith.xori"(%pair_lhs_neg_144, %pair_rhs_neg_144) : (i1, i1) -> i1
    %pair_sat_144 = "transfer.select"(%pair_res_neg_144, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_144 = "transfer.select"(%pair_ov_144, %pair_sat_144, %pair_mul_144) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_144 = "transfer.xor"(%pair_val_144, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_144 = "transfer.select"(%const_true, %pair_val0_144, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_144 = "transfer.select"(%const_true, %pair_val_144, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_144 = "transfer.and"(%pair_acc0_143, %pair_sel0_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_144 = "transfer.and"(%pair_acc1_143, %pair_sel1_144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_144 = "arith.ori"(%pair_any_143, %const_true) : (i1, i1) -> i1
    %pair_mul_145 = "transfer.mul"(%lhsu_v9, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_145 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_145 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_145 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_145 = "arith.xori"(%pair_lhs_neg_145, %pair_rhs_neg_145) : (i1, i1) -> i1
    %pair_sat_145 = "transfer.select"(%pair_res_neg_145, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_145 = "transfer.select"(%pair_ov_145, %pair_sat_145, %pair_mul_145) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_145 = "transfer.xor"(%pair_val_145, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_145 = "transfer.select"(%const_true, %pair_val0_145, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_145 = "transfer.select"(%const_true, %pair_val_145, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_145 = "transfer.and"(%pair_acc0_144, %pair_sel0_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_145 = "transfer.and"(%pair_acc1_144, %pair_sel1_145) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_145 = "arith.ori"(%pair_any_144, %const_true) : (i1, i1) -> i1
    %pair_mul_146 = "transfer.mul"(%lhsu_v9, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_146 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_146 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_146 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_146 = "arith.xori"(%pair_lhs_neg_146, %pair_rhs_neg_146) : (i1, i1) -> i1
    %pair_sat_146 = "transfer.select"(%pair_res_neg_146, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_146 = "transfer.select"(%pair_ov_146, %pair_sat_146, %pair_mul_146) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_146 = "transfer.xor"(%pair_val_146, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_146 = "transfer.select"(%const_true, %pair_val0_146, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_146 = "transfer.select"(%const_true, %pair_val_146, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_146 = "transfer.and"(%pair_acc0_145, %pair_sel0_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_146 = "transfer.and"(%pair_acc1_145, %pair_sel1_146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_146 = "arith.ori"(%pair_any_145, %const_true) : (i1, i1) -> i1
    %pair_mul_147 = "transfer.mul"(%lhsu_v9, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_147 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_147 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_147 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_147 = "arith.xori"(%pair_lhs_neg_147, %pair_rhs_neg_147) : (i1, i1) -> i1
    %pair_sat_147 = "transfer.select"(%pair_res_neg_147, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_147 = "transfer.select"(%pair_ov_147, %pair_sat_147, %pair_mul_147) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_147 = "transfer.xor"(%pair_val_147, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_147 = "transfer.select"(%const_true, %pair_val0_147, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_147 = "transfer.select"(%const_true, %pair_val_147, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_147 = "transfer.and"(%pair_acc0_146, %pair_sel0_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_147 = "transfer.and"(%pair_acc1_146, %pair_sel1_147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_147 = "arith.ori"(%pair_any_146, %const_true) : (i1, i1) -> i1
    %pair_mul_148 = "transfer.mul"(%lhsu_v9, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_148 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_148 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_148 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_148 = "arith.xori"(%pair_lhs_neg_148, %pair_rhs_neg_148) : (i1, i1) -> i1
    %pair_sat_148 = "transfer.select"(%pair_res_neg_148, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_148 = "transfer.select"(%pair_ov_148, %pair_sat_148, %pair_mul_148) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_148 = "transfer.xor"(%pair_val_148, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_148 = "transfer.select"(%const_true, %pair_val0_148, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_148 = "transfer.select"(%const_true, %pair_val_148, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_148 = "transfer.and"(%pair_acc0_147, %pair_sel0_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_148 = "transfer.and"(%pair_acc1_147, %pair_sel1_148) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_148 = "arith.ori"(%pair_any_147, %const_true) : (i1, i1) -> i1
    %pair_mul_149 = "transfer.mul"(%lhsu_v9, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_149 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_149 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_149 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_149 = "arith.xori"(%pair_lhs_neg_149, %pair_rhs_neg_149) : (i1, i1) -> i1
    %pair_sat_149 = "transfer.select"(%pair_res_neg_149, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_149 = "transfer.select"(%pair_ov_149, %pair_sat_149, %pair_mul_149) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_149 = "transfer.xor"(%pair_val_149, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_149 = "transfer.select"(%const_true, %pair_val0_149, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_149 = "transfer.select"(%const_true, %pair_val_149, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_149 = "transfer.and"(%pair_acc0_148, %pair_sel0_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_149 = "transfer.and"(%pair_acc1_148, %pair_sel1_149) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_149 = "arith.ori"(%pair_any_148, %const_true) : (i1, i1) -> i1
    %pair_mul_150 = "transfer.mul"(%lhsu_v9, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_150 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_150 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_150 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_150 = "arith.xori"(%pair_lhs_neg_150, %pair_rhs_neg_150) : (i1, i1) -> i1
    %pair_sat_150 = "transfer.select"(%pair_res_neg_150, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_150 = "transfer.select"(%pair_ov_150, %pair_sat_150, %pair_mul_150) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_150 = "transfer.xor"(%pair_val_150, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_150 = "transfer.select"(%const_true, %pair_val0_150, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_150 = "transfer.select"(%const_true, %pair_val_150, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_150 = "transfer.and"(%pair_acc0_149, %pair_sel0_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_150 = "transfer.and"(%pair_acc1_149, %pair_sel1_150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_150 = "arith.ori"(%pair_any_149, %const_true) : (i1, i1) -> i1
    %pair_mul_151 = "transfer.mul"(%lhsu_v9, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_151 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_151 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_151 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_151 = "arith.xori"(%pair_lhs_neg_151, %pair_rhs_neg_151) : (i1, i1) -> i1
    %pair_sat_151 = "transfer.select"(%pair_res_neg_151, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_151 = "transfer.select"(%pair_ov_151, %pair_sat_151, %pair_mul_151) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_151 = "transfer.xor"(%pair_val_151, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_151 = "transfer.select"(%const_true, %pair_val0_151, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_151 = "transfer.select"(%const_true, %pair_val_151, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_151 = "transfer.and"(%pair_acc0_150, %pair_sel0_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_151 = "transfer.and"(%pair_acc1_150, %pair_sel1_151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_151 = "arith.ori"(%pair_any_150, %const_true) : (i1, i1) -> i1
    %pair_mul_152 = "transfer.mul"(%lhsu_v9, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_152 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_152 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_152 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_152 = "arith.xori"(%pair_lhs_neg_152, %pair_rhs_neg_152) : (i1, i1) -> i1
    %pair_sat_152 = "transfer.select"(%pair_res_neg_152, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_152 = "transfer.select"(%pair_ov_152, %pair_sat_152, %pair_mul_152) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_152 = "transfer.xor"(%pair_val_152, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_152 = "transfer.select"(%const_true, %pair_val0_152, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_152 = "transfer.select"(%const_true, %pair_val_152, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_152 = "transfer.and"(%pair_acc0_151, %pair_sel0_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_152 = "transfer.and"(%pair_acc1_151, %pair_sel1_152) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_152 = "arith.ori"(%pair_any_151, %const_true) : (i1, i1) -> i1
    %pair_mul_153 = "transfer.mul"(%lhsu_v9, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_153 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_153 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_153 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_153 = "arith.xori"(%pair_lhs_neg_153, %pair_rhs_neg_153) : (i1, i1) -> i1
    %pair_sat_153 = "transfer.select"(%pair_res_neg_153, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_153 = "transfer.select"(%pair_ov_153, %pair_sat_153, %pair_mul_153) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_153 = "transfer.xor"(%pair_val_153, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_153 = "transfer.select"(%const_true, %pair_val0_153, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_153 = "transfer.select"(%const_true, %pair_val_153, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_153 = "transfer.and"(%pair_acc0_152, %pair_sel0_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_153 = "transfer.and"(%pair_acc1_152, %pair_sel1_153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_153 = "arith.ori"(%pair_any_152, %const_true) : (i1, i1) -> i1
    %pair_mul_154 = "transfer.mul"(%lhsu_v9, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_154 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_154 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_154 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_154 = "arith.xori"(%pair_lhs_neg_154, %pair_rhs_neg_154) : (i1, i1) -> i1
    %pair_sat_154 = "transfer.select"(%pair_res_neg_154, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_154 = "transfer.select"(%pair_ov_154, %pair_sat_154, %pair_mul_154) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_154 = "transfer.xor"(%pair_val_154, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_154 = "transfer.select"(%const_true, %pair_val0_154, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_154 = "transfer.select"(%const_true, %pair_val_154, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_154 = "transfer.and"(%pair_acc0_153, %pair_sel0_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_154 = "transfer.and"(%pair_acc1_153, %pair_sel1_154) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_154 = "arith.ori"(%pair_any_153, %const_true) : (i1, i1) -> i1
    %pair_mul_155 = "transfer.mul"(%lhsu_v9, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_155 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_155 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_155 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_155 = "arith.xori"(%pair_lhs_neg_155, %pair_rhs_neg_155) : (i1, i1) -> i1
    %pair_sat_155 = "transfer.select"(%pair_res_neg_155, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_155 = "transfer.select"(%pair_ov_155, %pair_sat_155, %pair_mul_155) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_155 = "transfer.xor"(%pair_val_155, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_155 = "transfer.select"(%const_true, %pair_val0_155, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_155 = "transfer.select"(%const_true, %pair_val_155, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_155 = "transfer.and"(%pair_acc0_154, %pair_sel0_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_155 = "transfer.and"(%pair_acc1_154, %pair_sel1_155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_155 = "arith.ori"(%pair_any_154, %const_true) : (i1, i1) -> i1
    %pair_mul_156 = "transfer.mul"(%lhsu_v9, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_156 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_156 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_156 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_156 = "arith.xori"(%pair_lhs_neg_156, %pair_rhs_neg_156) : (i1, i1) -> i1
    %pair_sat_156 = "transfer.select"(%pair_res_neg_156, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_156 = "transfer.select"(%pair_ov_156, %pair_sat_156, %pair_mul_156) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_156 = "transfer.xor"(%pair_val_156, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_156 = "transfer.select"(%const_true, %pair_val0_156, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_156 = "transfer.select"(%const_true, %pair_val_156, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_156 = "transfer.and"(%pair_acc0_155, %pair_sel0_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_156 = "transfer.and"(%pair_acc1_155, %pair_sel1_156) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_156 = "arith.ori"(%pair_any_155, %const_true) : (i1, i1) -> i1
    %pair_mul_157 = "transfer.mul"(%lhsu_v9, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_157 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_157 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_157 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_157 = "arith.xori"(%pair_lhs_neg_157, %pair_rhs_neg_157) : (i1, i1) -> i1
    %pair_sat_157 = "transfer.select"(%pair_res_neg_157, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_157 = "transfer.select"(%pair_ov_157, %pair_sat_157, %pair_mul_157) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_157 = "transfer.xor"(%pair_val_157, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_157 = "transfer.select"(%const_true, %pair_val0_157, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_157 = "transfer.select"(%const_true, %pair_val_157, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_157 = "transfer.and"(%pair_acc0_156, %pair_sel0_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_157 = "transfer.and"(%pair_acc1_156, %pair_sel1_157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_157 = "arith.ori"(%pair_any_156, %const_true) : (i1, i1) -> i1
    %pair_mul_158 = "transfer.mul"(%lhsu_v9, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_158 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_158 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_158 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_158 = "arith.xori"(%pair_lhs_neg_158, %pair_rhs_neg_158) : (i1, i1) -> i1
    %pair_sat_158 = "transfer.select"(%pair_res_neg_158, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_158 = "transfer.select"(%pair_ov_158, %pair_sat_158, %pair_mul_158) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_158 = "transfer.xor"(%pair_val_158, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_158 = "transfer.select"(%const_true, %pair_val0_158, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_158 = "transfer.select"(%const_true, %pair_val_158, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_158 = "transfer.and"(%pair_acc0_157, %pair_sel0_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_158 = "transfer.and"(%pair_acc1_157, %pair_sel1_158) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_158 = "arith.ori"(%pair_any_157, %const_true) : (i1, i1) -> i1
    %pair_mul_159 = "transfer.mul"(%lhsu_v9, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_159 = "transfer.smul_overflow"(%lhsu_v9, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_159 = "transfer.cmp"(%lhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_159 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_159 = "arith.xori"(%pair_lhs_neg_159, %pair_rhs_neg_159) : (i1, i1) -> i1
    %pair_sat_159 = "transfer.select"(%pair_res_neg_159, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_159 = "transfer.select"(%pair_ov_159, %pair_sat_159, %pair_mul_159) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_159 = "transfer.xor"(%pair_val_159, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_159 = "transfer.select"(%const_true, %pair_val0_159, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_159 = "transfer.select"(%const_true, %pair_val_159, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_159 = "transfer.and"(%pair_acc0_158, %pair_sel0_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_159 = "transfer.and"(%pair_acc1_158, %pair_sel1_159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_159 = "arith.ori"(%pair_any_158, %const_true) : (i1, i1) -> i1
    %pair_mul_160 = "transfer.mul"(%lhsu_v10, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_160 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_160 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_160 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_160 = "arith.xori"(%pair_lhs_neg_160, %pair_rhs_neg_160) : (i1, i1) -> i1
    %pair_sat_160 = "transfer.select"(%pair_res_neg_160, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_160 = "transfer.select"(%pair_ov_160, %pair_sat_160, %pair_mul_160) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_160 = "transfer.xor"(%pair_val_160, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_160 = "transfer.select"(%const_true, %pair_val0_160, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_160 = "transfer.select"(%const_true, %pair_val_160, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_160 = "transfer.and"(%pair_acc0_159, %pair_sel0_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_160 = "transfer.and"(%pair_acc1_159, %pair_sel1_160) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_160 = "arith.ori"(%pair_any_159, %const_true) : (i1, i1) -> i1
    %pair_mul_161 = "transfer.mul"(%lhsu_v10, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_161 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_161 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_161 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_161 = "arith.xori"(%pair_lhs_neg_161, %pair_rhs_neg_161) : (i1, i1) -> i1
    %pair_sat_161 = "transfer.select"(%pair_res_neg_161, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_161 = "transfer.select"(%pair_ov_161, %pair_sat_161, %pair_mul_161) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_161 = "transfer.xor"(%pair_val_161, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_161 = "transfer.select"(%const_true, %pair_val0_161, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_161 = "transfer.select"(%const_true, %pair_val_161, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_161 = "transfer.and"(%pair_acc0_160, %pair_sel0_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_161 = "transfer.and"(%pair_acc1_160, %pair_sel1_161) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_161 = "arith.ori"(%pair_any_160, %const_true) : (i1, i1) -> i1
    %pair_mul_162 = "transfer.mul"(%lhsu_v10, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_162 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_162 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_162 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_162 = "arith.xori"(%pair_lhs_neg_162, %pair_rhs_neg_162) : (i1, i1) -> i1
    %pair_sat_162 = "transfer.select"(%pair_res_neg_162, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_162 = "transfer.select"(%pair_ov_162, %pair_sat_162, %pair_mul_162) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_162 = "transfer.xor"(%pair_val_162, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_162 = "transfer.select"(%const_true, %pair_val0_162, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_162 = "transfer.select"(%const_true, %pair_val_162, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_162 = "transfer.and"(%pair_acc0_161, %pair_sel0_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_162 = "transfer.and"(%pair_acc1_161, %pair_sel1_162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_162 = "arith.ori"(%pair_any_161, %const_true) : (i1, i1) -> i1
    %pair_mul_163 = "transfer.mul"(%lhsu_v10, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_163 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_163 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_163 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_163 = "arith.xori"(%pair_lhs_neg_163, %pair_rhs_neg_163) : (i1, i1) -> i1
    %pair_sat_163 = "transfer.select"(%pair_res_neg_163, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_163 = "transfer.select"(%pair_ov_163, %pair_sat_163, %pair_mul_163) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_163 = "transfer.xor"(%pair_val_163, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_163 = "transfer.select"(%const_true, %pair_val0_163, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_163 = "transfer.select"(%const_true, %pair_val_163, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_163 = "transfer.and"(%pair_acc0_162, %pair_sel0_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_163 = "transfer.and"(%pair_acc1_162, %pair_sel1_163) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_163 = "arith.ori"(%pair_any_162, %const_true) : (i1, i1) -> i1
    %pair_mul_164 = "transfer.mul"(%lhsu_v10, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_164 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_164 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_164 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_164 = "arith.xori"(%pair_lhs_neg_164, %pair_rhs_neg_164) : (i1, i1) -> i1
    %pair_sat_164 = "transfer.select"(%pair_res_neg_164, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_164 = "transfer.select"(%pair_ov_164, %pair_sat_164, %pair_mul_164) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_164 = "transfer.xor"(%pair_val_164, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_164 = "transfer.select"(%const_true, %pair_val0_164, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_164 = "transfer.select"(%const_true, %pair_val_164, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_164 = "transfer.and"(%pair_acc0_163, %pair_sel0_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_164 = "transfer.and"(%pair_acc1_163, %pair_sel1_164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_164 = "arith.ori"(%pair_any_163, %const_true) : (i1, i1) -> i1
    %pair_mul_165 = "transfer.mul"(%lhsu_v10, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_165 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_165 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_165 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_165 = "arith.xori"(%pair_lhs_neg_165, %pair_rhs_neg_165) : (i1, i1) -> i1
    %pair_sat_165 = "transfer.select"(%pair_res_neg_165, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_165 = "transfer.select"(%pair_ov_165, %pair_sat_165, %pair_mul_165) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_165 = "transfer.xor"(%pair_val_165, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_165 = "transfer.select"(%const_true, %pair_val0_165, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_165 = "transfer.select"(%const_true, %pair_val_165, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_165 = "transfer.and"(%pair_acc0_164, %pair_sel0_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_165 = "transfer.and"(%pair_acc1_164, %pair_sel1_165) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_165 = "arith.ori"(%pair_any_164, %const_true) : (i1, i1) -> i1
    %pair_mul_166 = "transfer.mul"(%lhsu_v10, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_166 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_166 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_166 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_166 = "arith.xori"(%pair_lhs_neg_166, %pair_rhs_neg_166) : (i1, i1) -> i1
    %pair_sat_166 = "transfer.select"(%pair_res_neg_166, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_166 = "transfer.select"(%pair_ov_166, %pair_sat_166, %pair_mul_166) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_166 = "transfer.xor"(%pair_val_166, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_166 = "transfer.select"(%const_true, %pair_val0_166, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_166 = "transfer.select"(%const_true, %pair_val_166, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_166 = "transfer.and"(%pair_acc0_165, %pair_sel0_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_166 = "transfer.and"(%pair_acc1_165, %pair_sel1_166) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_166 = "arith.ori"(%pair_any_165, %const_true) : (i1, i1) -> i1
    %pair_mul_167 = "transfer.mul"(%lhsu_v10, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_167 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_167 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_167 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_167 = "arith.xori"(%pair_lhs_neg_167, %pair_rhs_neg_167) : (i1, i1) -> i1
    %pair_sat_167 = "transfer.select"(%pair_res_neg_167, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_167 = "transfer.select"(%pair_ov_167, %pair_sat_167, %pair_mul_167) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_167 = "transfer.xor"(%pair_val_167, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_167 = "transfer.select"(%const_true, %pair_val0_167, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_167 = "transfer.select"(%const_true, %pair_val_167, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_167 = "transfer.and"(%pair_acc0_166, %pair_sel0_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_167 = "transfer.and"(%pair_acc1_166, %pair_sel1_167) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_167 = "arith.ori"(%pair_any_166, %const_true) : (i1, i1) -> i1
    %pair_mul_168 = "transfer.mul"(%lhsu_v10, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_168 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_168 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_168 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_168 = "arith.xori"(%pair_lhs_neg_168, %pair_rhs_neg_168) : (i1, i1) -> i1
    %pair_sat_168 = "transfer.select"(%pair_res_neg_168, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_168 = "transfer.select"(%pair_ov_168, %pair_sat_168, %pair_mul_168) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_168 = "transfer.xor"(%pair_val_168, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_168 = "transfer.select"(%const_true, %pair_val0_168, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_168 = "transfer.select"(%const_true, %pair_val_168, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_168 = "transfer.and"(%pair_acc0_167, %pair_sel0_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_168 = "transfer.and"(%pair_acc1_167, %pair_sel1_168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_168 = "arith.ori"(%pair_any_167, %const_true) : (i1, i1) -> i1
    %pair_mul_169 = "transfer.mul"(%lhsu_v10, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_169 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_169 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_169 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_169 = "arith.xori"(%pair_lhs_neg_169, %pair_rhs_neg_169) : (i1, i1) -> i1
    %pair_sat_169 = "transfer.select"(%pair_res_neg_169, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_169 = "transfer.select"(%pair_ov_169, %pair_sat_169, %pair_mul_169) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_169 = "transfer.xor"(%pair_val_169, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_169 = "transfer.select"(%const_true, %pair_val0_169, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_169 = "transfer.select"(%const_true, %pair_val_169, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_169 = "transfer.and"(%pair_acc0_168, %pair_sel0_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_169 = "transfer.and"(%pair_acc1_168, %pair_sel1_169) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_169 = "arith.ori"(%pair_any_168, %const_true) : (i1, i1) -> i1
    %pair_mul_170 = "transfer.mul"(%lhsu_v10, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_170 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_170 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_170 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_170 = "arith.xori"(%pair_lhs_neg_170, %pair_rhs_neg_170) : (i1, i1) -> i1
    %pair_sat_170 = "transfer.select"(%pair_res_neg_170, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_170 = "transfer.select"(%pair_ov_170, %pair_sat_170, %pair_mul_170) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_170 = "transfer.xor"(%pair_val_170, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_170 = "transfer.select"(%const_true, %pair_val0_170, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_170 = "transfer.select"(%const_true, %pair_val_170, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_170 = "transfer.and"(%pair_acc0_169, %pair_sel0_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_170 = "transfer.and"(%pair_acc1_169, %pair_sel1_170) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_170 = "arith.ori"(%pair_any_169, %const_true) : (i1, i1) -> i1
    %pair_mul_171 = "transfer.mul"(%lhsu_v10, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_171 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_171 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_171 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_171 = "arith.xori"(%pair_lhs_neg_171, %pair_rhs_neg_171) : (i1, i1) -> i1
    %pair_sat_171 = "transfer.select"(%pair_res_neg_171, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_171 = "transfer.select"(%pair_ov_171, %pair_sat_171, %pair_mul_171) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_171 = "transfer.xor"(%pair_val_171, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_171 = "transfer.select"(%const_true, %pair_val0_171, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_171 = "transfer.select"(%const_true, %pair_val_171, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_171 = "transfer.and"(%pair_acc0_170, %pair_sel0_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_171 = "transfer.and"(%pair_acc1_170, %pair_sel1_171) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_171 = "arith.ori"(%pair_any_170, %const_true) : (i1, i1) -> i1
    %pair_mul_172 = "transfer.mul"(%lhsu_v10, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_172 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_172 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_172 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_172 = "arith.xori"(%pair_lhs_neg_172, %pair_rhs_neg_172) : (i1, i1) -> i1
    %pair_sat_172 = "transfer.select"(%pair_res_neg_172, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_172 = "transfer.select"(%pair_ov_172, %pair_sat_172, %pair_mul_172) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_172 = "transfer.xor"(%pair_val_172, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_172 = "transfer.select"(%const_true, %pair_val0_172, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_172 = "transfer.select"(%const_true, %pair_val_172, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_172 = "transfer.and"(%pair_acc0_171, %pair_sel0_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_172 = "transfer.and"(%pair_acc1_171, %pair_sel1_172) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_172 = "arith.ori"(%pair_any_171, %const_true) : (i1, i1) -> i1
    %pair_mul_173 = "transfer.mul"(%lhsu_v10, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_173 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_173 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_173 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_173 = "arith.xori"(%pair_lhs_neg_173, %pair_rhs_neg_173) : (i1, i1) -> i1
    %pair_sat_173 = "transfer.select"(%pair_res_neg_173, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_173 = "transfer.select"(%pair_ov_173, %pair_sat_173, %pair_mul_173) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_173 = "transfer.xor"(%pair_val_173, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_173 = "transfer.select"(%const_true, %pair_val0_173, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_173 = "transfer.select"(%const_true, %pair_val_173, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_173 = "transfer.and"(%pair_acc0_172, %pair_sel0_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_173 = "transfer.and"(%pair_acc1_172, %pair_sel1_173) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_173 = "arith.ori"(%pair_any_172, %const_true) : (i1, i1) -> i1
    %pair_mul_174 = "transfer.mul"(%lhsu_v10, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_174 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_174 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_174 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_174 = "arith.xori"(%pair_lhs_neg_174, %pair_rhs_neg_174) : (i1, i1) -> i1
    %pair_sat_174 = "transfer.select"(%pair_res_neg_174, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_174 = "transfer.select"(%pair_ov_174, %pair_sat_174, %pair_mul_174) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_174 = "transfer.xor"(%pair_val_174, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_174 = "transfer.select"(%const_true, %pair_val0_174, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_174 = "transfer.select"(%const_true, %pair_val_174, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_174 = "transfer.and"(%pair_acc0_173, %pair_sel0_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_174 = "transfer.and"(%pair_acc1_173, %pair_sel1_174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_174 = "arith.ori"(%pair_any_173, %const_true) : (i1, i1) -> i1
    %pair_mul_175 = "transfer.mul"(%lhsu_v10, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_175 = "transfer.smul_overflow"(%lhsu_v10, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_175 = "transfer.cmp"(%lhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_175 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_175 = "arith.xori"(%pair_lhs_neg_175, %pair_rhs_neg_175) : (i1, i1) -> i1
    %pair_sat_175 = "transfer.select"(%pair_res_neg_175, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_175 = "transfer.select"(%pair_ov_175, %pair_sat_175, %pair_mul_175) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_175 = "transfer.xor"(%pair_val_175, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_175 = "transfer.select"(%const_true, %pair_val0_175, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_175 = "transfer.select"(%const_true, %pair_val_175, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_175 = "transfer.and"(%pair_acc0_174, %pair_sel0_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_175 = "transfer.and"(%pair_acc1_174, %pair_sel1_175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_175 = "arith.ori"(%pair_any_174, %const_true) : (i1, i1) -> i1
    %pair_mul_176 = "transfer.mul"(%lhsu_v11, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_176 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_176 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_176 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_176 = "arith.xori"(%pair_lhs_neg_176, %pair_rhs_neg_176) : (i1, i1) -> i1
    %pair_sat_176 = "transfer.select"(%pair_res_neg_176, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_176 = "transfer.select"(%pair_ov_176, %pair_sat_176, %pair_mul_176) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_176 = "transfer.xor"(%pair_val_176, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_176 = "transfer.select"(%const_true, %pair_val0_176, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_176 = "transfer.select"(%const_true, %pair_val_176, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_176 = "transfer.and"(%pair_acc0_175, %pair_sel0_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_176 = "transfer.and"(%pair_acc1_175, %pair_sel1_176) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_176 = "arith.ori"(%pair_any_175, %const_true) : (i1, i1) -> i1
    %pair_mul_177 = "transfer.mul"(%lhsu_v11, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_177 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_177 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_177 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_177 = "arith.xori"(%pair_lhs_neg_177, %pair_rhs_neg_177) : (i1, i1) -> i1
    %pair_sat_177 = "transfer.select"(%pair_res_neg_177, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_177 = "transfer.select"(%pair_ov_177, %pair_sat_177, %pair_mul_177) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_177 = "transfer.xor"(%pair_val_177, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_177 = "transfer.select"(%const_true, %pair_val0_177, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_177 = "transfer.select"(%const_true, %pair_val_177, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_177 = "transfer.and"(%pair_acc0_176, %pair_sel0_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_177 = "transfer.and"(%pair_acc1_176, %pair_sel1_177) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_177 = "arith.ori"(%pair_any_176, %const_true) : (i1, i1) -> i1
    %pair_mul_178 = "transfer.mul"(%lhsu_v11, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_178 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_178 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_178 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_178 = "arith.xori"(%pair_lhs_neg_178, %pair_rhs_neg_178) : (i1, i1) -> i1
    %pair_sat_178 = "transfer.select"(%pair_res_neg_178, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_178 = "transfer.select"(%pair_ov_178, %pair_sat_178, %pair_mul_178) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_178 = "transfer.xor"(%pair_val_178, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_178 = "transfer.select"(%const_true, %pair_val0_178, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_178 = "transfer.select"(%const_true, %pair_val_178, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_178 = "transfer.and"(%pair_acc0_177, %pair_sel0_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_178 = "transfer.and"(%pair_acc1_177, %pair_sel1_178) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_178 = "arith.ori"(%pair_any_177, %const_true) : (i1, i1) -> i1
    %pair_mul_179 = "transfer.mul"(%lhsu_v11, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_179 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_179 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_179 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_179 = "arith.xori"(%pair_lhs_neg_179, %pair_rhs_neg_179) : (i1, i1) -> i1
    %pair_sat_179 = "transfer.select"(%pair_res_neg_179, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_179 = "transfer.select"(%pair_ov_179, %pair_sat_179, %pair_mul_179) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_179 = "transfer.xor"(%pair_val_179, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_179 = "transfer.select"(%const_true, %pair_val0_179, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_179 = "transfer.select"(%const_true, %pair_val_179, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_179 = "transfer.and"(%pair_acc0_178, %pair_sel0_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_179 = "transfer.and"(%pair_acc1_178, %pair_sel1_179) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_179 = "arith.ori"(%pair_any_178, %const_true) : (i1, i1) -> i1
    %pair_mul_180 = "transfer.mul"(%lhsu_v11, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_180 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_180 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_180 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_180 = "arith.xori"(%pair_lhs_neg_180, %pair_rhs_neg_180) : (i1, i1) -> i1
    %pair_sat_180 = "transfer.select"(%pair_res_neg_180, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_180 = "transfer.select"(%pair_ov_180, %pair_sat_180, %pair_mul_180) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_180 = "transfer.xor"(%pair_val_180, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_180 = "transfer.select"(%const_true, %pair_val0_180, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_180 = "transfer.select"(%const_true, %pair_val_180, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_180 = "transfer.and"(%pair_acc0_179, %pair_sel0_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_180 = "transfer.and"(%pair_acc1_179, %pair_sel1_180) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_180 = "arith.ori"(%pair_any_179, %const_true) : (i1, i1) -> i1
    %pair_mul_181 = "transfer.mul"(%lhsu_v11, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_181 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_181 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_181 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_181 = "arith.xori"(%pair_lhs_neg_181, %pair_rhs_neg_181) : (i1, i1) -> i1
    %pair_sat_181 = "transfer.select"(%pair_res_neg_181, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_181 = "transfer.select"(%pair_ov_181, %pair_sat_181, %pair_mul_181) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_181 = "transfer.xor"(%pair_val_181, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_181 = "transfer.select"(%const_true, %pair_val0_181, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_181 = "transfer.select"(%const_true, %pair_val_181, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_181 = "transfer.and"(%pair_acc0_180, %pair_sel0_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_181 = "transfer.and"(%pair_acc1_180, %pair_sel1_181) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_181 = "arith.ori"(%pair_any_180, %const_true) : (i1, i1) -> i1
    %pair_mul_182 = "transfer.mul"(%lhsu_v11, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_182 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_182 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_182 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_182 = "arith.xori"(%pair_lhs_neg_182, %pair_rhs_neg_182) : (i1, i1) -> i1
    %pair_sat_182 = "transfer.select"(%pair_res_neg_182, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_182 = "transfer.select"(%pair_ov_182, %pair_sat_182, %pair_mul_182) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_182 = "transfer.xor"(%pair_val_182, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_182 = "transfer.select"(%const_true, %pair_val0_182, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_182 = "transfer.select"(%const_true, %pair_val_182, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_182 = "transfer.and"(%pair_acc0_181, %pair_sel0_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_182 = "transfer.and"(%pair_acc1_181, %pair_sel1_182) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_182 = "arith.ori"(%pair_any_181, %const_true) : (i1, i1) -> i1
    %pair_mul_183 = "transfer.mul"(%lhsu_v11, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_183 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_183 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_183 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_183 = "arith.xori"(%pair_lhs_neg_183, %pair_rhs_neg_183) : (i1, i1) -> i1
    %pair_sat_183 = "transfer.select"(%pair_res_neg_183, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_183 = "transfer.select"(%pair_ov_183, %pair_sat_183, %pair_mul_183) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_183 = "transfer.xor"(%pair_val_183, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_183 = "transfer.select"(%const_true, %pair_val0_183, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_183 = "transfer.select"(%const_true, %pair_val_183, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_183 = "transfer.and"(%pair_acc0_182, %pair_sel0_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_183 = "transfer.and"(%pair_acc1_182, %pair_sel1_183) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_183 = "arith.ori"(%pair_any_182, %const_true) : (i1, i1) -> i1
    %pair_mul_184 = "transfer.mul"(%lhsu_v11, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_184 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_184 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_184 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_184 = "arith.xori"(%pair_lhs_neg_184, %pair_rhs_neg_184) : (i1, i1) -> i1
    %pair_sat_184 = "transfer.select"(%pair_res_neg_184, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_184 = "transfer.select"(%pair_ov_184, %pair_sat_184, %pair_mul_184) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_184 = "transfer.xor"(%pair_val_184, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_184 = "transfer.select"(%const_true, %pair_val0_184, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_184 = "transfer.select"(%const_true, %pair_val_184, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_184 = "transfer.and"(%pair_acc0_183, %pair_sel0_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_184 = "transfer.and"(%pair_acc1_183, %pair_sel1_184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_184 = "arith.ori"(%pair_any_183, %const_true) : (i1, i1) -> i1
    %pair_mul_185 = "transfer.mul"(%lhsu_v11, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_185 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_185 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_185 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_185 = "arith.xori"(%pair_lhs_neg_185, %pair_rhs_neg_185) : (i1, i1) -> i1
    %pair_sat_185 = "transfer.select"(%pair_res_neg_185, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_185 = "transfer.select"(%pair_ov_185, %pair_sat_185, %pair_mul_185) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_185 = "transfer.xor"(%pair_val_185, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_185 = "transfer.select"(%const_true, %pair_val0_185, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_185 = "transfer.select"(%const_true, %pair_val_185, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_185 = "transfer.and"(%pair_acc0_184, %pair_sel0_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_185 = "transfer.and"(%pair_acc1_184, %pair_sel1_185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_185 = "arith.ori"(%pair_any_184, %const_true) : (i1, i1) -> i1
    %pair_mul_186 = "transfer.mul"(%lhsu_v11, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_186 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_186 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_186 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_186 = "arith.xori"(%pair_lhs_neg_186, %pair_rhs_neg_186) : (i1, i1) -> i1
    %pair_sat_186 = "transfer.select"(%pair_res_neg_186, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_186 = "transfer.select"(%pair_ov_186, %pair_sat_186, %pair_mul_186) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_186 = "transfer.xor"(%pair_val_186, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_186 = "transfer.select"(%const_true, %pair_val0_186, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_186 = "transfer.select"(%const_true, %pair_val_186, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_186 = "transfer.and"(%pair_acc0_185, %pair_sel0_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_186 = "transfer.and"(%pair_acc1_185, %pair_sel1_186) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_186 = "arith.ori"(%pair_any_185, %const_true) : (i1, i1) -> i1
    %pair_mul_187 = "transfer.mul"(%lhsu_v11, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_187 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_187 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_187 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_187 = "arith.xori"(%pair_lhs_neg_187, %pair_rhs_neg_187) : (i1, i1) -> i1
    %pair_sat_187 = "transfer.select"(%pair_res_neg_187, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_187 = "transfer.select"(%pair_ov_187, %pair_sat_187, %pair_mul_187) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_187 = "transfer.xor"(%pair_val_187, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_187 = "transfer.select"(%const_true, %pair_val0_187, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_187 = "transfer.select"(%const_true, %pair_val_187, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_187 = "transfer.and"(%pair_acc0_186, %pair_sel0_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_187 = "transfer.and"(%pair_acc1_186, %pair_sel1_187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_187 = "arith.ori"(%pair_any_186, %const_true) : (i1, i1) -> i1
    %pair_mul_188 = "transfer.mul"(%lhsu_v11, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_188 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_188 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_188 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_188 = "arith.xori"(%pair_lhs_neg_188, %pair_rhs_neg_188) : (i1, i1) -> i1
    %pair_sat_188 = "transfer.select"(%pair_res_neg_188, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_188 = "transfer.select"(%pair_ov_188, %pair_sat_188, %pair_mul_188) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_188 = "transfer.xor"(%pair_val_188, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_188 = "transfer.select"(%const_true, %pair_val0_188, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_188 = "transfer.select"(%const_true, %pair_val_188, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_188 = "transfer.and"(%pair_acc0_187, %pair_sel0_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_188 = "transfer.and"(%pair_acc1_187, %pair_sel1_188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_188 = "arith.ori"(%pair_any_187, %const_true) : (i1, i1) -> i1
    %pair_mul_189 = "transfer.mul"(%lhsu_v11, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_189 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_189 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_189 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_189 = "arith.xori"(%pair_lhs_neg_189, %pair_rhs_neg_189) : (i1, i1) -> i1
    %pair_sat_189 = "transfer.select"(%pair_res_neg_189, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_189 = "transfer.select"(%pair_ov_189, %pair_sat_189, %pair_mul_189) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_189 = "transfer.xor"(%pair_val_189, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_189 = "transfer.select"(%const_true, %pair_val0_189, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_189 = "transfer.select"(%const_true, %pair_val_189, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_189 = "transfer.and"(%pair_acc0_188, %pair_sel0_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_189 = "transfer.and"(%pair_acc1_188, %pair_sel1_189) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_189 = "arith.ori"(%pair_any_188, %const_true) : (i1, i1) -> i1
    %pair_mul_190 = "transfer.mul"(%lhsu_v11, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_190 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_190 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_190 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_190 = "arith.xori"(%pair_lhs_neg_190, %pair_rhs_neg_190) : (i1, i1) -> i1
    %pair_sat_190 = "transfer.select"(%pair_res_neg_190, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_190 = "transfer.select"(%pair_ov_190, %pair_sat_190, %pair_mul_190) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_190 = "transfer.xor"(%pair_val_190, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_190 = "transfer.select"(%const_true, %pair_val0_190, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_190 = "transfer.select"(%const_true, %pair_val_190, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_190 = "transfer.and"(%pair_acc0_189, %pair_sel0_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_190 = "transfer.and"(%pair_acc1_189, %pair_sel1_190) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_190 = "arith.ori"(%pair_any_189, %const_true) : (i1, i1) -> i1
    %pair_mul_191 = "transfer.mul"(%lhsu_v11, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_191 = "transfer.smul_overflow"(%lhsu_v11, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_191 = "transfer.cmp"(%lhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_191 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_191 = "arith.xori"(%pair_lhs_neg_191, %pair_rhs_neg_191) : (i1, i1) -> i1
    %pair_sat_191 = "transfer.select"(%pair_res_neg_191, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_191 = "transfer.select"(%pair_ov_191, %pair_sat_191, %pair_mul_191) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_191 = "transfer.xor"(%pair_val_191, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_191 = "transfer.select"(%const_true, %pair_val0_191, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_191 = "transfer.select"(%const_true, %pair_val_191, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_191 = "transfer.and"(%pair_acc0_190, %pair_sel0_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_191 = "transfer.and"(%pair_acc1_190, %pair_sel1_191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_191 = "arith.ori"(%pair_any_190, %const_true) : (i1, i1) -> i1
    %pair_mul_192 = "transfer.mul"(%lhsu_v12, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_192 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_192 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_192 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_192 = "arith.xori"(%pair_lhs_neg_192, %pair_rhs_neg_192) : (i1, i1) -> i1
    %pair_sat_192 = "transfer.select"(%pair_res_neg_192, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_192 = "transfer.select"(%pair_ov_192, %pair_sat_192, %pair_mul_192) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_192 = "transfer.xor"(%pair_val_192, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_192 = "transfer.select"(%const_true, %pair_val0_192, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_192 = "transfer.select"(%const_true, %pair_val_192, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_192 = "transfer.and"(%pair_acc0_191, %pair_sel0_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_192 = "transfer.and"(%pair_acc1_191, %pair_sel1_192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_192 = "arith.ori"(%pair_any_191, %const_true) : (i1, i1) -> i1
    %pair_mul_193 = "transfer.mul"(%lhsu_v12, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_193 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_193 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_193 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_193 = "arith.xori"(%pair_lhs_neg_193, %pair_rhs_neg_193) : (i1, i1) -> i1
    %pair_sat_193 = "transfer.select"(%pair_res_neg_193, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_193 = "transfer.select"(%pair_ov_193, %pair_sat_193, %pair_mul_193) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_193 = "transfer.xor"(%pair_val_193, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_193 = "transfer.select"(%const_true, %pair_val0_193, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_193 = "transfer.select"(%const_true, %pair_val_193, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_193 = "transfer.and"(%pair_acc0_192, %pair_sel0_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_193 = "transfer.and"(%pair_acc1_192, %pair_sel1_193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_193 = "arith.ori"(%pair_any_192, %const_true) : (i1, i1) -> i1
    %pair_mul_194 = "transfer.mul"(%lhsu_v12, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_194 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_194 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_194 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_194 = "arith.xori"(%pair_lhs_neg_194, %pair_rhs_neg_194) : (i1, i1) -> i1
    %pair_sat_194 = "transfer.select"(%pair_res_neg_194, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_194 = "transfer.select"(%pair_ov_194, %pair_sat_194, %pair_mul_194) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_194 = "transfer.xor"(%pair_val_194, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_194 = "transfer.select"(%const_true, %pair_val0_194, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_194 = "transfer.select"(%const_true, %pair_val_194, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_194 = "transfer.and"(%pair_acc0_193, %pair_sel0_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_194 = "transfer.and"(%pair_acc1_193, %pair_sel1_194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_194 = "arith.ori"(%pair_any_193, %const_true) : (i1, i1) -> i1
    %pair_mul_195 = "transfer.mul"(%lhsu_v12, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_195 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_195 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_195 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_195 = "arith.xori"(%pair_lhs_neg_195, %pair_rhs_neg_195) : (i1, i1) -> i1
    %pair_sat_195 = "transfer.select"(%pair_res_neg_195, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_195 = "transfer.select"(%pair_ov_195, %pair_sat_195, %pair_mul_195) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_195 = "transfer.xor"(%pair_val_195, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_195 = "transfer.select"(%const_true, %pair_val0_195, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_195 = "transfer.select"(%const_true, %pair_val_195, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_195 = "transfer.and"(%pair_acc0_194, %pair_sel0_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_195 = "transfer.and"(%pair_acc1_194, %pair_sel1_195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_195 = "arith.ori"(%pair_any_194, %const_true) : (i1, i1) -> i1
    %pair_mul_196 = "transfer.mul"(%lhsu_v12, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_196 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_196 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_196 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_196 = "arith.xori"(%pair_lhs_neg_196, %pair_rhs_neg_196) : (i1, i1) -> i1
    %pair_sat_196 = "transfer.select"(%pair_res_neg_196, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_196 = "transfer.select"(%pair_ov_196, %pair_sat_196, %pair_mul_196) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_196 = "transfer.xor"(%pair_val_196, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_196 = "transfer.select"(%const_true, %pair_val0_196, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_196 = "transfer.select"(%const_true, %pair_val_196, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_196 = "transfer.and"(%pair_acc0_195, %pair_sel0_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_196 = "transfer.and"(%pair_acc1_195, %pair_sel1_196) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_196 = "arith.ori"(%pair_any_195, %const_true) : (i1, i1) -> i1
    %pair_mul_197 = "transfer.mul"(%lhsu_v12, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_197 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_197 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_197 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_197 = "arith.xori"(%pair_lhs_neg_197, %pair_rhs_neg_197) : (i1, i1) -> i1
    %pair_sat_197 = "transfer.select"(%pair_res_neg_197, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_197 = "transfer.select"(%pair_ov_197, %pair_sat_197, %pair_mul_197) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_197 = "transfer.xor"(%pair_val_197, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_197 = "transfer.select"(%const_true, %pair_val0_197, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_197 = "transfer.select"(%const_true, %pair_val_197, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_197 = "transfer.and"(%pair_acc0_196, %pair_sel0_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_197 = "transfer.and"(%pair_acc1_196, %pair_sel1_197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_197 = "arith.ori"(%pair_any_196, %const_true) : (i1, i1) -> i1
    %pair_mul_198 = "transfer.mul"(%lhsu_v12, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_198 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_198 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_198 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_198 = "arith.xori"(%pair_lhs_neg_198, %pair_rhs_neg_198) : (i1, i1) -> i1
    %pair_sat_198 = "transfer.select"(%pair_res_neg_198, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_198 = "transfer.select"(%pair_ov_198, %pair_sat_198, %pair_mul_198) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_198 = "transfer.xor"(%pair_val_198, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_198 = "transfer.select"(%const_true, %pair_val0_198, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_198 = "transfer.select"(%const_true, %pair_val_198, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_198 = "transfer.and"(%pair_acc0_197, %pair_sel0_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_198 = "transfer.and"(%pair_acc1_197, %pair_sel1_198) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_198 = "arith.ori"(%pair_any_197, %const_true) : (i1, i1) -> i1
    %pair_mul_199 = "transfer.mul"(%lhsu_v12, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_199 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_199 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_199 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_199 = "arith.xori"(%pair_lhs_neg_199, %pair_rhs_neg_199) : (i1, i1) -> i1
    %pair_sat_199 = "transfer.select"(%pair_res_neg_199, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_199 = "transfer.select"(%pair_ov_199, %pair_sat_199, %pair_mul_199) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_199 = "transfer.xor"(%pair_val_199, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_199 = "transfer.select"(%const_true, %pair_val0_199, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_199 = "transfer.select"(%const_true, %pair_val_199, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_199 = "transfer.and"(%pair_acc0_198, %pair_sel0_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_199 = "transfer.and"(%pair_acc1_198, %pair_sel1_199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_199 = "arith.ori"(%pair_any_198, %const_true) : (i1, i1) -> i1
    %pair_mul_200 = "transfer.mul"(%lhsu_v12, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_200 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_200 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_200 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_200 = "arith.xori"(%pair_lhs_neg_200, %pair_rhs_neg_200) : (i1, i1) -> i1
    %pair_sat_200 = "transfer.select"(%pair_res_neg_200, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_200 = "transfer.select"(%pair_ov_200, %pair_sat_200, %pair_mul_200) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_200 = "transfer.xor"(%pair_val_200, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_200 = "transfer.select"(%const_true, %pair_val0_200, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_200 = "transfer.select"(%const_true, %pair_val_200, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_200 = "transfer.and"(%pair_acc0_199, %pair_sel0_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_200 = "transfer.and"(%pair_acc1_199, %pair_sel1_200) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_200 = "arith.ori"(%pair_any_199, %const_true) : (i1, i1) -> i1
    %pair_mul_201 = "transfer.mul"(%lhsu_v12, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_201 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_201 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_201 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_201 = "arith.xori"(%pair_lhs_neg_201, %pair_rhs_neg_201) : (i1, i1) -> i1
    %pair_sat_201 = "transfer.select"(%pair_res_neg_201, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_201 = "transfer.select"(%pair_ov_201, %pair_sat_201, %pair_mul_201) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_201 = "transfer.xor"(%pair_val_201, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_201 = "transfer.select"(%const_true, %pair_val0_201, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_201 = "transfer.select"(%const_true, %pair_val_201, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_201 = "transfer.and"(%pair_acc0_200, %pair_sel0_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_201 = "transfer.and"(%pair_acc1_200, %pair_sel1_201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_201 = "arith.ori"(%pair_any_200, %const_true) : (i1, i1) -> i1
    %pair_mul_202 = "transfer.mul"(%lhsu_v12, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_202 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_202 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_202 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_202 = "arith.xori"(%pair_lhs_neg_202, %pair_rhs_neg_202) : (i1, i1) -> i1
    %pair_sat_202 = "transfer.select"(%pair_res_neg_202, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_202 = "transfer.select"(%pair_ov_202, %pair_sat_202, %pair_mul_202) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_202 = "transfer.xor"(%pair_val_202, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_202 = "transfer.select"(%const_true, %pair_val0_202, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_202 = "transfer.select"(%const_true, %pair_val_202, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_202 = "transfer.and"(%pair_acc0_201, %pair_sel0_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_202 = "transfer.and"(%pair_acc1_201, %pair_sel1_202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_202 = "arith.ori"(%pair_any_201, %const_true) : (i1, i1) -> i1
    %pair_mul_203 = "transfer.mul"(%lhsu_v12, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_203 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_203 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_203 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_203 = "arith.xori"(%pair_lhs_neg_203, %pair_rhs_neg_203) : (i1, i1) -> i1
    %pair_sat_203 = "transfer.select"(%pair_res_neg_203, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_203 = "transfer.select"(%pair_ov_203, %pair_sat_203, %pair_mul_203) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_203 = "transfer.xor"(%pair_val_203, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_203 = "transfer.select"(%const_true, %pair_val0_203, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_203 = "transfer.select"(%const_true, %pair_val_203, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_203 = "transfer.and"(%pair_acc0_202, %pair_sel0_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_203 = "transfer.and"(%pair_acc1_202, %pair_sel1_203) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_203 = "arith.ori"(%pair_any_202, %const_true) : (i1, i1) -> i1
    %pair_mul_204 = "transfer.mul"(%lhsu_v12, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_204 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_204 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_204 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_204 = "arith.xori"(%pair_lhs_neg_204, %pair_rhs_neg_204) : (i1, i1) -> i1
    %pair_sat_204 = "transfer.select"(%pair_res_neg_204, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_204 = "transfer.select"(%pair_ov_204, %pair_sat_204, %pair_mul_204) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_204 = "transfer.xor"(%pair_val_204, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_204 = "transfer.select"(%const_true, %pair_val0_204, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_204 = "transfer.select"(%const_true, %pair_val_204, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_204 = "transfer.and"(%pair_acc0_203, %pair_sel0_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_204 = "transfer.and"(%pair_acc1_203, %pair_sel1_204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_204 = "arith.ori"(%pair_any_203, %const_true) : (i1, i1) -> i1
    %pair_mul_205 = "transfer.mul"(%lhsu_v12, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_205 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_205 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_205 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_205 = "arith.xori"(%pair_lhs_neg_205, %pair_rhs_neg_205) : (i1, i1) -> i1
    %pair_sat_205 = "transfer.select"(%pair_res_neg_205, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_205 = "transfer.select"(%pair_ov_205, %pair_sat_205, %pair_mul_205) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_205 = "transfer.xor"(%pair_val_205, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_205 = "transfer.select"(%const_true, %pair_val0_205, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_205 = "transfer.select"(%const_true, %pair_val_205, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_205 = "transfer.and"(%pair_acc0_204, %pair_sel0_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_205 = "transfer.and"(%pair_acc1_204, %pair_sel1_205) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_205 = "arith.ori"(%pair_any_204, %const_true) : (i1, i1) -> i1
    %pair_mul_206 = "transfer.mul"(%lhsu_v12, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_206 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_206 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_206 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_206 = "arith.xori"(%pair_lhs_neg_206, %pair_rhs_neg_206) : (i1, i1) -> i1
    %pair_sat_206 = "transfer.select"(%pair_res_neg_206, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_206 = "transfer.select"(%pair_ov_206, %pair_sat_206, %pair_mul_206) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_206 = "transfer.xor"(%pair_val_206, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_206 = "transfer.select"(%const_true, %pair_val0_206, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_206 = "transfer.select"(%const_true, %pair_val_206, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_206 = "transfer.and"(%pair_acc0_205, %pair_sel0_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_206 = "transfer.and"(%pair_acc1_205, %pair_sel1_206) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_206 = "arith.ori"(%pair_any_205, %const_true) : (i1, i1) -> i1
    %pair_mul_207 = "transfer.mul"(%lhsu_v12, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_207 = "transfer.smul_overflow"(%lhsu_v12, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_207 = "transfer.cmp"(%lhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_207 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_207 = "arith.xori"(%pair_lhs_neg_207, %pair_rhs_neg_207) : (i1, i1) -> i1
    %pair_sat_207 = "transfer.select"(%pair_res_neg_207, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_207 = "transfer.select"(%pair_ov_207, %pair_sat_207, %pair_mul_207) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_207 = "transfer.xor"(%pair_val_207, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_207 = "transfer.select"(%const_true, %pair_val0_207, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_207 = "transfer.select"(%const_true, %pair_val_207, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_207 = "transfer.and"(%pair_acc0_206, %pair_sel0_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_207 = "transfer.and"(%pair_acc1_206, %pair_sel1_207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_207 = "arith.ori"(%pair_any_206, %const_true) : (i1, i1) -> i1
    %pair_mul_208 = "transfer.mul"(%lhsu_v13, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_208 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_208 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_208 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_208 = "arith.xori"(%pair_lhs_neg_208, %pair_rhs_neg_208) : (i1, i1) -> i1
    %pair_sat_208 = "transfer.select"(%pair_res_neg_208, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_208 = "transfer.select"(%pair_ov_208, %pair_sat_208, %pair_mul_208) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_208 = "transfer.xor"(%pair_val_208, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_208 = "transfer.select"(%const_true, %pair_val0_208, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_208 = "transfer.select"(%const_true, %pair_val_208, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_208 = "transfer.and"(%pair_acc0_207, %pair_sel0_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_208 = "transfer.and"(%pair_acc1_207, %pair_sel1_208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_208 = "arith.ori"(%pair_any_207, %const_true) : (i1, i1) -> i1
    %pair_mul_209 = "transfer.mul"(%lhsu_v13, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_209 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_209 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_209 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_209 = "arith.xori"(%pair_lhs_neg_209, %pair_rhs_neg_209) : (i1, i1) -> i1
    %pair_sat_209 = "transfer.select"(%pair_res_neg_209, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_209 = "transfer.select"(%pair_ov_209, %pair_sat_209, %pair_mul_209) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_209 = "transfer.xor"(%pair_val_209, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_209 = "transfer.select"(%const_true, %pair_val0_209, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_209 = "transfer.select"(%const_true, %pair_val_209, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_209 = "transfer.and"(%pair_acc0_208, %pair_sel0_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_209 = "transfer.and"(%pair_acc1_208, %pair_sel1_209) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_209 = "arith.ori"(%pair_any_208, %const_true) : (i1, i1) -> i1
    %pair_mul_210 = "transfer.mul"(%lhsu_v13, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_210 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_210 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_210 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_210 = "arith.xori"(%pair_lhs_neg_210, %pair_rhs_neg_210) : (i1, i1) -> i1
    %pair_sat_210 = "transfer.select"(%pair_res_neg_210, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_210 = "transfer.select"(%pair_ov_210, %pair_sat_210, %pair_mul_210) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_210 = "transfer.xor"(%pair_val_210, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_210 = "transfer.select"(%const_true, %pair_val0_210, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_210 = "transfer.select"(%const_true, %pair_val_210, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_210 = "transfer.and"(%pair_acc0_209, %pair_sel0_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_210 = "transfer.and"(%pair_acc1_209, %pair_sel1_210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_210 = "arith.ori"(%pair_any_209, %const_true) : (i1, i1) -> i1
    %pair_mul_211 = "transfer.mul"(%lhsu_v13, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_211 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_211 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_211 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_211 = "arith.xori"(%pair_lhs_neg_211, %pair_rhs_neg_211) : (i1, i1) -> i1
    %pair_sat_211 = "transfer.select"(%pair_res_neg_211, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_211 = "transfer.select"(%pair_ov_211, %pair_sat_211, %pair_mul_211) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_211 = "transfer.xor"(%pair_val_211, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_211 = "transfer.select"(%const_true, %pair_val0_211, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_211 = "transfer.select"(%const_true, %pair_val_211, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_211 = "transfer.and"(%pair_acc0_210, %pair_sel0_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_211 = "transfer.and"(%pair_acc1_210, %pair_sel1_211) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_211 = "arith.ori"(%pair_any_210, %const_true) : (i1, i1) -> i1
    %pair_mul_212 = "transfer.mul"(%lhsu_v13, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_212 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_212 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_212 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_212 = "arith.xori"(%pair_lhs_neg_212, %pair_rhs_neg_212) : (i1, i1) -> i1
    %pair_sat_212 = "transfer.select"(%pair_res_neg_212, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_212 = "transfer.select"(%pair_ov_212, %pair_sat_212, %pair_mul_212) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_212 = "transfer.xor"(%pair_val_212, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_212 = "transfer.select"(%const_true, %pair_val0_212, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_212 = "transfer.select"(%const_true, %pair_val_212, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_212 = "transfer.and"(%pair_acc0_211, %pair_sel0_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_212 = "transfer.and"(%pair_acc1_211, %pair_sel1_212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_212 = "arith.ori"(%pair_any_211, %const_true) : (i1, i1) -> i1
    %pair_mul_213 = "transfer.mul"(%lhsu_v13, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_213 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_213 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_213 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_213 = "arith.xori"(%pair_lhs_neg_213, %pair_rhs_neg_213) : (i1, i1) -> i1
    %pair_sat_213 = "transfer.select"(%pair_res_neg_213, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_213 = "transfer.select"(%pair_ov_213, %pair_sat_213, %pair_mul_213) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_213 = "transfer.xor"(%pair_val_213, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_213 = "transfer.select"(%const_true, %pair_val0_213, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_213 = "transfer.select"(%const_true, %pair_val_213, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_213 = "transfer.and"(%pair_acc0_212, %pair_sel0_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_213 = "transfer.and"(%pair_acc1_212, %pair_sel1_213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_213 = "arith.ori"(%pair_any_212, %const_true) : (i1, i1) -> i1
    %pair_mul_214 = "transfer.mul"(%lhsu_v13, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_214 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_214 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_214 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_214 = "arith.xori"(%pair_lhs_neg_214, %pair_rhs_neg_214) : (i1, i1) -> i1
    %pair_sat_214 = "transfer.select"(%pair_res_neg_214, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_214 = "transfer.select"(%pair_ov_214, %pair_sat_214, %pair_mul_214) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_214 = "transfer.xor"(%pair_val_214, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_214 = "transfer.select"(%const_true, %pair_val0_214, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_214 = "transfer.select"(%const_true, %pair_val_214, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_214 = "transfer.and"(%pair_acc0_213, %pair_sel0_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_214 = "transfer.and"(%pair_acc1_213, %pair_sel1_214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_214 = "arith.ori"(%pair_any_213, %const_true) : (i1, i1) -> i1
    %pair_mul_215 = "transfer.mul"(%lhsu_v13, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_215 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_215 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_215 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_215 = "arith.xori"(%pair_lhs_neg_215, %pair_rhs_neg_215) : (i1, i1) -> i1
    %pair_sat_215 = "transfer.select"(%pair_res_neg_215, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_215 = "transfer.select"(%pair_ov_215, %pair_sat_215, %pair_mul_215) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_215 = "transfer.xor"(%pair_val_215, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_215 = "transfer.select"(%const_true, %pair_val0_215, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_215 = "transfer.select"(%const_true, %pair_val_215, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_215 = "transfer.and"(%pair_acc0_214, %pair_sel0_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_215 = "transfer.and"(%pair_acc1_214, %pair_sel1_215) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_215 = "arith.ori"(%pair_any_214, %const_true) : (i1, i1) -> i1
    %pair_mul_216 = "transfer.mul"(%lhsu_v13, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_216 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_216 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_216 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_216 = "arith.xori"(%pair_lhs_neg_216, %pair_rhs_neg_216) : (i1, i1) -> i1
    %pair_sat_216 = "transfer.select"(%pair_res_neg_216, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_216 = "transfer.select"(%pair_ov_216, %pair_sat_216, %pair_mul_216) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_216 = "transfer.xor"(%pair_val_216, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_216 = "transfer.select"(%const_true, %pair_val0_216, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_216 = "transfer.select"(%const_true, %pair_val_216, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_216 = "transfer.and"(%pair_acc0_215, %pair_sel0_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_216 = "transfer.and"(%pair_acc1_215, %pair_sel1_216) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_216 = "arith.ori"(%pair_any_215, %const_true) : (i1, i1) -> i1
    %pair_mul_217 = "transfer.mul"(%lhsu_v13, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_217 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_217 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_217 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_217 = "arith.xori"(%pair_lhs_neg_217, %pair_rhs_neg_217) : (i1, i1) -> i1
    %pair_sat_217 = "transfer.select"(%pair_res_neg_217, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_217 = "transfer.select"(%pair_ov_217, %pair_sat_217, %pair_mul_217) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_217 = "transfer.xor"(%pair_val_217, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_217 = "transfer.select"(%const_true, %pair_val0_217, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_217 = "transfer.select"(%const_true, %pair_val_217, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_217 = "transfer.and"(%pair_acc0_216, %pair_sel0_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_217 = "transfer.and"(%pair_acc1_216, %pair_sel1_217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_217 = "arith.ori"(%pair_any_216, %const_true) : (i1, i1) -> i1
    %pair_mul_218 = "transfer.mul"(%lhsu_v13, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_218 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_218 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_218 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_218 = "arith.xori"(%pair_lhs_neg_218, %pair_rhs_neg_218) : (i1, i1) -> i1
    %pair_sat_218 = "transfer.select"(%pair_res_neg_218, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_218 = "transfer.select"(%pair_ov_218, %pair_sat_218, %pair_mul_218) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_218 = "transfer.xor"(%pair_val_218, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_218 = "transfer.select"(%const_true, %pair_val0_218, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_218 = "transfer.select"(%const_true, %pair_val_218, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_218 = "transfer.and"(%pair_acc0_217, %pair_sel0_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_218 = "transfer.and"(%pair_acc1_217, %pair_sel1_218) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_218 = "arith.ori"(%pair_any_217, %const_true) : (i1, i1) -> i1
    %pair_mul_219 = "transfer.mul"(%lhsu_v13, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_219 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_219 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_219 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_219 = "arith.xori"(%pair_lhs_neg_219, %pair_rhs_neg_219) : (i1, i1) -> i1
    %pair_sat_219 = "transfer.select"(%pair_res_neg_219, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_219 = "transfer.select"(%pair_ov_219, %pair_sat_219, %pair_mul_219) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_219 = "transfer.xor"(%pair_val_219, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_219 = "transfer.select"(%const_true, %pair_val0_219, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_219 = "transfer.select"(%const_true, %pair_val_219, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_219 = "transfer.and"(%pair_acc0_218, %pair_sel0_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_219 = "transfer.and"(%pair_acc1_218, %pair_sel1_219) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_219 = "arith.ori"(%pair_any_218, %const_true) : (i1, i1) -> i1
    %pair_mul_220 = "transfer.mul"(%lhsu_v13, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_220 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_220 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_220 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_220 = "arith.xori"(%pair_lhs_neg_220, %pair_rhs_neg_220) : (i1, i1) -> i1
    %pair_sat_220 = "transfer.select"(%pair_res_neg_220, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_220 = "transfer.select"(%pair_ov_220, %pair_sat_220, %pair_mul_220) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_220 = "transfer.xor"(%pair_val_220, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_220 = "transfer.select"(%const_true, %pair_val0_220, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_220 = "transfer.select"(%const_true, %pair_val_220, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_220 = "transfer.and"(%pair_acc0_219, %pair_sel0_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_220 = "transfer.and"(%pair_acc1_219, %pair_sel1_220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_220 = "arith.ori"(%pair_any_219, %const_true) : (i1, i1) -> i1
    %pair_mul_221 = "transfer.mul"(%lhsu_v13, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_221 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_221 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_221 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_221 = "arith.xori"(%pair_lhs_neg_221, %pair_rhs_neg_221) : (i1, i1) -> i1
    %pair_sat_221 = "transfer.select"(%pair_res_neg_221, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_221 = "transfer.select"(%pair_ov_221, %pair_sat_221, %pair_mul_221) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_221 = "transfer.xor"(%pair_val_221, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_221 = "transfer.select"(%const_true, %pair_val0_221, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_221 = "transfer.select"(%const_true, %pair_val_221, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_221 = "transfer.and"(%pair_acc0_220, %pair_sel0_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_221 = "transfer.and"(%pair_acc1_220, %pair_sel1_221) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_221 = "arith.ori"(%pair_any_220, %const_true) : (i1, i1) -> i1
    %pair_mul_222 = "transfer.mul"(%lhsu_v13, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_222 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_222 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_222 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_222 = "arith.xori"(%pair_lhs_neg_222, %pair_rhs_neg_222) : (i1, i1) -> i1
    %pair_sat_222 = "transfer.select"(%pair_res_neg_222, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_222 = "transfer.select"(%pair_ov_222, %pair_sat_222, %pair_mul_222) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_222 = "transfer.xor"(%pair_val_222, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_222 = "transfer.select"(%const_true, %pair_val0_222, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_222 = "transfer.select"(%const_true, %pair_val_222, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_222 = "transfer.and"(%pair_acc0_221, %pair_sel0_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_222 = "transfer.and"(%pair_acc1_221, %pair_sel1_222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_222 = "arith.ori"(%pair_any_221, %const_true) : (i1, i1) -> i1
    %pair_mul_223 = "transfer.mul"(%lhsu_v13, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_223 = "transfer.smul_overflow"(%lhsu_v13, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_223 = "transfer.cmp"(%lhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_223 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_223 = "arith.xori"(%pair_lhs_neg_223, %pair_rhs_neg_223) : (i1, i1) -> i1
    %pair_sat_223 = "transfer.select"(%pair_res_neg_223, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_223 = "transfer.select"(%pair_ov_223, %pair_sat_223, %pair_mul_223) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_223 = "transfer.xor"(%pair_val_223, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_223 = "transfer.select"(%const_true, %pair_val0_223, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_223 = "transfer.select"(%const_true, %pair_val_223, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_223 = "transfer.and"(%pair_acc0_222, %pair_sel0_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_223 = "transfer.and"(%pair_acc1_222, %pair_sel1_223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_223 = "arith.ori"(%pair_any_222, %const_true) : (i1, i1) -> i1
    %pair_mul_224 = "transfer.mul"(%lhsu_v14, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_224 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_224 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_224 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_224 = "arith.xori"(%pair_lhs_neg_224, %pair_rhs_neg_224) : (i1, i1) -> i1
    %pair_sat_224 = "transfer.select"(%pair_res_neg_224, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_224 = "transfer.select"(%pair_ov_224, %pair_sat_224, %pair_mul_224) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_224 = "transfer.xor"(%pair_val_224, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_224 = "transfer.select"(%const_true, %pair_val0_224, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_224 = "transfer.select"(%const_true, %pair_val_224, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_224 = "transfer.and"(%pair_acc0_223, %pair_sel0_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_224 = "transfer.and"(%pair_acc1_223, %pair_sel1_224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_224 = "arith.ori"(%pair_any_223, %const_true) : (i1, i1) -> i1
    %pair_mul_225 = "transfer.mul"(%lhsu_v14, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_225 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_225 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_225 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_225 = "arith.xori"(%pair_lhs_neg_225, %pair_rhs_neg_225) : (i1, i1) -> i1
    %pair_sat_225 = "transfer.select"(%pair_res_neg_225, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_225 = "transfer.select"(%pair_ov_225, %pair_sat_225, %pair_mul_225) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_225 = "transfer.xor"(%pair_val_225, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_225 = "transfer.select"(%const_true, %pair_val0_225, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_225 = "transfer.select"(%const_true, %pair_val_225, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_225 = "transfer.and"(%pair_acc0_224, %pair_sel0_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_225 = "transfer.and"(%pair_acc1_224, %pair_sel1_225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_225 = "arith.ori"(%pair_any_224, %const_true) : (i1, i1) -> i1
    %pair_mul_226 = "transfer.mul"(%lhsu_v14, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_226 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_226 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_226 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_226 = "arith.xori"(%pair_lhs_neg_226, %pair_rhs_neg_226) : (i1, i1) -> i1
    %pair_sat_226 = "transfer.select"(%pair_res_neg_226, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_226 = "transfer.select"(%pair_ov_226, %pair_sat_226, %pair_mul_226) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_226 = "transfer.xor"(%pair_val_226, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_226 = "transfer.select"(%const_true, %pair_val0_226, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_226 = "transfer.select"(%const_true, %pair_val_226, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_226 = "transfer.and"(%pair_acc0_225, %pair_sel0_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_226 = "transfer.and"(%pair_acc1_225, %pair_sel1_226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_226 = "arith.ori"(%pair_any_225, %const_true) : (i1, i1) -> i1
    %pair_mul_227 = "transfer.mul"(%lhsu_v14, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_227 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_227 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_227 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_227 = "arith.xori"(%pair_lhs_neg_227, %pair_rhs_neg_227) : (i1, i1) -> i1
    %pair_sat_227 = "transfer.select"(%pair_res_neg_227, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_227 = "transfer.select"(%pair_ov_227, %pair_sat_227, %pair_mul_227) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_227 = "transfer.xor"(%pair_val_227, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_227 = "transfer.select"(%const_true, %pair_val0_227, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_227 = "transfer.select"(%const_true, %pair_val_227, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_227 = "transfer.and"(%pair_acc0_226, %pair_sel0_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_227 = "transfer.and"(%pair_acc1_226, %pair_sel1_227) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_227 = "arith.ori"(%pair_any_226, %const_true) : (i1, i1) -> i1
    %pair_mul_228 = "transfer.mul"(%lhsu_v14, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_228 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_228 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_228 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_228 = "arith.xori"(%pair_lhs_neg_228, %pair_rhs_neg_228) : (i1, i1) -> i1
    %pair_sat_228 = "transfer.select"(%pair_res_neg_228, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_228 = "transfer.select"(%pair_ov_228, %pair_sat_228, %pair_mul_228) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_228 = "transfer.xor"(%pair_val_228, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_228 = "transfer.select"(%const_true, %pair_val0_228, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_228 = "transfer.select"(%const_true, %pair_val_228, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_228 = "transfer.and"(%pair_acc0_227, %pair_sel0_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_228 = "transfer.and"(%pair_acc1_227, %pair_sel1_228) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_228 = "arith.ori"(%pair_any_227, %const_true) : (i1, i1) -> i1
    %pair_mul_229 = "transfer.mul"(%lhsu_v14, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_229 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_229 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_229 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_229 = "arith.xori"(%pair_lhs_neg_229, %pair_rhs_neg_229) : (i1, i1) -> i1
    %pair_sat_229 = "transfer.select"(%pair_res_neg_229, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_229 = "transfer.select"(%pair_ov_229, %pair_sat_229, %pair_mul_229) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_229 = "transfer.xor"(%pair_val_229, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_229 = "transfer.select"(%const_true, %pair_val0_229, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_229 = "transfer.select"(%const_true, %pair_val_229, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_229 = "transfer.and"(%pair_acc0_228, %pair_sel0_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_229 = "transfer.and"(%pair_acc1_228, %pair_sel1_229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_229 = "arith.ori"(%pair_any_228, %const_true) : (i1, i1) -> i1
    %pair_mul_230 = "transfer.mul"(%lhsu_v14, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_230 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_230 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_230 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_230 = "arith.xori"(%pair_lhs_neg_230, %pair_rhs_neg_230) : (i1, i1) -> i1
    %pair_sat_230 = "transfer.select"(%pair_res_neg_230, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_230 = "transfer.select"(%pair_ov_230, %pair_sat_230, %pair_mul_230) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_230 = "transfer.xor"(%pair_val_230, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_230 = "transfer.select"(%const_true, %pair_val0_230, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_230 = "transfer.select"(%const_true, %pair_val_230, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_230 = "transfer.and"(%pair_acc0_229, %pair_sel0_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_230 = "transfer.and"(%pair_acc1_229, %pair_sel1_230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_230 = "arith.ori"(%pair_any_229, %const_true) : (i1, i1) -> i1
    %pair_mul_231 = "transfer.mul"(%lhsu_v14, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_231 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_231 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_231 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_231 = "arith.xori"(%pair_lhs_neg_231, %pair_rhs_neg_231) : (i1, i1) -> i1
    %pair_sat_231 = "transfer.select"(%pair_res_neg_231, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_231 = "transfer.select"(%pair_ov_231, %pair_sat_231, %pair_mul_231) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_231 = "transfer.xor"(%pair_val_231, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_231 = "transfer.select"(%const_true, %pair_val0_231, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_231 = "transfer.select"(%const_true, %pair_val_231, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_231 = "transfer.and"(%pair_acc0_230, %pair_sel0_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_231 = "transfer.and"(%pair_acc1_230, %pair_sel1_231) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_231 = "arith.ori"(%pair_any_230, %const_true) : (i1, i1) -> i1
    %pair_mul_232 = "transfer.mul"(%lhsu_v14, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_232 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_232 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_232 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_232 = "arith.xori"(%pair_lhs_neg_232, %pair_rhs_neg_232) : (i1, i1) -> i1
    %pair_sat_232 = "transfer.select"(%pair_res_neg_232, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_232 = "transfer.select"(%pair_ov_232, %pair_sat_232, %pair_mul_232) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_232 = "transfer.xor"(%pair_val_232, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_232 = "transfer.select"(%const_true, %pair_val0_232, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_232 = "transfer.select"(%const_true, %pair_val_232, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_232 = "transfer.and"(%pair_acc0_231, %pair_sel0_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_232 = "transfer.and"(%pair_acc1_231, %pair_sel1_232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_232 = "arith.ori"(%pair_any_231, %const_true) : (i1, i1) -> i1
    %pair_mul_233 = "transfer.mul"(%lhsu_v14, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_233 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_233 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_233 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_233 = "arith.xori"(%pair_lhs_neg_233, %pair_rhs_neg_233) : (i1, i1) -> i1
    %pair_sat_233 = "transfer.select"(%pair_res_neg_233, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_233 = "transfer.select"(%pair_ov_233, %pair_sat_233, %pair_mul_233) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_233 = "transfer.xor"(%pair_val_233, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_233 = "transfer.select"(%const_true, %pair_val0_233, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_233 = "transfer.select"(%const_true, %pair_val_233, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_233 = "transfer.and"(%pair_acc0_232, %pair_sel0_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_233 = "transfer.and"(%pair_acc1_232, %pair_sel1_233) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_233 = "arith.ori"(%pair_any_232, %const_true) : (i1, i1) -> i1
    %pair_mul_234 = "transfer.mul"(%lhsu_v14, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_234 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_234 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_234 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_234 = "arith.xori"(%pair_lhs_neg_234, %pair_rhs_neg_234) : (i1, i1) -> i1
    %pair_sat_234 = "transfer.select"(%pair_res_neg_234, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_234 = "transfer.select"(%pair_ov_234, %pair_sat_234, %pair_mul_234) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_234 = "transfer.xor"(%pair_val_234, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_234 = "transfer.select"(%const_true, %pair_val0_234, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_234 = "transfer.select"(%const_true, %pair_val_234, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_234 = "transfer.and"(%pair_acc0_233, %pair_sel0_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_234 = "transfer.and"(%pair_acc1_233, %pair_sel1_234) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_234 = "arith.ori"(%pair_any_233, %const_true) : (i1, i1) -> i1
    %pair_mul_235 = "transfer.mul"(%lhsu_v14, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_235 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_235 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_235 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_235 = "arith.xori"(%pair_lhs_neg_235, %pair_rhs_neg_235) : (i1, i1) -> i1
    %pair_sat_235 = "transfer.select"(%pair_res_neg_235, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_235 = "transfer.select"(%pair_ov_235, %pair_sat_235, %pair_mul_235) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_235 = "transfer.xor"(%pair_val_235, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_235 = "transfer.select"(%const_true, %pair_val0_235, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_235 = "transfer.select"(%const_true, %pair_val_235, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_235 = "transfer.and"(%pair_acc0_234, %pair_sel0_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_235 = "transfer.and"(%pair_acc1_234, %pair_sel1_235) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_235 = "arith.ori"(%pair_any_234, %const_true) : (i1, i1) -> i1
    %pair_mul_236 = "transfer.mul"(%lhsu_v14, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_236 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_236 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_236 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_236 = "arith.xori"(%pair_lhs_neg_236, %pair_rhs_neg_236) : (i1, i1) -> i1
    %pair_sat_236 = "transfer.select"(%pair_res_neg_236, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_236 = "transfer.select"(%pair_ov_236, %pair_sat_236, %pair_mul_236) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_236 = "transfer.xor"(%pair_val_236, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_236 = "transfer.select"(%const_true, %pair_val0_236, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_236 = "transfer.select"(%const_true, %pair_val_236, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_236 = "transfer.and"(%pair_acc0_235, %pair_sel0_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_236 = "transfer.and"(%pair_acc1_235, %pair_sel1_236) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_236 = "arith.ori"(%pair_any_235, %const_true) : (i1, i1) -> i1
    %pair_mul_237 = "transfer.mul"(%lhsu_v14, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_237 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_237 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_237 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_237 = "arith.xori"(%pair_lhs_neg_237, %pair_rhs_neg_237) : (i1, i1) -> i1
    %pair_sat_237 = "transfer.select"(%pair_res_neg_237, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_237 = "transfer.select"(%pair_ov_237, %pair_sat_237, %pair_mul_237) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_237 = "transfer.xor"(%pair_val_237, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_237 = "transfer.select"(%const_true, %pair_val0_237, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_237 = "transfer.select"(%const_true, %pair_val_237, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_237 = "transfer.and"(%pair_acc0_236, %pair_sel0_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_237 = "transfer.and"(%pair_acc1_236, %pair_sel1_237) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_237 = "arith.ori"(%pair_any_236, %const_true) : (i1, i1) -> i1
    %pair_mul_238 = "transfer.mul"(%lhsu_v14, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_238 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_238 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_238 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_238 = "arith.xori"(%pair_lhs_neg_238, %pair_rhs_neg_238) : (i1, i1) -> i1
    %pair_sat_238 = "transfer.select"(%pair_res_neg_238, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_238 = "transfer.select"(%pair_ov_238, %pair_sat_238, %pair_mul_238) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_238 = "transfer.xor"(%pair_val_238, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_238 = "transfer.select"(%const_true, %pair_val0_238, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_238 = "transfer.select"(%const_true, %pair_val_238, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_238 = "transfer.and"(%pair_acc0_237, %pair_sel0_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_238 = "transfer.and"(%pair_acc1_237, %pair_sel1_238) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_238 = "arith.ori"(%pair_any_237, %const_true) : (i1, i1) -> i1
    %pair_mul_239 = "transfer.mul"(%lhsu_v14, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_239 = "transfer.smul_overflow"(%lhsu_v14, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_239 = "transfer.cmp"(%lhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_239 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_239 = "arith.xori"(%pair_lhs_neg_239, %pair_rhs_neg_239) : (i1, i1) -> i1
    %pair_sat_239 = "transfer.select"(%pair_res_neg_239, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_239 = "transfer.select"(%pair_ov_239, %pair_sat_239, %pair_mul_239) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_239 = "transfer.xor"(%pair_val_239, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_239 = "transfer.select"(%const_true, %pair_val0_239, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_239 = "transfer.select"(%const_true, %pair_val_239, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_239 = "transfer.and"(%pair_acc0_238, %pair_sel0_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_239 = "transfer.and"(%pair_acc1_238, %pair_sel1_239) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_239 = "arith.ori"(%pair_any_238, %const_true) : (i1, i1) -> i1
    %pair_mul_240 = "transfer.mul"(%lhsu_v15, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_240 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v0) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_240 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_240 = "transfer.cmp"(%rhsu_v0, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_240 = "arith.xori"(%pair_lhs_neg_240, %pair_rhs_neg_240) : (i1, i1) -> i1
    %pair_sat_240 = "transfer.select"(%pair_res_neg_240, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_240 = "transfer.select"(%pair_ov_240, %pair_sat_240, %pair_mul_240) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_240 = "transfer.xor"(%pair_val_240, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_240 = "transfer.select"(%const_true, %pair_val0_240, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_240 = "transfer.select"(%const_true, %pair_val_240, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_240 = "transfer.and"(%pair_acc0_239, %pair_sel0_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_240 = "transfer.and"(%pair_acc1_239, %pair_sel1_240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_240 = "arith.ori"(%pair_any_239, %const_true) : (i1, i1) -> i1
    %pair_mul_241 = "transfer.mul"(%lhsu_v15, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_241 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v1) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_241 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_241 = "transfer.cmp"(%rhsu_v1, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_241 = "arith.xori"(%pair_lhs_neg_241, %pair_rhs_neg_241) : (i1, i1) -> i1
    %pair_sat_241 = "transfer.select"(%pair_res_neg_241, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_241 = "transfer.select"(%pair_ov_241, %pair_sat_241, %pair_mul_241) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_241 = "transfer.xor"(%pair_val_241, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_241 = "transfer.select"(%const_true, %pair_val0_241, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_241 = "transfer.select"(%const_true, %pair_val_241, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_241 = "transfer.and"(%pair_acc0_240, %pair_sel0_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_241 = "transfer.and"(%pair_acc1_240, %pair_sel1_241) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_241 = "arith.ori"(%pair_any_240, %const_true) : (i1, i1) -> i1
    %pair_mul_242 = "transfer.mul"(%lhsu_v15, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_242 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v2) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_242 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_242 = "transfer.cmp"(%rhsu_v2, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_242 = "arith.xori"(%pair_lhs_neg_242, %pair_rhs_neg_242) : (i1, i1) -> i1
    %pair_sat_242 = "transfer.select"(%pair_res_neg_242, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_242 = "transfer.select"(%pair_ov_242, %pair_sat_242, %pair_mul_242) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_242 = "transfer.xor"(%pair_val_242, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_242 = "transfer.select"(%const_true, %pair_val0_242, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_242 = "transfer.select"(%const_true, %pair_val_242, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_242 = "transfer.and"(%pair_acc0_241, %pair_sel0_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_242 = "transfer.and"(%pair_acc1_241, %pair_sel1_242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_242 = "arith.ori"(%pair_any_241, %const_true) : (i1, i1) -> i1
    %pair_mul_243 = "transfer.mul"(%lhsu_v15, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_243 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v3) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_243 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_243 = "transfer.cmp"(%rhsu_v3, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_243 = "arith.xori"(%pair_lhs_neg_243, %pair_rhs_neg_243) : (i1, i1) -> i1
    %pair_sat_243 = "transfer.select"(%pair_res_neg_243, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_243 = "transfer.select"(%pair_ov_243, %pair_sat_243, %pair_mul_243) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_243 = "transfer.xor"(%pair_val_243, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_243 = "transfer.select"(%const_true, %pair_val0_243, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_243 = "transfer.select"(%const_true, %pair_val_243, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_243 = "transfer.and"(%pair_acc0_242, %pair_sel0_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_243 = "transfer.and"(%pair_acc1_242, %pair_sel1_243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_243 = "arith.ori"(%pair_any_242, %const_true) : (i1, i1) -> i1
    %pair_mul_244 = "transfer.mul"(%lhsu_v15, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_244 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v4) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_244 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_244 = "transfer.cmp"(%rhsu_v4, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_244 = "arith.xori"(%pair_lhs_neg_244, %pair_rhs_neg_244) : (i1, i1) -> i1
    %pair_sat_244 = "transfer.select"(%pair_res_neg_244, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_244 = "transfer.select"(%pair_ov_244, %pair_sat_244, %pair_mul_244) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_244 = "transfer.xor"(%pair_val_244, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_244 = "transfer.select"(%const_true, %pair_val0_244, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_244 = "transfer.select"(%const_true, %pair_val_244, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_244 = "transfer.and"(%pair_acc0_243, %pair_sel0_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_244 = "transfer.and"(%pair_acc1_243, %pair_sel1_244) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_244 = "arith.ori"(%pair_any_243, %const_true) : (i1, i1) -> i1
    %pair_mul_245 = "transfer.mul"(%lhsu_v15, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_245 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v5) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_245 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_245 = "transfer.cmp"(%rhsu_v5, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_245 = "arith.xori"(%pair_lhs_neg_245, %pair_rhs_neg_245) : (i1, i1) -> i1
    %pair_sat_245 = "transfer.select"(%pair_res_neg_245, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_245 = "transfer.select"(%pair_ov_245, %pair_sat_245, %pair_mul_245) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_245 = "transfer.xor"(%pair_val_245, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_245 = "transfer.select"(%const_true, %pair_val0_245, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_245 = "transfer.select"(%const_true, %pair_val_245, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_245 = "transfer.and"(%pair_acc0_244, %pair_sel0_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_245 = "transfer.and"(%pair_acc1_244, %pair_sel1_245) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_245 = "arith.ori"(%pair_any_244, %const_true) : (i1, i1) -> i1
    %pair_mul_246 = "transfer.mul"(%lhsu_v15, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_246 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v6) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_246 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_246 = "transfer.cmp"(%rhsu_v6, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_246 = "arith.xori"(%pair_lhs_neg_246, %pair_rhs_neg_246) : (i1, i1) -> i1
    %pair_sat_246 = "transfer.select"(%pair_res_neg_246, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_246 = "transfer.select"(%pair_ov_246, %pair_sat_246, %pair_mul_246) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_246 = "transfer.xor"(%pair_val_246, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_246 = "transfer.select"(%const_true, %pair_val0_246, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_246 = "transfer.select"(%const_true, %pair_val_246, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_246 = "transfer.and"(%pair_acc0_245, %pair_sel0_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_246 = "transfer.and"(%pair_acc1_245, %pair_sel1_246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_246 = "arith.ori"(%pair_any_245, %const_true) : (i1, i1) -> i1
    %pair_mul_247 = "transfer.mul"(%lhsu_v15, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_247 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v7) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_247 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_247 = "transfer.cmp"(%rhsu_v7, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_247 = "arith.xori"(%pair_lhs_neg_247, %pair_rhs_neg_247) : (i1, i1) -> i1
    %pair_sat_247 = "transfer.select"(%pair_res_neg_247, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_247 = "transfer.select"(%pair_ov_247, %pair_sat_247, %pair_mul_247) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_247 = "transfer.xor"(%pair_val_247, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_247 = "transfer.select"(%const_true, %pair_val0_247, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_247 = "transfer.select"(%const_true, %pair_val_247, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_247 = "transfer.and"(%pair_acc0_246, %pair_sel0_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_247 = "transfer.and"(%pair_acc1_246, %pair_sel1_247) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_247 = "arith.ori"(%pair_any_246, %const_true) : (i1, i1) -> i1
    %pair_mul_248 = "transfer.mul"(%lhsu_v15, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_248 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v8) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_248 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_248 = "transfer.cmp"(%rhsu_v8, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_248 = "arith.xori"(%pair_lhs_neg_248, %pair_rhs_neg_248) : (i1, i1) -> i1
    %pair_sat_248 = "transfer.select"(%pair_res_neg_248, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_248 = "transfer.select"(%pair_ov_248, %pair_sat_248, %pair_mul_248) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_248 = "transfer.xor"(%pair_val_248, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_248 = "transfer.select"(%const_true, %pair_val0_248, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_248 = "transfer.select"(%const_true, %pair_val_248, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_248 = "transfer.and"(%pair_acc0_247, %pair_sel0_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_248 = "transfer.and"(%pair_acc1_247, %pair_sel1_248) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_248 = "arith.ori"(%pair_any_247, %const_true) : (i1, i1) -> i1
    %pair_mul_249 = "transfer.mul"(%lhsu_v15, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_249 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v9) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_249 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_249 = "transfer.cmp"(%rhsu_v9, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_249 = "arith.xori"(%pair_lhs_neg_249, %pair_rhs_neg_249) : (i1, i1) -> i1
    %pair_sat_249 = "transfer.select"(%pair_res_neg_249, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_249 = "transfer.select"(%pair_ov_249, %pair_sat_249, %pair_mul_249) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_249 = "transfer.xor"(%pair_val_249, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_249 = "transfer.select"(%const_true, %pair_val0_249, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_249 = "transfer.select"(%const_true, %pair_val_249, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_249 = "transfer.and"(%pair_acc0_248, %pair_sel0_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_249 = "transfer.and"(%pair_acc1_248, %pair_sel1_249) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_249 = "arith.ori"(%pair_any_248, %const_true) : (i1, i1) -> i1
    %pair_mul_250 = "transfer.mul"(%lhsu_v15, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_250 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v10) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_250 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_250 = "transfer.cmp"(%rhsu_v10, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_250 = "arith.xori"(%pair_lhs_neg_250, %pair_rhs_neg_250) : (i1, i1) -> i1
    %pair_sat_250 = "transfer.select"(%pair_res_neg_250, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_250 = "transfer.select"(%pair_ov_250, %pair_sat_250, %pair_mul_250) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_250 = "transfer.xor"(%pair_val_250, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_250 = "transfer.select"(%const_true, %pair_val0_250, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_250 = "transfer.select"(%const_true, %pair_val_250, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_250 = "transfer.and"(%pair_acc0_249, %pair_sel0_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_250 = "transfer.and"(%pair_acc1_249, %pair_sel1_250) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_250 = "arith.ori"(%pair_any_249, %const_true) : (i1, i1) -> i1
    %pair_mul_251 = "transfer.mul"(%lhsu_v15, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_251 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v11) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_251 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_251 = "transfer.cmp"(%rhsu_v11, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_251 = "arith.xori"(%pair_lhs_neg_251, %pair_rhs_neg_251) : (i1, i1) -> i1
    %pair_sat_251 = "transfer.select"(%pair_res_neg_251, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_251 = "transfer.select"(%pair_ov_251, %pair_sat_251, %pair_mul_251) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_251 = "transfer.xor"(%pair_val_251, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_251 = "transfer.select"(%const_true, %pair_val0_251, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_251 = "transfer.select"(%const_true, %pair_val_251, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_251 = "transfer.and"(%pair_acc0_250, %pair_sel0_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_251 = "transfer.and"(%pair_acc1_250, %pair_sel1_251) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_251 = "arith.ori"(%pair_any_250, %const_true) : (i1, i1) -> i1
    %pair_mul_252 = "transfer.mul"(%lhsu_v15, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_252 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v12) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_252 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_252 = "transfer.cmp"(%rhsu_v12, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_252 = "arith.xori"(%pair_lhs_neg_252, %pair_rhs_neg_252) : (i1, i1) -> i1
    %pair_sat_252 = "transfer.select"(%pair_res_neg_252, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_252 = "transfer.select"(%pair_ov_252, %pair_sat_252, %pair_mul_252) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_252 = "transfer.xor"(%pair_val_252, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_252 = "transfer.select"(%const_true, %pair_val0_252, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_252 = "transfer.select"(%const_true, %pair_val_252, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_252 = "transfer.and"(%pair_acc0_251, %pair_sel0_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_252 = "transfer.and"(%pair_acc1_251, %pair_sel1_252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_252 = "arith.ori"(%pair_any_251, %const_true) : (i1, i1) -> i1
    %pair_mul_253 = "transfer.mul"(%lhsu_v15, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_253 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v13) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_253 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_253 = "transfer.cmp"(%rhsu_v13, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_253 = "arith.xori"(%pair_lhs_neg_253, %pair_rhs_neg_253) : (i1, i1) -> i1
    %pair_sat_253 = "transfer.select"(%pair_res_neg_253, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_253 = "transfer.select"(%pair_ov_253, %pair_sat_253, %pair_mul_253) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_253 = "transfer.xor"(%pair_val_253, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_253 = "transfer.select"(%const_true, %pair_val0_253, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_253 = "transfer.select"(%const_true, %pair_val_253, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_253 = "transfer.and"(%pair_acc0_252, %pair_sel0_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_253 = "transfer.and"(%pair_acc1_252, %pair_sel1_253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_253 = "arith.ori"(%pair_any_252, %const_true) : (i1, i1) -> i1
    %pair_mul_254 = "transfer.mul"(%lhsu_v15, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_254 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v14) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_254 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_254 = "transfer.cmp"(%rhsu_v14, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_254 = "arith.xori"(%pair_lhs_neg_254, %pair_rhs_neg_254) : (i1, i1) -> i1
    %pair_sat_254 = "transfer.select"(%pair_res_neg_254, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_254 = "transfer.select"(%pair_ov_254, %pair_sat_254, %pair_mul_254) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_254 = "transfer.xor"(%pair_val_254, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_254 = "transfer.select"(%const_true, %pair_val0_254, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_254 = "transfer.select"(%const_true, %pair_val_254, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_254 = "transfer.and"(%pair_acc0_253, %pair_sel0_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_254 = "transfer.and"(%pair_acc1_253, %pair_sel1_254) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_254 = "arith.ori"(%pair_any_253, %const_true) : (i1, i1) -> i1
    %pair_mul_255 = "transfer.mul"(%lhsu_v15, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_ov_255 = "transfer.smul_overflow"(%lhsu_v15, %rhsu_v15) : (!transfer.integer, !transfer.integer) -> i1
    %pair_lhs_neg_255 = "transfer.cmp"(%lhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_rhs_neg_255 = "transfer.cmp"(%rhsu_v15, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %pair_res_neg_255 = "arith.xori"(%pair_lhs_neg_255, %pair_rhs_neg_255) : (i1, i1) -> i1
    %pair_sat_255 = "transfer.select"(%pair_res_neg_255, %signed_min, %signed_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val_255 = "transfer.select"(%pair_ov_255, %pair_sat_255, %pair_mul_255) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_val0_255 = "transfer.xor"(%pair_val_255, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel0_255 = "transfer.select"(%const_true, %pair_val0_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_sel1_255 = "transfer.select"(%const_true, %pair_val_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc0_255 = "transfer.and"(%pair_acc0_254, %pair_sel0_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_acc1_255 = "transfer.and"(%pair_acc1_254, %pair_sel1_255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair_any_255 = "arith.ori"(%pair_any_254, %const_true) : (i1, i1) -> i1
    %res0_exact = "transfer.select"(%pair_any_255, %pair_acc0_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_exact = "transfer.select"(%pair_any_255, %pair_acc1_255, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%exact_on, %res0_exact, %res0_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%exact_on, %res1_exact, %res1_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_smulsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
