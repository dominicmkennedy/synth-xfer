import SynthXfer.SIntRange.Witnesses

/-!
# LLVM comparisons in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

attribute [local simp] comparisonFn

theorem sintRange_icmpEq_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpEq : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpEqFn

theorem sintRange_icmpNe_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpNe : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpNeFn

theorem sintRange_icmpSlt_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpSltFn

theorem sintRange_icmpSle_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpSleFn

theorem sintRange_icmpSgt_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpSgtFn

theorem sintRange_icmpSge_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpSgeFn

theorem sintRange_icmpUlt_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpUlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpUltFn

theorem sintRange_icmpUle_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpUle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpUleFn

theorem sintRange_icmpUgt_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpUgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpUgtFn

theorem sintRange_icmpUge_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpUge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) :=
  SIntRange.binaryForwardComplete_i1Result icmpUgeFn

theorem sintRange_icmpEq_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpEq : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpEq
    255 1 0 0 0 0 1 0 0 (by decide) (by decide) (by decide)
  · simp [icmpEq, icmpEqFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpEq, icmpEqFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_icmpNe_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpNe : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpNe
    255 1 0 0 0 0 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpNe, icmpNeFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpNe, icmpNeFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_icmpSlt_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSlt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing icmpSltFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [SIntRange.orderedBy] at hx hy
  by_cases h₁ : x₁.toInt < y₁.toInt <;>
    by_cases h₂ : x₂.toInt < y₂.toInt <;>
    simp [icmpSltFn, comparisonFn, BitVec.slt_eq_decide, h₁, h₂]
  all_goals omega

theorem sintRange_icmpSle_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSle : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing icmpSleFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [SIntRange.orderedBy] at hx hy
  by_cases h₁ : x₁.toInt ≤ y₁.toInt <;>
    by_cases h₂ : x₂.toInt ≤ y₂.toInt <;>
    simp [icmpSleFn, comparisonFn, BitVec.sle_eq_decide, h₁, h₂]
  all_goals omega

theorem sintRange_icmpSgt_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSgt : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .decreasing .increasing icmpSgtFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [SIntRange.orderedBy] at hx hy
  by_cases h₁ : y₁.toInt < x₁.toInt <;>
    by_cases h₂ : y₂.toInt < x₂.toInt <;>
    simp [icmpSgtFn, comparisonFn, BitVec.slt_eq_decide, h₁, h₂]
  all_goals omega

theorem sintRange_icmpSge_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain 1)
      (icmpSge : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .decreasing .increasing icmpSgeFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp [SIntRange.orderedBy] at hx hy
  by_cases h₁ : y₁.toInt ≤ x₁.toInt <;>
    by_cases h₂ : y₂.toInt ≤ x₂.toInt <;>
    simp [icmpSgeFn, comparisonFn, BitVec.sle_eq_decide, h₁, h₂]
  all_goals omega

theorem sintRange_icmpUlt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpUlt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpUlt
    255 1 1 1 0 1 1 0 0 (by decide) (by decide) (by decide)
  · simp [icmpUlt, icmpUltFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpUlt, icmpUltFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_icmpUle_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpUle : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpUle
    255 1 0 0 0 0 1 0 0 (by decide) (by decide) (by decide)
  · simp [icmpUle, icmpUleFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpUle, icmpUleFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_icmpUgt_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpUgt : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpUgt
    255 1 0 0 0 0 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpUgt, icmpUgtFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpUgt, icmpUgtFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_icmpUge_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 1)
      (icmpUge : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 1)) := by
  apply binaryBackwardIncompleteOfCorner_i8 icmpUge
    255 1 1 1 0 1 0 1 1 (by decide) (by decide) (by decide)
  · simp [icmpUge, icmpUgeFn]
  · decide
  · decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [icmpUge, icmpUgeFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
