import SynthXfer.KnownBits.Witnesses
import SynthXfer.LLVMOps

/-!
# Completeness of LLVM operations in KnownBits

Proofs and concrete counterexamples classifying the operations from
`SynthXfer.LLVMOps` under the KnownBits abstract domain.
-/

namespace SynthXfer


namespace LLVM

private def binaryRelationalBoolModel {n m : Nat}
    (f : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec m)) :
    BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector m) :=
  fun x y ↦ (boolVectorEquivBitVec m).symm ''
    f x.toBitVec y.toBitVec

private theorem relationalBoolModel_ofOption_eq_singleton {n m : Nat}
    (f : BitVec n → Option (BitVec m)) (x : BoolVector n)
    (out : BoolVector m) (h : f x.toBitVec = some out.toBitVec) :
    KnownBits.relationalBoolModel (ConcreteOp.ofOption f) x = {out} := by
  have hout : BoolVector.ofBitVec out.toBitVec = out :=
    (boolVectorEquivBitVec m).left_inv out
  ext z
  simp [KnownBits.relationalBoolModel, ConcreteOp.transport,
    boolVectorEquivBitVec, h, hout]

private theorem binaryRelationalBoolModel_ofOption_eq_singleton {n m : Nat}
    (f : BitVec n → BitVec n → Option (BitVec m))
    (x y : BoolVector n) (out : BoolVector m)
    (h : f x.toBitVec y.toBitVec = some out.toBitVec) :
    binaryRelationalBoolModel (BinaryConcreteOp.ofOption f) x y = {out} := by
  have hout : BoolVector.ofBitVec out.toBitVec = out :=
    (boolVectorEquivBitVec m).left_inv out
  ext z
  simp [binaryRelationalBoolModel, boolVectorEquivBitVec, h, hout]

private theorem binaryRelationalBoolModel_ofOption_eq_empty {n m : Nat}
    (f : BitVec n → BitVec n → Option (BitVec m))
    (x y : BoolVector n) (h : f x.toBitVec y.toBitVec = none) :
    binaryRelationalBoolModel (BinaryConcreteOp.ofOption f) x y = ∅ := by
  ext z
  simp [binaryRelationalBoolModel, boolVectorEquivBitVec, h]

private theorem binaryForwardComplete_iff_boolModel {n m : Nat}
    (f : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec m)) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
        (KnownBits.domain m) f ↔
      BinaryForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain n)
        (KnownBits.boolDomain m) (binaryRelationalBoolModel f) := by
  calc
    _ ↔ NaryForwardComplete (fun _ : BinaryOperand ↦ KnownBits.domain n)
        (KnownBits.domain m) f.asNary :=
      SynthXfer.binaryForwardComplete_iff_nary
        (KnownBits.domain n) (KnownBits.domain m) f
    _ ↔ NaryForwardComplete (fun _ : BinaryOperand ↦ KnownBits.boolDomain n)
        (KnownBits.boolDomain m)
        (NaryConcreteOp.transport
          (fun _ ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary) := by
      simpa [KnownBits.domain] using
        (naryForwardComplete_transport_iff
          (fun _ : BinaryOperand ↦ KnownBits.boolDomain n)
          (KnownBits.boolDomain m)
          (fun _ ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary)
    _ ↔ _ := by
      have hop : NaryConcreteOp.transport
          (fun _ : BinaryOperand ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary =
          (binaryRelationalBoolModel f).asNary := by
        rfl
      rw [hop]
      exact (SynthXfer.binaryForwardComplete_iff_nary
        (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (binaryRelationalBoolModel f)).symm

private theorem binaryBackwardComplete_iff_boolModel {n m : Nat}
    (f : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec m)) :
    BinaryBackwardComplete (KnownBits.domain n) (KnownBits.domain n)
        (KnownBits.domain m) f ↔
      BinaryBackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain n)
        (KnownBits.boolDomain m) (binaryRelationalBoolModel f) := by
  calc
    _ ↔ NaryBackwardComplete (fun _ : BinaryOperand ↦ KnownBits.domain n)
        (KnownBits.domain m) f.asNary :=
      SynthXfer.binaryBackwardComplete_iff_nary
        (KnownBits.domain n) (KnownBits.domain m) f
    _ ↔ NaryBackwardComplete (fun _ : BinaryOperand ↦ KnownBits.boolDomain n)
        (KnownBits.boolDomain m)
        (NaryConcreteOp.transport
          (fun _ ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary) := by
      simpa [KnownBits.domain] using
        (naryBackwardComplete_transport_iff
          (fun _ : BinaryOperand ↦ KnownBits.boolDomain n)
          (KnownBits.boolDomain m)
          (fun _ ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary)
    _ ↔ _ := by
      have hop : NaryConcreteOp.transport
          (fun _ : BinaryOperand ↦ (boolVectorEquivBitVec n).symm)
          (boolVectorEquivBitVec m).symm f.asNary =
          (binaryRelationalBoolModel f).asNary := by
        rfl
      rw [hop]
      exact (SynthXfer.binaryBackwardComplete_iff_nary
        (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (binaryRelationalBoolModel f)).symm

private def boolVector8 (value : BitVec 8) : BoolVector 8 :=
  BoolVector.ofBitVec value

@[simp]
private theorem boolVector8_toBitVec (value : BitVec 8) :
    (boolVector8 value).toBitVec = value := by
  exact (boolVectorEquivBitVec 8).right_inv value

private theorem partialBinaryLeftCollision_i8
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (x y out outJ outL : BitVec 8)
    (j l forwardBit forwardBit' backwardBit : Fin 8)
    (hjl : j ≠ l) (hforwardBits : forwardBit ≠ forwardBit')
    (hbase : f (boolVector8 x).toBitVec (boolVector8 y).toBitVec =
      some (boolVector8 out).toBitVec)
    (hj : f (BitDependency.toggle (boolVector8 x) j).toBitVec
      (boolVector8 y).toBitVec = some (boolVector8 outJ).toBitVec)
    (hl : f (BitDependency.toggle (boolVector8 x) l).toBitVec
      (boolVector8 y).toBitVec = some (boolVector8 outL).toBitVec)
    (hforward : boolVector8 out forwardBit ≠ boolVector8 outJ forwardBit)
    (hforward' : boolVector8 out forwardBit' ≠
      boolVector8 outJ forwardBit')
    (hbackwardJ : boolVector8 out backwardBit ≠
      boolVector8 outJ backwardBit)
    (hbackwardL : boolVector8 out backwardBit ≠
      boolVector8 outL backwardBit) :
    (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f)) ∧
      ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  constructor
  · rw [binaryForwardComplete_iff_boolModel]
    exact BitDependency.binaryRelationalForwardIncomplete_of_localCollision
      (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
      (boolVector8 x) (boolVector8 y) j (boolVector8 out) (boolVector8 outJ)
      forwardBit forwardBit' hforwardBits
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (boolVector8 y) (boolVector8 out) hbase)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (BitDependency.toggle (boolVector8 x) j) (boolVector8 y)
          (boolVector8 outJ) hj) hforward hforward'
  · rw [binaryBackwardComplete_iff_boolModel]
    exact BitDependency.binaryRelationalBackwardIncomplete_of_localCollision
      (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
      (boolVector8 x) (boolVector8 y) j l hjl
      (boolVector8 out) (boolVector8 outJ) (boolVector8 outL) backwardBit
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (boolVector8 y) (boolVector8 out) hbase)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (BitDependency.toggle (boolVector8 x) j) (boolVector8 y)
          (boolVector8 outJ) hj)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (BitDependency.toggle (boolVector8 x) l) (boolVector8 y)
          (boolVector8 outL) hl) hbackwardJ hbackwardL

private theorem partialBinaryRightCollision_i8
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (x y out outJ outL : BitVec 8)
    (j l forwardBit forwardBit' backwardBit : Fin 8)
    (hjl : j ≠ l) (hforwardBits : forwardBit ≠ forwardBit')
    (hbase : f (boolVector8 x).toBitVec (boolVector8 y).toBitVec =
      some (boolVector8 out).toBitVec)
    (hj : f (boolVector8 x).toBitVec
      (BitDependency.toggle (boolVector8 y) j).toBitVec =
      some (boolVector8 outJ).toBitVec)
    (hl : f (boolVector8 x).toBitVec
      (BitDependency.toggle (boolVector8 y) l).toBitVec =
      some (boolVector8 outL).toBitVec)
    (hforward : boolVector8 out forwardBit ≠ boolVector8 outJ forwardBit)
    (hforward' : boolVector8 out forwardBit' ≠
      boolVector8 outJ forwardBit')
    (hbackwardJ : boolVector8 out backwardBit ≠
      boolVector8 outJ backwardBit)
    (hbackwardL : boolVector8 out backwardBit ≠
      boolVector8 outL backwardBit) :
    (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f)) ∧
      ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  constructor
  · rw [binaryForwardComplete_iff_boolModel]
    exact BitDependency.binaryRelationalForwardIncomplete_of_rightLocalCollision
      (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
      (boolVector8 x) (boolVector8 y) j (boolVector8 out) (boolVector8 outJ)
      forwardBit forwardBit' hforwardBits
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (boolVector8 y) (boolVector8 out) hbase)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (BitDependency.toggle (boolVector8 y) j)
          (boolVector8 outJ) hj) hforward hforward'
  · rw [binaryBackwardComplete_iff_boolModel]
    exact BitDependency.binaryRelationalBackwardIncomplete_of_rightLocalCollision
      (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
      (boolVector8 x) (boolVector8 y) j l hjl
      (boolVector8 out) (boolVector8 outJ) (boolVector8 outL) backwardBit
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (boolVector8 y) (boolVector8 out) hbase)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (BitDependency.toggle (boolVector8 y) j)
          (boolVector8 outJ) hj)
      (binaryRelationalBoolModel_ofOption_eq_singleton
        f (boolVector8 x) (BitDependency.toggle (boolVector8 y) l)
          (boolVector8 outL) hl) hbackwardJ hbackwardL

/-- Concrete data witnessing both KnownBits completeness failures for a
partial binary i8 operation. The selected operand is the one whose bits are
toggled; the other operand is held fixed. -/
private structure PartialBinaryCollisionI8
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8)) where
  operand : BinaryOperand
  left : BitVec 8
  right : BitVec 8
  output : BitVec 8
  toggledOutput : BitVec 8
  otherToggledOutput : BitVec 8
  toggledBit : Fin 8
  otherToggledBit : Fin 8
  forwardOutputBit : Fin 8
  otherForwardOutputBit : Fin 8
  backwardOutputBit : Fin 8
  inputBits_ne : toggledBit ≠ otherToggledBit
  outputBits_ne : forwardOutputBit ≠ otherForwardOutputBit
  base_defined : f left right = some output
  toggled_defined :
    (if operand = BinaryOperand.left then
      f (BitDependency.toggle (boolVector8 left) toggledBit).toBitVec right
    else
      f left (BitDependency.toggle (boolVector8 right) toggledBit).toBitVec) =
        some toggledOutput
  other_toggled_defined :
    (if operand = BinaryOperand.left then
      f (BitDependency.toggle (boolVector8 left) otherToggledBit).toBitVec right
    else
      f left (BitDependency.toggle (boolVector8 right) otherToggledBit).toBitVec) =
        some otherToggledOutput
  forward_changes :
    boolVector8 output forwardOutputBit ≠
      boolVector8 toggledOutput forwardOutputBit
  other_forward_changes :
    boolVector8 output otherForwardOutputBit ≠
      boolVector8 toggledOutput otherForwardOutputBit
  backward_changes :
    boolVector8 output backwardOutputBit ≠
      boolVector8 toggledOutput backwardOutputBit
  other_backward_changes :
    boolVector8 output backwardOutputBit ≠
      boolVector8 otherToggledOutput backwardOutputBit

private theorem PartialBinaryCollisionI8.incomplete
    {f : BitVec 8 → BitVec 8 → Option (BitVec 8)}
    (w : PartialBinaryCollisionI8 f) :
    (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f)) ∧
      ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  by_cases hleft : w.operand = BinaryOperand.left
  · exact partialBinaryLeftCollision_i8 f
      w.left w.right w.output w.toggledOutput w.otherToggledOutput
      w.toggledBit w.otherToggledBit w.forwardOutputBit
      w.otherForwardOutputBit w.backwardOutputBit
      w.inputBits_ne w.outputBits_ne (by simpa using w.base_defined)
      (by simpa [hleft] using w.toggled_defined)
      (by simpa [hleft] using w.other_toggled_defined)
      w.forward_changes w.other_forward_changes w.backward_changes
      w.other_backward_changes
  · have hright : w.operand = BinaryOperand.right := by
      apply Fin.ext
      change w.operand.val = 1
      have hval : w.operand.val ≠ 0 := by
        intro hzero
        apply hleft
        apply Fin.ext
        exact hzero
      have hlt := w.operand.isLt
      omega
    exact partialBinaryRightCollision_i8 f
      w.left w.right w.output w.toggledOutput w.otherToggledOutput
      w.toggledBit w.otherToggledBit w.forwardOutputBit
      w.otherForwardOutputBit w.backwardOutputBit
      w.inputBits_ne w.outputBits_ne (by simpa using w.base_defined)
      (by simpa [hright] using w.toggled_defined)
      (by simpa [hright] using w.other_toggled_defined)
      w.forward_changes w.other_forward_changes w.backward_changes
      w.other_backward_changes

private abbrev BinaryIncompleteAtI8
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) : Prop :=
  (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) f) ∧
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) f

