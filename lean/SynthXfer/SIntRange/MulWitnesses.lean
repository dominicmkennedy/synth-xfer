import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open SIntRange

private theorem mulGapInputs
    (x y : BitVec 8)
    (hxLower : (128 : BitVec 8).toInt ≤ x.toInt)
    (hxUpper : x.toInt ≤ (128 : BitVec 8).toInt)
    (hyLower : (255 : BitVec 8).toInt ≤ y.toInt)
    (hyUpper : y.toInt ≤ (1 : BitVec 8).toInt) :
    x = 128 ∧ (y = 255 ∨ y = 0 ∨ y = 1) := by
  have hxValue : (128 : BitVec 8).toInt = -128 := by bv_decide
  have hyLowerValue : (255 : BitVec 8).toInt = -1 := by bv_decide
  have hyUpperValue : (1 : BitVec 8).toInt = 1 := by bv_decide
  rw [hxValue] at hxLower hxUpper
  rw [hyLowerValue] at hyLower
  rw [hyUpperValue] at hyUpper
  constructor
  · apply BitVec.eq_of_toInt_eq
    rw [hxValue]
    omega
  · have hy : y.toInt = -1 ∨ y.toInt = 0 ∨ y.toInt = 1 := by omega
    rcases hy with hy | hy | hy
    · left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; right; apply BitVec.eq_of_toInt_eq; simpa using hy

private theorem mulForwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hbelow : (128 : BitVec 8) ∈ f 128 1)
    (habove : (0 : BitVec 8) ∈ f 128 0)
    (hgap : ∀ y, (y = (255 : BitVec 8) ∨ y = 0 ∨ y = 1) →
      (129 : BitVec 8) ∉ f 128 y) :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    128 128 255 1 128 129 0
    (by bv_decide) (by bv_decide) (by bv_decide)
    128 1 128 0 (by bv_decide) (by bv_decide) hbelow habove
  intro x y hxLower hxUpper hyLower hyUpper
  obtain ⟨rfl, hy⟩ := mulGapInputs x y hxLower hxUpper hyLower hyUpper
  exact hgap y hy

theorem sintRange_mul_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulForwardIncomplete mul
  · simp [mul, mulFn]
  · simp [mul, mulFn]
  · intro y hy
    rcases hy with rfl | rfl | rfl <;> simp [mul, mulFn]

theorem sintRange_mulNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulForwardIncomplete mulNsw
  · simp [mulNsw, mulNsw?, poisonIf, BitVec.smulOverflow]
  · simp [mulNsw, mulNsw?, poisonIf, BitVec.smulOverflow]
  · intro y hy
    rcases hy with rfl | rfl | rfl <;>
      simp [mulNsw, mulNsw?, poisonIf, BitVec.smulOverflow]

theorem sintRange_mulNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulForwardIncomplete mulNuw
  · simp [mulNuw, mulNuw?, poisonIf, BitVec.umulOverflow]
  · simp [mulNuw, mulNuw?, poisonIf, BitVec.umulOverflow]
  · intro y hy
    rcases hy with rfl | rfl | rfl <;>
      simp [mulNuw, mulNuw?, poisonIf, BitVec.umulOverflow]

theorem sintRange_mulNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulForwardIncomplete mulNswNuw
  · simp [mulNswNuw, mulNswNuw?, poisonIf, BitVec.smulOverflow,
      BitVec.umulOverflow]
  · simp [mulNswNuw, mulNswNuw?, poisonIf, BitVec.smulOverflow,
      BitVec.umulOverflow]
  · intro y hy
    rcases hy with rfl | rfl | rfl <;>
      simp [mulNswNuw, mulNswNuw?, poisonIf, BitVec.smulOverflow,
        BitVec.umulOverflow]

private theorem mulBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hinside : (0 : BitVec 8) ∈ f 128 0)
    (hcorners : ∀ x y z,
      (x = (128 : BitVec 8) ∨ x = 128) →
      (y = (255 : BitVec 8) ∨ y = 1) → z ∈ f x y →
      (128 : BitVec 8).toInt ≤ z.toInt ∧ z.toInt ≤ (128 : BitVec 8).toInt) :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    128 128 255 1 128 0 0 128 128
    (by bv_decide) (by bv_decide) (by bv_decide) hinside
    (by bv_decide) (by bv_decide) hcorners

theorem sintRange_mul_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mul : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulBackwardIncomplete mul
  · simp [mul, mulFn]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mul, mulFn] at hz <;> subst z <;> decide

theorem sintRange_mulNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulBackwardIncomplete mulNsw
  · simp [mulNsw, mulNsw?, poisonIf, BitVec.smulOverflow]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNsw, mulNsw?, poisonIf, BitVec.smulOverflow] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_mulNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulBackwardIncomplete mulNuw
  · simp [mulNuw, mulNuw?, poisonIf, BitVec.umulOverflow]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNuw, mulNuw?, poisonIf, BitVec.umulOverflow] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_mulNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (mulNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply mulBackwardIncomplete mulNswNuw
  · simp [mulNswNuw, mulNswNuw?, poisonIf, BitVec.smulOverflow,
      BitVec.umulOverflow]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [mulNswNuw, mulNswNuw?, poisonIf, BitVec.smulOverflow,
        BitVec.umulOverflow] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
