import SynthXfer.SIntRange.Witnesses
import SynthXfer.IntBox

namespace SynthXfer.LLVM

theorem toInt_ofInt_eq_of_between {n : Nat}
    (hn : ValidIntegerWidth n) (value : Int) (a b : BitVec n)
    (hlower : min a.toInt b.toInt ≤ value)
    (hupper : value ≤ max a.toInt b.toInt) :
    (BitVec.ofInt n value).toInt = value := by
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
  rw [BitVec.toInt_ofInt, Int.bmod_eq_of_le]
  · rw [hhalf]
    have ha := BitVec.le_toInt a
    have hb := BitVec.le_toInt b
    exact (le_min ha hb).trans hlower
  · rw [hhalfPlus]
    have ha := BitVec.toInt_le (x := a)
    have hb := BitVec.toInt_le (x := b)
    have hcast : ((2 ^ (n - 1) : Nat) : Int) =
        (2 : Int) ^ (n - 1) := by simp
    exact lt_of_le_of_lt (hupper.trans (max_le ha hb)) (by omega)

theorem sintRange_addNsw_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (addNsw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haData : addNsw? xa.bitvec ya.bitvec = some a.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, addNsw] using ha
  have hbData : addNsw? xb.bitvec yb.bitvec = some b.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, addNsw] using hb
  have haNoOverflow : xa.bitvec.saddOverflow ya.bitvec = false := by
    simpa [addNsw?, poisonIf] using congrArg Option.isSome haData
  have hbNoOverflow : xb.bitvec.saddOverflow yb.bitvec = false := by
    simpa [addNsw?, poisonIf] using congrArg Option.isSome hbData
  have haEq : xa.bitvec + ya.bitvec = a.bitvec := by
    simpa [addNsw?, poisonIf, haNoOverflow] using haData
  have hbEq : xb.bitvec + yb.bitvec = b.bitvec := by
    simpa [addNsw?, poisonIf, hbNoOverflow] using hbData
  have haInt : xa.bitvec.toInt + ya.bitvec.toInt = a.bitvec.toInt := by
    rw [← haEq, BitVec.toInt_add_of_not_saddOverflow]
    simpa using haNoOverflow
  have hbInt : xb.bitvec.toInt + yb.bitvec.toInt = b.bitvec.toInt := by
    rw [← hbEq, BitVec.toInt_add_of_not_saddOverflow]
    simpa using hbNoOverflow
  change a.bitvec.toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ b.bitvec.toInt at hz
  obtain ⟨xInt, yInt, hxLower, hxUpper, hyLower, hyUpper, hsum⟩ :=
    IntBox.exists_add (show xa.bitvec.toInt + ya.bitvec.toInt ≤
      z.bitvec.toInt by omega) (show z.bitvec.toInt ≤
      xb.bitvec.toInt + yb.bitvec.toInt by omega)
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
  · have hsumEq : x.bitvec + y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toInt_eq
      rw [BitVec.toInt_add, hxInt, hyInt, hsum]
      simp
    have hnoOverflow : x.bitvec.saddOverflow y.bitvec = false := by
      have hzLower := BitVec.le_toInt z.bitvec
      have hzUpper := BitVec.toInt_le (x := z.bitvec)
      simp [BitVec.saddOverflow, hxInt, hyInt, hsum]
      omega
    change z ∈ (SignedBitVec.equiv n) '' addNsw x.bitvec y.bitvec
    refine ⟨x.bitvec + y.bitvec, ?_, SignedBitVec.ext hsumEq⟩
    change addNsw? x.bitvec y.bitvec = some (x.bitvec + y.bitvec)
    simp [addNsw?, poisonIf, hnoOverflow]

theorem sintRange_subNsw_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryForwardComplete (SIntRange.domain n) (SIntRange.domain n)
      (SIntRange.domain n)
      (subNsw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haData : subNsw? xa.bitvec ya.bitvec = some a.bitvec := by
    simpa [xa, ya, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, subNsw] using ha
  have hbData : subNsw? xb.bitvec yb.bitvec = some b.bitvec := by
    simpa [xb, yb, SIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, subNsw] using hb
  have haNoOverflow : xa.bitvec.ssubOverflow ya.bitvec = false := by
    simpa [subNsw?, poisonIf] using congrArg Option.isSome haData
  have hbNoOverflow : xb.bitvec.ssubOverflow yb.bitvec = false := by
    simpa [subNsw?, poisonIf] using congrArg Option.isSome hbData
  have haEq : xa.bitvec - ya.bitvec = a.bitvec := by
    simpa [subNsw?, poisonIf, haNoOverflow] using haData
  have hbEq : xb.bitvec - yb.bitvec = b.bitvec := by
    simpa [subNsw?, poisonIf, hbNoOverflow] using hbData
  have haInt : xa.bitvec.toInt - ya.bitvec.toInt = a.bitvec.toInt := by
    rw [← haEq, BitVec.toInt_sub_of_not_ssubOverflow]
    simpa using haNoOverflow
  have hbInt : xb.bitvec.toInt - yb.bitvec.toInt = b.bitvec.toInt := by
    rw [← hbEq, BitVec.toInt_sub_of_not_ssubOverflow]
    simpa using hbNoOverflow
  change a.bitvec.toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ b.bitvec.toInt at hz
  obtain ⟨xInt, yInt, hxLower, hxUpper, hyLower, hyUpper, hdiff⟩ :=
    IntBox.exists_sub (show xa.bitvec.toInt - ya.bitvec.toInt ≤
      z.bitvec.toInt by omega) (show z.bitvec.toInt ≤
      xb.bitvec.toInt - yb.bitvec.toInt by omega)
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
  · have hdiffEq : x.bitvec - y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toInt_eq
      rw [BitVec.toInt_sub, hxInt, hyInt, hdiff]
      simp
    have hnoOverflow : x.bitvec.ssubOverflow y.bitvec = false := by
      have hzLower := BitVec.le_toInt z.bitvec
      have hzUpper := BitVec.toInt_le (x := z.bitvec)
      simp [BitVec.ssubOverflow, hxInt, hyInt, hdiff]
      omega
    change z ∈ (SignedBitVec.equiv n) '' subNsw x.bitvec y.bitvec
    refine ⟨x.bitvec - y.bitvec, ?_, SignedBitVec.ext hdiffEq⟩
    change subNsw? x.bitvec y.bitvec = some (x.bitvec - y.bitvec)
    simp [subNsw?, poisonIf, hnoOverflow]

end SynthXfer.LLVM
