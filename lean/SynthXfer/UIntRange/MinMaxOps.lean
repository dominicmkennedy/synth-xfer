import SynthXfer.UIntRange.NoWrapArithmetic
import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Minimum and maximum operations in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

@[simp] theorem uminFn_toNat {n : Nat} (x y : BitVec n) :
    (uminFn x y).toNat = min x.toNat y.toNat := by
  simp [uminFn, BitVec.ule_eq_decide]
  split <;> omega

@[simp] theorem umaxFn_toNat {n : Nat} (x y : BitVec n) :
    (umaxFn x y).toNat = max x.toNat y.toNat := by
  simp [umaxFn, BitVec.ule_eq_decide]
  split <;> omega

theorem uintRange_umin_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (umin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = uminFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, umin] using ha
  have hbEq : b.bitvec = uminFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, umin] using hb
  have haNat : a.bitvec.toNat = min xa.bitvec.toNat ya.bitvec.toNat := by
    rw [haEq]
    exact uminFn_toNat _ _
  have hbNat : b.bitvec.toNat = min xb.bitvec.toNat yb.bitvec.toNat := by
    rw [hbEq]
    exact uminFn_toNat _ _
  have hzNat : a.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ b.bitvec.toNat := hz
  rcases le_total xa.bitvec.toNat ya.bitvec.toNat with hxa | hya
  · have hxaZ : xa.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hzXb : z.bitvec.toNat ≤ xb.bitvec.toNat := by omega
    have hzYb : z.bitvec.toNat ≤ yb.bitvec.toNat := by omega
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then z else yb
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simp only [inputs, BinaryOperand.left, if_pos]
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
        have hxaXb := hxaZ.trans hzXb
        have hxaXb' : xa ≤ xb := hxaXb
        rw [min_eq_left hxaXb', max_eq_right hxaXb']
        exact ⟨hxaZ, hzXb⟩
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsB BinaryOperand.right
    · have hout : uminFn z.bitvec yb.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        simp [min_eq_left hzYb]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, umin, hout]
  · have hyaZ : ya.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hzXb : z.bitvec.toNat ≤ xb.bitvec.toNat := by omega
    have hzYb : z.bitvec.toNat ≤ yb.bitvec.toNat := by omega
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then xb else z
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsB BinaryOperand.left
      · change z ∈ (intervals BinaryOperand.right : Set (UnsignedBitVec n))
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
        have hyaYb := hyaZ.trans hzYb
        have hyaYb' : ya ≤ yb := hyaYb
        rw [min_eq_left hyaYb', max_eq_right hyaYb']
        exact ⟨hyaZ, hzYb⟩
    · have hout : uminFn xb.bitvec z.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        simp [min_eq_right hzXb]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, umin, hout]

theorem uintRange_umax_forwardComplete {n : Nat} :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (umax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = umaxFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, umax] using ha
  have hbEq : b.bitvec = umaxFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, umax] using hb
  have haNat : a.bitvec.toNat = max xa.bitvec.toNat ya.bitvec.toNat := by
    rw [haEq]
    exact umaxFn_toNat _ _
  have hbNat : b.bitvec.toNat = max xb.bitvec.toNat yb.bitvec.toNat := by
    rw [hbEq]
    exact umaxFn_toNat _ _
  have hzNat : a.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ b.bitvec.toNat := hz
  rcases le_total xb.bitvec.toNat yb.bitvec.toNat with hxb | hyb
  · have hxaZ : xa.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hyaZ : ya.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hzYb : z.bitvec.toNat ≤ yb.bitvec.toNat := by omega
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then xa else z
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsA BinaryOperand.left
      · change z ∈ (intervals BinaryOperand.right : Set (UnsignedBitVec n))
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
        have hyaYb := hyaZ.trans hzYb
        have hyaYb' : ya ≤ yb := hyaYb
        rw [min_eq_left hyaYb', max_eq_right hyaYb']
        exact ⟨hyaZ, hzYb⟩
    · have hout : umaxFn xa.bitvec z.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        simp [max_eq_right hxaZ]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, umax, hout]
  · have hxaZ : xa.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hyaZ : ya.bitvec.toNat ≤ z.bitvec.toNat := by omega
    have hzXb : z.bitvec.toNat ≤ xb.bitvec.toNat := by omega
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then z else ya
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simp only [inputs, BinaryOperand.left, if_pos]
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
        have hxaXb := hxaZ.trans hzXb
        have hxaXb' : xa ≤ xb := hxaXb
        rw [min_eq_left hxaXb', max_eq_right hxaXb']
        exact ⟨hxaZ, hzXb⟩
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsA BinaryOperand.right
    · have hout : umaxFn z.bitvec ya.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        simp [max_eq_left hyaZ]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, umax, hout]

theorem uintRange_umin_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (umin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing uminFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp only [uminFn_toNat]
  exact min_le_min hx hy

theorem uintRange_umax_backwardComplete {n : Nat} :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (umax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing umaxFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp only [umaxFn_toNat]
  exact max_le_max hx hy

theorem uintRange_smin_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smin : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 smin
    127 128 130 130 128 129 130 (by bv_decide) (by bv_decide)
      (by bv_decide) 128 130 127 130 (by bv_decide) (by bv_decide)
  · simp [smin, sminFn]
  · simp [smin, sminFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 130 := BitVec.eq_of_toNat_eq (by omega)
    have hx : x = 127 ∨ x = 128 := by
      have : x.toNat = 127 ∨ x.toNat = 128 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hx with rfl | rfl <;> simp [hy, smin, sminFn]

theorem uintRange_smin_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smin : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 smin
    127 129 131 131 128 131 128 129 131
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [smin, sminFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [smin, sminFn] at hz <;> rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_smax_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smax : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 smax
    125 125 127 128 125 126 127 (by bv_decide) (by bv_decide)
      (by bv_decide) 125 128 125 127 (by bv_decide) (by bv_decide)
  · simp [smax, smaxFn]
  · simp [smax, smaxFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hx : x = 125 := BitVec.eq_of_toNat_eq (by omega)
    have hy : y = 127 ∨ y = 128 := by
      have : y.toNat = 127 ∨ y.toNat = 128 := by
        simp at hyLower hyUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hy with rfl | rfl <;> simp [hx, smax, smaxFn]

theorem uintRange_smax_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smax : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 smax
    124 124 126 128 124 127 127 124 126
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [smax, smaxFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [smax, smaxFn] at hz <;> rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
