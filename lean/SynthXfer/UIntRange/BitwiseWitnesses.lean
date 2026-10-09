import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Bitwise-operation witnesses in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

theorem uintRange_xor_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (xor : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 xor
    2 2 0 2 0 1 3 (by bv_decide) (by bv_decide) (by bv_decide)
    2 2 2 1 (by bv_decide) (by bv_decide)
  · simp [xor, xorFn]
  · simp [xor, xorFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hzero : (0 : BitVec 8).toNat = 0 := by bv_decide
    have htwo : (2 : BitVec 8).toNat = 2 := by bv_decide
    rw [hzero] at hyLower
    rw [htwo] at hxLower hxUpper hyUpper
    have hx : x = (2 : BitVec 8) := by
      apply BitVec.eq_of_toNat_eq
      omega
    have hy : y = (0 : BitVec 8) ∨ y = (1 : BitVec 8) ∨
        y = (2 : BitVec 8) := by
      have : y.toNat = 0 ∨ y.toNat = 1 ∨ y.toNat = 2 := by omega
      exact this.imp BitVec.eq_of_toNat_eq
        (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)
    rcases hy with rfl | rfl | rfl <;> simp [hx, xor, xorFn]

theorem uintRange_and_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (and : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 and
    1 2 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    1 2 2 2 (by bv_decide) (by bv_decide)
  · simp [and, andFn]
  · simp [and, andFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 2 := BitVec.eq_of_toNat_eq (by omega)
    have hx : x = 1 ∨ x = 2 := by
      have : x.toNat = 1 ∨ x.toNat = 2 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hx with rfl | rfl <;> simp [hy, and, andFn]

theorem uintRange_and_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (and : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 and
    1 4 2 2 2 2 2 0 0 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [and, andFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [and, andFn] at hz <;> rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_or_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (or : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 or
    1 2 5 5 5 6 7 (by bv_decide) (by bv_decide) (by bv_decide)
    1 5 2 5 (by bv_decide) (by bv_decide)
  · simp [or, orFn]
  · simp [or, orFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 5 := BitVec.eq_of_toNat_eq (by omega)
    have hx : x = 1 ∨ x = 2 := by
      have : x.toNat = 1 ∨ x.toNat = 2 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hx with rfl | rfl <;> simp [hy, or, orFn]

theorem uintRange_or_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (or : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 or
    1 4 5 5 2 5 7 5 5 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [or, orFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [or, orFn] at hz <;> rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_xor_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (xor : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 xor
    0 2 1 1 1 1 0 1 3 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [xor, xorFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [xor, xorFn] at hz <;> rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_orDisjoint_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (orDisjoint : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 orDisjoint
    0 2 1 1 1 2 3 (by bv_decide) (by bv_decide) (by bv_decide)
    0 1 2 1 (by bv_decide) (by bv_decide)
  · simp [orDisjoint, orDisjoint?, poisonIf]
  · simp [orDisjoint, orDisjoint?, poisonIf]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 1 := BitVec.eq_of_toNat_eq (by omega)
    have hx : x = 0 ∨ x = 1 ∨ x = 2 := by
      have : x.toNat = 0 ∨ x.toNat = 1 ∨ x.toNat = 2 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq
        (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)
    rcases hx with rfl | rfl | rfl <;>
      simp_all [orDisjoint, orDisjoint?, poisonIf]

theorem uintRange_orDisjoint_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (orDisjoint : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 orDisjoint
    0 3 1 1 2 1 3 1 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [orDisjoint, orDisjoint?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [orDisjoint, orDisjoint?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