private theorem unary_dependency_of_witness
    {m : Nat} (f : BitVec 8 → BitVec m)
    (outputBit : Fin m) (inputBit : Fin 8)
    (input : BoolVector 8)
    (hchanges : BoolVector.ofBitVecUnaryOp f input outputBit ≠
      BoolVector.ofBitVecUnaryOp f (BitDependency.toggle input inputBit)
        outputBit) :
    inputBit ∈ BitDependency.dependencies
      (BoolVector.ofBitVecUnaryOp f) outputBit :=
  ⟨input, hchanges⟩

private def binaryInputs8 (lhs rhs : BitVec 8) : BinaryOperand → BoolVector 8 :=
  fun k ↦ if k = BinaryOperand.left then boolVector8 lhs else boolVector8 rhs

private theorem binary_dependencyAt_of_witness
    {m : Nat} (f : BitVec 8 → BitVec 8 → BitVec m)
    (operand : BinaryOperand) (outputBit : Fin m) (inputBit : Fin 8)
    (inputs : BinaryOperand → BoolVector 8)
    (hchanges : BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f)
        inputs outputBit ≠
      BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f)
        (BitDependency.toggleOperand inputs operand inputBit) outputBit) :
    inputBit ∈ BitDependency.dependenciesAt
      (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
      operand outputBit :=
  ⟨inputs, hchanges⟩

private theorem binary_slice_dependency_of_witness
    {m : Nat} (f : BitVec 8 → BitVec 8 → BitVec m)
    (operand : BinaryOperand) (context : BinaryOperand → BoolVector 8)
    (outputBit : Fin m) (inputBit : Fin 8) (input : BoolVector 8)
    (hchanges : BitDependency.sliceAt
        (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
        operand context input outputBit ≠
      BitDependency.sliceAt
        (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
        operand context (BitDependency.toggle input inputBit) outputBit) :
    inputBit ∈ BitDependency.dependencies
      (BitDependency.sliceAt
        (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
      operand context) outputBit :=
  ⟨input, hchanges⟩

private def truncSource {n m : Nat} (hmn : m < n) (i : Fin m) :
    Option (Fin n) :=
  some ⟨i, Nat.lt_trans i.isLt hmn⟩

private def extensionSource (n : Nat) (i : Fin m) : Option (Fin n) :=
  if hi : i < n then some ⟨i, hi⟩ else none

private def signExtensionSource {n : Nat} (hn : 0 < n) (i : Fin m) :
    Option (Fin n) :=
  if hi : i < n then some ⟨i, hi⟩ else some ⟨n - 1, by omega⟩

private theorem trunc_coordinate {n m : Nat} (hmn : m < n)
    (x : BoolVector n) (i : Fin m) :
    BoolVector.ofBitVecUnaryOp (BitVec.setWidth m) x i =
      match truncSource hmn i with
      | some j => x j
      | none => false := by
  change (BitVec.setWidth m x.toBitVec).getLsbD i = x _
  rw [BitVec.getLsbD_setWidth]
  simp only [i.isLt, decide_true, Bool.true_and]
  have hget := BoolVector.toBitVec_getLsb x
    ⟨i, Nat.lt_trans i.isLt hmn⟩
  simpa [BitVec.getLsbD, BitVec.getLsb] using hget

private theorem zext_coordinate {n m : Nat} (x : BoolVector n) (i : Fin m) :
    BoolVector.ofBitVecUnaryOp (BitVec.setWidth m) x i =
      match extensionSource n i with
      | some j => x j
      | none => false := by
  change (BitVec.setWidth m x.toBitVec).getLsbD i = _
  rw [BitVec.getLsbD_setWidth]
  simp only [i.isLt, decide_true, Bool.true_and]
  by_cases hi : (i : Nat) < n
  · rw [show extensionSource n i = some ⟨i, hi⟩ by simp [extensionSource, hi]]
    have hget := BoolVector.toBitVec_getLsb x ⟨i, hi⟩
    simpa [BitVec.getLsbD, BitVec.getLsb] using hget
  · rw [show extensionSource n i = none by simp [extensionSource, hi]]
    exact BitVec.getLsbD_of_ge x.toBitVec i (Nat.le_of_not_gt hi)

private theorem sext_coordinate {n m : Nat} (hn : 0 < n)
    (x : BoolVector n) (i : Fin m) :
    BoolVector.ofBitVecUnaryOp (BitVec.signExtend m) x i =
      match signExtensionSource hn i with
      | some j => x j
      | none => false := by
  change (BitVec.signExtend m x.toBitVec).getLsbD i = _
  rw [BitVec.getLsbD_signExtend]
  simp only [i.isLt, decide_true, Bool.true_and]
  by_cases hi : (i : Nat) < n
  · rw [if_pos hi]
    rw [show signExtensionSource hn i = some ⟨i, hi⟩ by
      simp [signExtensionSource, hi]]
    have hget := BoolVector.toBitVec_getLsb x ⟨i, hi⟩
    simpa [BitVec.getLsbD, BitVec.getLsb] using hget
  · rw [if_neg hi]
    rw [show signExtensionSource hn i = some ⟨n - 1, by omega⟩ by
      simp [signExtensionSource, hi]]
    rw [BitVec.msb, BitVec.getMsbD_eq_getLsbD]
    simp only [hn, decide_true, Bool.true_and, Nat.sub_zero]
    have hget := BoolVector.toBitVec_getLsb x ⟨n - 1, by omega⟩
    simpa [BitVec.getLsbD, BitVec.getLsb] using hget

/-! ## Width-changing casts -/

theorem knownBits_trunc_forwardComplete (n m : Nat)
    (hwidths : ValidTruncWidths n m) :
    ForwardComplete (KnownBits.domain n) (KnownBits.domain m) (trunc n m) := by
  change KnownBits.UnaryForwardComplete (BitVec.setWidth m : BitVec n → BitVec m)
  apply BitDependency.unaryForwardComplete_of_injectiveCoordinateMap
    (BitVec.setWidth m) (truncSource hwidths.2) (fun _ ↦ false)
  · exact trunc_coordinate hwidths.2
  · intro i l j hi hl
    simp only [truncSource, Option.some.injEq] at hi hl
    apply Fin.ext
    exact congrArg (fun q : Fin n ↦ q.val) (hi.trans hl.symm)

theorem knownBits_trunc_backwardComplete (n m : Nat)
    (hwidths : ValidTruncWidths n m) :
    BackwardComplete (KnownBits.domain n) (KnownBits.domain m) (trunc n m) := by
  change KnownBits.UnaryBackwardComplete (BitVec.setWidth m : BitVec n → BitVec m)
  exact BitDependency.unaryBackwardComplete_of_coordinateMap
    (BitVec.setWidth m) (truncSource hwidths.2) (fun _ ↦ false)
    (trunc_coordinate hwidths.2)

theorem knownBits_zext_forwardComplete (n m : Nat)
    (_hwidths : ValidExtensionWidths n m) :
    ForwardComplete (KnownBits.domain n) (KnownBits.domain m) (zext n m) := by
  change KnownBits.UnaryForwardComplete (BitVec.setWidth m : BitVec n → BitVec m)
  apply BitDependency.unaryForwardComplete_of_injectiveCoordinateMap
    (BitVec.setWidth m) (extensionSource n) (fun _ ↦ false)
  · exact zext_coordinate
  · intro i l j hi hl
    by_cases hii : (i : Nat) < n
    · by_cases hll : (l : Nat) < n
      · simp [extensionSource, hii, hll] at hi hl
        apply Fin.ext
        exact congrArg (fun q : Fin n ↦ q.val) (hi.trans hl.symm)
      · simp [extensionSource, hll] at hl
    · simp [extensionSource, hii] at hi

theorem knownBits_zext_backwardComplete (n m : Nat)
    (_hwidths : ValidExtensionWidths n m) :
    BackwardComplete (KnownBits.domain n) (KnownBits.domain m) (zext n m) := by
  change KnownBits.UnaryBackwardComplete (BitVec.setWidth m : BitVec n → BitVec m)
  exact BitDependency.unaryBackwardComplete_of_coordinateMap
    (BitVec.setWidth m) (extensionSource n) (fun _ ↦ false) zext_coordinate

theorem knownBits_sext_backwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    BackwardComplete (KnownBits.domain n) (KnownBits.domain m) (sext n m) := by
  change KnownBits.UnaryBackwardComplete (BitVec.signExtend m : BitVec n → BitVec m)
  exact BitDependency.unaryBackwardComplete_of_coordinateMap
    (BitVec.signExtend m) (signExtensionSource hwidths.1) (fun _ ↦ false)
    (sext_coordinate hwidths.1)

theorem knownBits_sext_i8_i16_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 16) (sext 8 16) := by
  change ¬ KnownBits.UnaryForwardComplete
    (BitVec.signExtend 16 : BitVec 8 → BitVec 16)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    (BitVec.signExtend 16) (8 : Fin 16) (9 : Fin 16) (by decide) (7 : Fin 8)
  · exact unary_dependency_of_witness (BitVec.signExtend 16) 8 7
      (boolVector8 0) (by decide)
  · exact unary_dependency_of_witness (BitVec.signExtend 16) 9 7
      (boolVector8 0) (by decide)

theorem knownBits_zextBool_forwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    ForwardComplete (KnownBits.domain 1) (KnownBits.domain n)
      (zextBool n) := by
  simpa [zextBool] using knownBits_zext_forwardComplete 1 n hwidths

theorem knownBits_zextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (KnownBits.domain 1) (KnownBits.domain n)
      (zextBool n) := by
  simpa [zextBool] using knownBits_zext_backwardComplete 1 n hwidths

theorem knownBits_sextBool_i1_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 1) (KnownBits.domain 8)
      (sextBool 8) := by
  change ¬ KnownBits.UnaryForwardComplete
    (BitVec.signExtend 8 : BitVec 1 → BitVec 8)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    (BitVec.signExtend 8) (1 : Fin 8) (2 : Fin 8) (by decide) (0 : Fin 1)
  · exact ⟨fun _ ↦ false, by decide⟩
  · exact ⟨fun _ ↦ false, by decide⟩

theorem knownBits_sextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (KnownBits.domain 1) (KnownBits.domain n)
      (sextBool n) := by
  simpa [sextBool] using knownBits_sext_backwardComplete 1 n hwidths

theorem knownBits_truncToBool_forwardComplete (n : Nat)
    (hwidths : ValidTruncWidths n 1) :
    ForwardComplete (KnownBits.domain n) (KnownBits.domain 1)
      (truncToBool n) := by
  simpa [truncToBool] using knownBits_trunc_forwardComplete n 1 hwidths

theorem knownBits_truncToBool_backwardComplete (n : Nat)
    (hwidths : ValidTruncWidths n 1) :
    BackwardComplete (KnownBits.domain n) (KnownBits.domain 1)
      (truncToBool n) := by
  simpa [truncToBool] using knownBits_trunc_backwardComplete n 1 hwidths

/-! ## Select -/

private def selectInputs8 :
    (operand : SelectOperand) → BoolVector (operand.width 8)
  | .condition => fun _ ↦ false
  | .trueValue => boolVector8 3
  | .falseValue => boolVector8 0

private theorem select_condition_dependency_bit0_i8 :
    (0 : Fin 1) ∈ BitDependency.dependenciesAt
      (BoolVector.ofBitVecNaryOp (selectFn (n := 8)))
      SelectOperand.condition (0 : Fin 8) := by
  rw [BitDependency.mem_dependenciesAt_iff]
  exact ⟨selectInputs8, by decide⟩

private theorem select_condition_dependency_bit1_i8 :
    (0 : Fin 1) ∈ BitDependency.dependenciesAt
      (BoolVector.ofBitVecNaryOp (selectFn (n := 8)))
      SelectOperand.condition (1 : Fin 8) := by
  rw [BitDependency.mem_dependenciesAt_iff]
  exact ⟨selectInputs8, by decide⟩

theorem knownBits_select_i8_not_forwardComplete :
    ¬ NaryForwardComplete
      (fun operand : SelectOperand ↦ KnownBits.domain (operand.width 8))
      (KnownBits.domain 8) (select (n := 8)) := by
  change ¬ KnownBits.ForwardCompleteNary (selectFn (n := 8))
  rw [BitDependency.forwardCompleteNary_iff_pairwiseDisjointDependencies]
  intro hdisjoint
  have hbits := hdisjoint SelectOperand.condition
    (0 : Fin 8) (1 : Fin 8) (by decide)
  rw [Set.disjoint_left] at hbits
  exact hbits select_condition_dependency_bit0_i8
    select_condition_dependency_bit1_i8

theorem knownBits_select_backwardComplete (n : Nat) :
    NaryBackwardComplete
      (fun operand : SelectOperand ↦ KnownBits.domain (operand.width n))
      (KnownBits.domain n) (select (n := n)) := by
  change KnownBits.BackwardCompleteNary (selectFn (n := n))
  rw [BitDependency.backwardCompleteNary_iff_contextwiseAtMostOneDependency]
  intro operand context i
  cases operand with
  | condition =>
      intro j _ l _
      exact Subsingleton.elim j l
  | trueValue =>
      intro j hj l hl
      have dependency_eq (q : Fin n)
          (hq : q ∈ BitDependency.dependencies
            (BitDependency.sliceAt
              (BoolVector.ofBitVecNaryOp (selectFn (n := n)))
              SelectOperand.trueValue context) i) : q = i := by
        rw [BitDependency.mem_dependencies_iff] at hq
        obtain ⟨value, hvalue⟩ := hq
        by_contra hqi
        apply hvalue
        by_cases hcondition :
            (context SelectOperand.condition).toBitVec == (1 : BitVec 1)
        · have hcondition' :
              (context SelectOperand.condition).toBitVec = (1 : BitVec 1) := by
            simpa using hcondition
          have heq : value i = BitDependency.toggle value q i := by
            simp [BitDependency.toggle, BitDependency.toggleIndex, Ne.symm hqi]
          have hbit : value.toBitVec[i.val] =
              (BitDependency.toggle value q).toBitVec[i.val] := by
            rw [show value.toBitVec[i.val] = value i from
                BoolVector.toBitVec_getLsb value i,
              show (BitDependency.toggle value q).toBitVec[i.val] =
                  BitDependency.toggle value q i from
                BoolVector.toBitVec_getLsb (BitDependency.toggle value q) i]
            exact heq
          simpa [BitDependency.sliceAt, BoolVector.ofBitVecNaryOp,
            selectFn, hcondition, hcondition'] using hbit
        · have hcondition' :
              (context SelectOperand.condition).toBitVec ≠ (1 : BitVec 1) := by
            simpa using hcondition
          suffices
              (if (context SelectOperand.condition).toBitVec = (1 : BitVec 1)
                  then value.toBitVec
                  else (context SelectOperand.falseValue).toBitVec)[i.val] =
                (if (context SelectOperand.condition).toBitVec = (1 : BitVec 1)
                  then (BitDependency.toggle value q).toBitVec
                  else (context SelectOperand.falseValue).toBitVec)[i.val] by
            simpa [BitDependency.sliceAt, BoolVector.ofBitVecNaryOp, selectFn]
          rw [if_neg hcondition', if_neg hcondition']
      exact (dependency_eq j hj).trans (dependency_eq l hl).symm
  | falseValue =>
      intro j hj l hl
      have dependency_eq (q : Fin n)
          (hq : q ∈ BitDependency.dependencies
            (BitDependency.sliceAt
              (BoolVector.ofBitVecNaryOp (selectFn (n := n)))
              SelectOperand.falseValue context) i) : q = i := by
        rw [BitDependency.mem_dependencies_iff] at hq
        obtain ⟨value, hvalue⟩ := hq
        by_contra hqi
        apply hvalue
        by_cases hcondition :
            (context SelectOperand.condition).toBitVec == (1 : BitVec 1)
        · have hcondition' :
              (context SelectOperand.condition).toBitVec = (1 : BitVec 1) := by
            simpa using hcondition
          simp [BitDependency.sliceAt, BoolVector.ofBitVecNaryOp,
            selectFn, hcondition']
        · have hcondition' :
              (context SelectOperand.condition).toBitVec ≠ (1 : BitVec 1) := by
            simpa using hcondition
          have heq : value i = BitDependency.toggle value q i := by
            simp [BitDependency.toggle, BitDependency.toggleIndex, Ne.symm hqi]
          have hbit : value.toBitVec[i.val] =
              (BitDependency.toggle value q).toBitVec[i.val] := by
            rw [show value.toBitVec[i.val] = value i from
                BoolVector.toBitVec_getLsb value i,
              show (BitDependency.toggle value q).toBitVec[i.val] =
                  BitDependency.toggle value q i from
                BoolVector.toBitVec_getLsb (BitDependency.toggle value q) i]
            exact heq
          suffices
              (if (context SelectOperand.condition).toBitVec = (1 : BitVec 1)
                  then (context SelectOperand.trueValue).toBitVec
                  else value.toBitVec)[i.val] =
                (if (context SelectOperand.condition).toBitVec = (1 : BitVec 1)
                  then (context SelectOperand.trueValue).toBitVec
                  else (BitDependency.toggle value q).toBitVec)[i.val] by
            simpa [BitDependency.sliceAt, BoolVector.ofBitVecNaryOp, selectFn]
          rw [if_neg hcondition', if_neg hcondition']
          exact hbit
      exact (dependency_eq j hj).trans (dependency_eq l hl).symm

/-! ## Unary counterexamples -/

theorem knownBits_abs_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (abs : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryForwardComplete (BitVec.abs : BitVec 8 → BitVec 8)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    BitVec.abs (1 : Fin 8) (2 : Fin 8) (by decide) (7 : Fin 8)
  · exact unary_dependency_of_witness BitVec.abs 1 7 (boolVector8 1) (by decide)
  · exact unary_dependency_of_witness BitVec.abs 2 7 (boolVector8 1) (by decide)

theorem knownBits_abs_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (abs : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryBackwardComplete (BitVec.abs : BitVec 8 → BitVec 8)
  apply BitDependency.unaryBackwardIncomplete_of_dependencyCollision
    BitVec.abs (1 : Fin 8) (1 : Fin 8) (7 : Fin 8) (by decide)
  · exact unary_dependency_of_witness BitVec.abs 1 1 (boolVector8 1) (by decide)
  · exact unary_dependency_of_witness BitVec.abs 1 7 (boolVector8 1) (by decide)

theorem knownBits_absUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.forwardComplete_iff_preservesKnownBitsSets]
  rw [← BitDependency.boolForwardComplete_iff_preservesKnownBitsSets]
  apply BitDependency.unaryRelationalForwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 1) (7 : Fin 8) (boolVector8 1) (boolVector8 127)
    (1 : Fin 8) (2 : Fin 8) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      absUndef? (boolVector8 1) (boolVector8 1) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      absUndef? (BitDependency.toggle (boolVector8 1) 7)
        (boolVector8 127) (by decide)
  · decide
  · decide

theorem knownBits_absUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.backwardComplete_iff_observationFibersRepresentable]
  rw [← BitDependency.boolBackwardComplete_iff_observationFibersRepresentable]
  apply BitDependency.unaryRelationalBackwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 1) (1 : Fin 8) (7 : Fin 8) (by decide)
    (boolVector8 1) (boolVector8 3) (boolVector8 127) (1 : Fin 8)
  · exact relationalBoolModel_ofOption_eq_singleton
      absUndef? (boolVector8 1) (boolVector8 1) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      absUndef? (BitDependency.toggle (boolVector8 1) 1)
        (boolVector8 3) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      absUndef? (BitDependency.toggle (boolVector8 1) 7)
        (boolVector8 127) (by decide)
  · decide
  · decide

theorem knownBits_popCount_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryForwardComplete (BitVec.cpop : BitVec 8 → BitVec 8)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    BitVec.cpop (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact unary_dependency_of_witness BitVec.cpop 0 0 (boolVector8 2) (by decide)
  · exact unary_dependency_of_witness BitVec.cpop 1 0 (boolVector8 2) (by decide)

theorem knownBits_popCount_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryBackwardComplete (BitVec.cpop : BitVec 8 → BitVec 8)
  apply BitDependency.unaryBackwardIncomplete_of_dependencyCollision
    BitVec.cpop (0 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact unary_dependency_of_witness BitVec.cpop 0 0 (boolVector8 2) (by decide)
  · exact unary_dependency_of_witness BitVec.cpop 0 1 (boolVector8 2) (by decide)

theorem knownBits_ctlz_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (ctlz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryForwardComplete (BitVec.clz : BitVec 8 → BitVec 8)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    BitVec.clz (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact unary_dependency_of_witness BitVec.clz 0 0 (boolVector8 0) (by decide)
  · exact unary_dependency_of_witness BitVec.clz 1 0 (boolVector8 0) (by decide)

theorem knownBits_ctlz_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (ctlz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryBackwardComplete (BitVec.clz : BitVec 8 → BitVec 8)
  apply BitDependency.unaryBackwardIncomplete_of_dependencyCollision
    BitVec.clz (0 : Fin 8) (0 : Fin 8) (2 : Fin 8) (by decide)
  · exact unary_dependency_of_witness BitVec.clz 0 0 (boolVector8 0) (by decide)
  · exact unary_dependency_of_witness BitVec.clz 0 2 (boolVector8 0) (by decide)

theorem knownBits_cttz_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryForwardComplete (BitVec.ctz : BitVec 8 → BitVec 8)
  apply BitDependency.unaryForwardIncomplete_of_dependencyCollision
    BitVec.ctz (0 : Fin 8) (1 : Fin 8) (by decide) (7 : Fin 8)
  · exact unary_dependency_of_witness BitVec.ctz 0 7 (boolVector8 0) (by decide)
  · exact unary_dependency_of_witness BitVec.ctz 1 7 (boolVector8 0) (by decide)

theorem knownBits_cttz_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.UnaryBackwardComplete (BitVec.ctz : BitVec 8 → BitVec 8)
  apply BitDependency.unaryBackwardIncomplete_of_dependencyCollision
    BitVec.ctz (0 : Fin 8) (7 : Fin 8) (5 : Fin 8) (by decide)
  · exact unary_dependency_of_witness BitVec.ctz 0 7 (boolVector8 0) (by decide)
  · exact unary_dependency_of_witness BitVec.ctz 0 5 (boolVector8 0) (by decide)

theorem knownBits_ctlzUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.forwardComplete_iff_preservesKnownBitsSets]
  rw [← BitDependency.boolForwardComplete_iff_preservesKnownBitsSets]
  apply BitDependency.unaryRelationalForwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 1) (3 : Fin 8) (boolVector8 7) (boolVector8 4)
    (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      ctlzUndef? (boolVector8 1) (boolVector8 7) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      ctlzUndef? (BitDependency.toggle (boolVector8 1) 3)
        (boolVector8 4) (by decide)
  · decide
  · decide

theorem knownBits_ctlzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.backwardComplete_iff_observationFibersRepresentable]
  rw [← BitDependency.boolBackwardComplete_iff_observationFibersRepresentable]
  apply BitDependency.unaryRelationalBackwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 1) (3 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 7) (boolVector8 4) (boolVector8 6) (0 : Fin 8)
  · exact relationalBoolModel_ofOption_eq_singleton
      ctlzUndef? (boolVector8 1) (boolVector8 7) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      ctlzUndef? (BitDependency.toggle (boolVector8 1) 3)
        (boolVector8 4) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      ctlzUndef? (BitDependency.toggle (boolVector8 1) 1)
        (boolVector8 6) (by decide)
  · decide
  · decide

theorem knownBits_cttzUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.forwardComplete_iff_preservesKnownBitsSets]
  rw [← BitDependency.boolForwardComplete_iff_preservesKnownBitsSets]
  apply BitDependency.unaryRelationalForwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 4) (1 : Fin 8) (boolVector8 2) (boolVector8 1)
    (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      cttzUndef? (boolVector8 4) (boolVector8 2) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      cttzUndef? (BitDependency.toggle (boolVector8 4) 1)
        (boolVector8 1) (by decide)
  · decide
  · decide

theorem knownBits_cttzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  rw [KnownBits.backwardComplete_iff_observationFibersRepresentable]
  rw [← BitDependency.boolBackwardComplete_iff_observationFibersRepresentable]
  apply BitDependency.unaryRelationalBackwardIncomplete_of_localCollision
    (KnownBits.relationalBoolModel
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)))
    (boolVector8 4) (1 : Fin 8) (0 : Fin 8) (by decide)
    (boolVector8 2) (boolVector8 1) (boolVector8 0) (1 : Fin 8)
  · exact relationalBoolModel_ofOption_eq_singleton
      cttzUndef? (boolVector8 4) (boolVector8 2) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      cttzUndef? (BitDependency.toggle (boolVector8 4) 1)
        (boolVector8 1) (by decide)
  · exact relationalBoolModel_ofOption_eq_singleton
      cttzUndef? (BitDependency.toggle (boolVector8 4) 0)
        (boolVector8 0) (by decide)
  · decide
  · decide

private theorem and_isPointwiseNary (n : Nat) :
    BitDependency.IsPointwiseNary
      (KnownBits.binaryAsNary fun x y : BitVec n ↦ x &&& y) := by
  refine ⟨fun _ bits ↦ bits 0 && bits 1, ?_⟩
  intro x i
  simp [KnownBits.binaryAsNary]

private theorem or_isPointwiseNary (n : Nat) :
    BitDependency.IsPointwiseNary
      (KnownBits.binaryAsNary fun x y : BitVec n ↦ x ||| y) := by
  refine ⟨fun _ bits ↦ bits 0 || bits 1, ?_⟩
  intro x i
  simp [KnownBits.binaryAsNary]

private theorem xor_isPointwiseNary (n : Nat) :
    BitDependency.IsPointwiseNary
      (KnownBits.binaryAsNary fun x y : BitVec n ↦ x ^^^ y) := by
  refine ⟨fun _ bits ↦ bits 0 ^^ bits 1, ?_⟩
  intro x i
  simp [KnownBits.binaryAsNary]

theorem knownBits_and_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (and : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (fun x y : BitVec n ↦ x &&& y)
  apply (KnownBits.binaryForwardComplete_iff_dependencies _).mpr
  exact BitDependency.pairwiseDisjointDependenciesNary_of_isPointwiseNary
    (and_isPointwiseNary n)

theorem knownBits_and_backwardComplete (n : Nat) :
    BinaryBackwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (and : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryBackwardComplete (fun x y : BitVec n ↦ x &&& y)
  apply (KnownBits.binaryBackwardComplete_iff_dependencies _).mpr
  exact BitDependency.contextwiseAtMostOneDependencyNary_of_isPointwiseNary
    (and_isPointwiseNary n)

theorem knownBits_or_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (or : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (fun x y : BitVec n ↦ x ||| y)
  apply (KnownBits.binaryForwardComplete_iff_dependencies _).mpr
  exact BitDependency.pairwiseDisjointDependenciesNary_of_isPointwiseNary
    (or_isPointwiseNary n)

theorem knownBits_or_backwardComplete (n : Nat) :
    BinaryBackwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (or : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryBackwardComplete (fun x y : BitVec n ↦ x ||| y)
  apply (KnownBits.binaryBackwardComplete_iff_dependencies _).mpr
  exact BitDependency.contextwiseAtMostOneDependencyNary_of_isPointwiseNary
    (or_isPointwiseNary n)

theorem knownBits_xor_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (xor : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (fun x y : BitVec n ↦ x ^^^ y)
  apply (KnownBits.binaryForwardComplete_iff_dependencies _).mpr
  exact BitDependency.pairwiseDisjointDependenciesNary_of_isPointwiseNary
    (xor_isPointwiseNary n)

theorem knownBits_xor_backwardComplete (n : Nat) :
    BinaryBackwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n) (xor : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryBackwardComplete (fun x y : BitVec n ↦ x ^^^ y)
  apply (KnownBits.binaryBackwardComplete_iff_dependencies _).mpr
  exact BitDependency.contextwiseAtMostOneDependencyNary_of_isPointwiseNary
    (xor_isPointwiseNary n)

private theorem orDisjoint_boolModel_isPointwise (n : Nat) :
    BitDependency.IsPointwiseBinaryRelation
      (binaryRelationalBoolModel
        (orDisjoint : BinaryConcreteOp (BitVec n) (BitVec n) _)) := by
  refine ⟨fun _ x y z ↦ (¬ (x = true ∧ y = true)) ∧ z = (x || y), ?_⟩
  intro x y z
  change z ∈ binaryRelationalBoolModel
      (BinaryConcreteOp.ofOption orDisjoint?) x y ↔ _
  have hmembership : z ∈ binaryRelationalBoolModel
      (BinaryConcreteOp.ofOption orDisjoint?) x y ↔
      x.toBitVec &&& y.toBitVec = 0 ∧
        BoolVector.ofBitVec (x.toBitVec ||| y.toBitVec) = z := by
    simp [binaryRelationalBoolModel, orDisjoint?, poisonIf,
      boolVectorEquivBitVec]
  rw [hmembership]
  simp only [not_and, Bool.not_eq_true]
  constructor
  · rintro ⟨hzero, hout⟩ i
    constructor
    · intro hxi
      have hbit := congrArg (fun value : BitVec n ↦ value.getLsbD i.val) hzero
      have hbit' : x.toBitVec[i.val] = true →
          y.toBitVec[i.val] = false := by
        simpa using hbit
      have hx : x.toBitVec[i.val] = x i :=
        BoolVector.toBitVec_getLsb x i
      have hy : y.toBitVec[i.val] = y i :=
        BoolVector.toBitVec_getLsb y i
      rw [hx, hy] at hbit'
      exact hbit' hxi
    · have hbit := congrArg (fun value : BoolVector n ↦ value i) hout
      have hbit' : (x.toBitVec[i.val] || y.toBitVec[i.val]) = z i := by
        simpa using hbit
      have hx : x.toBitVec[i.val] = x i :=
        BoolVector.toBitVec_getLsb x i
      have hy : y.toBitVec[i.val] = y i :=
        BoolVector.toBitVec_getLsb y i
      rw [hx, hy] at hbit'
      exact hbit'.symm
  · intro h
    constructor
    · apply BitVec.eq_of_getLsbD_eq
      intro i hi
      have hbit := (h ⟨i, hi⟩).1
      have hx : x.toBitVec.toNat.testBit i = x ⟨i, hi⟩ :=
        BoolVector.toBitVec_getLsb x ⟨i, hi⟩
      have hy : y.toBitVec.toNat.testBit i = y ⟨i, hi⟩ :=
        BoolVector.toBitVec_getLsb y ⟨i, hi⟩
      have hdisjoint : x.toBitVec.toNat.testBit i = true →
          y.toBitVec.toNat.testBit i = false := by
        rw [hx, hy]
        exact hbit
      simpa [BitVec.getLsbD] using hdisjoint
    · funext i
      have hx : x.toBitVec[i.val] = x i :=
        BoolVector.toBitVec_getLsb x i
      have hy : y.toBitVec[i.val] = y i :=
        BoolVector.toBitVec_getLsb y i
      have hbit : (x.toBitVec[i.val] || y.toBitVec[i.val]) = z i := by
        rw [hx, hy]
        exact (h i).2.symm
      simpa using hbit

theorem knownBits_orDisjoint_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain n)
      (orDisjoint : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  rw [binaryForwardComplete_iff_boolModel]
  exact BitDependency.binaryForwardComplete_of_pointwiseRelation
    (orDisjoint_boolModel_isPointwise n)

theorem knownBits_orDisjoint_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (orDisjoint : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_undefinedCorner
    (binaryRelationalBoolModel
      (orDisjoint : BinaryConcreteOp (BitVec 8) (BitVec 8) _))
    (boolVector8 0) (boolVector8 3) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 3)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      orDisjoint? (boolVector8 0) (boolVector8 3) (boolVector8 3) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_empty
      orDisjoint? (BitDependency.toggle (boolVector8 0) 0)
        (boolVector8 3) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_empty
      orDisjoint? (BitDependency.toggle (boolVector8 0) 1)
        (boolVector8 3) (by decide)

/-! Addition already fails both completeness notions at width eight.  Both
proofs use the same concrete setup: the left operand is zero and the right
operand is one. Toggling left bit zero changes both result bits zero and one,
which witnesses forward failure. With the right operand fixed to one, result
bit one depends on both bits zero and one of the left operand, which witnesses
backward failure. -/

theorem knownBits_add_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (add : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  change ¬ KnownBits.BinaryForwardComplete addFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    addFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness addFn BinaryOperand.left 0 0
      (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness addFn BinaryOperand.left 1 0
      (binaryInputs8 0 1) (by decide)

theorem knownBits_add_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (add : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete addFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    addFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness addFn BinaryOperand.left context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness addFn BinaryOperand.left context 1 1
      (boolVector8 0) (by decide)

theorem knownBits_addNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_localCollision
    (binaryRelationalBoolModel
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8)
    (boolVector8 1) (boolVector8 2) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      addNsw? (boolVector8 0) (boolVector8 1) (boolVector8 1) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      addNsw? (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 2) (by decide)
  · decide
  · decide

theorem knownBits_addNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_localCollision
    (binaryRelationalBoolModel
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 1) (boolVector8 2) (boolVector8 3) (1 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      addNsw? (boolVector8 0) (boolVector8 1) (boolVector8 1) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      addNsw? (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 2) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      addNsw? (BitDependency.toggle (boolVector8 0) 1) (boolVector8 1)
        (boolVector8 3) (by decide)
  · decide
  · decide

private theorem partialAdd_i8_not_forwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 1))
    (htoggle : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 2)) :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8)
    (boolVector8 1) (boolVector8 2) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 1) (boolVector8 1)
        (by
          rw [show (boolVector8 0).toBitVec = BitVec.ofNat 8 0 by decide,
            show (boolVector8 1).toBitVec = BitVec.ofNat 8 1 by decide]
          exact hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 2) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
              BitVec.ofNat 8 1 by decide,
            show (boolVector8 1).toBitVec = BitVec.ofNat 8 1 by decide,
            show (boolVector8 2).toBitVec = BitVec.ofNat 8 2 by decide]
          exact htoggle)
  · decide
  · decide

private theorem partialAdd_i8_not_backwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 1))
    (hbit0 : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 2))
    (hbit1 : f (BitVec.ofNat 8 2) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 3)) :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 1) (boolVector8 2) (boolVector8 3) (1 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 1) (boolVector8 1)
        (by
          rw [show (boolVector8 0).toBitVec = BitVec.ofNat 8 0 by decide,
            show (boolVector8 1).toBitVec = BitVec.ofNat 8 1 by decide]
          exact hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 2) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
              BitVec.ofNat 8 1 by decide,
            show (boolVector8 1).toBitVec = BitVec.ofNat 8 1 by decide,
            show (boolVector8 2).toBitVec = BitVec.ofNat 8 2 by decide]
          exact hbit0)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 1) (boolVector8 1)
        (boolVector8 3) (by
          rw [show (BitDependency.toggle (boolVector8 0) 1).toBitVec =
              BitVec.ofNat 8 2 by decide,
            show (boolVector8 1).toBitVec = BitVec.ofNat 8 1 by decide,
            show (boolVector8 3).toBitVec = BitVec.ofNat 8 3 by decide]
          exact hbit1)
  · decide
  · decide

