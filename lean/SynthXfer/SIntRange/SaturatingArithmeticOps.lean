import SynthXfer.SIntRange.NoWrapArithmetic
import Mathlib.Algebra.Order.Ring.Int
import Std.Tactic.BVDecide

/-!
# Saturating arithmetic in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

private def signedClamp (n : Nat) (value : Int) : Int :=
  max (signedMin n) (min value (signedMax n))

private theorem clampSigned_toInt {n : Nat} (hn : ValidIntegerWidth n)
    (value : Int) : (clampSigned n value).toInt = signedClamp n value := by
  unfold ValidIntegerWidth at hn
  have hnShape : n = (n - 1) + 1 := by omega
  have hpowNat : 2 ^ n = 2 * 2 ^ (n - 1) := by
    calc
      2 ^ n = 2 ^ ((n - 1) + 1) := by rw [← hnShape]
      _ = 2 ^ (n - 1) * 2 := pow_succ _ _
      _ = 2 * 2 ^ (n - 1) := Nat.mul_comm _ _
  have hpowInt : ((2 ^ n : Nat) : Int) =
      2 * ((2 ^ (n - 1) : Nat) : Int) := by
    have h := congrArg (fun value : Nat ↦ (value : Int)) hpowNat
    simpa only [Nat.cast_mul, Nat.cast_ofNat] using h
  have hhalf : (((2 ^ n : Nat) : Int) / 2) =
      ((2 ^ (n - 1) : Nat) : Int) := by
    rw [hpowInt]
    simp
  have hhalfPlus : ((((2 ^ n : Nat) : Int) + 1) / 2) =
      ((2 ^ (n - 1) : Nat) : Int) := by
    rw [hpowInt]
    rw [Int.add_ediv_of_dvd_left (by simp)]
    simp
  rw [clampSigned, BitVec.toInt_ofInt, Int.bmod_eq_of_le]
  · rfl
  · rw [hhalf]
    simp only [signedMin, signedMax, show n ≠ 0 by omega,
      ↓reduceIte]
    exact le_max_left _ _
  · rw [hhalfPlus]
    simp only [signedMin, signedMax, show n ≠ 0 by omega,
      ↓reduceIte]
    have hp : (0 : Int) < ((2 ^ (n - 1) : Nat) : Int) := by
      exact_mod_cast Nat.two_pow_pos (n - 1)
    have h := min_le_right value (((2 ^ (n - 1) : Nat) : Int) - 1)
    have := max_le (by omega) h
    omega

private theorem signedClamp_mono {n : Nat} : Monotone (signedClamp n) := by
  intro a b hab
  exact max_le_max le_rfl (min_le_min hab le_rfl)

private theorem saddSatFn_toInt {n : Nat} (hn : ValidIntegerWidth n)
    (x y : BitVec n) :
    (saddSatFn x y).toInt = signedClamp n (x.toInt + y.toInt) := by
  rw [saddSatFn, clampSigned_toInt hn]

private theorem ssubSatFn_toInt {n : Nat} (hn : ValidIntegerWidth n)
    (x y : BitVec n) :
    (ssubSatFn x y).toInt = signedClamp n (x.toInt - y.toInt) := by
  rw [ssubSatFn, clampSigned_toInt hn]

private theorem smulSatFn_toInt {n : Nat} (hn : ValidIntegerWidth n)
    (x y : BitVec n) :
    (smulSatFn x y).toInt = signedClamp n (x.toInt * y.toInt) := by
  rw [smulSatFn, clampSigned_toInt hn]

private theorem signedMin_le_toInt {n : Nat} (hn : ValidIntegerWidth n)
    (x : BitVec n) : signedMin n ≤ x.toInt := by
  have h := BitVec.le_toInt x
  simpa [signedMin, show n ≠ 0 by exact Nat.ne_of_gt hn] using h

private theorem toInt_le_signedMax {n : Nat} (hn : ValidIntegerWidth n)
    (x : BitVec n) : x.toInt ≤ signedMax n := by
  have h := BitVec.toInt_le (x := x)
  simpa [signedMax, show n ≠ 0 by exact Nat.ne_of_gt hn] using h

private theorem signedMin_le_signedMax {n : Nat} (hn : ValidIntegerWidth n) :
    signedMin n ≤ signedMax n := by
  have h := signedMin_le_toInt hn (0 : BitVec n)
  have h' := toInt_le_signedMax hn (0 : BitVec n)
  omega

