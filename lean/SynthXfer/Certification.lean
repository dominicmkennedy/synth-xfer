import SynthXfer

/-!
# Kernel axiom audit and checked status report

Running this file asks Lean to report every axiom used by the headline
theorems and renders the KnownBits operation table from proof-carrying values.
`propext`, `Classical.choice`, and `Quot.sound` are standard parts of Lean's
trusted logical foundation. Project-specific axioms, `sorryAx`, or
native-evaluation axioms must not appear.
-/

namespace SynthXfer.Certification

/-- A displayed status that can only be constructed with the corresponding
proof or counterexample. The proposition is stored implicitly in the
constructor and checked by Lean. -/
inductive CheckedStatus where
  | complete {claim : Prop} (proof : claim)
  | incompleteAt {claim : Prop} (width : Nat) (proof : ¬ claim)
  | incompleteAtWidths {claim : Prop}
      (sourceWidth destinationWidth : Nat) (proof : ¬ claim)
  | unclassified

def CheckedStatus.label : CheckedStatus → String
  | .complete _ => "complete"
  | .incompleteAt width _ => s!"incomplete i{width}"
  | .incompleteAtWidths sourceWidth destinationWidth _ =>
      s!"incomplete i{sourceWidth}→i{destinationWidth}"
  | .unclassified => "?"

structure StatusRow where
  operation : String
  forward : CheckedStatus
  backward : CheckedStatus

