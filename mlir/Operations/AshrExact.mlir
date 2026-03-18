module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.ashr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ctz = "transfer.countr_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %ctz_ok = "transfer.cmp"(%ctz, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cto = "transfer.countr_one"(%arg0) : (!transfer.integer) -> !transfer.integer
    %cto_ok = "transfer.cmp"(%cto, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    
    %const_0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %arg0_non_neg = "transfer.cmp"(%arg0, %const_0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %exact = "transfer.select"(%arg0_non_neg, %ctz_ok, %cto_ok) : (i1, i1, i1) -> i1

    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %res = arith.andi %shift_lt_bw, %exact : i1
    return %res : i1
  }
}