theorem knownBits_addNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [addNuw] using partialAdd_i8_not_forwardComplete addNuw?
    (by decide) (by decide)

theorem knownBits_addNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [addNuw] using partialAdd_i8_not_backwardComplete addNuw?
    (by decide) (by decide) (by decide)

theorem knownBits_addNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [addNswNuw] using partialAdd_i8_not_forwardComplete addNswNuw?
    (by decide) (by decide)

theorem knownBits_addNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [addNswNuw] using partialAdd_i8_not_backwardComplete addNswNuw?
    (by decide) (by decide) (by decide)

/-! Subtraction and multiplication have the same low-bit dependency
collisions as addition. Each pair of proofs uses one shared concrete setup. -/

theorem knownBits_sub_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ x - y
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 0 (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 0 (binaryInputs8 0 1) (by decide)

theorem knownBits_sub_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ x - y
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (1 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 1 1
      (boolVector8 0) (by decide)

private theorem partialSub_i8_not_forwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 255))
    (htoggle : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 0)) :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8)
    (boolVector8 255) (boolVector8 0) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 1) (boolVector8 255) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 0) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact htoggle)
  · decide
  · decide

private theorem partialSub_i8_not_backwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 255))
    (hbit0 : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 0))
    (hbit1 : f (BitVec.ofNat 8 2) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 1)) :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 1) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 255) (boolVector8 0) (boolVector8 1) (1 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 1) (boolVector8 255) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 1)
        (boolVector8 0) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 1) (boolVector8 1)
        (boolVector8 1) (by
          rw [show (BitDependency.toggle (boolVector8 0) 1).toBitVec =
            BitVec.ofNat 8 2 by decide]
          exact hbit1)
  · decide
  · decide