private def knownBitsStatusRows : List StatusRow :=
  [ ⟨"Abs", .incompleteAt 8 LLVM.knownBits_abs_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_abs_i8_not_backwardComplete⟩
  , ⟨"AbsUndef",
      .incompleteAt 8 LLVM.knownBits_absUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_absUndef_i8_not_backwardComplete⟩
  , ⟨"PopCount",
      .incompleteAt 8 LLVM.knownBits_popCount_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_popCount_i8_not_backwardComplete⟩
  , ⟨"Ctlz", .incompleteAt 8 LLVM.knownBits_ctlz_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ctlz_i8_not_backwardComplete⟩
  , ⟨"CtlzUndef",
      .incompleteAt 8 LLVM.knownBits_ctlzUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ctlzUndef_i8_not_backwardComplete⟩
  , ⟨"Cttz", .incompleteAt 8 LLVM.knownBits_cttz_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_cttz_i8_not_backwardComplete⟩
  , ⟨"CttzUndef",
      .incompleteAt 8 LLVM.knownBits_cttzUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_cttzUndef_i8_not_backwardComplete⟩
  , ⟨"Add", .incompleteAt 8 LLVM.knownBits_add_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_add_i8_not_backwardComplete⟩
  , ⟨"AddNsw", .incompleteAt 8 LLVM.knownBits_addNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_addNsw_i8_not_backwardComplete⟩
  , ⟨"AddNuw", .incompleteAt 8 LLVM.knownBits_addNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_addNuw_i8_not_backwardComplete⟩
  , ⟨"AddNswNuw",
      .incompleteAt 8 LLVM.knownBits_addNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_addNswNuw_i8_not_backwardComplete⟩
  , ⟨"And", .complete LLVM.knownBits_and_forwardComplete,
      .complete LLVM.knownBits_and_backwardComplete⟩
  , ⟨"Ashr", .incompleteAt 8 LLVM.knownBits_ashr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ashr_i8_not_backwardComplete⟩
  , ⟨"AshrExact",
      .incompleteAt 8 LLVM.knownBits_ashrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ashrExact_i8_not_backwardComplete⟩
  , ⟨"Lshr", .incompleteAt 8 LLVM.knownBits_lshr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_lshr_i8_not_backwardComplete⟩
  , ⟨"LshrExact",
      .incompleteAt 8 LLVM.knownBits_lshrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_lshrExact_i8_not_backwardComplete⟩
  , ⟨"Mul", .incompleteAt 8 LLVM.knownBits_mul_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_mul_i8_not_backwardComplete⟩
  , ⟨"MulNsw", .incompleteAt 8 LLVM.knownBits_mulNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_mulNsw_i8_not_backwardComplete⟩
  , ⟨"MulNuw", .incompleteAt 8 LLVM.knownBits_mulNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_mulNuw_i8_not_backwardComplete⟩
  , ⟨"MulNswNuw",
      .incompleteAt 8 LLVM.knownBits_mulNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_mulNswNuw_i8_not_backwardComplete⟩
  , ⟨"Or", .complete LLVM.knownBits_or_forwardComplete,
      .complete LLVM.knownBits_or_backwardComplete⟩
  , ⟨"OrDisjoint", .complete LLVM.knownBits_orDisjoint_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_orDisjoint_i8_not_backwardComplete⟩
  , ⟨"Sdiv", .incompleteAt 8 LLVM.knownBits_sdiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_sdiv_i8_not_backwardComplete⟩
  , ⟨"SdivExact",
      .incompleteAt 8 LLVM.knownBits_sdivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_sdivExact_i8_not_backwardComplete⟩
  , ⟨"Shl", .incompleteAt 8 LLVM.knownBits_shl_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_shl_i8_not_backwardComplete⟩
  , ⟨"ShlNsw", .incompleteAt 8 LLVM.knownBits_shlNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_shlNsw_i8_not_backwardComplete⟩
  , ⟨"ShlNuw", .incompleteAt 8 LLVM.knownBits_shlNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_shlNuw_i8_not_backwardComplete⟩
  , ⟨"ShlNswNuw",
      .incompleteAt 8 LLVM.knownBits_shlNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_shlNswNuw_i8_not_backwardComplete⟩
  , ⟨"Srem", .incompleteAt 8 LLVM.knownBits_srem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_srem_i8_not_backwardComplete⟩
  , ⟨"Sub", .incompleteAt 8 LLVM.knownBits_sub_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_sub_i8_not_backwardComplete⟩
  , ⟨"SubNsw", .incompleteAt 8 LLVM.knownBits_subNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_subNsw_i8_not_backwardComplete⟩
  , ⟨"SubNuw", .incompleteAt 8 LLVM.knownBits_subNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_subNuw_i8_not_backwardComplete⟩
  , ⟨"SubNswNuw",
      .incompleteAt 8 LLVM.knownBits_subNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_subNswNuw_i8_not_backwardComplete⟩
  , ⟨"Udiv", .incompleteAt 8 LLVM.knownBits_udiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_udiv_i8_not_backwardComplete⟩
  , ⟨"UdivExact",
      .incompleteAt 8 LLVM.knownBits_udivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_udivExact_i8_not_backwardComplete⟩
  , ⟨"Urem", .incompleteAt 8 LLVM.knownBits_urem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_urem_i8_not_backwardComplete⟩
  , ⟨"Xor", .complete LLVM.knownBits_xor_forwardComplete,
      .complete LLVM.knownBits_xor_backwardComplete⟩
  , ⟨"Umax", .incompleteAt 8 LLVM.knownBits_umax_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_umax_i8_not_backwardComplete⟩
  , ⟨"Umin", .incompleteAt 8 LLVM.knownBits_umin_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_umin_i8_not_backwardComplete⟩
  , ⟨"Smax", .incompleteAt 8 LLVM.knownBits_smax_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_smax_i8_not_backwardComplete⟩
  , ⟨"Smin", .incompleteAt 8 LLVM.knownBits_smin_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_smin_i8_not_backwardComplete⟩
  , ⟨"SaddSat", .incompleteAt 8 LLVM.knownBits_saddSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_saddSat_i8_not_backwardComplete⟩
  , ⟨"UaddSat", .incompleteAt 8 LLVM.knownBits_uaddSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_uaddSat_i8_not_backwardComplete⟩
  , ⟨"SsubSat", .incompleteAt 8 LLVM.knownBits_ssubSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ssubSat_i8_not_backwardComplete⟩
  , ⟨"UsubSat", .incompleteAt 8 LLVM.knownBits_usubSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_usubSat_i8_not_backwardComplete⟩
  , ⟨"SmulSat", .incompleteAt 8 LLVM.knownBits_smulSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_smulSat_i8_not_backwardComplete⟩
  , ⟨"UmulSat", .incompleteAt 8 LLVM.knownBits_umulSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_umulSat_i8_not_backwardComplete⟩
  , ⟨"SshlSat", .incompleteAt 8 LLVM.knownBits_sshlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_sshlSat_i8_not_backwardComplete⟩
  , ⟨"UshlSat", .incompleteAt 8 LLVM.knownBits_ushlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_ushlSat_i8_not_backwardComplete⟩
  , ⟨"ICmpEq", .complete LLVM.knownBits_icmpEq_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpEq_i8_not_backwardComplete⟩
  , ⟨"ICmpNe", .complete LLVM.knownBits_icmpNe_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpNe_i8_not_backwardComplete⟩
  , ⟨"ICmpSlt", .complete LLVM.knownBits_icmpSlt_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpSlt_i8_not_backwardComplete⟩
  , ⟨"ICmpSle", .complete LLVM.knownBits_icmpSle_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpSle_i8_not_backwardComplete⟩
  , ⟨"ICmpSgt", .complete LLVM.knownBits_icmpSgt_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpSgt_i8_not_backwardComplete⟩
  , ⟨"ICmpSge", .complete LLVM.knownBits_icmpSge_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpSge_i8_not_backwardComplete⟩
  , ⟨"ICmpUlt", .complete LLVM.knownBits_icmpUlt_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpUlt_i8_not_backwardComplete⟩
  , ⟨"ICmpUle", .complete LLVM.knownBits_icmpUle_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpUle_i8_not_backwardComplete⟩
  , ⟨"ICmpUgt", .complete LLVM.knownBits_icmpUgt_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpUgt_i8_not_backwardComplete⟩
  , ⟨"ICmpUge", .complete LLVM.knownBits_icmpUge_forwardComplete,
      .incompleteAt 8 LLVM.knownBits_icmpUge_i8_not_backwardComplete⟩
  , ⟨"Trunc", .complete LLVM.knownBits_trunc_forwardComplete,
      .complete LLVM.knownBits_trunc_backwardComplete⟩
  , ⟨"Zext", .complete LLVM.knownBits_zext_forwardComplete,
      .complete LLVM.knownBits_zext_backwardComplete⟩
  , ⟨"Sext", .incompleteAtWidths 8 16
        LLVM.knownBits_sext_i8_i16_not_forwardComplete,
      .complete LLVM.knownBits_sext_backwardComplete⟩
  , ⟨"ZextBool", .complete LLVM.knownBits_zextBool_forwardComplete,
      .complete LLVM.knownBits_zextBool_backwardComplete⟩
  , ⟨"SextBool", .incompleteAtWidths 1 8
        LLVM.knownBits_sextBool_i1_i8_not_forwardComplete,
      .complete LLVM.knownBits_sextBool_backwardComplete⟩
  , ⟨"TruncToBool",
      .complete LLVM.knownBits_truncToBool_forwardComplete,
      .complete LLVM.knownBits_truncToBool_backwardComplete⟩
  , ⟨"Select", .incompleteAt 8 LLVM.knownBits_select_i8_not_forwardComplete,
      .complete LLVM.knownBits_select_backwardComplete⟩ ]

