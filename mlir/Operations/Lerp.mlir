"builtin.module"() ({
  "func.func"() ({
  ^bb0(%a: !transfer.integer, %b: !transfer.integer, %c: !transfer.integer, %d: !transfer.integer):
    %bminc = "transfer.sub"(%b, %c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %amulbc = "transfer.mul"(%a, %bminc) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cmuld = "transfer.mul"(%c, %d) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res = "transfer.add"(%amulbc, %cmuld) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    "func.return"(%res) : (!transfer.integer) -> ()
  }) {function_type = (!transfer.integer,!transfer.integer,!transfer.integer,!transfer.integer) -> !transfer.integer, sym_name = "concrete_op"} : () -> ()

  "func.func"() ({
  ^bb0(%a: !transfer.integer, %b: !transfer.integer, %c: !transfer.integer, %d: !transfer.integer):
    %const0 = "transfer.constant"(%a) {value=0}:(!transfer.integer)->!transfer.integer
    %age0 = "transfer.cmp"(%a, %const0) {predicate=5}: (!transfer.integer, !transfer.integer) -> i1
    %bge0 = "transfer.cmp"(%b, %const0) {predicate=5}: (!transfer.integer, !transfer.integer) -> i1
    %cge0 = "transfer.cmp"(%c, %const0) {predicate=5}: (!transfer.integer, !transfer.integer) -> i1
    %dge0 = "transfer.cmp"(%d, %const0) {predicate=5}: (!transfer.integer, !transfer.integer) -> i1
    %bgec = "transfer.cmp"(%b, %c) {predicate=5}: (!transfer.integer, !transfer.integer) -> i1
    
    %aandb = "arith.andi"(%age0, %bge0) : (i1, i1) -> i1
    %abandc = "arith.andi"(%aandb, %cge0) : (i1, i1) -> i1
    %abcandd = "arith.andi"(%abandc, %dge0) : (i1, i1) -> i1
    %abcdandbc = "arith.andi"(%abcandd, %bgec) : (i1, i1) -> i1
    "func.return"(%abcdandbc) : (i1) -> ()
  }) {function_type = (!transfer.integer, !transfer.integer, !transfer.integer, !transfer.integer) -> i1, sym_name = "op_constraint"} : () -> ()
}): () -> ()