theorem sintRange_saddSat_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (saddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = saddSatFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, saddSat] using ha
  have hbEq : b.bitvec = saddSatFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, saddSat] using hb
  have haInt : a.bitvec.toInt =
      signedClamp n (xa.bitvec.toInt + ya.bitvec.toInt) := by
    rw [haEq, saddSatFn_toInt hn]
  have hbInt : b.bitvec.toInt =
      signedClamp n (xb.bitvec.toInt + yb.bitvec.toInt) := by
    rw [hbEq, saddSatFn_toInt hn]
  change a.bitvec.toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ b.bitvec.toInt at hz
  have hzLower := signedMin_le_toInt hn z.bitvec
  have hzUpper := toInt_le_signedMax hn z.bitvec
  have haLower := signedMin_le_toInt hn a.bitvec
  have hbUpper := toInt_le_signedMax hn b.bitvec
  have hMinMax := signedMin_le_signedMax hn
  by_cases hzMin : z.bitvec.toInt = signedMin n
  · have haz : a = z := SignedBitVec.ext (BitVec.eq_of_toInt_eq (by omega))
    subst z
    exact ⟨inputsA, hinputsA, ha⟩
  by_cases hzMax : z.bitvec.toInt = signedMax n
  · have hbz : b = z := SignedBitVec.ext (BitVec.eq_of_toInt_eq (by omega))
    subst z
    exact ⟨inputsB, hinputsB, hb⟩
  have hzMinLt : signedMin n < z.bitvec.toInt := by omega
  have hzLtMax : z.bitvec.toInt < signedMax n := by omega
  have hrawLower : xa.bitvec.toInt + ya.bitvec.toInt ≤ z.bitvec.toInt := by
    rw [haInt] at hz
    simp only [signedClamp] at hz
    omega
  have hrawUpper : z.bitvec.toInt ≤
      xb.bitvec.toInt + yb.bitvec.toInt := by
    rw [hbInt] at hz
    simp only [signedClamp] at hz
    omega
  obtain ⟨xInt, yInt, hxLower, hxUpper, hyLower, hyUpper, hsum⟩ :=
    IntBox.exists_add hrawLower hrawUpper
  let x : SignedBitVec n := ⟨BitVec.ofInt n xInt⟩
  let y : SignedBitVec n := ⟨BitVec.ofInt n yInt⟩
  have hxInt : x.bitvec.toInt = xInt :=
    toInt_ofInt_eq_of_between hn xInt xa.bitvec xb.bitvec hxLower hxUpper
  have hyInt : y.bitvec.toInt = yInt :=
    toInt_ofInt_eq_of_between hn yInt ya.bitvec yb.bitvec hyLower hyUpper
  have hxMem : x ∈ (intervals BinaryOperand.left : Set (SignedBitVec n)) := by
    apply IntervalDomain.mem_interval_of_between
      (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
    simpa [xa, xb, hxInt] using And.intro hxLower hxUpper
  have hyMem : y ∈ (intervals BinaryOperand.right : Set (SignedBitVec n)) := by
    apply IntervalDomain.mem_interval_of_between
      (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
    simpa [ya, yb, hyInt] using And.intro hyLower hyUpper
  let inputs : BinaryOperand → SignedBitVec n := fun k ↦
    if k = BinaryOperand.left then x else y
  refine ⟨inputs, ?_, ?_⟩
  · intro k
    rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
      simp [inputs, BinaryOperand.left, BinaryOperand.right, hxMem, hyMem]
  · have hout : saddSatFn x.bitvec y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toInt_eq
      rw [saddSatFn_toInt hn, hxInt, hyInt, hsum]
      simp [signedClamp, min_eq_left hzUpper, max_eq_right hzLower]
    simp [inputs, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, saddSat, hout]

theorem sintRange_ssubSat_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (ssubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = ssubSatFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, ssubSat] using ha
  have hbEq : b.bitvec = ssubSatFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, ssubSat] using hb
  have haInt : a.bitvec.toInt =
      signedClamp n (xa.bitvec.toInt - ya.bitvec.toInt) := by
    rw [haEq, ssubSatFn_toInt hn]
  have hbInt : b.bitvec.toInt =
      signedClamp n (xb.bitvec.toInt - yb.bitvec.toInt) := by
    rw [hbEq, ssubSatFn_toInt hn]
  change a.bitvec.toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ b.bitvec.toInt at hz
  have hzLower := signedMin_le_toInt hn z.bitvec
  have hzUpper := toInt_le_signedMax hn z.bitvec
  have haLower := signedMin_le_toInt hn a.bitvec
  have hbUpper := toInt_le_signedMax hn b.bitvec
  have hMinMax := signedMin_le_signedMax hn
  by_cases hzMin : z.bitvec.toInt = signedMin n
  · have haz : a = z := SignedBitVec.ext (BitVec.eq_of_toInt_eq (by omega))
    subst z
    exact ⟨inputsA, hinputsA, ha⟩
  by_cases hzMax : z.bitvec.toInt = signedMax n
  · have hbz : b = z := SignedBitVec.ext (BitVec.eq_of_toInt_eq (by omega))
    subst z
    exact ⟨inputsB, hinputsB, hb⟩
  have hzMinLt : signedMin n < z.bitvec.toInt := by omega
  have hzLtMax : z.bitvec.toInt < signedMax n := by omega
  have hrawLower : xa.bitvec.toInt - ya.bitvec.toInt ≤ z.bitvec.toInt := by
    rw [haInt] at hz
    simp only [signedClamp] at hz
    omega
  have hrawUpper : z.bitvec.toInt ≤
      xb.bitvec.toInt - yb.bitvec.toInt := by
    rw [hbInt] at hz
    simp only [signedClamp] at hz
    omega
  obtain ⟨xInt, yInt, hxLower, hxUpper, hyLower, hyUpper, hdiff⟩ :=
    IntBox.exists_sub hrawLower hrawUpper
  let x : SignedBitVec n := ⟨BitVec.ofInt n xInt⟩
  let y : SignedBitVec n := ⟨BitVec.ofInt n yInt⟩
  have hxInt : x.bitvec.toInt = xInt :=
    toInt_ofInt_eq_of_between hn xInt xa.bitvec xb.bitvec hxLower hxUpper
  have hyInt : y.bitvec.toInt = yInt :=
    toInt_ofInt_eq_of_between hn yInt ya.bitvec yb.bitvec hyLower hyUpper
  have hxMem : x ∈ (intervals BinaryOperand.left : Set (SignedBitVec n)) := by
    apply IntervalDomain.mem_interval_of_between
      (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
    simpa [xa, xb, hxInt] using And.intro hxLower hxUpper
  have hyMem : y ∈ (intervals BinaryOperand.right : Set (SignedBitVec n)) := by
    apply IntervalDomain.mem_interval_of_between
      (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
    simpa [ya, yb, hyInt] using And.intro hyLower hyUpper
  let inputs : BinaryOperand → SignedBitVec n := fun k ↦
    if k = BinaryOperand.left then x else y
  refine ⟨inputs, ?_, ?_⟩
  · intro k
    rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
      simp [inputs, BinaryOperand.left, BinaryOperand.right, hxMem, hyMem]
  · have hout : ssubSatFn x.bitvec y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toInt_eq
      rw [ssubSatFn_toInt hn, hxInt, hyInt, hdiff]
      simp [signedClamp, min_eq_left hzUpper, max_eq_right hzLower]
    simp [inputs, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, ssubSat, hout]

theorem sintRange_saddSat_backwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (saddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing saddSatFn
  intro x₁ x₂ y₁ y₂ hx hy
  rw [saddSatFn_toInt hn, saddSatFn_toInt hn]
  exact signedClamp_mono (add_le_add hx hy)

theorem sintRange_ssubSat_backwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (ssubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply SIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing ssubSatFn
  intro x₁ x₂ y₁ y₂ hx hy
  rw [ssubSatFn_toInt hn, ssubSatFn_toInt hn]
  exact signedClamp_mono (sub_le_sub hx hy)

private theorem exists_corner_mul_le
    {xl xu yl yu x y : Int}
    (hx : xl ≤ x ∧ x ≤ xu) (hy : yl ≤ y ∧ y ≤ yu) :
    ∃ cx cy, (cx = xl ∨ cx = xu) ∧ (cy = yl ∨ cy = yu) ∧
      cx * cy ≤ x * y := by
  by_cases hyNonneg : 0 ≤ y
  · have hxy : xl * y ≤ x * y :=
      mul_le_mul_of_nonneg_right hx.1 hyNonneg
    by_cases hxlNonneg : 0 ≤ xl
    · exact ⟨xl, yl, Or.inl rfl, Or.inl rfl,
        (mul_le_mul_of_nonneg_left hy.1 hxlNonneg).trans hxy⟩
    · exact ⟨xl, yu, Or.inl rfl, Or.inr rfl,
        (mul_le_mul_of_nonpos_left hy.2 (le_of_not_ge hxlNonneg)).trans hxy⟩
  · have hyNonpos : y ≤ 0 := le_of_not_ge hyNonneg
    have hxy : xu * y ≤ x * y :=
      mul_le_mul_of_nonpos_right hx.2 hyNonpos
    by_cases hxuNonneg : 0 ≤ xu
    · exact ⟨xu, yl, Or.inr rfl, Or.inl rfl,
        (mul_le_mul_of_nonneg_left hy.1 hxuNonneg).trans hxy⟩
    · exact ⟨xu, yu, Or.inr rfl, Or.inr rfl,
        (mul_le_mul_of_nonpos_left hy.2 (le_of_not_ge hxuNonneg)).trans hxy⟩

private theorem exists_mul_le_corner
    {xl xu yl yu x y : Int}
    (hx : xl ≤ x ∧ x ≤ xu) (hy : yl ≤ y ∧ y ≤ yu) :
    ∃ cx cy, (cx = xl ∨ cx = xu) ∧ (cy = yl ∨ cy = yu) ∧
      x * y ≤ cx * cy := by
  by_cases hyNonneg : 0 ≤ y
  · have hxy : x * y ≤ xu * y :=
      mul_le_mul_of_nonneg_right hx.2 hyNonneg
    by_cases hxuNonneg : 0 ≤ xu
    · exact ⟨xu, yu, Or.inr rfl, Or.inr rfl,
        hxy.trans (mul_le_mul_of_nonneg_left hy.2 hxuNonneg)⟩
    · exact ⟨xu, yl, Or.inr rfl, Or.inl rfl,
        hxy.trans (mul_le_mul_of_nonpos_left hy.1 (le_of_not_ge hxuNonneg))⟩
  · have hyNonpos : y ≤ 0 := le_of_not_ge hyNonneg
    have hxy : x * y ≤ xl * y :=
      mul_le_mul_of_nonpos_right hx.1 hyNonpos
    by_cases hxlNonneg : 0 ≤ xl
    · exact ⟨xl, yu, Or.inl rfl, Or.inr rfl,
        hxy.trans (mul_le_mul_of_nonneg_left hy.2 hxlNonneg)⟩
    · exact ⟨xl, yl, Or.inl rfl, Or.inl rfl,
        hxy.trans (mul_le_mul_of_nonpos_left hy.1 (le_of_not_ge hxlNonneg))⟩

private theorem smulSat_corner_bounds {n : Nat}
    (hn : ValidIntegerWidth n)
    (xl xu yl yu x y : SignedBitVec n)
    (hx : xl ≤ x ∧ x ≤ xu) (hy : yl ≤ y ∧ y ≤ yu) :
    ∃ lowerX lowerY upperX upperY,
      (lowerX = xl ∨ lowerX = xu) ∧
      (lowerY = yl ∨ lowerY = yu) ∧
      (upperX = xl ∨ upperX = xu) ∧
      (upperY = yl ∨ upperY = yu) ∧
      (SignedBitVec.equiv n (smulSatFn lowerX.bitvec lowerY.bitvec) ≤
        SignedBitVec.equiv n (smulSatFn x.bitvec y.bitvec)) ∧
      (SignedBitVec.equiv n (smulSatFn x.bitvec y.bitvec) ≤
        SignedBitVec.equiv n (smulSatFn upperX.bitvec upperY.bitvec)) := by
  obtain ⟨lowerXInt, lowerYInt, hlx, hly, hlower⟩ :=
    exists_corner_mul_le hx hy
  obtain ⟨upperXInt, upperYInt, hux, huy, hupper⟩ :=
    exists_mul_le_corner hx hy
  let lowerX := if lowerXInt = xl.bitvec.toInt then xl else xu
  let lowerY := if lowerYInt = yl.bitvec.toInt then yl else yu
  let upperX := if upperXInt = xl.bitvec.toInt then xl else xu
  let upperY := if upperYInt = yl.bitvec.toInt then yl else yu
  have hlxInt : lowerX.bitvec.toInt = lowerXInt := by
    simp only [lowerX]
    split <;> simp_all
  have hlyInt : lowerY.bitvec.toInt = lowerYInt := by
    simp only [lowerY]
    split <;> simp_all
  have huxInt : upperX.bitvec.toInt = upperXInt := by
    simp only [upperX]
    split <;> simp_all
  have huyInt : upperY.bitvec.toInt = upperYInt := by
    simp only [upperY]
    split <;> simp_all
  refine ⟨lowerX, lowerY, upperX, upperY, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · by_cases h : lowerXInt = xl.bitvec.toInt <;> simp [lowerX, h]
  · by_cases h : lowerYInt = yl.bitvec.toInt <;> simp [lowerY, h]
  · by_cases h : upperXInt = xl.bitvec.toInt <;> simp [upperX, h]
  · by_cases h : upperYInt = yl.bitvec.toInt <;> simp [upperY, h]
  · change (smulSatFn _ _).toInt ≤ (smulSatFn _ _).toInt
    rw [smulSatFn_toInt hn, smulSatFn_toInt hn, hlxInt, hlyInt]
    exact signedClamp_mono hlower
  · change (smulSatFn _ _).toInt ≤ (smulSatFn _ _).toInt
    rw [smulSatFn_toInt hn, smulSatFn_toInt hn, huxInt, huyInt]
    exact signedClamp_mono hupper

theorem sintRange_smulSat_backwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (smulSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryBackwardComplete_iff_nary]
  change NaryBackwardComplete (fun _ : BinaryOperand ↦ SIntRange.domain n)
    (SIntRange.domain n)
    (NaryConcreteOp.ofTotal fun inputs ↦
      smulSatFn (inputs BinaryOperand.left)
        (inputs BinaryOperand.right))
  rw [SIntRange.naryBackwardComplete_ofTotal_iff_boundedByCornerImages]
  intro lower upper hlowerUpper inputs hinputs
  have hx := hinputs BinaryOperand.left
  have hy := hinputs BinaryOperand.right
  obtain ⟨lowerX, lowerY, upperX, upperY, hlx, hly, hux, huy,
      hlower, hupper⟩ :=
    smulSat_corner_bounds hn
      (lower BinaryOperand.left) (upper BinaryOperand.left)
      (lower BinaryOperand.right) (upper BinaryOperand.right)
      (inputs BinaryOperand.left) (inputs BinaryOperand.right) hx hy
  let lowerInputs : BinaryOperand → SignedBitVec n := fun k ↦
    if k = BinaryOperand.left then lowerX else lowerY
  let upperInputs : BinaryOperand → SignedBitVec n := fun k ↦
    if k = BinaryOperand.left then upperX else upperY
  apply IntervalDomain.mem_hull_of_between
    (a := SignedBitVec.equiv n (smulSatFn lowerX.bitvec lowerY.bitvec))
    (b := SignedBitVec.equiv n (smulSatFn upperX.bitvec upperY.bitvec))
  · refine ⟨lowerInputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [lowerInputs, BinaryOperand.left, BinaryOperand.right] using hlx
      · simpa [lowerInputs, BinaryOperand.left, BinaryOperand.right] using hly
    · rfl
  · refine ⟨upperInputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl
      · simpa [upperInputs, BinaryOperand.left, BinaryOperand.right] using hux
      · simpa [upperInputs, BinaryOperand.left, BinaryOperand.right] using huy
    · rfl
  · constructor
    · exact (min_le_left _ _).trans hlower
    · exact hupper.trans (le_max_right _ _)

private theorem bitvec8_eq_125_or_126_or_127 {x : BitVec 8}
    (hlower : (125 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (127 : BitVec 8).toInt) :
    x = 125 ∨ x = 126 ∨ x = 127 := by
  have h125 : (125 : BitVec 8).toInt = 125 := by bv_decide
  have h127 : (127 : BitVec 8).toInt = 127 := by bv_decide
  rw [h125] at hlower
  rw [h127] at hupper
  have hx : x.toInt = 125 ∨ x.toInt = 126 ∨ x.toInt = 127 := by
    omega
  exact hx.imp BitVec.eq_of_toInt_eq
    (fun h ↦ Or.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq h)

private theorem bitvec8_eq_128_or_129_or_130 {x : BitVec 8}
    (hlower : (128 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (130 : BitVec 8).toInt) :
    x = 128 ∨ x = 129 ∨ x = 130 := by
  have h128 : (128 : BitVec 8).toInt = -128 := by bv_decide
  have h130 : (130 : BitVec 8).toInt = -126 := by bv_decide
  rw [h128] at hlower
  rw [h130] at hupper
  have hx : x.toInt = -128 ∨ x.toInt = -127 ∨ x.toInt = -126 := by
    omega
  rcases hx with h | h | h
  · exact Or.inl (BitVec.eq_of_toInt_eq (by simpa using h))
  · exact Or.inr (Or.inl (BitVec.eq_of_toInt_eq (by simpa using h)))
  · exact Or.inr (Or.inr (BitVec.eq_of_toInt_eq (by simpa using h)))

private theorem bitvec8_eq_62_or_63_or_64 {x : BitVec 8}
    (hlower : (62 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (64 : BitVec 8).toInt) :
    x = 62 ∨ x = 63 ∨ x = 64 := by
  have h62 : (62 : BitVec 8).toInt = 62 := by bv_decide
  have h64 : (64 : BitVec 8).toInt = 64 := by bv_decide
  rw [h62] at hlower
  rw [h64] at hupper
  have hx : x.toInt = 62 ∨ x.toInt = 63 ∨ x.toInt = 64 := by
    omega
  exact hx.imp BitVec.eq_of_toInt_eq
    (fun h ↦ Or.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq h)

private theorem bitvec8_eq_zero_or_one {x : BitVec 8}
    (hlower : (0 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (1 : BitVec 8).toInt) : x = 0 ∨ x = 1 := by
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  have h1 : (1 : BitVec 8).toInt = 1 := by bv_decide
  rw [h0] at hlower
  rw [h1] at hupper
  have hx : x.toInt = 0 ∨ x.toInt = 1 := by
    omega
  exact hx.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq

theorem sintRange_uaddSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (uaddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 uaddSat
    125 127 1 1 128 0 126 (by bv_decide) (by bv_decide) (by bv_decide)
    127 1 125 1 (by bv_decide) (by bv_decide)
  · simp [uaddSat, uaddSatFn, clampUnsigned, unsignedMax]
  · simp [uaddSat, uaddSatFn, clampUnsigned, unsignedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 1 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_125_or_126_or_127 hxLower hxUpper with
      rfl | rfl | rfl <;>
      simp [hy, uaddSat, uaddSatFn, clampUnsigned, unsignedMax]

theorem sintRange_uaddSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (uaddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 uaddSat
    125 127 1 1 126 1 127 128 126
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [uaddSat, uaddSatFn, clampUnsigned, unsignedMax]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [uaddSat, uaddSatFn, clampUnsigned, unsignedMax] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem sintRange_usubSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (usubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 usubSat
    128 130 1 1 129 0 127 (by bv_decide) (by bv_decide) (by bv_decide)
    130 1 128 1 (by bv_decide) (by bv_decide)
  · simp [usubSat, usubSatFn]
  · simp [usubSat, usubSatFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 1 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_128_or_129_or_130 hxLower hxUpper with
      rfl | rfl | rfl <;> simp [hy, usubSat, usubSatFn]

theorem sintRange_usubSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (usubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 usubSat
    128 130 1 1 129 1 128 129 127
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [usubSat, usubSatFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [usubSat, usubSatFn] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem sintRange_umulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 umulSat
    62 64 2 2 128 0 124 (by bv_decide) (by bv_decide) (by bv_decide)
    64 2 62 2 (by bv_decide) (by bv_decide)
  · simp [umulSat, umulSatFn, clampUnsigned, unsignedMax]
  · simp [umulSat, umulSatFn, clampUnsigned, unsignedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 2 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_62_or_63_or_64 hxLower hxUpper with
      rfl | rfl | rfl <;>
      simp [hy, umulSat, umulSatFn, clampUnsigned, unsignedMax]

theorem sintRange_umulSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (umulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 umulSat
    62 64 2 2 63 2 126 128 124
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [umulSat, umulSatFn, clampUnsigned, unsignedMax]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [umulSat, umulSatFn, clampUnsigned, unsignedMax] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem sintRange_smulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (smulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 smulSat
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax]
  · simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have hy : y = 2 := BitVec.eq_of_toInt_eq (by omega)
    rcases bitvec8_eq_zero_or_one hxLower hxUpper with rfl | rfl <;>
      simp [hy, smulSat, smulSatFn, clampSigned, signedMin, signedMax]

end SynthXfer.LLVM
