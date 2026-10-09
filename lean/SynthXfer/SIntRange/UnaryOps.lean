import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Unary LLVM operations in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

private theorem bitvec8_eq_of_toInt_interval_two {x lower upper : BitVec 8}
    (hsucc : lower.toInt + 1 = upper.toInt)
    (hlower : lower.toInt ≤ x.toInt) (hupper : x.toInt ≤ upper.toInt) :
    x = lower ∨ x = upper := by
  have hx : x.toInt = lower.toInt ∨ x.toInt = upper.toInt := by omega
  exact hx.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq

private theorem bitvec8_eq_of_toInt_interval_three {x lower middle upper : BitVec 8}
    (hfirst : lower.toInt + 1 = middle.toInt)
    (hsecond : middle.toInt + 1 = upper.toInt)
    (hlower : lower.toInt ≤ x.toInt) (hupper : x.toInt ≤ upper.toInt) :
    x = lower ∨ x = middle ∨ x = upper := by
  have hx : x.toInt = lower.toInt ∨ x.toInt = middle.toInt ∨
      x.toInt = upper.toInt := by omega
  exact hx.imp BitVec.eq_of_toInt_eq
    (fun h ↦ Or.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq h)

theorem sintRange_abs_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (abs : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 abs
    128 129 128 129 127 128 129
    (by decide) (by decide) (by decide) (by decide)
  · simp [abs]
  · simp [abs]
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_two
      (x := x) (lower := 128) (upper := 129) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl <;> simp [abs]

theorem sintRange_abs_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (abs : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 abs
    128 130 129 127 128 126 (by decide) (by decide)
  · simp [abs]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [abs] at hz <;> subst z <;> decide

theorem sintRange_absUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 absUndef
    128 130 129 127 126 126 (by decide) (by decide)
  · simp [absUndef, absUndef?, poisonIf] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl
    · simp [absUndef, absUndef?, poisonIf, BitVec.negOverflow] at hz
    · simp [absUndef, absUndef?, poisonIf] at hz
      rcases hz with ⟨_, rfl⟩
      decide

theorem sintRange_popCount_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 popCount
    135 136 2 3 4 136 135
    (by decide) (by decide) (by decide) (by decide)
  · simp [popCount]
  · simp [popCount]
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_two
      (x := x) (lower := 135) (upper := 136) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl <;> simp [popCount]

theorem sintRange_popCount_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 popCount
    130 132 131 3 2 2 (by decide) (by decide)
  · simp [popCount]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [popCount] at hz <;> subst z <;> decide

theorem sintRange_ctlz_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (ctlz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 ctlz
    255 0 0 1 8 255 0
    (by decide) (by decide) (by decide) (by decide)
  · simp [ctlz]
  · simp [ctlz]
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_two
      (x := x) (lower := 255) (upper := 0) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl <;> simp [ctlz]

theorem sintRange_ctlz_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (ctlz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 ctlz
    255 1 0 8 0 7 (by decide) (by decide)
  · simp [ctlz]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [ctlz] at hz <;> subst z <;> decide

theorem sintRange_ctlzUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 ctlzUndef
    255 1 0 1 7 255 1
    (by decide) (by decide) (by decide) (by decide)
  · simp [ctlzUndef, ctlzUndef?, poisonIf]
  · simp [ctlzUndef, ctlzUndef?, poisonIf]
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_three
      (x := x) (lower := 255) (middle := 0) (upper := 1)
      (by decide) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl | rfl <;>
      simp [ctlzUndef, ctlzUndef?, poisonIf]

theorem sintRange_ctlzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 ctlzUndef
    0 2 1 7 6 6 (by decide) (by decide)
  · simp [ctlzUndef, ctlzUndef?, poisonIf]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;>
      simp [ctlzUndef, ctlzUndef?, poisonIf] at hz <;> subst z <;> decide

theorem sintRange_cttz_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 cttz
    128 129 0 1 7 129 128
    (by decide) (by decide) (by decide) (by decide)
  · simp [cttz] <;> decide
  · simp [cttz] <;> decide
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_two
      (x := x) (lower := 128) (upper := 129) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl <;> simp [cttz] <;> decide

theorem sintRange_cttz_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 cttz
    128 130 129 0 1 7 (by decide) (by decide)
  · simp [cttz] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [cttz] at hz <;> subst z <;> decide

theorem sintRange_cttzUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 cttzUndef
    128 129 0 1 7 129 128
    (by decide) (by decide) (by decide) (by decide)
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · intro x hxLower hxUpper
    have hx := bitvec8_eq_of_toInt_interval_two
      (x := x) (lower := 128) (upper := 129) (by decide) hxLower hxUpper
    rcases hx with rfl | rfl <;>
      simp [cttzUndef, cttzUndef?, poisonIf] <;> decide

theorem sintRange_cttzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 cttzUndef
    128 130 129 0 1 7 (by decide) (by decide)
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;>
      simp [cttzUndef, cttzUndef?, poisonIf] at hz <;> subst z <;> decide

private theorem msb_eq_true_iff_toInt_neg {n : Nat}
    (hn : ValidIntegerWidth n) (x : BitVec n) :
    x.msb = true ↔ x.toInt < 0 := by
  unfold ValidIntegerWidth at hn
  rw [BitVec.msb_eq_decide, decide_eq_true_eq, BitVec.toInt_neg_iff]
  have hnShape : n = (n - 1) + 1 := by omega
  have hp : 2 ^ n = 2 * 2 ^ (n - 1) := by
    calc
      2 ^ n = 2 ^ ((n - 1) + 1) := by rw [← hnShape]
      _ = 2 ^ (n - 1) * 2 := pow_succ _ _
      _ = 2 * 2 ^ (n - 1) := Nat.mul_comm _ _
  omega

private theorem abs_toInt_of_noOverflow {n : Nat}
    (hn : ValidIntegerWidth n) (x : BitVec n)
    (hnoOverflow : x.negOverflow = false) :
    x.abs.toInt = if x.toInt < 0 then -x.toInt else x.toInt := by
  rw [BitVec.abs_eq]
  by_cases hneg : x.toInt < 0
  · rw [if_pos hneg, if_pos ((msb_eq_true_iff_toInt_neg hn x).2 hneg)]
    rw [BitVec.toInt_neg_of_not_negOverflow]
    simpa using hnoOverflow
  · rw [if_neg hneg, if_neg]
    exact fun hmsb ↦ hneg ((msb_eq_true_iff_toInt_neg hn x).1 hmsb)

private theorem negOverflow_false_of_nonneg {n : Nat}
    (_hn : ValidIntegerWidth n) (x : BitVec n) (hx : 0 ≤ x.toInt) :
    x.negOverflow = false := by
  simp only [BitVec.negOverflow]
  apply decide_eq_false
  have hpow : (0 : Int) < 2 ^ (n - 1) :=
    Int.pow_pos (by decide : (0 : Int) < 2)
  intro heq
  omega

private theorem neg_negOverflow_false_of_nonneg {n : Nat}
    (hn : ValidIntegerWidth n) (x : BitVec n) (hx : 0 ≤ x.toInt) :
    (-x).negOverflow = false := by
  have hxNoOverflow := negOverflow_false_of_nonneg hn x hx
  have hnegInt : (-x).toInt = -x.toInt := by
    rw [BitVec.toInt_neg_of_not_negOverflow]
    simpa using hxNoOverflow
  have hxUpper := BitVec.toInt_le (x := x)
  simp only [BitVec.negOverflow]
  apply decide_eq_false
  intro heq
  rw [hnegInt] at heq
  omega

private theorem abs_eq_self_of_nonneg {n : Nat}
    (hn : ValidIntegerWidth n) (x : BitVec n) (hx : 0 ≤ x.toInt) :
    x.abs = x := by
  rw [BitVec.abs_eq, if_neg]
  intro hmsb
  exact (not_lt_of_ge hx) ((msb_eq_true_iff_toInt_neg hn x).1 hmsb)

private theorem abs_neg_eq_self_of_nonneg {n : Nat}
    (hn : ValidIntegerWidth n) (x : BitVec n) (hx : 0 ≤ x.toInt) :
    (-x).abs = x := by
  by_cases hxZero : x = 0
  · rw [hxZero, BitVec.abs_eq]
    simp
  have hxNoOverflow := negOverflow_false_of_nonneg hn x hx
  have hnegInt : (-x).toInt = -x.toInt := by
    rw [BitVec.toInt_neg_of_not_negOverflow]
    simpa using hxNoOverflow
  have hxIntNe : x.toInt ≠ 0 := by
    intro hzero
    apply hxZero
    apply BitVec.eq_of_toInt_eq
    simpa using hzero
  have hneg : (-x).toInt < 0 := by omega
  rw [BitVec.abs_eq, if_pos ((msb_eq_true_iff_toInt_neg hn (-x)).2 hneg)]
  simp

private theorem mem_interval_of_toInt_between {n : Nat}
    {interval : SIntRange n} {x y z : SignedBitVec n}
    (hx : x ∈ (interval : Set (SignedBitVec n)))
    (hy : y ∈ (interval : Set (SignedBitVec n)))
    (hz : min x.bitvec.toInt y.bitvec.toInt ≤ z.bitvec.toInt ∧
      z.bitvec.toInt ≤ max x.bitvec.toInt y.bitvec.toInt) :
    z ∈ (interval : Set (SignedBitVec n)) := by
  apply IntervalDomain.mem_interval_of_between hx hy
  rcases le_total x y with hxy | hyx
  · rw [min_eq_left hxy, max_eq_right hxy]
    have hxyInt : x.bitvec.toInt ≤ y.bitvec.toInt := hxy
    simpa [min_eq_left hxyInt, max_eq_right hxyInt] using hz
  · rw [min_eq_right hyx, max_eq_left hyx]
    have hyxInt : y.bitvec.toInt ≤ x.bitvec.toInt := hyx
    simpa [min_eq_right hyxInt, max_eq_left hyxInt] using hz

theorem sintRange_absUndef_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    ForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (absUndef : ConcreteOp (BitVec n) (BitVec n)) := by
  rw [SIntRange.forwardComplete_iff_ordConnected]
  intro interval
  constructor
  rintro a ⟨x, hx, ha⟩ b ⟨y, hy, hb⟩ z hz
  have haData : x.bitvec.negOverflow = false ∧ x.bitvec.abs = a.bitvec := by
    simpa [SIntRange.orderedRelational, ConcreteOp.transport, absUndef,
      absUndef?, poisonIf] using ha
  have hbData : y.bitvec.negOverflow = false ∧ y.bitvec.abs = b.bitvec := by
    simpa [SIntRange.orderedRelational, ConcreteOp.transport, absUndef,
      absUndef?, poisonIf] using hb
  change a.bitvec.toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ b.bitvec.toInt at hz
  have haAbs := abs_toInt_of_noOverflow hn x.bitvec haData.1
  have hbAbs := abs_toInt_of_noOverflow hn y.bitvec hbData.1
  have haInt : a.bitvec.toInt =
      if x.bitvec.toInt < 0 then -x.bitvec.toInt else x.bitvec.toInt := by
    rw [← haData.2]
    exact haAbs
  have hbInt : b.bitvec.toInt =
      if y.bitvec.toInt < 0 then -y.bitvec.toInt else y.bitvec.toInt := by
    rw [← hbData.2]
    exact hbAbs
  have haNonnegative : 0 ≤ a.bitvec.toInt := by
    rw [haInt]
    split <;> omega
  have hzNonnegative : 0 ≤ z.bitvec.toInt := haNonnegative.trans hz.1
  have hzNoOverflow := negOverflow_false_of_nonneg hn z.bitvec hzNonnegative
  have hnegZNoOverflow :=
    neg_negOverflow_false_of_nonneg hn z.bitvec hzNonnegative
  have hzAbs := abs_eq_self_of_nonneg hn z.bitvec hzNonnegative
  have hnegZAbs := abs_neg_eq_self_of_nonneg hn z.bitvec hzNonnegative
  have hnegZInt : (-z.bitvec).toInt = -z.bitvec.toInt := by
    rw [BitVec.toInt_neg_of_not_negOverflow]
    simpa using hzNoOverflow
  by_cases hxNeg : x.bitvec.toInt < 0 <;>
    by_cases hyNeg : y.bitvec.toInt < 0
  · refine ⟨⟨-z.bitvec⟩, ?_, ?_⟩
    · apply mem_interval_of_toInt_between hx hy
      change min x.bitvec.toInt y.bitvec.toInt ≤ (-z.bitvec).toInt ∧
        (-z.bitvec).toInt ≤ max x.bitvec.toInt y.bitvec.toInt
      rw [hnegZInt]
      simp [hxNeg, hyNeg] at haInt hbInt
      have hyz : y.bitvec.toInt ≤ -z.bitvec.toInt := by omega
      have hzx : -z.bitvec.toInt ≤ x.bitvec.toInt := by omega
      exact ⟨(min_le_right _ _).trans hyz,
        hzx.trans (le_max_left _ _)⟩
    · change z ∈ (SignedBitVec.equiv n) '' absUndef (-z.bitvec)
      refine ⟨z.bitvec, ?_, rfl⟩
      change absUndef? (-z.bitvec) = some z.bitvec
      simp [absUndef?, poisonIf, hnegZNoOverflow, hnegZAbs]
  · refine ⟨⟨z.bitvec⟩, ?_, ?_⟩
    · apply mem_interval_of_toInt_between hx hy
      simp [hxNeg, hyNeg] at haInt hbInt
      have hxz : x.bitvec.toInt ≤ z.bitvec.toInt := by omega
      have hzy : z.bitvec.toInt ≤ y.bitvec.toInt := by omega
      exact ⟨(min_le_left _ _).trans hxz,
        hzy.trans (le_max_right _ _)⟩
    · change z ∈ (SignedBitVec.equiv n) '' absUndef z.bitvec
      refine ⟨z.bitvec, ?_, rfl⟩
      change absUndef? z.bitvec = some z.bitvec
      simp [absUndef?, poisonIf, hzNoOverflow, hzAbs]
  · refine ⟨⟨-z.bitvec⟩, ?_, ?_⟩
    · apply mem_interval_of_toInt_between hx hy
      change min x.bitvec.toInt y.bitvec.toInt ≤ (-z.bitvec).toInt ∧
        (-z.bitvec).toInt ≤ max x.bitvec.toInt y.bitvec.toInt
      rw [hnegZInt]
      simp [hxNeg, hyNeg] at haInt hbInt
      have hyz : y.bitvec.toInt ≤ -z.bitvec.toInt := by omega
      have hzx : -z.bitvec.toInt ≤ x.bitvec.toInt := by omega
      exact ⟨(min_le_right _ _).trans hyz,
        hzx.trans (le_max_left _ _)⟩
    · change z ∈ (SignedBitVec.equiv n) '' absUndef (-z.bitvec)
      refine ⟨z.bitvec, ?_, rfl⟩
      change absUndef? (-z.bitvec) = some z.bitvec
      simp [absUndef?, poisonIf, hnegZNoOverflow, hnegZAbs]
  · refine ⟨⟨z.bitvec⟩, ?_, ?_⟩
    · apply mem_interval_of_toInt_between hx hy
      simp [hxNeg, hyNeg] at haInt hbInt
      have hxz : x.bitvec.toInt ≤ z.bitvec.toInt := by omega
      have hzy : z.bitvec.toInt ≤ y.bitvec.toInt := by omega
      exact ⟨(min_le_left _ _).trans hxz,
        hzy.trans (le_max_right _ _)⟩
    · change z ∈ (SignedBitVec.equiv n) '' absUndef z.bitvec
      refine ⟨z.bitvec, ?_, rfl⟩
      change absUndef? z.bitvec = some z.bitvec
      simp [absUndef?, poisonIf, hzNoOverflow, hzAbs]

end SynthXfer.LLVM
