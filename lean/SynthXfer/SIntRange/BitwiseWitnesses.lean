import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Bitwise-operation witnesses in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

private theorem bitvec8_eq_zero_or_one_or_two {x : BitVec 8}
    (hlower : (0 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (2 : BitVec 8).toInt) :
    x = 0 ∨ x = 1 ∨ x = 2 := by
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  have h2 : (2 : BitVec 8).toInt = 2 := by bv_decide
  rw [h0] at hlower
  rw [h2] at hupper
  have hx : x.toInt = 0 ∨ x.toInt = 1 ∨ x.toInt = 2 := by omega
  exact hx.imp BitVec.eq_of_toInt_eq
    (fun h ↦ Or.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq h)

private theorem bitvec8_eq_one_or_two {x : BitVec 8}
    (hlower : (1 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (2 : BitVec 8).toInt) : x = 1 ∨ x = 2 := by
  have h1 : (1 : BitVec 8).toInt = 1 := by bv_decide
  have h2 : (2 : BitVec 8).toInt = 2 := by bv_decide
  rw [h1] at hlower
  rw [h2] at hupper
  have hx : x.toInt = 1 ∨ x.toInt = 2 := by omega
  exact hx.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq

theorem sintRange_xor_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (xor : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 xor
    2 2 0 2 0 1 3 (by bv_decide) (by bv_decide) (by bv_decide)
    2 2 2 1 (by bv_decide) (by bv_decide)
  · simp [xor, xorFn]
  · simp [xor, xorFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hx : x = 2 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_zero_or_one_or_two hyLower hyUpper with
      rfl | rfl | rfl <;> simp [hx, xor, xorFn]

theorem sintRange_xor_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (xor : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 xor
    0 2 1 1 1 1 0 1 3 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [xor, xorFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [xor, xorFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_and_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (and : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 and
    1 2 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    1 2 2 2 (by bv_decide) (by bv_decide)
  · simp [and, andFn]
  · simp [and, andFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 2 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_one_or_two hxLower hxUpper with rfl | rfl <;>
      simp [hy, and, andFn]

theorem sintRange_and_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (and : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 and
    1 4 2 2 2 2 2 0 0 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [and, andFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [and, andFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_or_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (or : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 or
    1 2 5 5 5 6 7 (by bv_decide) (by bv_decide) (by bv_decide)
    1 5 2 5 (by bv_decide) (by bv_decide)
  · simp [or, orFn]
  · simp [or, orFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 5 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_one_or_two hxLower hxUpper with rfl | rfl <;>
      simp [hy, or, orFn]

theorem sintRange_or_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (or : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 or
    1 4 5 5 2 5 7 5 5 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [or, orFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [or, orFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_orDisjoint_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (orDisjoint : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 orDisjoint
    0 2 1 1 1 2 3 (by bv_decide) (by bv_decide) (by bv_decide)
    0 1 2 1 (by bv_decide) (by bv_decide)
  · simp [orDisjoint, orDisjoint?, poisonIf]
  · simp [orDisjoint, orDisjoint?, poisonIf]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 1 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_zero_or_one_or_two hxLower hxUpper with
      rfl | rfl | rfl <;>
      simp_all [orDisjoint, orDisjoint?, poisonIf]

theorem sintRange_orDisjoint_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
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