theorem knownBits_subNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [subNsw] using partialSub_i8_not_forwardComplete subNsw?
    (by decide) (by decide)

theorem knownBits_subNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [subNsw] using partialSub_i8_not_backwardComplete subNsw?
    (by decide) (by decide) (by decide)

private theorem subNuwCollision :
    (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8)
        (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _)) ∧
      ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8)
        (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [subNuw] using (PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.right
       left := 8, right := 0, output := 8
       toggledOutput := 7, otherToggledOutput := 6
       toggledBit := 0, otherToggledBit := 1
       forwardOutputBit := 0, otherForwardOutputBit := 1
       backwardOutputBit := 3
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 subNuw?))

theorem knownBits_subNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) :=
  subNuwCollision.1

theorem knownBits_subNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) :=
  subNuwCollision.2

private theorem subNswNuwCollision :
    (¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8)
        (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _)) ∧
      ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
        (KnownBits.domain 8)
        (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [subNswNuw] using (PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.right
       left := 8, right := 0, output := 8
       toggledOutput := 7, otherToggledOutput := 6
       toggledBit := 0, otherToggledBit := 1
       forwardOutputBit := 0, otherForwardOutputBit := 1
       backwardOutputBit := 3
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 subNswNuw?))

theorem knownBits_subNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) :=
  subNswNuwCollision.1