private def padRight (width : Nat) (text : String) : String :=
  text ++ String.ofList (List.replicate (width - text.length) ' ')

private def renderRow (row : StatusRow) : String :=
  padRight 16 row.operation ++
    padRight 24 row.forward.label ++ row.backward.label

private def renderTable (rows : List StatusRow) : String :=
  String.intercalate "\n"
    ([ "Operation       Forward                 Backward"
     , "----------------------------------------------------" ] ++
      rows.map renderRow)

def knownBitsStatusTable : String :=
  renderTable knownBitsStatusRows

private def uintRangeStatusRows : List StatusRow :=
  [ ⟨"Abs", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (LLVM.abs : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_abs_forwardComplete hn),
      .incompleteAt 8 LLVM.uintRange_abs_i8_not_backwardComplete⟩
  , ⟨"AbsUndef", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (LLVM.absUndef : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_absUndef_forwardComplete hn),
      .incompleteAt 8 LLVM.uintRange_absUndef_i8_not_backwardComplete⟩
  , ⟨"PopCount",
      .incompleteAt 8 LLVM.uintRange_popCount_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_popCount_i8_not_backwardComplete⟩
  , ⟨"Ctlz", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (LLVM.ctlz : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_ctlz_forwardComplete hn),
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (LLVM.ctlz : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_ctlz_backwardComplete hn)⟩
  , ⟨"CtlzUndef", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (LLVM.ctlzUndef : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_ctlzUndef_forwardComplete hn),
      .incompleteAt 8 LLVM.uintRange_ctlzUndef_i8_not_backwardComplete⟩
  , ⟨"Cttz", .incompleteAt 8 LLVM.uintRange_cttz_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_cttz_i8_not_backwardComplete⟩
  , ⟨"CttzUndef",
      .incompleteAt 8 LLVM.uintRange_cttzUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_cttzUndef_i8_not_backwardComplete⟩
  , ⟨"Add", .incompleteAt 8 LLVM.uintRange_add_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_add_i8_not_backwardComplete⟩
  , ⟨"AddNsw",
      .incompleteAt 8 LLVM.uintRange_addNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_addNsw_i8_not_backwardComplete⟩
  , ⟨"AddNuw", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.addNuw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_addNuw_forwardComplete hn),
      .incompleteAt 8 LLVM.uintRange_addNuw_i8_not_backwardComplete⟩
  , ⟨"AddNswNuw",
      .incompleteAt 8 LLVM.uintRange_addNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_addNswNuw_i8_not_backwardComplete⟩
  , ⟨"And", .incompleteAt 8 LLVM.uintRange_and_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_and_i8_not_backwardComplete⟩
  , ⟨"Or", .incompleteAt 8 LLVM.uintRange_or_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_or_i8_not_backwardComplete⟩
  , ⟨"OrDisjoint",
      .incompleteAt 8 LLVM.uintRange_orDisjoint_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_orDisjoint_i8_not_backwardComplete⟩
  , ⟨"Xor", .incompleteAt 8 LLVM.uintRange_xor_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_xor_i8_not_backwardComplete⟩
  , ⟨"Umax", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n) (LLVM.umax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.uintRange_umax_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n) (LLVM.umax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.uintRange_umax_backwardComplete)⟩
  , ⟨"Umin", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n) (LLVM.umin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.uintRange_umin_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n) (LLVM.umin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.uintRange_umin_backwardComplete)⟩
  , ⟨"Smax", .incompleteAt 8 LLVM.uintRange_smax_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_smax_i8_not_backwardComplete⟩
  , ⟨"Smin", .incompleteAt 8 LLVM.uintRange_smin_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_smin_i8_not_backwardComplete⟩
  , ⟨"SaddSat",
      .incompleteAt 8 LLVM.uintRange_saddSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_saddSat_i8_not_backwardComplete⟩
  , ⟨"UaddSat", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.uaddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_uaddSat_forwardComplete hn),
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.uaddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_uaddSat_backwardComplete hn)⟩
  , ⟨"SsubSat",
      .incompleteAt 8 LLVM.uintRange_ssubSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_ssubSat_i8_not_backwardComplete⟩
  , ⟨"UsubSat", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.usubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_usubSat_forwardComplete hn),
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.usubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_usubSat_backwardComplete hn)⟩
  , ⟨"SmulSat",
      .incompleteAt 8 LLVM.uintRange_smulSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_smulSat_i8_not_backwardComplete⟩
  , ⟨"UmulSat",
      .incompleteAt 8 LLVM.uintRange_umulSat_i8_not_forwardComplete,
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.umulSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_umulSat_backwardComplete hn)⟩
  , ⟨"Sub", .incompleteAt 8 LLVM.uintRange_sub_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_sub_i8_not_backwardComplete⟩
  , ⟨"SubNsw",
      .incompleteAt 8 LLVM.uintRange_subNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_subNsw_i8_not_backwardComplete⟩
  , ⟨"SubNuw", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain n)
          (LLVM.subNuw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.uintRange_subNuw_forwardComplete hn),
      .incompleteAt 8 LLVM.uintRange_subNuw_i8_not_backwardComplete⟩
  , ⟨"SubNswNuw",
      .incompleteAt 8 LLVM.uintRange_subNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_subNswNuw_i8_not_backwardComplete⟩
  , ⟨"Mul", .incompleteAt 8 LLVM.uintRange_mul_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_mul_i8_not_backwardComplete⟩
  , ⟨"MulNsw",
      .incompleteAt 8 LLVM.uintRange_mulNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_mulNsw_i8_not_backwardComplete⟩
  , ⟨"MulNuw",
      .incompleteAt 8 LLVM.uintRange_mulNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_mulNuw_i8_not_backwardComplete⟩
  , ⟨"MulNswNuw",
      .incompleteAt 8 LLVM.uintRange_mulNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_mulNswNuw_i8_not_backwardComplete⟩
  , ⟨"Sdiv", .incompleteAt 8 LLVM.uintRange_sdiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_sdiv_i8_not_backwardComplete⟩
  , ⟨"SdivExact",
      .incompleteAt 8 LLVM.uintRange_sdivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_sdivExact_i8_not_backwardComplete⟩
  , ⟨"Srem", .incompleteAt 8 LLVM.uintRange_srem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_srem_i8_not_backwardComplete⟩
  , ⟨"Udiv", .incompleteAt 8 LLVM.uintRange_udiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_udiv_i8_not_backwardComplete⟩
  , ⟨"UdivExact",
      .incompleteAt 8 LLVM.uintRange_udivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_udivExact_i8_not_backwardComplete⟩
  , ⟨"Urem", .incompleteAt 8 LLVM.uintRange_urem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_urem_i8_not_backwardComplete⟩
  , ⟨"Shl", .incompleteAt 8 LLVM.uintRange_shl_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_shl_i8_not_backwardComplete⟩
  , ⟨"ShlNsw", .incompleteAt 8 LLVM.uintRange_shlNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_shlNsw_i8_not_backwardComplete⟩
  , ⟨"ShlNuw", .incompleteAt 8 LLVM.uintRange_shlNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_shlNuw_i8_not_backwardComplete⟩
  , ⟨"ShlNswNuw",
      .incompleteAt 8 LLVM.uintRange_shlNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_shlNswNuw_i8_not_backwardComplete⟩
  , ⟨"Lshr", .incompleteAt 8 LLVM.uintRange_lshr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_lshr_i8_not_backwardComplete⟩
  , ⟨"LshrExact",
      .incompleteAt 8 LLVM.uintRange_lshrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_lshrExact_i8_not_backwardComplete⟩
  , ⟨"Ashr", .incompleteAt 8 LLVM.uintRange_ashr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_ashr_i8_not_backwardComplete⟩
  , ⟨"AshrExact",
      .incompleteAt 8 LLVM.uintRange_ashrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_ashrExact_i8_not_backwardComplete⟩
  , ⟨"SshlSat",
      .incompleteAt 8 LLVM.uintRange_sshlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_sshlSat_i8_not_backwardComplete⟩
  , ⟨"UshlSat",
      .incompleteAt 8 LLVM.uintRange_ushlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.uintRange_ushlSat_i8_not_backwardComplete⟩
  , ⟨"ICmpEq", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpEq : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpEq_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpEq_i8_not_backwardComplete⟩
  , ⟨"ICmpNe", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpNe : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpNe_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpNe_i8_not_backwardComplete⟩
  , ⟨"ICmpSlt", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpSlt_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpSlt_i8_not_backwardComplete⟩
  , ⟨"ICmpSle", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpSle_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpSle_i8_not_backwardComplete⟩
  , ⟨"ICmpSgt", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpSgt_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpSgt_i8_not_backwardComplete⟩
  , ⟨"ICmpSge", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpSge_forwardComplete),
      .incompleteAt 8 LLVM.uintRange_icmpSge_i8_not_backwardComplete⟩
  , ⟨"ICmpUlt", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUlt_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUlt_backwardComplete)⟩
  , ⟨"ICmpUle", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUle_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUle_backwardComplete)⟩
  , ⟨"ICmpUgt", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUgt_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUgt_backwardComplete)⟩
  , ⟨"ICmpUge", .complete (claim := ∀ n,
        BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUge_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
          (UIntRange.domain 1) (LLVM.icmpUge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.uintRange_icmpUge_backwardComplete)⟩
  , ⟨"Trunc", .incompleteAtWidths 8 4
        LLVM.uintRange_trunc_i8_i4_not_forwardComplete,
      .incompleteAtWidths 8 4
        LLVM.uintRange_trunc_i8_i4_not_backwardComplete⟩
  , ⟨"Zext", .complete LLVM.uintRange_zext_forwardComplete,
      .complete LLVM.uintRange_zext_backwardComplete⟩
  , ⟨"Sext", .incompleteAtWidths 8 16
        LLVM.uintRange_sext_i8_i16_not_forwardComplete,
      .complete LLVM.uintRange_sext_backwardComplete⟩
  , ⟨"ZextBool", .complete LLVM.uintRange_zextBool_forwardComplete,
      .complete LLVM.uintRange_zextBool_backwardComplete⟩
  , ⟨"SextBool", .incompleteAtWidths 1 8
        LLVM.uintRange_sextBool_i1_i8_not_forwardComplete,
      .complete LLVM.uintRange_sextBool_backwardComplete⟩
  , ⟨"TruncToBool",
      .complete LLVM.uintRange_truncToBool_forwardComplete,
      .incompleteAtWidths 8 1
        LLVM.uintRange_truncToBool_i8_i1_not_backwardComplete⟩
  , ⟨"Select", .incompleteAt 8
        LLVM.uintRange_select_i8_not_forwardComplete,
      .complete LLVM.uintRange_select_backwardComplete⟩ ]

