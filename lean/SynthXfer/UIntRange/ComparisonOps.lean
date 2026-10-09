import SynthXfer.UIntRange.Witnesses

/-!
# LLVM comparisons in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

attribute [local simp] comparisonFn

theorem uintRange_icmpEq_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpEq : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpEqFn

theorem uintRange_icmpNe_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpNe : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpNeFn

theorem uintRange_icmpSlt_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpSltFn

theorem uintRange_icmpSle_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpSle : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpSleFn

theorem uintRange_icmpSgt_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpSgtFn

theorem uintRange_icmpSge_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpSge : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpSgeFn

theorem uintRange_icmpUlt_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpUltFn

theorem uintRange_icmpUle_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUle : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpUleFn

theorem uintRange_icmpUgt_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpUgtFn

theorem uintRange_icmpUge_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUge : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) :=
  UIntRange.binaryForwardComplete_i1Result icmpUgeFn

theorem uintRange_icmpEq_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpEq : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpEq
    0 2 1 3 1 1 1 0 0 (by decide) (by decide) (by decide)
  · simp [icmpEq, icmpEqFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpEq, icmpEqFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpNe_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpNe : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpNe
    0 2 1 3 1 1 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpNe, icmpNeFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpNe, icmpNeFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpSlt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpSlt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpSlt
    128 128 127 129 128 128 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpSlt, icmpSltFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpSlt, icmpSltFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpSle_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpSle : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpSle
    129 129 127 129 129 128 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpSle, icmpSleFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpSle, icmpSleFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpSgt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpSgt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpSgt
    127 129 128 128 128 128 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpSgt, icmpSgtFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpSgt, icmpSgtFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpSge_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 1)
      (icmpSge : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpSge
    127 129 129 129 128 129 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpSge, icmpSgeFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpSge, icmpSgeFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_icmpUlt_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .decreasing .increasing icmpUltFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [UIntRange.orderedBy] at hx hy
  by_cases h₁ : x₁.toNat < y₁.toNat
  · have h₂ : x₂.toNat < y₂.toNat := by omega
    simp [icmpUltFn, comparisonFn, BitVec.ult_eq_decide, h₁, h₂]
  · simp [icmpUltFn, comparisonFn, BitVec.ult_eq_decide, h₁]

theorem uintRange_icmpUle_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUle : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .decreasing .increasing icmpUleFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [UIntRange.orderedBy] at hx hy
  by_cases h₁ : x₁.toNat ≤ y₁.toNat
  · have h₂ : x₂.toNat ≤ y₂.toNat := by omega
    simp [icmpUleFn, comparisonFn, BitVec.ule_eq_decide, h₁, h₂]
  · simp [icmpUleFn, comparisonFn, BitVec.ule_eq_decide, h₁]

theorem uintRange_icmpUgt_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing icmpUgtFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [UIntRange.orderedBy] at hx hy
  by_cases h₁ : y₁.toNat < x₁.toNat
  · have h₂ : y₂.toNat < x₂.toNat := by omega
    simp [icmpUgtFn, comparisonFn, BitVec.ult_eq_decide, h₁, h₂]
  · simp [icmpUgtFn, comparisonFn, BitVec.ult_eq_decide, h₁]

theorem uintRange_icmpUge_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain 1) (icmpUge : BinaryConcreteOp (BitVec n) (BitVec n)
        (BitVec 1)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing icmpUgeFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [UIntRange.orderedBy] at hx hy
  by_cases h₁ : y₁.toNat ≤ x₁.toNat
  · have h₂ : y₂.toNat ≤ x₂.toNat := by omega
    simp [icmpUgeFn, comparisonFn, BitVec.ule_eq_decide, h₁, h₂]
  · simp [icmpUgeFn, comparisonFn, BitVec.ule_eq_decide, h₁]

end SynthXfer.LLVM