theorem knownBits_subNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) :=
  subNswNuwCollision.2

theorem knownBits_mul_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ x * y
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 0 (binaryInputs8 0 3) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 0 (binaryInputs8 0 3) (by decide)

theorem knownBits_mul_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ x * y
  let context := binaryInputs8 0 3
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (1 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 1 1
      (boolVector8 0) (by decide)

private theorem partialMul_i8_not_forwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 3) =
      some (BitVec.ofNat 8 0))
    (htoggle : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 3) =
      some (BitVec.ofNat 8 3)) :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 3) (0 : Fin 8)
    (boolVector8 0) (boolVector8 3) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 3) (boolVector8 0) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 3)
        (boolVector8 3) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact htoggle)
  · decide
  · decide

private theorem partialMul_i8_not_backwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 0) (BitVec.ofNat 8 3) =
      some (BitVec.ofNat 8 0))
    (hbit0 : f (BitVec.ofNat 8 1) (BitVec.ofNat 8 3) =
      some (BitVec.ofNat 8 3))
    (hbit1 : f (BitVec.ofNat 8 2) (BitVec.ofNat 8 3) =
      some (BitVec.ofNat 8 6)) :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_localCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 0) (boolVector8 3) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 0) (boolVector8 3) (boolVector8 6) (1 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 0) (boolVector8 3) (boolVector8 0) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 0) (boolVector8 3)
        (boolVector8 3) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (BitDependency.toggle (boolVector8 0) 1) (boolVector8 3)
        (boolVector8 6) (by
          rw [show (BitDependency.toggle (boolVector8 0) 1).toBitVec =
            BitVec.ofNat 8 2 by decide]
          exact hbit1)
  · decide
  · decide

