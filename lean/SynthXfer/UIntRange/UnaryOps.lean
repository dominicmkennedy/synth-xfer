import SynthXfer.UIntRange.Witnesses

/-!
# Unary LLVM operations in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

theorem uintRange_abs_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (abs : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 abs 0 129 128 128 0 127
    (by decide) (by decide)
  · simp [abs]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [abs] at hz <;> subst z <;> decide

theorem uintRange_absUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (absUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 absUndef 0 128 1 1 0 0
    (by decide) (by decide)
  · simp [absUndef, absUndef?, poisonIf] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl
    · simp [absUndef, absUndef?, poisonIf] at hz
      rcases hz with ⟨_, hz⟩
      rw [← hz]
      decide
    · simp [absUndef, absUndef?, poisonIf] at hz
      have h := hz.1
      have hf : (128#8).negOverflow ≠ false := by decide
      exact (hf h).elim

theorem uintRange_popCount_i8_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 popCount 7 8 1 2 3 8 7
    (by decide) (by decide) (by decide) (by decide)
  · simp [popCount]
  · simp [popCount]
  · simp [popCount, ConcreteOp.ofTotal]
    decide

theorem uintRange_popCount_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (popCount : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 popCount 0 4 3 2 0 1
    (by decide) (by decide)
  · simp [popCount]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [popCount] at hz <;> subst z <;> decide

theorem uintRange_ctlzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (ctlzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 ctlzUndef 0 2 1 7 6 6
    (by decide) (by decide)
  · simp [ctlzUndef, ctlzUndef?, poisonIf]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;>
      simp [ctlzUndef, ctlzUndef?, poisonIf] at hz <;> subst z <;> decide

theorem uintRange_cttz_i8_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 cttz 0 1 0 1 8 1 0
    (by decide) (by decide) (by decide) (by decide)
  · simp [cttz] <;> decide
  · simp [cttz] <;> decide
  · simp [cttz, ConcreteOp.ofTotal]
    decide

theorem uintRange_cttz_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (cttz : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 cttz 0 2 1 0 1 8
    (by decide) (by decide)
  · simp [cttz] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [cttz] at hz <;> subst z <;> decide

theorem uintRange_cttzUndef_i8_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryForwardIncompleteOfGap_i8 cttzUndef 3 4 0 1 2 3 4
    (by decide) (by decide) (by decide) (by decide)
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · simp [cttzUndef, cttzUndef?, poisonIf, ConcreteOp.ofOption]
    decide

theorem uintRange_cttzUndef_i8_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (cttzUndef : ConcreteOp (BitVec 8) (BitVec 8)) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 cttzUndef 0 2 1 0 1 1
    (by decide) (by decide)
  · simp [cttzUndef, cttzUndef?, poisonIf] <;> decide
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;>
      simp [cttzUndef, cttzUndef?, poisonIf] at hz <;> subst z <;> decide

private theorem orderedClz_antitone {n : Nat} (hn : 0 < n) :
    Antitone (UIntRange.orderedUnary (BitVec.clz : BitVec n → BitVec n)) := by
  intro x y hxy
  change y.bitvec.clz.toNat ≤ x.bitvec.clz.toNat
  change x.bitvec.toNat ≤ y.bitvec.toNat at hxy
  by_cases hx : x.bitvec = 0
  · have hyLe := BitVec.clz_le (x := y.bitvec)
    change y.bitvec.clz.toNat ≤ (BitVec.ofNat n n).toNat at hyLe
    have hzero : (0 : BitVec n).clz = BitVec.ofNat n n :=
      BitVec.clz_eq_iff_eq_zero.mpr rfl
    rw [hx, hzero]
    exact hyLe
  by_contra hnot
  have hclz : x.bitvec.clz.toNat < y.bitvec.clz.toNat := by omega
  have hy : y.bitvec ≠ 0 := by
    intro hy
    have hyNat : y.bitvec.toNat = 0 := by simp [hy]
    exact hx (BitVec.eq_of_toNat_eq (Nat.eq_zero_of_le_zero (by omega)))
  have hxLower := BitVec.two_pow_sub_clz_le_toNat_of_ne_zero hn hx
  have hyUpper := BitVec.toNat_lt_two_pow_sub_clz (x := y.bitvec)
  have hxClzLe := BitVec.clz_le (x := x.bitvec)
  have hyClzLe := BitVec.clz_le (x := y.bitvec)
  have hp : 2 ^ (n - y.bitvec.clz.toNat) ≤
      2 ^ (n - 1 - x.bitvec.clz.toNat) := by
    apply Nat.pow_le_pow_right (by omega)
    omega
  omega

private theorem orderedClz_intermediate {n : Nat} (hn : 0 < n) :
    ∀ a b z : UnsignedBitVec n, a ≤ b →
      UIntRange.orderedUnary BitVec.clz b ≤ z →
      z ≤ UIntRange.orderedUnary BitVec.clz a →
      ∃ x ∈ Set.Icc a b, UIntRange.orderedUnary BitVec.clz x = z := by
  intro a b z hab hbz hza
  change a.bitvec.toNat ≤ b.bitvec.toNat at hab
  change b.bitvec.clz.toNat ≤ z.bitvec.toNat at hbz
  change z.bitvec.toNat ≤ a.bitvec.clz.toNat at hza
  have clzLeN (v : BitVec n) : v.clz.toNat ≤ n := by
    have h := BitVec.clz_le (x := v)
    change v.clz.toNat ≤ (BitVec.ofNat n n).toNat at h
    simpa [BitVec.toNat_ofNat, Nat.mod_eq_of_lt Nat.lt_two_pow_self] using h
  by_cases hzaEq : z.bitvec.toNat = a.bitvec.clz.toNat
  · exact ⟨a, ⟨le_rfl, hab⟩,
      UnsignedBitVec.ext (BitVec.eq_of_toNat_eq hzaEq.symm)⟩
  by_cases hzbEq : z.bitvec.toNat = b.bitvec.clz.toNat
  · exact ⟨b, ⟨hab, le_rfl⟩,
      UnsignedBitVec.ext (BitVec.eq_of_toNat_eq hzbEq.symm)⟩
  have hzaStrict : z.bitvec.toNat < a.bitvec.clz.toNat := by omega
  have hbzStrict : b.bitvec.clz.toNat < z.bitvec.toNat := by omega
  have hb : b.bitvec ≠ 0 := by
    intro hb
    have hbNat : b.bitvec.toNat = 0 := by simp [hb]
    have haNat : a.bitvec.toNat = 0 := Nat.eq_zero_of_le_zero (by omega)
    have ha : a.bitvec = 0 := BitVec.eq_of_toNat_eq haNat
    have hc : a.bitvec.clz.toNat = b.bitvec.clz.toNat := by simp [ha, hb]
    omega
  have hzLeN : z.bitvec.toNat < n := by
    have haClzLe := clzLeN a.bitvec
    omega
  let exponent := n - 1 - z.bitvec.toNat
  let q : BitVec n := BitVec.ofNat n (2 ^ exponent)
  have hexponent : exponent < n := by simp [exponent]; omega
  have hpowLt : 2 ^ exponent < 2 ^ n :=
    Nat.pow_lt_pow_right (by omega) hexponent
  have hqNat : q.toNat = 2 ^ exponent := by
    simp [q, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hpowLt]
  have hq : q ≠ 0 := by
    intro hq
    have := congrArg BitVec.toNat hq
    simp [hqNat] at this
  have hqLower := BitVec.two_pow_sub_clz_le_toNat_of_ne_zero hn hq
  have hqUpper := BitVec.toNat_lt_two_pow_sub_clz (x := q)
  rw [hqNat] at hqLower hqUpper
  have hqClzLe := clzLeN q
  have hqClz : q.clz.toNat = z.bitvec.toNat := by
    have hpowLower : n - 1 - q.clz.toNat ≤ exponent :=
      (Nat.pow_le_pow_iff_right (by omega)).mp hqLower
    have hpowUpper : exponent < n - q.clz.toNat :=
      (Nat.pow_lt_pow_iff_right (by omega)).mp hqUpper
    simp [exponent] at hpowLower hpowUpper
    omega
  have haClzLe := clzLeN a.bitvec
  have hbClzLe := clzLeN b.bitvec
  have hbLower := BitVec.two_pow_sub_clz_le_toNat_of_ne_zero hn hb
  have haLeQ : a.bitvec.toNat ≤ q.toNat := by
    by_cases ha : a.bitvec = 0
    · simp [ha]
    · have haUpper := BitVec.toNat_lt_two_pow_sub_clz (x := a.bitvec)
      have hp : 2 ^ (n - a.bitvec.clz.toNat) ≤ 2 ^ exponent := by
        apply Nat.pow_le_pow_right (by omega)
        simp [exponent]
        omega
      omega
  have hqLeB : q.toNat ≤ b.bitvec.toNat := by
    have hp : 2 ^ exponent ≤
        2 ^ (n - 1 - b.bitvec.clz.toNat) := by
      apply Nat.pow_le_pow_right (by omega)
      simp [exponent]
      omega
    omega
  exact ⟨⟨q⟩, ⟨haLeQ, hqLeB⟩,
    UnsignedBitVec.ext (BitVec.eq_of_toNat_eq hqClz)⟩

private theorem orderedClz_image_ordConnected {n : Nat} (hn : 0 < n) :
    ∀ i : UIntRange n,
      (UIntRange.orderedUnary BitVec.clz ''
        (i : Set (UnsignedBitVec n))).OrdConnected := by
  have h := (IntervalDomain.forwardComplete_iff_ordConnected
    (ConcreteOp.ofTotal
      (UIntRange.orderedUnary (BitVec.clz : BitVec n → BitVec n)))).mp
        (IntervalDomain.forwardComplete_of_antitone_intermediate _
          (orderedClz_antitone hn) (orderedClz_intermediate hn))
  simpa using h

theorem uintRange_ctlz_forwardComplete {n : Nat} (hn : ValidIntegerWidth n) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (ctlz : ConcreteOp (BitVec n) (BitVec n)) := by
  change ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
    (ConcreteOp.ofTotal BitVec.clz)
  rw [UIntRange.forwardComplete_ofTotal_iff_ordConnected]
  exact orderedClz_image_ordConnected hn

theorem uintRange_ctlz_backwardComplete {n : Nat} (hn : ValidIntegerWidth n) :
    BackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (ctlz : ConcreteOp (BitVec n) (BitVec n)) := by
  change BackwardComplete (UIntRange.domain n) (UIntRange.domain n)
    (ConcreteOp.ofTotal BitVec.clz)
  rw [UIntRange.backwardComplete_ofTotal_iff_boundedByEndpointImages]
  intro lower upper hlowerUpper x hx
  have hanti := orderedClz_antitone hn
  rw [min_eq_right (hanti hlowerUpper), max_eq_left (hanti hlowerUpper)]
  exact ⟨hanti hx.2, hanti hx.1⟩

private theorem abs_toNat_le_half {n : Nat} (hn : 0 < n) (x : BitVec n) :
    x.abs.toNat ≤ 2 ^ (n - 1) := by
  rcases n with _ | n
  · omega
  rw [BitVec.toNat_abs, BitVec.msb_eq_decide]
  have hxLt := x.isLt
  simp only [Nat.add_one_sub_one, decide_eq_true_eq]
  split <;> rename_i h
  · simp only [Nat.pow_succ]
    omega
  · omega

private theorem abs_eq_self_of_toNat_le_half {n : Nat} (hn : 0 < n)
    (x : BitVec n) (hx : x.toNat ≤ 2 ^ (n - 1)) : x.abs = x := by
  apply BitVec.eq_of_toNat_eq
  rcases n with _ | n
  · omega
  simp only [Nat.add_one_sub_one] at hx
  rw [BitVec.toNat_abs, BitVec.msb_eq_decide]
  have hxLt := x.isLt
  simp only [Nat.add_one_sub_one, decide_eq_true_eq, Nat.pow_succ]
  split <;> rename_i h
  · omega
  · rfl

private theorem neg_toNat_eq_sub_of_pos {n : Nat} {x : BitVec n}
    (hx : 0 < x.toNat) : (-x).toNat = 2 ^ n - x.toNat := by
  rw [BitVec.toNat_neg, Nat.mod_eq_of_lt]
  have hxLt := x.isLt
  omega

private theorem abs_neg_eq_self_of_toNat_le_half {n : Nat} (hn : 0 < n)
    (x : BitVec n) (hx : x.toNat ≤ 2 ^ (n - 1)) : (-x).abs = x := by
  by_cases hx0 : x = 0
  · subst x
    apply BitVec.eq_of_toNat_eq
    simp [BitVec.toNat_abs]
  have hxPos := BitVec.toNat_pos_of_ne_zero hx0
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_abs, BitVec.msb_eq_decide,
    neg_toNat_eq_sub_of_pos hxPos]
  rcases n with _ | n
  · omega
  simp only [Nat.add_one_sub_one] at hx
  have hxLt := x.isLt
  simp only [Nat.add_one_sub_one, Nat.pow_succ, decide_eq_true_eq]
  have hsign : 2 ^ n ≤ 2 ^ n * 2 - x.toNat := by omega
  rw [if_pos hsign]
  omega

private theorem orderedAbs_image_ordConnected {n : Nat} (hn : 0 < n)
    (i : UIntRange n) :
    (UIntRange.orderedUnary BitVec.abs ''
      (i : Set (UnsignedBitVec n))).OrdConnected := by
  constructor
  rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩ z hz
  have hzy : z.bitvec.toNat ≤ y.bitvec.abs.toNat := hz.2
  have hzHalf : z.bitvec.toNat ≤ 2 ^ (n - 1) :=
    hzy.trans (abs_toNat_le_half hn y.bitvec)
  have hzAbs : z.bitvec.abs = z.bitvec :=
    abs_eq_self_of_toNat_le_half hn z.bitvec hzHalf
  have hnegAbs : (-z.bitvec).abs = z.bitvec :=
    abs_neg_eq_self_of_toNat_le_half hn z.bitvec hzHalf
  have hxLt := x.bitvec.isLt
  have hyLt := y.bitvec.isLt
  have hzLt := z.bitvec.isLt
  rcases n with _ | n
  · omega
  simp only [UIntRange.orderedUnary] at hz
  by_cases hxm : 2 ^ n ≤ x.bitvec.toNat <;>
    by_cases hym : 2 ^ n ≤ y.bitvec.toNat
  · have hxmsb : x.bitvec.msb = true := by
      rw [BitVec.msb_eq_decide]
      simp [hxm]
    have hymsb : y.bitvec.msb = true := by
      rw [BitVec.msb_eq_decide]
      simp [hym]
    simp [hxmsb, hymsb, Nat.pow_succ] at hz
    have hzPos : 0 < z.bitvec.toNat := by omega
    have hnegNat := neg_toNat_eq_sub_of_pos hzPos
    simp only [Nat.pow_succ] at hnegNat
    have hyNeg : y.bitvec.toNat ≤ (-z.bitvec).toNat := by
      rw [hnegNat]
      apply Nat.le_sub_of_add_le
      have := (Nat.le_sub_iff_add_le hyLt.le).mp hz.2
      omega
    have hnegX : (-z.bitvec).toNat ≤ x.bitvec.toNat := by
      rw [hnegNat]
      apply (Nat.sub_le_iff_le_add).2
      omega
    refine ⟨⟨-z.bitvec⟩, ?_, UnsignedBitVec.ext hnegAbs⟩
    cases i with
    | none => exact False.elim (show False from hx)
    | some iv =>
        exact ⟨hy.1.trans hyNeg, hnegX.trans hx.2⟩
  · have hxmsb : x.bitvec.msb = true := by
      rw [BitVec.msb_eq_decide]
      simp [hxm]
    have hymsb : y.bitvec.msb = false := by
      rw [BitVec.msb_eq_decide]
      simp [hym]
    simp [hxmsb, hymsb, Nat.pow_succ] at hz
    have hzPos : 0 < z.bitvec.toNat := by omega
    have hnegNat := neg_toNat_eq_sub_of_pos hzPos
    simp only [Nat.pow_succ] at hnegNat
    have hyNeg : y.bitvec.toNat ≤ (-z.bitvec).toNat := by
      rw [hnegNat]
      apply Nat.le_sub_of_add_le
      omega
    have hnegX : (-z.bitvec).toNat ≤ x.bitvec.toNat := by
      rw [hnegNat]
      apply (Nat.sub_le_iff_le_add).2
      omega
    refine ⟨⟨-z.bitvec⟩, ?_, UnsignedBitVec.ext hnegAbs⟩
    cases i with
    | none => exact False.elim (show False from hx)
    | some iv => exact ⟨hy.1.trans hyNeg, hnegX.trans hx.2⟩
  · have hxmsb : x.bitvec.msb = false := by
      rw [BitVec.msb_eq_decide]
      simp [hxm]
    have hymsb : y.bitvec.msb = true := by
      rw [BitVec.msb_eq_decide]
      simp [hym]
    simp [hxmsb, hymsb, Nat.pow_succ] at hz
    have hzY : z.bitvec.toNat ≤ y.bitvec.toNat := by omega
    refine ⟨⟨z.bitvec⟩, ?_, UnsignedBitVec.ext hzAbs⟩
    cases i with
    | none => exact False.elim (show False from hx)
    | some iv => exact ⟨hx.1.trans hz.1, hzY.trans hy.2⟩
  · have hxmsb : x.bitvec.msb = false := by
      rw [BitVec.msb_eq_decide]
      simp [hxm]
    have hymsb : y.bitvec.msb = false := by
      rw [BitVec.msb_eq_decide]
      simp [hym]
    simp [hxmsb, hymsb] at hz
    refine ⟨⟨z.bitvec⟩, ?_, UnsignedBitVec.ext hzAbs⟩
    cases i with
    | none => exact False.elim (show False from hx)
    | some iv => exact ⟨hx.1.trans hz.1, hz.2.trans hy.2⟩

theorem uintRange_abs_forwardComplete {n : Nat} (hn : ValidIntegerWidth n) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (abs : ConcreteOp (BitVec n) (BitVec n)) := by
  change ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
    (ConcreteOp.ofTotal BitVec.abs)
  rw [UIntRange.forwardComplete_ofTotal_iff_ordConnected]
  exact orderedAbs_image_ordConnected hn

private theorem eq_intMin_of_abs_toNat_eq_half {n : Nat} (hn : 0 < n)
    {x : BitVec n} (hx : x.abs.toNat = 2 ^ (n - 1)) :
    x = BitVec.intMin n := by
  have habsMsb : x.abs.msb = true := by
    rw [BitVec.msb_eq_decide]
    simp [hx]
  rw [BitVec.msb_abs] at habsMsb
  simpa [hn] using habsMsb

theorem uintRange_absUndef_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (absUndef : ConcreteOp (BitVec n) (BitVec n)) := by
  rw [UIntRange.forwardComplete_iff_ordConnected]
  intro i
  have habs := orderedAbs_image_ordConnected hn i
  constructor
  rintro a ⟨x, hx, ha⟩ b ⟨y, hy, hb⟩ z hz
  have haData : x.bitvec.negOverflow = false ∧ x.bitvec.abs = a.bitvec := by
    simpa [UIntRange.orderedRelational, ConcreteOp.transport, absUndef,
      absUndef?, poisonIf] using ha
  have hbData : y.bitvec.negOverflow = false ∧ y.bitvec.abs = b.bitvec := by
    simpa [UIntRange.orderedRelational, ConcreteOp.transport, absUndef,
      absUndef?, poisonIf] using hb
  have haAbs : UIntRange.orderedUnary BitVec.abs x = a :=
    UnsignedBitVec.ext haData.2
  have hbAbs : UIntRange.orderedUnary BitVec.abs y = b :=
    UnsignedBitVec.ext hbData.2
  have hzAbsImage := habs.out
    ⟨x, hx, haAbs⟩ ⟨y, hy, hbAbs⟩ hz
  rcases hzAbsImage with ⟨t, ht, htResult⟩
  have hbLe := abs_toNat_le_half hn y.bitvec
  have hbLt : b.bitvec.toNat < 2 ^ (n - 1) := by
    rw [← hbData.2]
    apply lt_of_le_of_ne hbLe
    intro heq
    have hyMin := eq_intMin_of_abs_toNat_eq_half hn heq
    have hover : y.bitvec.negOverflow = true := by
      rw [BitVec.negOverflow_eq, hyMin]
      simp [show 0 < n from hn]
    exact Bool.noConfusion (hover.symm.trans hbData.1)
  have hzLt : z.bitvec.toNat < 2 ^ (n - 1) := lt_of_le_of_lt hz.2 hbLt
  have htNotMin : t.bitvec ≠ BitVec.intMin n := by
    intro htMin
    have htHalf : t.bitvec.abs.toNat = 2 ^ (n - 1) := by
      rw [htMin, BitVec.abs_intMin, BitVec.toNat_intMin_of_pos hn]
    have htResultNat := congrArg (fun v : UnsignedBitVec n ↦ v.bitvec.toNat)
      htResult
    change t.bitvec.abs.toNat = z.bitvec.toNat at htResultNat
    omega
  have htNoOverflow : t.bitvec.negOverflow = false := by
    rw [BitVec.negOverflow_eq]
    simp [htNotMin]
  refine ⟨t, ht, ?_⟩
  change z ∈ (UnsignedBitVec.equiv n) '' absUndef t.bitvec
  refine ⟨t.bitvec.abs, ?_, ?_⟩
  · change absUndef? t.bitvec = some t.bitvec.abs
    simp [absUndef?, poisonIf, htNoOverflow]
  · exact htResult

theorem uintRange_ctlzUndef_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (ctlzUndef : ConcreteOp (BitVec n) (BitVec n)) := by
  rw [UIntRange.forwardComplete_iff_ordConnected]
  intro i
  have hctlz := orderedClz_image_ordConnected hn i
  constructor
  rintro a ⟨x, hx, ha⟩ b ⟨y, hy, hb⟩ z hz
  have haData : (x.bitvec == 0) = false ∧ x.bitvec.clz = a.bitvec := by
    simpa [UIntRange.orderedRelational, ConcreteOp.transport, ctlzUndef,
      ctlzUndef?, poisonIf] using ha
  have hbData : (y.bitvec == 0) = false ∧ y.bitvec.clz = b.bitvec := by
    simpa [UIntRange.orderedRelational, ConcreteOp.transport, ctlzUndef,
      ctlzUndef?, poisonIf] using hb
  have haClz : UIntRange.orderedUnary BitVec.clz x = a :=
    UnsignedBitVec.ext haData.2
  have hbClz : UIntRange.orderedUnary BitVec.clz y = b :=
    UnsignedBitVec.ext hbData.2
  rcases hctlz.out ⟨x, hx, haClz⟩ ⟨y, hy, hbClz⟩ hz with
    ⟨t, ht, htResult⟩
  have hyNe : y.bitvec ≠ 0 := by
    simpa using hbData.1
  have hyClzLtBV := (BitVec.clz_lt_iff_ne_zero (x := y.bitvec)).mpr hyNe
  have hyClzLt : y.bitvec.clz.toNat < n := by
    change y.bitvec.clz.toNat < (BitVec.ofNat n n).toNat at hyClzLtBV
    simpa [BitVec.toNat_ofNat, Nat.mod_eq_of_lt Nat.lt_two_pow_self] using
      hyClzLtBV
  have htNe : t.bitvec ≠ 0 := by
    intro htZero
    have htResultNat := congrArg (fun v : UnsignedBitVec n ↦ v.bitvec.toNat)
      htResult
    change t.bitvec.clz.toNat = z.bitvec.toNat at htResultNat
    have hzLeB : z.bitvec.toNat ≤ b.bitvec.toNat := hz.2
    rw [← hbData.2] at hzLeB
    have htClz : t.bitvec.clz = BitVec.ofNat n n :=
      BitVec.clz_eq_iff_eq_zero.mpr htZero
    rw [htClz] at htResultNat
    have hnMod : (BitVec.ofNat n n).toNat = n := by
      simp [BitVec.toNat_ofNat, Nat.mod_eq_of_lt Nat.lt_two_pow_self]
    rw [hnMod] at htResultNat
    omega
  refine ⟨t, ht, ?_⟩
  change z ∈ (UnsignedBitVec.equiv n) '' ctlzUndef t.bitvec
  refine ⟨t.bitvec.clz, ?_, ?_⟩
  · change ctlzUndef? t.bitvec = some t.bitvec.clz
    simp [ctlzUndef?, poisonIf]
    exact htNe
  · exact htResult

end SynthXfer.LLVM
