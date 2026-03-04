builtin.module {
  func.func @known_bits_rotation_three_operands(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The known bits of a bitwise rotation combining left and right shifts for each valid shift amount drawn from three input operands.
    %v6 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v7 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.and"(%v6, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v8 = "transfer.constant"(%v9) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v4 = "transfer.cmp"(%v5, %v8) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v12 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v13 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.and"(%v12, %v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v14 = "transfer.constant"(%v15) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v10 = "transfer.cmp"(%v11, %v14) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v3 = "arith.andi"(%v4, %v10) : (i1, i1) -> i1
    %v18 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v19 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v17 = "transfer.and"(%v18, %v19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v21 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v20 = "transfer.constant"(%v21) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.cmp"(%v17, %v20) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v2 = "arith.andi"(%v3, %v16) : (i1, i1) -> i1
    %v26 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v28 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v27 = "transfer.constant"(%v28) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.cmp"(%v26, %v27) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v30 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v32 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get_all_ones"(%v32) : (!transfer.integer) -> !transfer.integer
    %v29 = "transfer.cmp"(%v30, %v31) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v24 = "arith.andi"(%v25, %v29) : (i1, i1) -> i1
    %v35 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.constant"(%v37) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v34 = "transfer.cmp"(%v35, %v36) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v39 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v41 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v40 = "transfer.get_all_ones"(%v41) : (!transfer.integer) -> !transfer.integer
    %v38 = "transfer.cmp"(%v39, %v40) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v33 = "arith.andi"(%v34, %v38) : (i1, i1) -> i1
    %v23 = "arith.andi"(%v24, %v33) : (i1, i1) -> i1
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.constant"(%v43) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v48 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v50 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v49 = "transfer.get_all_ones"(%v50) : (!transfer.integer) -> !transfer.integer
    %v47 = "transfer.cmp"(%v48, %v49) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v52 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v54 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v53 = "transfer.constant"(%v54) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v51 = "transfer.cmp"(%v52, %v53) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v46 = "arith.andi"(%v47, %v51) : (i1, i1) -> i1
    %v57 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v59 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v58 = "transfer.get_all_ones"(%v59) : (!transfer.integer) -> !transfer.integer
    %v56 = "transfer.cmp"(%v57, %v58) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v61 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v63 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v62 = "transfer.constant"(%v63) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v60 = "transfer.cmp"(%v61, %v62) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v55 = "arith.andi"(%v56, %v60) : (i1, i1) -> i1
    %v45 = "arith.andi"(%v46, %v55) : (i1, i1) -> i1
    %v65 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v64 = "transfer.get_all_ones"(%v65) : (!transfer.integer) -> !transfer.integer
    %v68 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v70 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v72 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v71 = "transfer.get_all_ones"(%v72) : (!transfer.integer) -> !transfer.integer
    %v69 = "transfer.xor"(%v70, %v71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v67 = "transfer.cmp"(%v68, %v69) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v75 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v77 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v79 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v78 = "transfer.get_bit_width"(%v79) : (!transfer.integer) -> !transfer.integer
    %v76 = "transfer.urem"(%v77, %v78) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v74 = func.call @%h0(%v75, %v76) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v81 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v84 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v83 = "transfer.get_bit_width"(%v84) : (!transfer.integer) -> !transfer.integer
    %v86 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v88 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v87 = "transfer.get_bit_width"(%v88) : (!transfer.integer) -> !transfer.integer
    %v85 = "transfer.urem"(%v86, %v87) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v82 = "transfer.sub"(%v83, %v85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v80 = func.call @%h1(%v81, %v82) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v73 = "transfer.or"(%v74, %v80) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v94 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v95 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v93 = "transfer.or"(%v94, %v95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v97 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v96 = "transfer.get_all_ones"(%v97) : (!transfer.integer) -> !transfer.integer
    %v92 = "transfer.xor"(%v93, %v96) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v99 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v98 = "transfer.constant"(%v99) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v91 = "transfer.cmp"(%v92, %v98) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v104 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v105 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v103 = "transfer.or"(%v104, %v105) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v107 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v106 = "transfer.get_all_ones"(%v107) : (!transfer.integer) -> !transfer.integer
    %v102 = "transfer.xor"(%v103, %v106) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v111 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v112 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v110 = "transfer.or"(%v111, %v112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v114 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v113 = "transfer.get_all_ones"(%v114) : (!transfer.integer) -> !transfer.integer
    %v109 = "transfer.xor"(%v110, %v113) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v116 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v115 = "transfer.constant"(%v116) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v108 = "transfer.sub"(%v109, %v115) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v101 = "transfer.and"(%v102, %v108) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v118 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v117 = "transfer.constant"(%v118) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v100 = "transfer.cmp"(%v101, %v117) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v90 = "arith.andi"(%v91, %v100) : (i1, i1) -> i1
    %v125 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v126 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v124 = "transfer.or"(%v125, %v126) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v128 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v127 = "transfer.get_all_ones"(%v128) : (!transfer.integer) -> !transfer.integer
    %v123 = "transfer.xor"(%v124, %v127) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v130 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v129 = "transfer.constant"(%v130) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v122 = "transfer.cmp"(%v123, %v129) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v135 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v136 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v134 = "transfer.or"(%v135, %v136) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v138 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v137 = "transfer.get_all_ones"(%v138) : (!transfer.integer) -> !transfer.integer
    %v133 = "transfer.xor"(%v134, %v137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v142 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v143 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v141 = "transfer.or"(%v142, %v143) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v145 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v144 = "transfer.get_all_ones"(%v145) : (!transfer.integer) -> !transfer.integer
    %v140 = "transfer.xor"(%v141, %v144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v147 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v146 = "transfer.constant"(%v147) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v139 = "transfer.sub"(%v140, %v146) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v132 = "transfer.and"(%v133, %v139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v149 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v148 = "transfer.constant"(%v149) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v131 = "transfer.cmp"(%v132, %v148) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v121 = "arith.andi"(%v122, %v131) : (i1, i1) -> i1
    %v152 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v154 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v156 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v155 = "transfer.get_bit_width"(%v156) : (!transfer.integer) -> !transfer.integer
    %v153 = "transfer.urem"(%v154, %v155) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v151 = func.call @%h0(%v152, %v153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v158 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v161 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v160 = "transfer.get_bit_width"(%v161) : (!transfer.integer) -> !transfer.integer
    %v163 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v165 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v164 = "transfer.get_bit_width"(%v165) : (!transfer.integer) -> !transfer.integer
    %v162 = "transfer.urem"(%v163, %v164) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v159 = "transfer.sub"(%v160, %v162) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v157 = func.call @%h1(%v158, %v159) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v150 = "transfer.or"(%v151, %v157) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v167 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v166 = "transfer.get_all_ones"(%v167) : (!transfer.integer) -> !transfer.integer
    %v120 = "transfer.select"(%v121, %v150, %v166) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v173 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v174 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v172 = "transfer.or"(%v173, %v174) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v176 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v175 = "transfer.get_all_ones"(%v176) : (!transfer.integer) -> !transfer.integer
    %v171 = "transfer.xor"(%v172, %v175) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v178 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v177 = "transfer.constant"(%v178) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v170 = "transfer.cmp"(%v171, %v177) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v183 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v184 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v182 = "transfer.or"(%v183, %v184) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v186 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v185 = "transfer.get_all_ones"(%v186) : (!transfer.integer) -> !transfer.integer
    %v181 = "transfer.xor"(%v182, %v185) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v190 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v191 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v189 = "transfer.or"(%v190, %v191) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v193 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v192 = "transfer.get_all_ones"(%v193) : (!transfer.integer) -> !transfer.integer
    %v188 = "transfer.xor"(%v189, %v192) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v195 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v194 = "transfer.constant"(%v195) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v187 = "transfer.sub"(%v188, %v194) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v180 = "transfer.and"(%v181, %v187) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v197 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v196 = "transfer.constant"(%v197) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v179 = "transfer.cmp"(%v180, %v196) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v169 = "arith.andi"(%v170, %v179) : (i1, i1) -> i1
    %v200 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v203 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v206 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v207 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v205 = "transfer.or"(%v206, %v207) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v209 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v208 = "transfer.get_all_ones"(%v209) : (!transfer.integer) -> !transfer.integer
    %v204 = "transfer.xor"(%v205, %v208) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v202 = "transfer.add"(%v203, %v204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v211 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v210 = "transfer.get_bit_width"(%v211) : (!transfer.integer) -> !transfer.integer
    %v201 = "transfer.urem"(%v202, %v210) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v199 = func.call @%h0(%v200, %v201) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v213 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v216 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v215 = "transfer.get_bit_width"(%v216) : (!transfer.integer) -> !transfer.integer
    %v219 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v222 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v223 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v221 = "transfer.or"(%v222, %v223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v225 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v224 = "transfer.get_all_ones"(%v225) : (!transfer.integer) -> !transfer.integer
    %v220 = "transfer.xor"(%v221, %v224) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v218 = "transfer.add"(%v219, %v220) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v227 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v226 = "transfer.get_bit_width"(%v227) : (!transfer.integer) -> !transfer.integer
    %v217 = "transfer.urem"(%v218, %v226) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v214 = "transfer.sub"(%v215, %v217) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v212 = func.call @%h1(%v213, %v214) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v198 = "transfer.or"(%v199, %v212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v229 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v228 = "transfer.get_all_ones"(%v229) : (!transfer.integer) -> !transfer.integer
    %v168 = "transfer.select"(%v169, %v198, %v228) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v119 = "transfer.and"(%v120, %v168) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v231 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v230 = "transfer.constant"(%v231) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v89 = "transfer.select"(%v90, %v119, %v230) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v66 = "transfer.select"(%v67, %v73, %v89) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v44 = "transfer.select"(%v45, %v64, %v66) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v22 = "transfer.select"(%v23, %v42, %v44) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v233 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v232 = "transfer.get_all_ones"(%v233) : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v22, %v232) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v239 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v240 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v238 = "transfer.and"(%v239, %v240) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v242 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v241 = "transfer.constant"(%v242) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v237 = "transfer.cmp"(%v238, %v241) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v245 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v246 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v244 = "transfer.and"(%v245, %v246) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v248 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v247 = "transfer.constant"(%v248) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v243 = "transfer.cmp"(%v244, %v247) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v236 = "arith.andi"(%v237, %v243) : (i1, i1) -> i1
    %v251 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v252 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v250 = "transfer.and"(%v251, %v252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v254 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v253 = "transfer.constant"(%v254) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v249 = "transfer.cmp"(%v250, %v253) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v235 = "arith.andi"(%v236, %v249) : (i1, i1) -> i1
    %v259 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v261 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v260 = "transfer.constant"(%v261) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v258 = "transfer.cmp"(%v259, %v260) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v263 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v265 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v264 = "transfer.get_all_ones"(%v265) : (!transfer.integer) -> !transfer.integer
    %v262 = "transfer.cmp"(%v263, %v264) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v257 = "arith.andi"(%v258, %v262) : (i1, i1) -> i1
    %v268 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v270 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v269 = "transfer.constant"(%v270) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v267 = "transfer.cmp"(%v268, %v269) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v272 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v274 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v273 = "transfer.get_all_ones"(%v274) : (!transfer.integer) -> !transfer.integer
    %v271 = "transfer.cmp"(%v272, %v273) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v266 = "arith.andi"(%v267, %v271) : (i1, i1) -> i1
    %v256 = "arith.andi"(%v257, %v266) : (i1, i1) -> i1
    %v276 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v275 = "transfer.get_all_ones"(%v276) : (!transfer.integer) -> !transfer.integer
    %v281 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v283 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v282 = "transfer.get_all_ones"(%v283) : (!transfer.integer) -> !transfer.integer
    %v280 = "transfer.cmp"(%v281, %v282) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v285 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v287 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v286 = "transfer.constant"(%v287) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v284 = "transfer.cmp"(%v285, %v286) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v279 = "arith.andi"(%v280, %v284) : (i1, i1) -> i1
    %v290 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v292 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v291 = "transfer.get_all_ones"(%v292) : (!transfer.integer) -> !transfer.integer
    %v289 = "transfer.cmp"(%v290, %v291) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v294 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v296 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v295 = "transfer.constant"(%v296) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v293 = "transfer.cmp"(%v294, %v295) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v288 = "arith.andi"(%v289, %v293) : (i1, i1) -> i1
    %v278 = "arith.andi"(%v279, %v288) : (i1, i1) -> i1
    %v298 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v297 = "transfer.constant"(%v298) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v301 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v303 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v305 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v304 = "transfer.get_all_ones"(%v305) : (!transfer.integer) -> !transfer.integer
    %v302 = "transfer.xor"(%v303, %v304) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v300 = "transfer.cmp"(%v301, %v302) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v308 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v310 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v312 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v311 = "transfer.get_bit_width"(%v312) : (!transfer.integer) -> !transfer.integer
    %v309 = "transfer.urem"(%v310, %v311) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v307 = func.call @%h0(%v308, %v309) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v314 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v317 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v316 = "transfer.get_bit_width"(%v317) : (!transfer.integer) -> !transfer.integer
    %v319 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v321 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v320 = "transfer.get_bit_width"(%v321) : (!transfer.integer) -> !transfer.integer
    %v318 = "transfer.urem"(%v319, %v320) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v315 = "transfer.sub"(%v316, %v318) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v313 = func.call @%h1(%v314, %v315) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v306 = "transfer.or"(%v307, %v313) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v327 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v328 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v326 = "transfer.or"(%v327, %v328) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v330 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v329 = "transfer.get_all_ones"(%v330) : (!transfer.integer) -> !transfer.integer
    %v325 = "transfer.xor"(%v326, %v329) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v332 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v331 = "transfer.constant"(%v332) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v324 = "transfer.cmp"(%v325, %v331) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v337 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v338 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v336 = "transfer.or"(%v337, %v338) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v340 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v339 = "transfer.get_all_ones"(%v340) : (!transfer.integer) -> !transfer.integer
    %v335 = "transfer.xor"(%v336, %v339) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v344 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v345 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v343 = "transfer.or"(%v344, %v345) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v347 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v346 = "transfer.get_all_ones"(%v347) : (!transfer.integer) -> !transfer.integer
    %v342 = "transfer.xor"(%v343, %v346) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v349 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v348 = "transfer.constant"(%v349) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v341 = "transfer.sub"(%v342, %v348) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v334 = "transfer.and"(%v335, %v341) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v351 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v350 = "transfer.constant"(%v351) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v333 = "transfer.cmp"(%v334, %v350) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v323 = "arith.andi"(%v324, %v333) : (i1, i1) -> i1
    %v358 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v359 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v357 = "transfer.or"(%v358, %v359) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v361 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v360 = "transfer.get_all_ones"(%v361) : (!transfer.integer) -> !transfer.integer
    %v356 = "transfer.xor"(%v357, %v360) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v363 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v362 = "transfer.constant"(%v363) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v355 = "transfer.cmp"(%v356, %v362) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v368 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v369 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v367 = "transfer.or"(%v368, %v369) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v371 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v370 = "transfer.get_all_ones"(%v371) : (!transfer.integer) -> !transfer.integer
    %v366 = "transfer.xor"(%v367, %v370) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v375 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v376 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v374 = "transfer.or"(%v375, %v376) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v378 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v377 = "transfer.get_all_ones"(%v378) : (!transfer.integer) -> !transfer.integer
    %v373 = "transfer.xor"(%v374, %v377) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v380 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v379 = "transfer.constant"(%v380) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v372 = "transfer.sub"(%v373, %v379) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v365 = "transfer.and"(%v366, %v372) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v382 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v381 = "transfer.constant"(%v382) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v364 = "transfer.cmp"(%v365, %v381) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v354 = "arith.andi"(%v355, %v364) : (i1, i1) -> i1
    %v385 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v387 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v389 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v388 = "transfer.get_bit_width"(%v389) : (!transfer.integer) -> !transfer.integer
    %v386 = "transfer.urem"(%v387, %v388) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v384 = func.call @%h0(%v385, %v386) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v391 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v394 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v393 = "transfer.get_bit_width"(%v394) : (!transfer.integer) -> !transfer.integer
    %v396 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v398 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v397 = "transfer.get_bit_width"(%v398) : (!transfer.integer) -> !transfer.integer
    %v395 = "transfer.urem"(%v396, %v397) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v392 = "transfer.sub"(%v393, %v395) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v390 = func.call @%h1(%v391, %v392) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v383 = "transfer.or"(%v384, %v390) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v400 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v399 = "transfer.get_all_ones"(%v400) : (!transfer.integer) -> !transfer.integer
    %v353 = "transfer.select"(%v354, %v383, %v399) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v406 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v407 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v405 = "transfer.or"(%v406, %v407) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v409 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v408 = "transfer.get_all_ones"(%v409) : (!transfer.integer) -> !transfer.integer
    %v404 = "transfer.xor"(%v405, %v408) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v411 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v410 = "transfer.constant"(%v411) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v403 = "transfer.cmp"(%v404, %v410) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v416 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v417 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v415 = "transfer.or"(%v416, %v417) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v419 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v418 = "transfer.get_all_ones"(%v419) : (!transfer.integer) -> !transfer.integer
    %v414 = "transfer.xor"(%v415, %v418) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v423 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v424 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v422 = "transfer.or"(%v423, %v424) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v426 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v425 = "transfer.get_all_ones"(%v426) : (!transfer.integer) -> !transfer.integer
    %v421 = "transfer.xor"(%v422, %v425) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v428 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v427 = "transfer.constant"(%v428) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v420 = "transfer.sub"(%v421, %v427) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v413 = "transfer.and"(%v414, %v420) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v430 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v429 = "transfer.constant"(%v430) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v412 = "transfer.cmp"(%v413, %v429) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v402 = "arith.andi"(%v403, %v412) : (i1, i1) -> i1
    %v433 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v436 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v439 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v440 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v438 = "transfer.or"(%v439, %v440) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v442 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v441 = "transfer.get_all_ones"(%v442) : (!transfer.integer) -> !transfer.integer
    %v437 = "transfer.xor"(%v438, %v441) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v435 = "transfer.add"(%v436, %v437) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v444 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v443 = "transfer.get_bit_width"(%v444) : (!transfer.integer) -> !transfer.integer
    %v434 = "transfer.urem"(%v435, %v443) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v432 = func.call @%h0(%v433, %v434) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v446 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v449 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v448 = "transfer.get_bit_width"(%v449) : (!transfer.integer) -> !transfer.integer
    %v452 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v455 = "transfer.get"(%arg2) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v456 = "transfer.get"(%arg2) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v454 = "transfer.or"(%v455, %v456) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v458 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v457 = "transfer.get_all_ones"(%v458) : (!transfer.integer) -> !transfer.integer
    %v453 = "transfer.xor"(%v454, %v457) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v451 = "transfer.add"(%v452, %v453) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v460 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v459 = "transfer.get_bit_width"(%v460) : (!transfer.integer) -> !transfer.integer
    %v450 = "transfer.urem"(%v451, %v459) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v447 = "transfer.sub"(%v448, %v450) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v445 = func.call @%h1(%v446, %v447) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v431 = "transfer.or"(%v432, %v445) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v462 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v461 = "transfer.get_all_ones"(%v462) : (!transfer.integer) -> !transfer.integer
    %v401 = "transfer.select"(%v402, %v431, %v461) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v352 = "transfer.and"(%v353, %v401) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v464 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v463 = "transfer.constant"(%v464) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v322 = "transfer.select"(%v323, %v352, %v463) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v299 = "transfer.select"(%v300, %v306, %v322) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v277 = "transfer.select"(%v278, %v297, %v299) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v255 = "transfer.select"(%v256, %v275, %v277) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v466 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v465 = "transfer.get_all_ones"(%v466) : (!transfer.integer) -> !transfer.integer
    %v234 = "transfer.select"(%v235, %v255, %v465) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v234) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @known_bits_rotation_two_operands(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // The known bits of a bitwise rotation combining left and right shifts for each valid shift amount drawn from two input operands.
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.constant"(%v6) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v3 = "transfer.cmp"(%v4, %v5) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v8 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v9 = "transfer.get_all_ones"(%v10) : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.cmp"(%v8, %v9) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v2 = "arith.andi"(%v3, %v7) : (i1, i1) -> i1
    %v12 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.constant"(%v12) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v18 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v17 = "transfer.get_all_ones"(%v18) : (!transfer.integer) -> !transfer.integer
    %v15 = "transfer.cmp"(%v16, %v17) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v20 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v21 = "transfer.constant"(%v22) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v19 = "transfer.cmp"(%v20, %v21) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v14 = "arith.andi"(%v15, %v19) : (i1, i1) -> i1
    %v24 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v23 = "transfer.get_all_ones"(%v24) : (!transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v29 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v30 = "transfer.get_all_ones"(%v31) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.xor"(%v29, %v30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v26 = "transfer.cmp"(%v27, %v28) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v34 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v38 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.get_bit_width"(%v38) : (!transfer.integer) -> !transfer.integer
    %v35 = "transfer.urem"(%v36, %v37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v33 = func.call @%h0(%v34, %v35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v40 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v43 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v42 = "transfer.get_bit_width"(%v43) : (!transfer.integer) -> !transfer.integer
    %v45 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v47 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v46 = "transfer.get_bit_width"(%v47) : (!transfer.integer) -> !transfer.integer
    %v44 = "transfer.urem"(%v45, %v46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = "transfer.sub"(%v42, %v44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v39 = func.call @%h1(%v40, %v41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v32 = "transfer.or"(%v33, %v39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v53 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v54 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v52 = "transfer.or"(%v53, %v54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v56 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v55 = "transfer.get_all_ones"(%v56) : (!transfer.integer) -> !transfer.integer
    %v51 = "transfer.xor"(%v52, %v55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v58 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v57 = "transfer.constant"(%v58) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v50 = "transfer.cmp"(%v51, %v57) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v63 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v64 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v62 = "transfer.or"(%v63, %v64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v66 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v65 = "transfer.get_all_ones"(%v66) : (!transfer.integer) -> !transfer.integer
    %v61 = "transfer.xor"(%v62, %v65) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v70 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v71 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v69 = "transfer.or"(%v70, %v71) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v73 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v72 = "transfer.get_all_ones"(%v73) : (!transfer.integer) -> !transfer.integer
    %v68 = "transfer.xor"(%v69, %v72) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v75 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v74 = "transfer.constant"(%v75) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v67 = "transfer.sub"(%v68, %v74) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v60 = "transfer.and"(%v61, %v67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v77 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v76 = "transfer.constant"(%v77) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v59 = "transfer.cmp"(%v60, %v76) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v49 = "arith.andi"(%v50, %v59) : (i1, i1) -> i1
    %v83 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v84 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v82 = "transfer.or"(%v83, %v84) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v86 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v85 = "transfer.get_all_ones"(%v86) : (!transfer.integer) -> !transfer.integer
    %v81 = "transfer.xor"(%v82, %v85) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v88 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v87 = "transfer.constant"(%v88) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v80 = "transfer.cmp"(%v81, %v87) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v93 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v94 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v92 = "transfer.or"(%v93, %v94) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v96 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v95 = "transfer.get_all_ones"(%v96) : (!transfer.integer) -> !transfer.integer
    %v91 = "transfer.xor"(%v92, %v95) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v100 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v101 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v99 = "transfer.or"(%v100, %v101) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v103 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v102 = "transfer.get_all_ones"(%v103) : (!transfer.integer) -> !transfer.integer
    %v98 = "transfer.xor"(%v99, %v102) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v105 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v104 = "transfer.constant"(%v105) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v97 = "transfer.sub"(%v98, %v104) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v90 = "transfer.and"(%v91, %v97) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v107 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v106 = "transfer.constant"(%v107) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v89 = "transfer.cmp"(%v90, %v106) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v79 = "arith.andi"(%v80, %v89) : (i1, i1) -> i1
    %v111 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v113 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v115 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v114 = "transfer.get_bit_width"(%v115) : (!transfer.integer) -> !transfer.integer
    %v112 = "transfer.urem"(%v113, %v114) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v110 = func.call @%h0(%v111, %v112) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v117 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v120 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v119 = "transfer.get_bit_width"(%v120) : (!transfer.integer) -> !transfer.integer
    %v122 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v124 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v123 = "transfer.get_bit_width"(%v124) : (!transfer.integer) -> !transfer.integer
    %v121 = "transfer.urem"(%v122, %v123) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v118 = "transfer.sub"(%v119, %v121) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v116 = func.call @%h1(%v117, %v118) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v109 = "transfer.or"(%v110, %v116) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v127 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v130 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v133 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v134 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v132 = "transfer.or"(%v133, %v134) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v136 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v135 = "transfer.get_all_ones"(%v136) : (!transfer.integer) -> !transfer.integer
    %v131 = "transfer.xor"(%v132, %v135) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v129 = "transfer.add"(%v130, %v131) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v138 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v137 = "transfer.get_bit_width"(%v138) : (!transfer.integer) -> !transfer.integer
    %v128 = "transfer.urem"(%v129, %v137) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v126 = func.call @%h0(%v127, %v128) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v140 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v143 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v142 = "transfer.get_bit_width"(%v143) : (!transfer.integer) -> !transfer.integer
    %v146 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v149 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v150 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v148 = "transfer.or"(%v149, %v150) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v152 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v151 = "transfer.get_all_ones"(%v152) : (!transfer.integer) -> !transfer.integer
    %v147 = "transfer.xor"(%v148, %v151) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v145 = "transfer.add"(%v146, %v147) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v154 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v153 = "transfer.get_bit_width"(%v154) : (!transfer.integer) -> !transfer.integer
    %v144 = "transfer.urem"(%v145, %v153) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v141 = "transfer.sub"(%v142, %v144) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v139 = func.call @%h1(%v140, %v141) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v125 = "transfer.or"(%v126, %v139) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v108 = "transfer.and"(%v109, %v125) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v156 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v155 = "transfer.constant"(%v156) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v78 = "transfer.select"(%v79, %v108, %v155) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v158 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v157 = "transfer.constant"(%v158) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v48 = "transfer.select"(%v49, %v78, %v157) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v25 = "transfer.select"(%v26, %v32, %v48) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v13 = "transfer.select"(%v14, %v23, %v25) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v11, %v13) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v162 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v164 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v163 = "transfer.constant"(%v164) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v161 = "transfer.cmp"(%v162, %v163) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v166 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v168 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v167 = "transfer.get_all_ones"(%v168) : (!transfer.integer) -> !transfer.integer
    %v165 = "transfer.cmp"(%v166, %v167) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v160 = "arith.andi"(%v161, %v165) : (i1, i1) -> i1
    %v170 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v169 = "transfer.get_all_ones"(%v170) : (!transfer.integer) -> !transfer.integer
    %v174 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v176 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v175 = "transfer.get_all_ones"(%v176) : (!transfer.integer) -> !transfer.integer
    %v173 = "transfer.cmp"(%v174, %v175) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v178 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v180 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v179 = "transfer.constant"(%v180) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v177 = "transfer.cmp"(%v178, %v179) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v172 = "arith.andi"(%v173, %v177) : (i1, i1) -> i1
    %v182 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v181 = "transfer.constant"(%v182) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v185 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v187 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v189 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v188 = "transfer.get_all_ones"(%v189) : (!transfer.integer) -> !transfer.integer
    %v186 = "transfer.xor"(%v187, %v188) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v184 = "transfer.cmp"(%v185, %v186) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v192 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v194 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v196 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v195 = "transfer.get_bit_width"(%v196) : (!transfer.integer) -> !transfer.integer
    %v193 = "transfer.urem"(%v194, %v195) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v191 = func.call @%h0(%v192, %v193) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v198 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v201 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v200 = "transfer.get_bit_width"(%v201) : (!transfer.integer) -> !transfer.integer
    %v203 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v205 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v204 = "transfer.get_bit_width"(%v205) : (!transfer.integer) -> !transfer.integer
    %v202 = "transfer.urem"(%v203, %v204) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v199 = "transfer.sub"(%v200, %v202) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v197 = func.call @%h1(%v198, %v199) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v190 = "transfer.or"(%v191, %v197) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v211 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v212 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v210 = "transfer.or"(%v211, %v212) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v214 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v213 = "transfer.get_all_ones"(%v214) : (!transfer.integer) -> !transfer.integer
    %v209 = "transfer.xor"(%v210, %v213) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v216 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v215 = "transfer.constant"(%v216) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v208 = "transfer.cmp"(%v209, %v215) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v221 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v222 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v220 = "transfer.or"(%v221, %v222) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v224 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v223 = "transfer.get_all_ones"(%v224) : (!transfer.integer) -> !transfer.integer
    %v219 = "transfer.xor"(%v220, %v223) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v228 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v229 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v227 = "transfer.or"(%v228, %v229) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v231 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v230 = "transfer.get_all_ones"(%v231) : (!transfer.integer) -> !transfer.integer
    %v226 = "transfer.xor"(%v227, %v230) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v233 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v232 = "transfer.constant"(%v233) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v225 = "transfer.sub"(%v226, %v232) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v218 = "transfer.and"(%v219, %v225) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v235 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v234 = "transfer.constant"(%v235) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v217 = "transfer.cmp"(%v218, %v234) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v207 = "arith.andi"(%v208, %v217) : (i1, i1) -> i1
    %v241 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v242 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v240 = "transfer.or"(%v241, %v242) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v244 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v243 = "transfer.get_all_ones"(%v244) : (!transfer.integer) -> !transfer.integer
    %v239 = "transfer.xor"(%v240, %v243) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v246 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v245 = "transfer.constant"(%v246) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v238 = "transfer.cmp"(%v239, %v245) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v251 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v252 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v250 = "transfer.or"(%v251, %v252) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v254 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v253 = "transfer.get_all_ones"(%v254) : (!transfer.integer) -> !transfer.integer
    %v249 = "transfer.xor"(%v250, %v253) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v258 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v259 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v257 = "transfer.or"(%v258, %v259) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v261 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v260 = "transfer.get_all_ones"(%v261) : (!transfer.integer) -> !transfer.integer
    %v256 = "transfer.xor"(%v257, %v260) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v263 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v262 = "transfer.constant"(%v263) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %v255 = "transfer.sub"(%v256, %v262) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v248 = "transfer.and"(%v249, %v255) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v265 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v264 = "transfer.constant"(%v265) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v247 = "transfer.cmp"(%v248, %v264) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v237 = "arith.andi"(%v238, %v247) : (i1, i1) -> i1
    %v269 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v271 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v273 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v272 = "transfer.get_bit_width"(%v273) : (!transfer.integer) -> !transfer.integer
    %v270 = "transfer.urem"(%v271, %v272) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v268 = func.call @%h0(%v269, %v270) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v275 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v278 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v277 = "transfer.get_bit_width"(%v278) : (!transfer.integer) -> !transfer.integer
    %v280 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v282 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v281 = "transfer.get_bit_width"(%v282) : (!transfer.integer) -> !transfer.integer
    %v279 = "transfer.urem"(%v280, %v281) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v276 = "transfer.sub"(%v277, %v279) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v274 = func.call @%h1(%v275, %v276) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v267 = "transfer.or"(%v268, %v274) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v285 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v288 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v291 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v292 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v290 = "transfer.or"(%v291, %v292) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v294 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v293 = "transfer.get_all_ones"(%v294) : (!transfer.integer) -> !transfer.integer
    %v289 = "transfer.xor"(%v290, %v293) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v287 = "transfer.add"(%v288, %v289) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v296 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v295 = "transfer.get_bit_width"(%v296) : (!transfer.integer) -> !transfer.integer
    %v286 = "transfer.urem"(%v287, %v295) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v284 = func.call @%h0(%v285, %v286) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v298 = "transfer.get"(%arg0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v301 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v300 = "transfer.get_bit_width"(%v301) : (!transfer.integer) -> !transfer.integer
    %v304 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v307 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v308 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v306 = "transfer.or"(%v307, %v308) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v310 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v309 = "transfer.get_all_ones"(%v310) : (!transfer.integer) -> !transfer.integer
    %v305 = "transfer.xor"(%v306, %v309) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v303 = "transfer.add"(%v304, %v305) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v312 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v311 = "transfer.get_bit_width"(%v312) : (!transfer.integer) -> !transfer.integer
    %v302 = "transfer.urem"(%v303, %v311) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v299 = "transfer.sub"(%v300, %v302) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v297 = func.call @%h1(%v298, %v299) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v283 = "transfer.or"(%v284, %v297) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v266 = "transfer.and"(%v267, %v283) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v314 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v313 = "transfer.constant"(%v314) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v236 = "transfer.select"(%v237, %v266, %v313) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v316 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v315 = "transfer.constant"(%v316) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v206 = "transfer.select"(%v207, %v236, %v315) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v183 = "transfer.select"(%v184, %v190, %v206) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v171 = "transfer.select"(%v172, %v181, %v183) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v159 = "transfer.select"(%v160, %v169, %v171) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v159) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @double_and_mask_transfer(%h0 : !transfer.integer, %h1 : !transfer.integer, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.integer) -> !transfer.integer {
    // The abstract image of the input sequentially masked by two constant bit-masks.
    %v2 = "transfer.and"(%arg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.and"(%h1, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}