theorem knownBits_mulNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNsw] using partialMul_i8_not_forwardComplete mulNsw?
    (by decide) (by decide)

theorem knownBits_mulNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNsw] using partialMul_i8_not_backwardComplete mulNsw?
    (by decide) (by decide) (by decide)

theorem knownBits_mulNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNuw] using partialMul_i8_not_forwardComplete mulNuw?
    (by decide) (by decide)

theorem knownBits_mulNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNuw] using partialMul_i8_not_backwardComplete mulNuw?
    (by decide) (by decide) (by decide)

theorem knownBits_mulNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNswNuw] using partialMul_i8_not_forwardComplete mulNswNuw?
    (by decide) (by decide)

theorem knownBits_mulNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [mulNswNuw] using partialMul_i8_not_backwardComplete mulNswNuw?
    (by decide) (by decide) (by decide)

/-! ## Shift counterexamples

The shift amount is the varying operand in these witnesses. Amounts zero,
one, and two are all valid at i8. Values `3` and `12` also keep every flagged
or exact execution used below defined. -/

private theorem leftShiftWitness_i8_not_forwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 3) (BitVec.ofNat 8 0) =
      some (BitVec.ofNat 8 3))
    (hbit0 : f (BitVec.ofNat 8 3) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 6)) :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_rightLocalCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 3) (boolVector8 0) (0 : Fin 8)
    (boolVector8 3) (boolVector8 6) (0 : Fin 8) (2 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 3) (boolVector8 0) (boolVector8 3) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 3) (BitDependency.toggle (boolVector8 0) 0)
        (boolVector8 6) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · decide
  · decide