def uintRangeStatusTable : String :=
  renderTable uintRangeStatusRows

private def sintRangeStatusRows : List StatusRow :=
  [ ⟨"Abs", .incompleteAt 8 LLVM.sintRange_abs_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_abs_i8_not_backwardComplete⟩
  , ⟨"AbsUndef", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        ForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (LLVM.absUndef : ConcreteOp (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_absUndef_forwardComplete hn),
      .incompleteAt 8 LLVM.sintRange_absUndef_i8_not_backwardComplete⟩
  , ⟨"PopCount",
      .incompleteAt 8 LLVM.sintRange_popCount_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_popCount_i8_not_backwardComplete⟩
  , ⟨"Ctlz", .incompleteAt 8 LLVM.sintRange_ctlz_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_ctlz_i8_not_backwardComplete⟩
  , ⟨"CtlzUndef",
      .incompleteAt 8 LLVM.sintRange_ctlzUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_ctlzUndef_i8_not_backwardComplete⟩
  , ⟨"Cttz", .incompleteAt 8 LLVM.sintRange_cttz_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_cttz_i8_not_backwardComplete⟩
  , ⟨"CttzUndef",
      .incompleteAt 8 LLVM.sintRange_cttzUndef_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_cttzUndef_i8_not_backwardComplete⟩
  , ⟨"Add", .incompleteAt 8 LLVM.sintRange_add_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_add_i8_not_backwardComplete⟩
  , ⟨"AddNsw", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.addNsw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_addNsw_forwardComplete hn),
      .incompleteAt 8 LLVM.sintRange_addNsw_i8_not_backwardComplete⟩
  , ⟨"AddNuw", .incompleteAt 8 LLVM.sintRange_addNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_addNuw_i8_not_backwardComplete⟩
  , ⟨"AddNswNuw",
      .incompleteAt 8 LLVM.sintRange_addNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_addNswNuw_i8_not_backwardComplete⟩
  , ⟨"Sub", .incompleteAt 8 LLVM.sintRange_sub_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_sub_i8_not_backwardComplete⟩
  , ⟨"SubNsw", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.subNsw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_subNsw_forwardComplete hn),
      .incompleteAt 8 LLVM.sintRange_subNsw_i8_not_backwardComplete⟩
  , ⟨"SubNuw", .incompleteAt 8 LLVM.sintRange_subNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_subNuw_i8_not_backwardComplete⟩
  , ⟨"SubNswNuw",
      .incompleteAt 8 LLVM.sintRange_subNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_subNswNuw_i8_not_backwardComplete⟩
  , ⟨"Mul", .incompleteAt 8 LLVM.sintRange_mul_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_mul_i8_not_backwardComplete⟩
  , ⟨"MulNsw", .incompleteAt 8 LLVM.sintRange_mulNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_mulNsw_i8_not_backwardComplete⟩
  , ⟨"MulNuw", .incompleteAt 8 LLVM.sintRange_mulNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_mulNuw_i8_not_backwardComplete⟩
  , ⟨"MulNswNuw",
      .incompleteAt 8 LLVM.sintRange_mulNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_mulNswNuw_i8_not_backwardComplete⟩
  , ⟨"And", .incompleteAt 8 LLVM.sintRange_and_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_and_i8_not_backwardComplete⟩
  , ⟨"Or", .incompleteAt 8 LLVM.sintRange_or_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_or_i8_not_backwardComplete⟩
  , ⟨"OrDisjoint",
      .incompleteAt 8 LLVM.sintRange_orDisjoint_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_orDisjoint_i8_not_backwardComplete⟩
  , ⟨"Xor", .incompleteAt 8 LLVM.sintRange_xor_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_xor_i8_not_backwardComplete⟩
  , ⟨"Umax", .incompleteAt 8 LLVM.sintRange_umax_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_umax_i8_not_backwardComplete⟩
  , ⟨"Umin", .incompleteAt 8 LLVM.sintRange_umin_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_umin_i8_not_backwardComplete⟩
  , ⟨"Smax", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.smax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.sintRange_smax_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.smax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.sintRange_smax_backwardComplete)⟩
  , ⟨"Smin", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.smin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.sintRange_smin_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.smin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ ↦ LLVM.sintRange_smin_backwardComplete)⟩
  , ⟨"SaddSat", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.saddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_saddSat_forwardComplete hn),
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.saddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_saddSat_backwardComplete hn)⟩
  , ⟨"UaddSat",
      .incompleteAt 8 LLVM.sintRange_uaddSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_uaddSat_i8_not_backwardComplete⟩
  , ⟨"SsubSat", .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.ssubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_ssubSat_forwardComplete hn),
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.ssubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_ssubSat_backwardComplete hn)⟩
  , ⟨"UsubSat",
      .incompleteAt 8 LLVM.sintRange_usubSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_usubSat_i8_not_backwardComplete⟩
  , ⟨"SmulSat",
      .incompleteAt 8 LLVM.sintRange_smulSat_i8_not_forwardComplete,
      .complete (claim := ∀ n, LLVM.ValidIntegerWidth n →
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain n)
          (LLVM.smulSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)))
        (fun _ hn ↦ LLVM.sintRange_smulSat_backwardComplete hn)⟩
  , ⟨"UmulSat",
      .incompleteAt 8 LLVM.sintRange_umulSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_umulSat_i8_not_backwardComplete⟩
  , ⟨"Shl", .incompleteAt 8 LLVM.sintRange_shl_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_shl_i8_not_backwardComplete⟩
  , ⟨"ShlNsw", .incompleteAt 8 LLVM.sintRange_shlNsw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_shlNsw_i8_not_backwardComplete⟩
  , ⟨"ShlNuw", .incompleteAt 8 LLVM.sintRange_shlNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_shlNuw_i8_not_backwardComplete⟩
  , ⟨"ShlNswNuw",
      .incompleteAt 8 LLVM.sintRange_shlNswNuw_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_shlNswNuw_i8_not_backwardComplete⟩
  , ⟨"Lshr", .incompleteAt 8 LLVM.sintRange_lshr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_lshr_i8_not_backwardComplete⟩
  , ⟨"LshrExact",
      .incompleteAt 8 LLVM.sintRange_lshrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_lshrExact_i8_not_backwardComplete⟩
  , ⟨"Ashr", .incompleteAt 8 LLVM.sintRange_ashr_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_ashr_i8_not_backwardComplete⟩
  , ⟨"AshrExact",
      .incompleteAt 8 LLVM.sintRange_ashrExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_ashrExact_i8_not_backwardComplete⟩
  , ⟨"SshlSat", .incompleteAt 8 LLVM.sintRange_sshlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_sshlSat_i8_not_backwardComplete⟩
  , ⟨"UshlSat", .incompleteAt 8 LLVM.sintRange_ushlSat_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_ushlSat_i8_not_backwardComplete⟩
  , ⟨"Sdiv", .incompleteAt 8 LLVM.sintRange_sdiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_sdiv_i8_not_backwardComplete⟩
  , ⟨"SdivExact",
      .incompleteAt 8 LLVM.sintRange_sdivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_sdivExact_i8_not_backwardComplete⟩
  , ⟨"Srem", .incompleteAt 8 LLVM.sintRange_srem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_srem_i8_not_backwardComplete⟩
  , ⟨"Udiv", .incompleteAt 8 LLVM.sintRange_udiv_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_udiv_i8_not_backwardComplete⟩
  , ⟨"UdivExact",
      .incompleteAt 8 LLVM.sintRange_udivExact_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_udivExact_i8_not_backwardComplete⟩
  , ⟨"Urem", .incompleteAt 8 LLVM.sintRange_urem_i8_not_forwardComplete,
      .incompleteAt 8 LLVM.sintRange_urem_i8_not_backwardComplete⟩
  , ⟨"ICmpEq", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpEq : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpEq_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpEq_i8_not_backwardComplete⟩
  , ⟨"ICmpNe", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpNe : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpNe_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpNe_i8_not_backwardComplete⟩
  , ⟨"ICmpSlt", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSlt_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSlt_backwardComplete)⟩
  , ⟨"ICmpSle", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSle_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSle_backwardComplete)⟩
  , ⟨"ICmpSgt", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSgt_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSgt_backwardComplete)⟩
  , ⟨"ICmpSge", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSge_forwardComplete),
      .complete (claim := ∀ n,
        BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpSge_backwardComplete)⟩
  , ⟨"ICmpUlt", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpUlt_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpUlt_i8_not_backwardComplete⟩
  , ⟨"ICmpUle", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpUle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpUle_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpUle_i8_not_backwardComplete⟩
  , ⟨"ICmpUgt", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpUgt_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpUgt_i8_not_backwardComplete⟩
  , ⟨"ICmpUge", .complete (claim := ∀ n,
        BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
          (SIntRange.domain 1) (LLVM.icmpUge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)))
        (fun _ ↦ LLVM.sintRange_icmpUge_forwardComplete),
      .incompleteAt 8 LLVM.sintRange_icmpUge_i8_not_backwardComplete⟩
  , ⟨"Trunc", .incompleteAtWidths 8 4
        LLVM.sintRange_trunc_i8_i4_not_forwardComplete,
      .incompleteAtWidths 8 4
        LLVM.sintRange_trunc_i8_i4_not_backwardComplete⟩
  , ⟨"Zext", .incompleteAtWidths 8 16
        LLVM.sintRange_zext_i8_i16_not_forwardComplete,
      .incompleteAtWidths 8 16
        LLVM.sintRange_zext_i8_i16_not_backwardComplete⟩
  , ⟨"Sext", .complete LLVM.sintRange_sext_forwardComplete,
      .complete LLVM.sintRange_sext_backwardComplete⟩
  , ⟨"ZextBool", .complete LLVM.sintRange_zextBool_forwardComplete,
      .complete LLVM.sintRange_zextBool_backwardComplete⟩
  , ⟨"SextBool", .complete LLVM.sintRange_sextBool_forwardComplete,
      .complete LLVM.sintRange_sextBool_backwardComplete⟩
  , ⟨"TruncToBool",
      .complete LLVM.sintRange_truncToBool_forwardComplete,
      .incompleteAtWidths 8 1
        LLVM.sintRange_truncToBool_i8_i1_not_backwardComplete⟩
  , ⟨"Select", .incompleteAt 8
        LLVM.sintRange_select_i8_not_forwardComplete,
      .complete LLVM.sintRange_select_backwardComplete⟩ ]

