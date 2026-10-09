import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open UIntRange

private theorem mulGapInputs
    (x y : BitVec 8)
    (hxLower : (0 : BitVec 8).toNat ≤ x.toNat)
    (hxUpper : x.toNat ≤ (1 : BitVec 8).toNat)
    (hyLower : (2 : BitVec 8).toNat ≤ y.toNat)
    (hyUpper : y.toNat ≤ (2 : BitVec 8).toNat) :
    (x = 0 ∨ x = 1) ∧ y = 2 := by
  have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
  have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
  have h2 : (2 : BitVec 8).toNat = 2 := by bv_decide
  rw [h0] at hxLower
  rw [h1] at hxUpper
  rw [h2] at hyLower hyUpper
  constructor
  · have hx : x.toNat = 0 ∨ x.toNat = 1 := by omega
    exact hx.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
  · exact BitVec.eq_of_toNat_eq (by omega)

theorem uintRange_mul_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [mul, mulFn]
  · simp [mul, mulFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨hx, hy⟩ := mulGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hx with rfl | rfl <;> simp [hy, mul, mulFn]

theorem uintRange_mul_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 128 1 1 1 0 0
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [mul, mulFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mul, mulFn] at hz <;> subst z <;> bv_decide

theorem uintRange_mulNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [mulNsw, mulNsw?, poisonIf] <;> bv_decide
  · simp [mulNsw, mulNsw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨hx, hy⟩ := mulGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hx with rfl | rfl
    all_goals simp [hy, mulNsw, mulNsw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_mulNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 64 1 1 1 0 0
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [mulNsw, mulNsw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNsw, mulNsw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all [BitVec.smulOverflow]

theorem uintRange_mulNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [mulNuw, mulNuw?, poisonIf] <;> bv_decide
  · simp [mulNuw, mulNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨hx, hy⟩ := mulGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hx with rfl | rfl
    all_goals simp [hy, mulNuw, mulNuw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_mulNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 128 1 1 1 0 0
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [mulNuw, mulNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNuw, mulNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem uintRange_mulNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [mulNswNuw, mulNswNuw?, poisonIf] <;> bv_decide
  · simp [mulNswNuw, mulNswNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨hx, hy⟩ := mulGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hx with rfl | rfl
    all_goals simp [hy, mulNswNuw, mulNswNuw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_mulNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 64 1 1 1 0 0
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [mulNswNuw, mulNswNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNswNuw, mulNswNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

end SynthXfer.LLVM