private theorem leftShiftWitness_i8_not_backwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 3) (BitVec.ofNat 8 0) =
      some (BitVec.ofNat 8 3))
    (hbit0 : f (BitVec.ofNat 8 3) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 6))
    (hbit1 : f (BitVec.ofNat 8 3) (BitVec.ofNat 8 2) =
      some (BitVec.ofNat 8 12)) :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_rightLocalCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 3) (boolVector8 0) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 3) (boolVector8 6) (boolVector8 12) (0 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 3) (boolVector8 0) (boolVector8 3) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 3) (BitDependency.toggle (boolVector8 0) 0)
        (boolVector8 6) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 3) (BitDependency.toggle (boolVector8 0) 1)
        (boolVector8 12) (by
          rw [show (BitDependency.toggle (boolVector8 0) 1).toBitVec =
            BitVec.ofNat 8 2 by decide]
          exact hbit1)
  · decide
  · decide

private theorem rightShiftWitness_i8_not_forwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 12) (BitVec.ofNat 8 0) =
      some (BitVec.ofNat 8 12))
    (hbit0 : f (BitVec.ofNat 8 12) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 6)) :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryForwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalForwardIncomplete_of_rightLocalCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 12) (boolVector8 0) (0 : Fin 8)
    (boolVector8 12) (boolVector8 6) (1 : Fin 8) (3 : Fin 8) (by decide)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 12) (boolVector8 0) (boolVector8 12) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 12) (BitDependency.toggle (boolVector8 0) 0)
        (boolVector8 6) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · decide
  · decide

private theorem rightShiftWitness_i8_not_backwardComplete
    (f : BitVec 8 → BitVec 8 → Option (BitVec 8))
    (hbase : f (BitVec.ofNat 8 12) (BitVec.ofNat 8 0) =
      some (BitVec.ofNat 8 12))
    (hbit0 : f (BitVec.ofNat 8 12) (BitVec.ofNat 8 1) =
      some (BitVec.ofNat 8 6))
    (hbit1 : f (BitVec.ofNat 8 12) (BitVec.ofNat 8 2) =
      some (BitVec.ofNat 8 3)) :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (BinaryConcreteOp.ofOption f) := by
  rw [binaryBackwardComplete_iff_boolModel]
  apply BitDependency.binaryRelationalBackwardIncomplete_of_rightLocalCollision
    (binaryRelationalBoolModel (BinaryConcreteOp.ofOption f))
    (boolVector8 12) (boolVector8 0) (0 : Fin 8) (1 : Fin 8) (by decide)
    (boolVector8 12) (boolVector8 6) (boolVector8 3) (3 : Fin 8)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 12) (boolVector8 0) (boolVector8 12) (by simpa using hbase)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 12) (BitDependency.toggle (boolVector8 0) 0)
        (boolVector8 6) (by
          rw [show (BitDependency.toggle (boolVector8 0) 0).toBitVec =
            BitVec.ofNat 8 1 by decide]
          exact hbit0)
  · exact binaryRelationalBoolModel_ofOption_eq_singleton
      f (boolVector8 12) (BitDependency.toggle (boolVector8 0) 1)
        (boolVector8 3) (by
          rw [show (BitDependency.toggle (boolVector8 0) 1).toBitVec =
            BitVec.ofNat 8 2 by decide]
          exact hbit1)
  · decide
  · decide

theorem knownBits_shl_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shl] using leftShiftWitness_i8_not_forwardComplete shl?
    (by decide) (by decide)

theorem knownBits_shl_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shl] using leftShiftWitness_i8_not_backwardComplete shl?
    (by decide) (by decide) (by decide)

theorem knownBits_shlNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNsw] using leftShiftWitness_i8_not_forwardComplete shlNsw?
    (by decide) (by decide)

theorem knownBits_shlNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNsw] using leftShiftWitness_i8_not_backwardComplete shlNsw?
    (by decide) (by decide) (by decide)

theorem knownBits_shlNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNuw] using leftShiftWitness_i8_not_forwardComplete shlNuw?
    (by decide) (by decide)

theorem knownBits_shlNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNuw] using leftShiftWitness_i8_not_backwardComplete shlNuw?
    (by decide) (by decide) (by decide)

theorem knownBits_shlNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNswNuw] using leftShiftWitness_i8_not_forwardComplete shlNswNuw?
    (by decide) (by decide)

theorem knownBits_shlNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [shlNswNuw] using leftShiftWitness_i8_not_backwardComplete shlNswNuw?
    (by decide) (by decide) (by decide)

theorem knownBits_lshr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [lshr] using rightShiftWitness_i8_not_forwardComplete lshr?
    (by decide) (by decide)

theorem knownBits_lshr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [lshr] using rightShiftWitness_i8_not_backwardComplete lshr?
    (by decide) (by decide) (by decide)

theorem knownBits_lshrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [lshrExact] using rightShiftWitness_i8_not_forwardComplete lshrExact?
    (by decide) (by decide)

theorem knownBits_lshrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [lshrExact] using rightShiftWitness_i8_not_backwardComplete lshrExact?
    (by decide) (by decide) (by decide)

theorem knownBits_ashr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ashr] using rightShiftWitness_i8_not_forwardComplete ashr?
    (by decide) (by decide)

theorem knownBits_ashr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ashr] using rightShiftWitness_i8_not_backwardComplete ashr?
    (by decide) (by decide) (by decide)

theorem knownBits_ashrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ashrExact] using rightShiftWitness_i8_not_forwardComplete ashrExact?
    (by decide) (by decide)

theorem knownBits_ashrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ashrExact] using rightShiftWitness_i8_not_backwardComplete ashrExact?
    (by decide) (by decide) (by decide)

theorem knownBits_ushlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ushlSat] using leftShiftWitness_i8_not_forwardComplete ushlSat?
    (by decide) (by decide)

theorem knownBits_ushlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [ushlSat] using leftShiftWitness_i8_not_backwardComplete ushlSat?
    (by decide) (by decide) (by decide)

theorem knownBits_sshlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sshlSat] using leftShiftWitness_i8_not_forwardComplete sshlSat?
    (by decide) (by decide)

theorem knownBits_sshlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sshlSat] using leftShiftWitness_i8_not_backwardComplete sshlSat?
    (by decide) (by decide) (by decide)

/-! ## Division and remainder counterexamples -/

private theorem udivCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption udiv?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.left
       left := 0, right := 3, output := 0
       toggledOutput := 5, otherToggledOutput := 1
       toggledBit := 4, otherToggledBit := 2
       forwardOutputBit := 0, otherForwardOutputBit := 2
       backwardOutputBit := 0
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 udiv?)