def sintRangeStatusTable : String :=
  renderTable sintRangeStatusRows

end SynthXfer.Certification

#eval IO.println "\n=== General completeness theory ==="
#eval IO.println "Transport changes only the concrete representation; it preserves completeness."
#eval IO.println "Witness theorems turn concrete precision failures into incompleteness proofs.\n"

#print axioms SynthXfer.forwardComplete_transport_iff
#print axioms SynthXfer.backwardComplete_transport_iff
#print axioms SynthXfer.naryForwardComplete_transport_iff
#print axioms SynthXfer.naryBackwardComplete_transport_iff
#print axioms SynthXfer.backwardIncomplete_of_witness
#print axioms SynthXfer.naryBackwardIncomplete_of_witness

#eval IO.println "\n=== Interval completeness theory ==="
#eval IO.println "These theorems characterize completeness using interval endpoints and corners.\n"

#print axioms SynthXfer.IntervalDomain.backwardComplete_iff_boundedByEndpointResults
#print axioms SynthXfer.IntervalDomain.naryBackwardComplete_iff_boundedByCornerResults

#eval IO.println "\n=== KnownBits completeness theory ==="
#eval IO.println "Forward: represented input boxes must produce a represented output set."
#eval IO.println "Backward: every output-observation failure fiber must be KnownBits-representable.\n"

