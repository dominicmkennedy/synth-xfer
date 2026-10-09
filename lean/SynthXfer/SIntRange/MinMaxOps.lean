import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Minimum and maximum operations in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

@[simp] theorem sminFn_toInt {n : Nat} (x y : BitVec n) :
    (sminFn x y).toInt = min x.toInt y.toInt := by
  simp [sminFn, BitVec.sle_eq_decide]
  split <;> omega

@[simp] theorem smaxFn_toInt {n : Nat} (x y : BitVec n) :
    (smaxFn x y).toInt = max x.toInt y.toInt := by
  simp [smaxFn, BitVec.sle_eq_decide]
  split <;> omega

theorem sintRange_smin_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (smin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = sminFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, smin] using ha
  have hbEq : b.bitvec = sminFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, smin] using hb
  have haInt : a.bitvec.toInt = min xa.bitvec.toInt ya.bitvec.toInt := by
    rw [haEq]
    exact sminFn_toInt _ _
  have hbInt : b.bitvec.toInt = min xb.bitvec.toInt yb.bitvec.toInt := by
    rw [hbEq]
    exact sminFn_toInt _ _
  have hzInt : a.bitvec.toInt ≤ z.bitvec.toInt ∧
      z.bitvec.toInt ≤ b.bitvec.toInt := hz
  rcases le_total xa.bitvec.toInt ya.bitvec.toInt with hxa | hya
  · have hxaZ : xa.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hzXb : z.bitvec.toInt ≤ xb.bitvec.toInt := by omega
    have hzYb : z.bitvec.toInt ≤ yb.bitvec.toInt := by omega
    let inputs : BinaryOperand → SignedBitVec n := fun k ↦
      if k = BinaryOperand.left then z else yb
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simp only [inputs, BinaryOperand.left, if_pos]
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
        have hxaXb : xa ≤ xb := hxaZ.trans hzXb
        rw [min_eq_left hxaXb, max_eq_right hxaXb]
        exact ⟨hxaZ, hzXb⟩
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsB BinaryOperand.right
    · have hout : sminFn z.bitvec yb.bitvec = z.bitvec := by
        apply BitVec.eq_of_toInt_eq
        simp [min_eq_left hzYb]
      simp [inputs, SIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, smin, hout]
  · have hyaZ : ya.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hzXb : z.bitvec.toInt ≤ xb.bitvec.toInt := by omega
    have hzYb : z.bitvec.toInt ≤ yb.bitvec.toInt := by omega
    let inputs : BinaryOperand → SignedBitVec n := fun k ↦
      if k = BinaryOperand.left then xb else z
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsB BinaryOperand.left
      · change z ∈ (intervals BinaryOperand.right : Set (SignedBitVec n))
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
        have hyaYb : ya ≤ yb := hyaZ.trans hzYb
        rw [min_eq_left hyaYb, max_eq_right hyaYb]
        exact ⟨hyaZ, hzYb⟩
    · have hout : sminFn xb.bitvec z.bitvec = z.bitvec := by
        apply BitVec.eq_of_toInt_eq
        simp [min_eq_right hzXb]
      simp [inputs, SIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, smin, hout]