theorem knownBits_udiv_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (udiv : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [udiv] using udivCollision.1

theorem knownBits_udiv_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (udiv : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [udiv] using udivCollision.2

private theorem udivExactCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption udivExact?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.right
       left := 9, right := 1, output := 9
       toggledOutput := 3, otherToggledOutput := 1
       toggledBit := 1, otherToggledBit := 3
       forwardOutputBit := 1, otherForwardOutputBit := 3
       backwardOutputBit := 3
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 udivExact?)

theorem knownBits_udivExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (udivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [udivExact] using udivExactCollision.1

theorem knownBits_udivExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (udivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [udivExact] using udivExactCollision.2

private theorem uremCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption urem?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.left
       left := 0, right := 5, output := 0
       toggledOutput := 3, otherToggledOutput := 1
       toggledBit := 3, otherToggledBit := 0
       forwardOutputBit := 0, otherForwardOutputBit := 1
       backwardOutputBit := 0
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 urem?)

theorem knownBits_urem_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (urem : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [urem] using uremCollision.1

theorem knownBits_urem_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (urem : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [urem] using uremCollision.2

private theorem sdivCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption sdiv?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.left
       left := 0, right := 3, output := 0
       toggledOutput := 5, otherToggledOutput := 1
       toggledBit := 4, otherToggledBit := 2
       forwardOutputBit := 0, otherForwardOutputBit := 2
       backwardOutputBit := 0
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 sdiv?)

theorem knownBits_sdiv_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (sdiv : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sdiv] using sdivCollision.1

theorem knownBits_sdiv_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (sdiv : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sdiv] using sdivCollision.2

private theorem sdivExactCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption sdivExact?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.left
       left := 0, right := 192, output := 0
       toggledOutput := 255, otherToggledOutput := 2
       toggledBit := 6, otherToggledBit := 7
       forwardOutputBit := 0, otherForwardOutputBit := 1
       backwardOutputBit := 1
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 sdivExact?)

theorem knownBits_sdivExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (sdivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sdivExact] using sdivExactCollision.1

theorem knownBits_sdivExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (sdivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [sdivExact] using sdivExactCollision.2

private theorem sremCollision :
    BinaryIncompleteAtI8 (BinaryConcreteOp.ofOption srem?) :=
  PartialBinaryCollisionI8.incomplete
    ({ operand := BinaryOperand.left
       left := 0, right := 3, output := 0
       toggledOutput := 254, otherToggledOutput := 2
       toggledBit := 7, otherToggledBit := 1
       forwardOutputBit := 1, otherForwardOutputBit := 2
       backwardOutputBit := 1
       inputBits_ne := by decide, outputBits_ne := by decide
       base_defined := by decide, toggled_defined := by decide
       other_toggled_defined := by decide
       forward_changes := by decide, other_forward_changes := by decide
       backward_changes := by decide, other_backward_changes := by decide } :
      PartialBinaryCollisionI8 srem?)

theorem knownBits_srem_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (srem : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [srem] using sremCollision.1

theorem knownBits_srem_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (srem : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  simpa [srem] using sremCollision.2

/-! Min and max choose an entire operand. Around the selection boundary this
makes one input bit control multiple output bits, and makes one output bit
depend on multiple bits of the selected operand. -/

theorem knownBits_umax_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (umax : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.ule y then y else x
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (1 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 1 (binaryInputs8 2 1) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 1 (binaryInputs8 2 1) (by decide)

theorem knownBits_umax_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (umax : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.ule y then y else x
  let context := binaryInputs8 2 1
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (0 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 0
      (boolVector8 2) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 1
      (boolVector8 2) (by decide)

theorem knownBits_umin_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (umin : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.ule y then x else y
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (1 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 1 (binaryInputs8 1 2) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 1 (binaryInputs8 1 2) (by decide)

theorem knownBits_umin_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (umin : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.ule y then x else y
  let context := binaryInputs8 1 2
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (0 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 0
      (boolVector8 1) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 1
      (boolVector8 1) (by decide)

theorem knownBits_smax_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (smax : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.sle y then y else x
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (1 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 1 (binaryInputs8 2 1) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 1 (binaryInputs8 2 1) (by decide)

theorem knownBits_smax_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (smax : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.sle y then y else x
  let context := binaryInputs8 2 1
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (0 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 0
      (boolVector8 2) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 1
      (boolVector8 2) (by decide)

theorem knownBits_smin_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (smin : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.sle y then x else y
  change ¬ KnownBits.BinaryForwardComplete f
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (1 : Fin 8)
  · exact binary_dependencyAt_of_witness f 0 0 1 (binaryInputs8 1 2) (by decide)
  · exact binary_dependencyAt_of_witness f 0 1 1 (binaryInputs8 1 2) (by decide)

theorem knownBits_smin_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8) (smin : BinaryConcreteOp (BitVec 8) (BitVec 8) _) := by
  let f := fun x y : BitVec 8 ↦ if x.sle y then x else y
  let context := binaryInputs8 1 2
  change ¬ KnownBits.BinaryBackwardComplete f
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left context (0 : Fin 8) (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 0
      (boolVector8 1) (by decide)
  · exact binary_slice_dependency_of_witness f 0 context 0 1
      (boolVector8 1) (by decide)

/-! ## Saturating arithmetic -/

theorem knownBits_uaddSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (uaddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete uaddSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    uaddSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness uaddSatFn 0 0 0
      (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness uaddSatFn 0 1 0
      (binaryInputs8 0 1) (by decide)

theorem knownBits_uaddSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (uaddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete uaddSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    uaddSatFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness uaddSatFn 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness uaddSatFn 0 context 1 1
      (boolVector8 0) (by decide)

theorem knownBits_saddSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (saddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete saddSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    saddSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness saddSatFn 0 0 0
      (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness saddSatFn 0 1 0
      (binaryInputs8 0 1) (by decide)

theorem knownBits_saddSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (saddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete saddSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    saddSatFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness saddSatFn 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness saddSatFn 0 context 1 1
      (boolVector8 0) (by decide)

theorem knownBits_usubSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (usubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete usubSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    usubSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (2 : Fin 8)
  · exact binary_dependencyAt_of_witness usubSatFn 0 0 2
      (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness usubSatFn 0 1 2
      (binaryInputs8 0 1) (by decide)

theorem knownBits_usubSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (usubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete usubSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    usubSatFn BinaryOperand.left context (0 : Fin 8)
      (1 : Fin 8) (2 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness usubSatFn 0 context 0 1
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness usubSatFn 0 context 0 2
      (boolVector8 0) (by decide)

theorem knownBits_ssubSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ssubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete ssubSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    ssubSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness ssubSatFn 0 0 0
      (binaryInputs8 0 1) (by decide)
  · exact binary_dependencyAt_of_witness ssubSatFn 0 1 0
      (binaryInputs8 0 1) (by decide)

theorem knownBits_ssubSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (ssubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 1
  change ¬ KnownBits.BinaryBackwardComplete ssubSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    ssubSatFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness ssubSatFn 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness ssubSatFn 0 context 1 1
      (boolVector8 0) (by decide)

theorem knownBits_umulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (umulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete umulSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    umulSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness umulSatFn 0 0 0
      (binaryInputs8 0 3) (by decide)
  · exact binary_dependencyAt_of_witness umulSatFn 0 1 0
      (binaryInputs8 0 3) (by decide)

theorem knownBits_umulSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (umulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 3
  change ¬ KnownBits.BinaryBackwardComplete umulSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    umulSatFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness umulSatFn 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness umulSatFn 0 context 1 1
      (boolVector8 0) (by decide)

theorem knownBits_smulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (smulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  change ¬ KnownBits.BinaryForwardComplete smulSatFn
  apply BitDependency.binaryForwardIncomplete_of_dependencyCollision
    smulSatFn BinaryOperand.left (0 : Fin 8) (1 : Fin 8) (by decide) (0 : Fin 8)
  · exact binary_dependencyAt_of_witness smulSatFn 0 0 0
      (binaryInputs8 0 3) (by decide)
  · exact binary_dependencyAt_of_witness smulSatFn 0 1 0
      (binaryInputs8 0 3) (by decide)

theorem knownBits_smulSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 8)
      (smulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  let context := binaryInputs8 0 3
  change ¬ KnownBits.BinaryBackwardComplete smulSatFn
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    smulSatFn BinaryOperand.left context (1 : Fin 8)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness smulSatFn 0 context 1 0
      (boolVector8 0) (by decide)
  · exact binary_slice_dependency_of_witness smulSatFn 0 context 1 1
      (boolVector8 0) (by decide)

/-! ## Integer comparisons -/

theorem knownBits_icmpEq_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpEq : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpEqFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpEqFn

theorem knownBits_icmpNe_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpNe : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpNeFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpNeFn

theorem knownBits_icmpSlt_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpSltFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpSltFn

theorem knownBits_icmpSle_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpSleFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpSleFn

theorem knownBits_icmpSgt_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpSgtFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpSgtFn

theorem knownBits_icmpSge_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpSgeFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpSgeFn

theorem knownBits_icmpUlt_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpUltFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpUltFn

theorem knownBits_icmpUle_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpUle : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpUleFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpUleFn

theorem knownBits_icmpUgt_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpUgtFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpUgtFn

theorem knownBits_icmpUge_forwardComplete (n : Nat) :
    BinaryForwardComplete (KnownBits.domain n) (KnownBits.domain n)
      (KnownBits.domain 1) (icmpUge : BinaryConcreteOp (BitVec n) (BitVec n) _) := by
  change KnownBits.BinaryForwardComplete (icmpUgeFn : BitVec n → BitVec n → BitVec 1)
  exact BitDependency.binaryToI1_forwardComplete icmpUgeFn

private def icmpDependencyWitness
    (f : BitVec 8 → BitVec 8 → BitVec 1) (rhs : Nat)
    (inputBit : Fin 8) : Prop :=
  BitDependency.sliceAt
      (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
      BinaryOperand.left (binaryInputs8 0 rhs) (boolVector8 0) (0 : Fin 1) ≠
    BitDependency.sliceAt
      (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
      BinaryOperand.left (binaryInputs8 0 rhs)
      (BitDependency.toggle (boolVector8 0) inputBit) (0 : Fin 1)

private theorem icmp_i8_backwardIncomplete_of_witness
    (f : BitVec 8 → BitVec 8 → BitVec 1) (rhs : Nat)
    (hbit0 : icmpDependencyWitness f rhs (0 : Fin 8))
    (hbit1 : icmpDependencyWitness f rhs (1 : Fin 8)) :
    ¬ KnownBits.BinaryBackwardComplete f := by
  apply BitDependency.binaryBackwardIncomplete_of_dependencyCollision
    f BinaryOperand.left (binaryInputs8 0 rhs) (0 : Fin 1)
      (0 : Fin 8) (1 : Fin 8) (by decide)
  · exact binary_slice_dependency_of_witness f 0 (binaryInputs8 0 rhs)
      0 0 (boolVector8 0) hbit0
  · exact binary_slice_dependency_of_witness f 0 (binaryInputs8 0 rhs)
      0 1 (boolVector8 0) hbit1

theorem knownBits_icmpEq_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpEq : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpEqFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpEqFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpNe_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpNe : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpNeFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpNeFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpSlt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpSlt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpSltFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpSltFn 1
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpSle_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpSle : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpSleFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpSleFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpSgt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpSgt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpSgtFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpSgtFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpSge_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpSge : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpSgeFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpSgeFn 1
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpUlt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpUlt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpUltFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpUltFn 1
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpUle_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpUle : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpUleFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpUleFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpUgt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpUgt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpUgtFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpUgtFn 0
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

theorem knownBits_icmpUge_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (KnownBits.domain 8) (KnownBits.domain 8)
      (KnownBits.domain 1)
      (icmpUge : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  change ¬ KnownBits.BinaryBackwardComplete (icmpUgeFn : BitVec 8 → BitVec 8 → BitVec 1)
  exact icmp_i8_backwardIncomplete_of_witness icmpUgeFn 1
    (by unfold icmpDependencyWitness; decide)
    (by unfold icmpDependencyWitness; decide)

end LLVM

end SynthXfer
