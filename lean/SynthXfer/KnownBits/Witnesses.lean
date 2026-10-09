import SynthXfer.KnownBits

/-!
# Reusable KnownBits completeness witnesses

Generic criteria and concrete witness theorems for proving KnownBits completeness or incompleteness.
-/

namespace SynthXfer

namespace BitDependency

private theorem isKnownBitsSet_singleton {n : Nat} (x : BoolVector n) :
    IsKnownBitsSet ({x} : Set (BoolVector n)) := by
  right
  constructor
  · exact ⟨x, by simp⟩
  · intro z hz
    have hzx : z = x := by
      funext i
      obtain ⟨y, hy, hyi⟩ := hz i
      have hyx : y = x := by simpa using hy
      subst y
      exact hyi.symm
    simp [hzx]

/-- A partial unary operation is forward-incomplete when, on a defined input
edge, one input bit changes two distinct result bits. -/
theorem unaryRelationalForwardIncomplete_of_localCollision
    {n m : Nat} (f : ConcreteOp (BoolVector n) (BoolVector m))
    (x : BoolVector n) (j : Fin n) (out out' : BoolVector m)
    (i l : Fin m) (hil : i ≠ l) (hbase : f x = {out})
    (htoggle : f (toggle x j) = {out'})
    (hi : out i ≠ out' i) (hl : out l ≠ out' l) :
    ¬ ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  rw [forwardComplete_iff_closure]
  intro hcomplete
  let inputs : Set (BoolVector n) := {x, toggle x j}
  have hinputs : (KnownBits.boolDomain n).closure inputs = inputs :=
    isKnownBitsSet_iff_closure_eq.mp
      (Or.inr (by simpa [inputs] using isBooleanBox_pair_toggleIndex x j))
  have hout : out ∈ ConcreteOp.lift f inputs :=
    ⟨x, by simp [inputs], by simp [hbase]⟩
  have hout' : out' ∈ ConcreteOp.lift f inputs :=
    ⟨toggle x j, by simp [inputs], by simp [htoggle]⟩
  let mixed := Function.update out i (out' i)
  have hmixedClosed : mixed ∈ (KnownBits.boolDomain m).closure
      (ConcreteOp.lift f inputs) := update_mem_closure hout hout' i
  have hmixed : mixed ∈ ConcreteOp.lift f inputs := by
    have := hcomplete inputs
    rw [hinputs] at this
    exact this ▸ hmixedClosed
  rcases hmixed with ⟨a, ha, hab⟩
  rcases ha with ha | ha
  · subst a
    rw [hbase] at hab
    have heq := Set.mem_singleton_iff.mp hab
    have := congrArg (fun z ↦ z i) heq
    exact hi (by simpa [mixed] using this.symm)
  · subst a
    rw [htoggle] at hab
    have heq := Set.mem_singleton_iff.mp hab
    have := congrArg (fun z ↦ z l) heq
    exact hl (by simpa [mixed, Ne.symm hil] using this)

/-- A partial unary operation is backward-incomplete when one result bit
depends locally on two input bits and all three witness executions are
defined. -/
theorem unaryRelationalBackwardIncomplete_of_localCollision
    {n m : Nat} (f : ConcreteOp (BoolVector n) (BoolVector m))
    (x : BoolVector n) (j l : Fin n) (hjl : j ≠ l)
    (out outJ outL : BoolVector m) (i : Fin m)
    (hbase : f x = {out}) (hj : f (toggle x j) = {outJ})
    (hl : f (toggle x l) = {outL})
    (hij : out i ≠ outJ i) (hil : out i ≠ outL i) :
    ¬ BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  rw [backwardComplete_iff_closure]
  intro hcomplete
  let inputs : Set (BoolVector n) := {toggle x j, toggle x l}
  have hxClosure : x ∈ (KnownBits.boolDomain n).closure inputs := by
    have hmix := update_mem_closure
      (s := inputs) (x := toggle x j) (y := toggle x l)
      (by simp [inputs]) (by simp [inputs]) j
    have heq : Function.update (toggle x j) j ((toggle x l) j) = x := by
      funext q
      by_cases hqj : q = j
      · subst q
        simp [toggle, toggleIndex, hjl]
      · simp [toggle, toggleIndex, hqj]
    simpa [heq] using hmix
  have houtClosedInputs : out ∈ (KnownBits.boolDomain m).closure
      (ConcreteOp.lift f ((KnownBits.boolDomain n).closure inputs)) := by
    apply (KnownBits.boolDomain m).subset_closure _
    exact ⟨x, hxClosure, by simp [hbase]⟩
  have houtOriginal : out ∉ (KnownBits.boolDomain m).closure
      (ConcreteOp.lift f inputs) := by
    intro houtClosure
    change out ∈ KnownBits.concretize
      (KnownBits.abstract (ConcreteOp.lift f inputs)) at houtClosure
    have hresults : (ConcreteOp.lift f inputs).Nonempty := by
      exact ⟨outJ, toggle x j, by simp [inputs], by simp [hj]⟩
    rw [KnownBits.abstract, dif_pos hresults] at houtClosure
    obtain ⟨z, hz, hzi⟩ := houtClosure i
    rcases hz with ⟨a, ha, hab⟩
    rcases ha with ha | ha
    · subst a
      rw [hj] at hab
      have hzEq := Set.mem_singleton_iff.mp hab
      subst z
      exact hij hzi.symm
    · subst a
      rw [hl] at hab
      have hzEq := Set.mem_singleton_iff.mp hab
      subst z
      exact hil hzi.symm
  exact houtOriginal ((hcomplete inputs) ▸ houtClosedInputs)

/-- A partial binary operation is forward-incomplete when, on a defined
input edge, one input bit changes two distinct result bits. -/
theorem binaryRelationalForwardIncomplete_of_localCollision
    {n m : Nat} (f : BinaryConcreteOp (BoolVector n) (BoolVector n)
      (BoolVector m)) (x y : BoolVector n) (j : Fin n)
    (out out' : BoolVector m) (i l : Fin m) (hil : i ≠ l)
    (hbase : f x y = {out}) (htoggle : f (toggle x j) y = {out'})
    (hi : out i ≠ out' i) (hl : out l ≠ out' l) :
    ¬ BinaryForwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  rw [binaryForwardComplete_iff_closure]
  intro hcomplete
  let lhs : Set (BoolVector n) := {x, toggle x j}
  let rhs : Set (BoolVector n) := {y}
  have hlhs : (KnownBits.boolDomain n).closure lhs = lhs :=
    isKnownBitsSet_iff_closure_eq.mp
      (Or.inr (by simpa [lhs] using isBooleanBox_pair_toggleIndex x j))
  have hrhs : (KnownBits.boolDomain n).closure rhs = rhs :=
    isKnownBitsSet_iff_closure_eq.mp (isKnownBitsSet_singleton y)
  have hout : out ∈ BinaryConcreteOp.lift f lhs rhs := by
    exact ⟨x, by simp [lhs], y, by simp [rhs], by simp [hbase]⟩
  have hout' : out' ∈ BinaryConcreteOp.lift f lhs rhs := by
    exact ⟨toggle x j, by simp [lhs], y, by simp [rhs], by simp [htoggle]⟩
  let mixed := Function.update out i (out' i)
  have hmixedClosed : mixed ∈ (KnownBits.boolDomain m).closure
      (BinaryConcreteOp.lift f lhs rhs) :=
    update_mem_closure hout hout' i
  have hmixed : mixed ∈ BinaryConcreteOp.lift f lhs rhs := by
    have := hcomplete lhs rhs
    rw [hlhs, hrhs] at this
    exact this ▸ hmixedClosed
  rcases hmixed with ⟨a, ha, b, hb, hab⟩
  have hbEq : b = y := by simpa [rhs] using hb
  subst b
  rcases ha with ha | ha
  · subst a
    rw [hbase] at hab
    have heq := Set.mem_singleton_iff.mp hab
    have := congrArg (fun z ↦ z i) heq
    exact hi (by simpa [mixed] using this.symm)
  · subst a
    rw [htoggle] at hab
    have heq := Set.mem_singleton_iff.mp hab
    have := congrArg (fun z ↦ z l) heq
    exact hl (by simpa [mixed, Ne.symm hil] using this)

/-- A partial binary operation is backward-incomplete when, in one fixed
context, one result bit depends on two distinct bits of an operand and all
three witness executions are defined. -/
theorem binaryRelationalBackwardIncomplete_of_localCollision
    {n m : Nat} (f : BinaryConcreteOp (BoolVector n) (BoolVector n)
      (BoolVector m)) (x y : BoolVector n) (j l : Fin n) (hjl : j ≠ l)
    (out outJ outL : BoolVector m) (i : Fin m)
    (hbase : f x y = {out}) (hj : f (toggle x j) y = {outJ})
    (hl : f (toggle x l) y = {outL})
    (hij : out i ≠ outJ i) (hil : out i ≠ outL i) :
    ¬ BinaryBackwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  rw [binaryBackwardComplete_iff_closure]
  intro hcomplete
  let lhs : Set (BoolVector n) := {toggle x j, toggle x l}
  let rhs : Set (BoolVector n) := {y}
  have hxClosure : x ∈ (KnownBits.boolDomain n).closure lhs := by
    have hmix := update_mem_closure
      (s := lhs) (x := toggle x j) (y := toggle x l)
      (by simp [lhs]) (by simp [lhs]) j
    have heq : Function.update (toggle x j) j ((toggle x l) j) = x := by
      funext q
      by_cases hqj : q = j
      · subst q
        simp [toggle, toggleIndex, hjl]
      · simp [toggle, toggleIndex, hqj]
    simpa [heq] using hmix
  have hyClosure : y ∈ (KnownBits.boolDomain n).closure rhs :=
    (KnownBits.boolDomain n).subset_closure rhs (by simp [rhs])
  have houtClosedInputs : out ∈ (KnownBits.boolDomain m).closure
      (BinaryConcreteOp.lift f
        ((KnownBits.boolDomain n).closure lhs)
        ((KnownBits.boolDomain n).closure rhs)) := by
    apply (KnownBits.boolDomain m).subset_closure _
    exact ⟨x, hxClosure, y, hyClosure, by simp [hbase]⟩
  have houtOriginal : out ∉ (KnownBits.boolDomain m).closure
      (BinaryConcreteOp.lift f lhs rhs) := by
    intro houtClosure
    change out ∈ KnownBits.concretize
      (KnownBits.abstract (BinaryConcreteOp.lift f lhs rhs)) at houtClosure
    have hresults : (BinaryConcreteOp.lift f lhs rhs).Nonempty := by
      exact ⟨outJ, toggle x j, by simp [lhs], y, by simp [rhs], by simp [hj]⟩
    rw [KnownBits.abstract, dif_pos hresults] at houtClosure
    obtain ⟨z, hz, hzi⟩ := houtClosure i
    rcases hz with ⟨a, ha, b, hb, hab⟩
    have hbEq : b = y := by simpa [rhs] using hb
    subst b
    rcases ha with ha | ha
    · subst a
      rw [hj] at hab
      have hzEq := Set.mem_singleton_iff.mp hab
      subst z
      exact hij hzi.symm
    · subst a
      rw [hl] at hab
      have hzEq := Set.mem_singleton_iff.mp hab
      subst z
      exact hil hzi.symm
  exact houtOriginal ((hcomplete lhs rhs) ▸ houtClosedInputs)

private theorem binaryLift_swap {n m : Nat}
    (f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector m))
    (xs ys : Set (BoolVector n)) :
    BinaryConcreteOp.lift (fun y x ↦ f x y) ys xs =
      BinaryConcreteOp.lift f xs ys := by
  ext z
  constructor
  · rintro ⟨y, hy, x, hx, hz⟩
    exact ⟨x, hx, y, hy, hz⟩
  · rintro ⟨x, hx, y, hy, hz⟩
    exact ⟨y, hy, x, hx, hz⟩

private theorem binaryForwardComplete_swap {n m : Nat}
    {f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector m)}
    (h : BinaryForwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f) :
    BinaryForwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (fun y x ↦ f x y) := by
  rw [binaryForwardComplete_iff_closure] at h ⊢
  intro ys xs
  simpa only [binaryLift_swap] using h xs ys

private theorem binaryBackwardComplete_swap {n m : Nat}
    {f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector m)}
    (h : BinaryBackwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f) :
    BinaryBackwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (fun y x ↦ f x y) := by
  rw [binaryBackwardComplete_iff_closure] at h ⊢
  intro ys xs
  simpa only [binaryLift_swap] using h xs ys

/-- Right-operand version of
`binaryRelationalForwardIncomplete_of_localCollision`. -/
theorem binaryRelationalForwardIncomplete_of_rightLocalCollision
    {n m : Nat} (f : BinaryConcreteOp (BoolVector n) (BoolVector n)
      (BoolVector m)) (x y : BoolVector n) (j : Fin n)
    (out out' : BoolVector m) (i l : Fin m) (hil : i ≠ l)
    (hbase : f x y = {out}) (htoggle : f x (toggle y j) = {out'})
    (hi : out i ≠ out' i) (hl : out l ≠ out' l) :
    ¬ BinaryForwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  intro hcomplete
  exact binaryRelationalForwardIncomplete_of_localCollision
    (fun y x ↦ f x y) y x j out out' i l hil hbase htoggle hi hl
    (binaryForwardComplete_swap hcomplete)

/-- Right-operand version of
`binaryRelationalBackwardIncomplete_of_localCollision`. -/
theorem binaryRelationalBackwardIncomplete_of_rightLocalCollision
    {n m : Nat} (f : BinaryConcreteOp (BoolVector n) (BoolVector n)
      (BoolVector m)) (x y : BoolVector n) (j l : Fin n) (hjl : j ≠ l)
    (out outJ outL : BoolVector m) (i : Fin m)
    (hbase : f x y = {out}) (hj : f x (toggle y j) = {outJ})
    (hl : f x (toggle y l) = {outL})
    (hij : out i ≠ outJ i) (hil : out i ≠ outL i) :
    ¬ BinaryBackwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  intro hcomplete
  exact binaryRelationalBackwardIncomplete_of_localCollision
    (fun y x ↦ f x y) y x j l hjl out outJ outL i
      hbase hj hl hij hil (binaryBackwardComplete_swap hcomplete)

/-- Backward completeness fails when two one-bit changes are individually
undefined but their KnownBits closure contains a defined input. -/
theorem binaryRelationalBackwardIncomplete_of_undefinedCorner
    {n m : Nat} (f : BinaryConcreteOp (BoolVector n) (BoolVector n)
      (BoolVector m)) (x y : BoolVector n) (j l : Fin n) (hjl : j ≠ l)
    (out : BoolVector m) (hbase : f x y = {out})
    (hj : f (toggle x j) y = ∅) (hl : f (toggle x l) y = ∅) :
    ¬ BinaryBackwardComplete (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) (KnownBits.boolDomain m) f := by
  rw [binaryBackwardComplete_iff_closure]
  intro hcomplete
  let lhs : Set (BoolVector n) := {toggle x j, toggle x l}
  let rhs : Set (BoolVector n) := {y}
  have hxClosure : x ∈ (KnownBits.boolDomain n).closure lhs := by
    have hmix := update_mem_closure
      (s := lhs) (x := toggle x j) (y := toggle x l)
      (by simp [lhs]) (by simp [lhs]) j
    have heq : Function.update (toggle x j) j ((toggle x l) j) = x := by
      funext q
      by_cases hqj : q = j
      · subst q
        simp [toggle, toggleIndex, hjl]
      · simp [toggle, toggleIndex, hqj]
    simpa [heq] using hmix
  have hyClosure : y ∈ (KnownBits.boolDomain n).closure rhs :=
    (KnownBits.boolDomain n).subset_closure rhs (by simp [rhs])
  have houtClosed : out ∈ (KnownBits.boolDomain m).closure
      (BinaryConcreteOp.lift f
        ((KnownBits.boolDomain n).closure lhs)
        ((KnownBits.boolDomain n).closure rhs)) := by
    apply (KnownBits.boolDomain m).subset_closure _
    exact ⟨x, hxClosure, y, hyClosure, by simp [hbase]⟩
  have horiginal : BinaryConcreteOp.lift f lhs rhs = ∅ := by
    ext z
    constructor
    · rintro ⟨a, ha, b, hb, hz⟩
      have hbEq : b = y := by simpa [rhs] using hb
      subst b
      rcases ha with ha | ha
      · subst a
        simp [hj] at hz
      · subst a
        simp [hl] at hz
    · simp
  have hEq := hcomplete lhs rhs
  rw [horiginal] at hEq
  have : out ∈ (KnownBits.boolDomain m).closure ∅ := hEq ▸ houtClosed
  simp [AbstractDomain.closure, KnownBits.boolDomain] at this

/-- A homogeneous n-ary bitvector operation is pointwise when output bit `i`
depends only on bit `i` of every operand. -/
def IsPointwiseNary {ι : Type*} {n : Nat}
    (f : ((k : ι) → BitVec n) → BitVec n) : Prop :=
  ∃ bit : Fin n → (ι → Bool) → Bool,
    ∀ x i, (f x).getLsb i = bit i (fun k ↦ (x k).getLsb i)

theorem dependenciesAt_subset_singleton_of_isPointwiseNary
    {ι : Type*} [DecidableEq ι] {n : Nat}
    {f : ((k : ι) → BitVec n) → BitVec n}
    (hpointwise : IsPointwiseNary f) (k : ι) (i : Fin n) :
    dependenciesAt (BoolVector.ofBitVecNaryOp f) k i ⊆ {i} := by
  classical
  obtain ⟨bit, hbit⟩ := hpointwise
  intro j hj
  rw [mem_dependenciesAt_iff] at hj
  obtain ⟨x, hx⟩ := hj
  apply Set.mem_singleton_iff.mpr
  by_contra hji
  apply hx
  change BoolVector.ofBitVec (f fun l ↦ (x l).toBitVec) i =
    BoolVector.ofBitVec
      (f fun l ↦ ((toggleOperand x k j) l).toBitVec) i
  simp only [BoolVector.ofBitVec_apply, hbit]
  congr 1
  funext l
  by_cases hlk : l = k
  · subst l
    rw [BoolVector.toBitVec_getLsb, BoolVector.toBitVec_getLsb]
    simp [toggleOperand, toggle, toggleIndex, Ne.symm hji]
  · simp [toggleOperand, hlk]

theorem slice_dependencies_subset_singleton_of_isPointwiseNary
    {ι : Type*} [DecidableEq ι] {n : Nat}
    {f : ((k : ι) → BitVec n) → BitVec n}
    (hpointwise : IsPointwiseNary f) (k : ι)
    (context : (l : ι) → BoolVector n) (i : Fin n) :
    dependencies (sliceAt (BoolVector.ofBitVecNaryOp f) k context) i ⊆ {i} := by
  classical
  obtain ⟨bit, hbit⟩ := hpointwise
  intro j hj
  rw [mem_dependencies_iff] at hj
  obtain ⟨x, hx⟩ := hj
  apply Set.mem_singleton_iff.mpr
  by_contra hji
  apply hx
  change BoolVector.ofBitVec
      (f fun l ↦ ((Function.update context k x) l).toBitVec) i =
    BoolVector.ofBitVec
      (f fun l ↦ ((Function.update context k (toggle x j)) l).toBitVec) i
  simp only [BoolVector.ofBitVec_apply, hbit]
  congr 1
  funext l
  by_cases hlk : l = k
  · subst l
    rw [BoolVector.toBitVec_getLsb, BoolVector.toBitVec_getLsb]
    simp [toggle, toggleIndex, Ne.symm hji]
  · simp [hlk]

theorem pairwiseDisjointDependenciesNary_of_isPointwiseNary
    {ι : Type*} [DecidableEq ι] {n : Nat}
    {f : ((k : ι) → BitVec n) → BitVec n}
    (hpointwise : IsPointwiseNary f) :
    PairwiseDisjointDependenciesNary f := by
  intro k i l hil
  rw [Set.disjoint_left]
  intro j hji hjl
  have hjiEq := Set.mem_singleton_iff.mp
    (dependenciesAt_subset_singleton_of_isPointwiseNary hpointwise k i hji)
  have hjlEq := Set.mem_singleton_iff.mp
    (dependenciesAt_subset_singleton_of_isPointwiseNary hpointwise k l hjl)
  exact hil (hjiEq.symm.trans hjlEq)

theorem contextwiseAtMostOneDependencyNary_of_isPointwiseNary
    {ι : Type*} [DecidableEq ι] {n : Nat}
    {f : ((k : ι) → BitVec n) → BitVec n}
    (hpointwise : IsPointwiseNary f) :
    ContextwiseAtMostOneDependencyNary f := by
  intro k context i j hj l hl
  have hjEq := Set.mem_singleton_iff.mp
    (slice_dependencies_subset_singleton_of_isPointwiseNary
      hpointwise k context i hj)
  have hlEq := Set.mem_singleton_iff.mp
    (slice_dependencies_subset_singleton_of_isPointwiseNary
      hpointwise k context i hl)
  exact hjEq.trans hlEq.symm

/-- Two distinct output bits sharing an essential input bit are a directly
checkable witness of unary KnownBits forward incompleteness. -/
theorem unaryForwardIncomplete_of_dependencyCollision
    {n m : Nat} (f : BitVec n → BitVec m)
    (i l : Fin m) (hil : i ≠ l) (j : Fin n)
    (hji : j ∈ dependencies (BoolVector.ofBitVecUnaryOp f) i)
    (hjl : j ∈ dependencies (BoolVector.ofBitVecUnaryOp f) l) :
    ¬ KnownBits.UnaryForwardComplete f := by
  rw [KnownBits.unaryForwardComplete_iff_dependencies]
  intro hdisjoint
  rw [PairwiseDisjointDependencies, BoolPairwiseDisjointDependenciesUnary]
    at hdisjoint
  have hd := hdisjoint i l hil
  rw [Set.disjoint_left] at hd
  exact hd hji hjl

/-- One output bit having two distinct essential input bits is a directly
checkable witness of unary KnownBits backward incompleteness. -/
theorem unaryBackwardIncomplete_of_dependencyCollision
    {n m : Nat} (f : BitVec n → BitVec m)
    (i : Fin m) (j l : Fin n) (hjl : j ≠ l)
    (hji : j ∈ dependencies (BoolVector.ofBitVecUnaryOp f) i)
    (hli : l ∈ dependencies (BoolVector.ofBitVecUnaryOp f) i) :
    ¬ KnownBits.UnaryBackwardComplete f := by
  rw [KnownBits.unaryBackwardComplete_iff_dependencies]
  intro hsubsingleton
  exact hjl (hsubsingleton i hji hli)

/-- Each output coordinate of `f` is either constant or copies one input
coordinate. Such an operation is KnownBits backward complete. -/
theorem unaryBackwardComplete_of_coordinateMap
    {n m : Nat} (f : BitVec n → BitVec m)
    (source : Fin m → Option (Fin n)) (constant : Fin m → Bool)
    (hcoordinate : ∀ x i,
      BoolVector.ofBitVecUnaryOp f x i =
        match source i with
        | some j => x j
        | none => constant i) :
    KnownBits.UnaryBackwardComplete f := by
  rw [KnownBits.unaryBackwardComplete_iff_dependencies]
  intro i j hj l hl
  cases hsource : source i with
  | none =>
      rw [mem_dependencies_iff] at hj
      obtain ⟨x, hx⟩ := hj
      apply (hx _).elim
      rw [hcoordinate, hcoordinate, hsource]
  | some q =>
      have dependency_eq (r : Fin n)
          (hr : r ∈ dependencies (BoolVector.ofBitVecUnaryOp f) i) : r = q := by
        rw [mem_dependencies_iff] at hr
        obtain ⟨x, hx⟩ := hr
        by_contra hrq
        apply hx
        rw [hcoordinate, hcoordinate, hsource]
        exact (toggle_of_ne x (Ne.symm hrq)).symm
      exact (dependency_eq j hj).trans (dependency_eq l hl).symm

/-- A coordinate-copying operation is also forward complete when no input
coordinate is copied to two distinct outputs. -/
theorem unaryForwardComplete_of_injectiveCoordinateMap
    {n m : Nat} (f : BitVec n → BitVec m)
    (source : Fin m → Option (Fin n)) (constant : Fin m → Bool)
    (hcoordinate : ∀ x i,
      BoolVector.ofBitVecUnaryOp f x i =
        match source i with
        | some j => x j
        | none => constant i)
    (hinjective : ∀ i l j, source i = some j → source l = some j → i = l) :
    KnownBits.UnaryForwardComplete f := by
  rw [KnownBits.unaryForwardComplete_iff_dependencies]
  intro i l hil
  rw [Set.disjoint_left]
  intro j hji hjl
  have source_eq (o : Fin m) (r : Fin n)
      (hr : r ∈ dependencies (BoolVector.ofBitVecUnaryOp f) o) :
      source o = some r := by
    cases hsource : source o with
    | none =>
        rw [mem_dependencies_iff] at hr
        obtain ⟨x, hx⟩ := hr
        apply (hx _).elim
        rw [hcoordinate, hcoordinate, hsource]
    | some q =>
        congr 1
        rw [mem_dependencies_iff] at hr
        obtain ⟨x, hx⟩ := hr
        by_contra hrq
        apply hx
        rw [hcoordinate, hcoordinate, hsource]
        exact (toggle_of_ne x hrq).symm
  exact hil (hinjective i l j (source_eq i j hji) (source_eq l j hjl))

/-- Structured n-ary witness that one operand bit influences two distinct
output bits. -/
structure NaryForwardDependencyCollision
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) where
  operand : ι
  outputBit : Fin m
  otherOutputBit : Fin m
  outputBits_ne : outputBit ≠ otherOutputBit
  inputBit : Fin (width operand)
  affects_output : inputBit ∈ dependenciesAt
    (BoolVector.ofBitVecNaryOp f) operand outputBit
  affects_other_output : inputBit ∈ dependenciesAt
    (BoolVector.ofBitVecNaryOp f) operand otherOutputBit

/-- A structured dependency collision disproves n-ary KnownBits forward
completeness. -/
theorem NaryForwardDependencyCollision.incomplete
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    {f : ((k : ι) → BitVec (width k)) → BitVec m}
    (w : NaryForwardDependencyCollision f) :
    ¬ KnownBits.ForwardCompleteNary f := by
  rw [forwardCompleteNary_iff_pairwiseDisjointDependencies]
  intro hdisjoint
  have hd := hdisjoint w.operand w.outputBit w.otherOutputBit w.outputBits_ne
  rw [Set.disjoint_left] at hd
  exact hd w.affects_output w.affects_other_output

/-- Structured n-ary witness that, in one fixed context, an output bit
depends on two different bits of the same operand. -/
structure NaryBackwardDependencyCollision
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) where
  operand : ι
  context : (k : ι) → BoolVector (width k)
  outputBit : Fin m
  inputBit : Fin (width operand)
  otherInputBit : Fin (width operand)
  inputBits_ne : inputBit ≠ otherInputBit
  affects_output : inputBit ∈ dependencies
    (sliceAt (BoolVector.ofBitVecNaryOp f) operand context) outputBit
  other_affects_output : otherInputBit ∈ dependencies
    (sliceAt (BoolVector.ofBitVecNaryOp f) operand context) outputBit

/-- A structured context-wise dependency collision disproves n-ary
KnownBits backward completeness. -/
theorem NaryBackwardDependencyCollision.incomplete
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    {f : ((k : ι) → BitVec (width k)) → BitVec m}
    (w : NaryBackwardDependencyCollision f) :
    ¬ KnownBits.BackwardCompleteNary f := by
  rw [backwardCompleteNary_iff_contextwiseAtMostOneDependency]
  intro hsubsingleton
  exact w.inputBits_ne
    (hsubsingleton w.operand w.context w.outputBit
      w.affects_output w.other_affects_output)

/-- For a binary operation, one operand bit influencing two distinct output
bits witnesses KnownBits forward incompleteness. -/
theorem binaryForwardIncomplete_of_dependencyCollision
    {n m : Nat} (f : BitVec n → BitVec n → BitVec m)
    (k : BinaryOperand) (i l : Fin m) (hil : i ≠ l) (j : Fin n)
    (hji : j ∈ dependenciesAt
      (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f)) k i)
    (hjl : j ∈ dependenciesAt
      (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f)) k l) :
    ¬ KnownBits.BinaryForwardComplete f := by
  rw [KnownBits.binaryForwardComplete_iff_nary]
  exact NaryForwardDependencyCollision.incomplete
    { operand := k
      outputBit := i
      otherOutputBit := l
      outputBits_ne := hil
      inputBit := j
      affects_output := hji
      affects_other_output := hjl }

/-- In one fixed context, one output bit depending on two bits of the same
operand witnesses KnownBits backward incompleteness. -/
theorem binaryBackwardIncomplete_of_dependencyCollision
    {n m : Nat} (f : BitVec n → BitVec n → BitVec m)
    (k : BinaryOperand) (context : BinaryOperand → BoolVector n)
    (i : Fin m) (j l : Fin n) (hjl : j ≠ l)
    (hji : j ∈ dependencies
      (sliceAt (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
        k context) i)
    (hli : l ∈ dependencies
      (sliceAt (BoolVector.ofBitVecNaryOp (KnownBits.binaryAsNary f))
        k context) i) :
    ¬ KnownBits.BinaryBackwardComplete f := by
  rw [KnownBits.binaryBackwardComplete_iff_nary]
  exact NaryBackwardDependencyCollision.incomplete
    { operand := k
      context := context
      outputBit := i
      inputBit := j
      otherInputBit := l
      inputBits_ne := hjl
      affects_output := hji
      other_affects_output := hli }

/-- Every total binary operation with a one-bit result is KnownBits forward
complete: there are no two distinct output bits whose dependencies could
overlap. -/
theorem binaryToI1_forwardComplete {n : Nat}
    (f : BitVec n → BitVec n → BitVec 1) :
    KnownBits.BinaryForwardComplete f := by
  rw [KnownBits.binaryForwardComplete_iff_dependencies]
  intro _ i l hil
  exact (hil (Subsingleton.elim i l)).elim

/-- A relational binary operation is pointwise when result membership is the
conjunction of independent, per-bit relations. This includes operations whose
definedness is itself a conjunction of per-bit conditions. -/
def IsPointwiseBinaryRelation {n : Nat}
    (f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector n)) : Prop :=
  ∃ bitRelation : Fin n → Bool → Bool → Bool → Prop,
    ∀ x y z, z ∈ f x y ↔
      ∀ i, bitRelation i (x i) (y i) (z i)

theorem isKnownBitsSet_binaryLift_of_pointwiseRelation {n : Nat}
    {f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector n)}
    (hpointwise : IsPointwiseBinaryRelation f)
    {xs ys : Set (BoolVector n)}
    (hxs : IsKnownBitsSet xs) (hys : IsKnownBitsSet ys) :
    IsKnownBitsSet (BinaryConcreteOp.lift f xs ys) := by
  classical
  rcases hxs with rfl | hxs
  · left
    exact BinaryConcreteOp.lift_empty_left f ys
  rcases hys with rfl | hys
  · left
    exact BinaryConcreteOp.lift_empty_right f xs
  by_cases hresults : (BinaryConcreteOp.lift f xs ys).Nonempty
  · right
    constructor
    · exact hresults
    · intro z hz
      choose out hout houtBit using hz
      choose left hleft rest using hout
      choose right hright hresult using rest
      let combinedLeft : BoolVector n := fun i ↦ left i i
      let combinedRight : BoolVector n := fun i ↦ right i i
      have hcombinedLeft : combinedLeft ∈ xs := by
        apply hxs.2 combinedLeft
        intro i
        exact ⟨left i, hleft i, rfl⟩
      have hcombinedRight : combinedRight ∈ ys := by
        apply hys.2 combinedRight
        intro i
        exact ⟨right i, hright i, rfl⟩
      refine ⟨combinedLeft, hcombinedLeft, combinedRight, hcombinedRight, ?_⟩
      obtain ⟨bitRelation, hpointwise⟩ := hpointwise
      apply (hpointwise combinedLeft combinedRight z).mpr
      intro i
      have hlocal := (hpointwise (left i) (right i) (out i)).mp
        (hresult i) i
      simpa [combinedLeft, combinedRight, houtBit i] using hlocal
  · left
    exact Set.not_nonempty_iff_eq_empty.mp hresults

theorem binaryForwardComplete_of_pointwiseRelation {n : Nat}
    {f : BinaryConcreteOp (BoolVector n) (BoolVector n) (BoolVector n)}
    (hpointwise : IsPointwiseBinaryRelation f) :
    BinaryForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain n)
      (KnownBits.boolDomain n) f := by
  rw [binaryForwardComplete_iff_closure]
  intro xs ys
  apply isKnownBitsSet_iff_closure_eq.mp
  apply isKnownBitsSet_binaryLift_of_pointwiseRelation hpointwise
  · apply isKnownBitsSet_iff_closure_eq.mpr
    exact (KnownBits.boolDomain n).closure_idempotent xs
  · apply isKnownBitsSet_iff_closure_eq.mpr
    exact (KnownBits.boolDomain n).closure_idempotent ys

end BitDependency


end SynthXfer