theorem sintRange_smax_forwardComplete {n : Nat} :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (smax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = smaxFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, smax] using ha
  have hbEq : b.bitvec = smaxFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, smax] using hb
  have haInt : a.bitvec.toInt = max xa.bitvec.toInt ya.bitvec.toInt := by
    rw [haEq]
    exact smaxFn_toInt _ _
  have hbInt : b.bitvec.toInt = max xb.bitvec.toInt yb.bitvec.toInt := by
    rw [hbEq]
    exact smaxFn_toInt _ _
  have hzInt : a.bitvec.toInt ≤ z.bitvec.toInt ∧
      z.bitvec.toInt ≤ b.bitvec.toInt := hz
  rcases le_total xb.bitvec.toInt yb.bitvec.toInt with hxb | hyb
  · have hxaZ : xa.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hyaZ : ya.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hzYb : z.bitvec.toInt ≤ yb.bitvec.toInt := by omega
    let inputs : BinaryOperand → SignedBitVec n := fun k ↦
      if k = BinaryOperand.left then xa else z
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsA BinaryOperand.left
      · change z ∈ (intervals BinaryOperand.right : Set (SignedBitVec n))
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
        have hyaYb : ya ≤ yb := hyaZ.trans hzYb
        rw [min_eq_left hyaYb, max_eq_right hyaYb]
        exact ⟨hyaZ, hzYb⟩
    · have hout : smaxFn xa.bitvec z.bitvec = z.bitvec := by
        apply BitVec.eq_of_toInt_eq
        simp [max_eq_right hxaZ]
      simp [inputs, SIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, smax, hout]
  · have hxaZ : xa.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hyaZ : ya.bitvec.toInt ≤ z.bitvec.toInt := by omega
    have hzXb : z.bitvec.toInt ≤ xb.bitvec.toInt := by omega
    let inputs : BinaryOperand → SignedBitVec n := fun k ↦
      if k = BinaryOperand.left then z else ya
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simp only [inputs, BinaryOperand.left, if_pos]
        apply IntervalDomain.mem_interval_of_between
          (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
        have hxaXb : xa ≤ xb := hxaZ.trans hzXb
        rw [min_eq_left hxaXb, max_eq_right hxaXb]
        exact ⟨hxaZ, hzXb⟩
      · simpa [inputs, BinaryOperand.left, BinaryOperand.right] using
          hinputsA BinaryOperand.right
    · have hout : smaxFn z.bitvec ya.bitvec = z.bitvec := by
        apply BitVec.eq_of_toInt_eq
        simp [max_eq_left hyaZ]
      simp [inputs, SIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, smax, hout]

theorem sintRange_smin_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (smin : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing sminFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp only [sminFn_toInt]
  exact min_le_min hx hy

theorem sintRange_smax_backwardComplete {n : Nat} :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (smax : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing smaxFn
  intro x₁ x₂ y₁ y₂ hx hy
  simp only [smaxFn_toInt]
  exact max_le_max hx hy

private theorem bitvec8_eq_neg_one_or_zero {x : BitVec 8}
    (hlower : (255 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (0 : BitVec 8).toInt) : x = 255 ∨ x = 0 := by
  have h255 : (255 : BitVec 8).toInt = -1 := by bv_decide
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  rw [h255] at hlower
  rw [h0] at hupper
  have hx : x.toInt = -1 ∨ x.toInt = 0 := by omega
  rcases hx with hx | hx
  · exact Or.inl (BitVec.eq_of_toInt_eq (by simpa using hx))
  · exact Or.inr (BitVec.eq_of_toInt_eq hx)

theorem sintRange_umin_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umin : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 umin
    255 0 128 128 128 129 0 (by bv_decide) (by bv_decide)
      (by bv_decide) 255 128 0 128 (by bv_decide) (by bv_decide)
  · simp [umin, uminFn]
  · simp [umin, uminFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 128 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_neg_one_or_zero hxLower hxUpper with rfl | rfl <;>
      simp [hy, umin, uminFn]

theorem sintRange_umin_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umin : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 umin
    255 1 1 1 0 1 0 1 1
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [umin, uminFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [umin, uminFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem sintRange_umax_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umax : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 umax
    255 0 1 1 255 0 1 (by bv_decide) (by bv_decide)
      (by bv_decide) 255 1 0 1 (by bv_decide) (by bv_decide)
  · simp [umax, umaxFn]
  · simp [umax, umaxFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 1 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_neg_one_or_zero hxLower hxUpper with rfl | rfl <;>
      simp [hy, umax, umaxFn]

theorem sintRange_umax_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umax : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 umax
    128 0 128 128 255 128 255 128 128
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [umax, umaxFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [umax, umaxFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

end SynthXfer.LLVM