#print axioms SynthXfer.KnownBits.forwardComplete_iff_preservesKnownBitsSets
#print axioms SynthXfer.KnownBits.backwardComplete_iff_observationFibersRepresentable
#print axioms SynthXfer.KnownBits.forwardCompleteNary_iff_preservesKnownBitsSets
#print axioms SynthXfer.KnownBits.backwardCompleteNary_iff_observationFibersRepresentable

#eval IO.println "\n=== Certified KnownBits operation statuses ==="
#eval IO.println "Every displayed classification is generated from a Lean value containing its proof."
#eval IO.println "A question mark means that no classification has been entered yet.\n"


#eval IO.println ("\n" ++ SynthXfer.Certification.knownBitsStatusTable)

#eval IO.println "\n=== Certified UIntRange operation statuses ==="
#eval IO.println "Complete means proved for every positive bit width; incomplete rows carry an i8 counterexample."
#eval IO.println "Every displayed classification is generated from a Lean value containing its proof.\n"

#eval IO.println ("\n" ++ SynthXfer.Certification.uintRangeStatusTable)

#eval IO.println "\n=== Certified SIntRange operation statuses ==="
#eval IO.println "Complete means proved for every positive bit width; incomplete rows carry an i8 counterexample."
#eval IO.println "Every displayed classification is generated from a Lean value containing its proof.\n"

#eval IO.println ("\n" ++ SynthXfer.Certification.sintRangeStatusTable)
