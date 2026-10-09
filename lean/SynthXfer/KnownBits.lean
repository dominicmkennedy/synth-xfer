import SynthXfer.ConcreteOps
import Init.Data.BitVec.Lemmas
import Mathlib.Data.BitVec
import Mathlib.Data.Finset.Update
import Mathlib.Data.Finset.Max
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Sigma

/-!
# Known bits

This file defines the KnownBits abstract domain first over Boolean vectors.
Each non-bottom abstract value independently records a nonempty set of possible
values for every bit. Since a bit is Boolean, these possibilities are exactly
known zero, known one, or unknown. A single global bottom represents the empty
set of concrete vectors.
-/

namespace SynthXfer

/-- A bitvector represented extensionally as a Boolean value at every index. -/
abbrev BoolVector (n : Nat) := Fin n → Bool

/-- Assemble a bitvector from its least-significant-bit-indexed Boolean
coordinates. -/
def BoolVector.toBitVec {n : Nat} (x : BoolVector n) : BitVec n :=
  (BitVec.ofBoolListLE (List.ofFn x)).cast (by simp)

@[simp]
theorem BoolVector.toBitVec_getLsb {n : Nat} (x : BoolVector n) (i : Fin n) :
    x.toBitVec.getLsb i = x i := by
  change (BitVec.ofBoolListLE (List.ofFn x)).getLsbD i = x i
  rw [BitVec.getLsbD_ofBoolListLE]
  simp

/-- View a bitvector as its least-significant-bit-indexed Boolean coordinates. -/
def BoolVector.ofBitVec {n : Nat} (x : BitVec n) : BoolVector n :=
  fun i ↦ x.getLsb i

@[simp]
theorem BoolVector.ofBitVec_apply {n : Nat} (x : BitVec n) (i : Fin n) :
    BoolVector.ofBitVec x i = x.getLsb i :=
  rfl

/-- The bit-preserving equivalence between Boolean vectors and `BitVec`. -/
def boolVectorEquivBitVec (n : Nat) : BoolVector n ≃ BitVec n where
  toFun := BoolVector.toBitVec
  invFun := BoolVector.ofBitVec
  left_inv x := by
    funext i
    exact x.toBitVec_getLsb i
  right_inv x := by
    apply BitVec.eq_of_getLsbD_eq
    intro i hi
    exact BoolVector.toBitVec_getLsb (BoolVector.ofBitVec x) ⟨i, hi⟩

/-- Express a heterogeneous bitvector operation using Boolean vectors while
preserving every operand and result bit index. -/
def BoolVector.ofBitVecNaryOp {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    ((k : ι) → BoolVector (width k)) → BoolVector m :=
  fun x ↦ BoolVector.ofBitVec (f fun k ↦ (x k).toBitVec)

@[simp]
theorem transportTotal_eq_ofBitVecNaryOp {ι : Type*}
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryConcreteOp.transportTotal
        (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
        (boolVectorEquivBitVec m).symm f =
      BoolVector.ofBitVecNaryOp f := by
  rfl

/-- Express a unary bitvector operation using Boolean vectors. -/
def BoolVector.ofBitVecUnaryOp {n m : Nat} (f : BitVec n → BitVec m) :
    BoolVector n → BoolVector m :=
  fun x ↦ BoolVector.ofBitVec (f x.toBitVec)

@[simp]
theorem transportUnary_eq_ofBitVecUnaryOp {n m : Nat}
    (f : BitVec n → BitVec m) :
    AbstractDomain.transportUnary (boolVectorEquivBitVec n).symm
      (boolVectorEquivBitVec m).symm f = BoolVector.ofBitVecUnaryOp f := by
  rfl

/-- The nonempty set of values allowed for one bit. -/
abbrev BitKnowledge := {s : Set Bool // s.Nonempty}

namespace BitKnowledge

/-- A bit known to have value `b`. -/
def known (b : Bool) : BitKnowledge :=
  ⟨{b}, Set.singleton_nonempty b⟩

/-- A bit whose value is unknown. -/
def unknown : BitKnowledge :=
  ⟨Set.univ, Set.univ_nonempty⟩

instance : OrderTop BitKnowledge where
  top := unknown
  le_top _ := Set.subset_univ _

@[simp]
theorem mem_known {a b : Bool} : a ∈ (known b : Set Bool) ↔ a = b :=
  Set.mem_singleton_iff

@[simp]
theorem mem_unknown (b : Bool) : b ∈ (unknown : Set Bool) :=
  Set.mem_univ b

end BitKnowledge

/-- KnownBits values: either bottom, or independent knowledge for every bit. -/
abbrev KnownBits (n : Nat) := WithBot (Fin n → BitKnowledge)

namespace KnownBits

private def observed {n : Nat} (s : Set (BoolVector n)) (hs : s.Nonempty)
    (i : Fin n) : BitKnowledge :=
  ⟨{b | ∃ x ∈ s, x i = b}, by
    obtain ⟨x, hxs⟩ := hs
    exact ⟨x i, x, hxs, rfl⟩⟩

/-- The best KnownBits abstraction of a set of Boolean vectors. -/
noncomputable def abstract {n : Nat} (s : Set (BoolVector n)) : KnownBits n := by
  classical
  exact if hs : s.Nonempty then
    ((fun i ↦ observed s hs i) : Fin n → BitKnowledge)
  else
    ⊥

/-- The Boolean vectors represented by a KnownBits value. -/
def concretize {n : Nat} : KnownBits n → Set (BoolVector n)
  | ⊥ => ∅
  | (p : Fin n → BitKnowledge) => {x | ∀ i, x i ∈ (p i : Set Bool)}

@[simp]
theorem concretize_bot {n : Nat} : concretize (⊥ : KnownBits n) = ∅ :=
  rfl

@[simp]
theorem mem_concretize_coe {n : Nat} {p : Fin n → BitKnowledge}
    {x : BoolVector n} :
    x ∈ concretize (p : KnownBits n) ↔ ∀ i, x i ∈ (p i : Set Bool) :=
  Iff.rfl

private theorem abstract_gc {n : Nat} :
    GaloisConnection (abstract : Set (BoolVector n) → KnownBits n) concretize := by
  intro s a
  classical
  by_cases hs : s.Nonempty
  · rw [abstract, dif_pos hs]
    induction a using WithBot.recBotCoe with
    | bot =>
        constructor
        · exact fun h ↦ (WithBot.not_coe_le_bot _ h).elim
        · intro h
          obtain ⟨x, hxs⟩ := hs
          have : x ∈ (∅ : Set (BoolVector n)) := h hxs
          exact this.elim
    | coe p =>
        rw [WithBot.coe_le_coe]
        constructor
        · intro h x hxs i
          exact h i ⟨x, hxs, rfl⟩
        · intro h i b hb
          obtain ⟨x, hxs, rfl⟩ := hb
          exact h hxs i
  · have hempty : s = ∅ := by
      ext x
      constructor
      · intro hxs
        exact (hs ⟨x, hxs⟩).elim
      · simp
    subst s
    simp [abstract, concretize]

private theorem abstract_concretize {n : Nat} :
    Function.LeftInverse (abstract : Set (BoolVector n) → KnownBits n) concretize := by
  intro a
  classical
  induction a using WithBot.recBotCoe with
  | bot => simp [abstract, concretize]
  | coe p =>
      let default : BoolVector n := fun i ↦ Classical.choose (p i).property
      have hdefault : default ∈ concretize (p : KnownBits n) :=
        fun i ↦ Classical.choose_spec (p i).property
      have hs : (concretize (p : KnownBits n)).Nonempty := ⟨default, hdefault⟩
      rw [abstract, dif_pos hs, WithBot.coe_eq_coe]
      funext i
      apply Subtype.ext
      ext b
      constructor
      · rintro ⟨x, hx, rfl⟩
        exact hx i
      · intro hb
        let x : BoolVector n := Function.update default i b
        have hx : x ∈ concretize (p : KnownBits n) := by
          intro j
          by_cases hji : j = i
          · subst j
            simpa [x] using hb
          · simpa [x, hji] using hdefault j
        exact ⟨x, hx, by simp [x]⟩

/-- Internal Boolean-coordinate presentation of the KnownBits domain. Concrete
operation APIs should use `KnownBits.domain`, whose carrier is `BitVec`. -/
noncomputable def boolDomain (n : Nat) :
    AbstractDomain (BoolVector n) (KnownBits n) where
  abstract := abstract
  concretize := concretize
  gc := abstract_gc
  insertion := abstract_concretize

/-- The public KnownBits abstract domain over Lean bitvectors. -/
noncomputable def domain (n : Nat) :
    AbstractDomain (BitVec n) (KnownBits n) :=
  (boolDomain n).comapEquiv (boolVectorEquivBitVec n).symm

@[simp]
theorem mem_domain_concretize {n : Nat} {a : KnownBits n}
    {x : BitVec n} :
    x ∈ (domain n).concretize a ↔ BoolVector.ofBitVec x ∈ concretize a :=
  Iff.rfl

/-- Forward completeness of a heterogeneous operation under independent
KnownBits operands. -/
def BoolForwardCompleteNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) : Prop :=
  SynthXfer.NaryForwardComplete (fun k ↦ boolDomain (width k)) (boolDomain m)
    (NaryConcreteOp.ofTotal f)

/-- Backward completeness after independently abstracting every KnownBits
operand. -/
def BoolBackwardCompleteNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) : Prop :=
  SynthXfer.NaryBackwardComplete (fun k ↦ boolDomain (width k)) (boolDomain m)
    (NaryConcreteOp.ofTotal f)

/-- Backward completeness with respect to one specified KnownBits operand. -/
def BoolBackwardCompleteAt {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι) : Prop :=
  SynthXfer.NaryBackwardCompleteAt (fun l ↦ boolDomain (width l)) (boolDomain m)
    (NaryConcreteOp.ofTotal f) k

/-- Forward completeness of a heterogeneous operation on Lean bitvectors. -/
def ForwardCompleteNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) : Prop :=
  SynthXfer.NaryForwardComplete (fun k ↦ domain (width k)) (domain m)
    (NaryConcreteOp.ofTotal f)

/-- Backward completeness of a heterogeneous operation on Lean bitvectors. -/
def BackwardCompleteNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) : Prop :=
  SynthXfer.NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
    (NaryConcreteOp.ofTotal f)

/-- Per-operand backward completeness for an operation on Lean bitvectors. -/
def BackwardCompleteAt {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) (k : ι) : Prop :=
  SynthXfer.NaryBackwardCompleteAt (fun l ↦ domain (width l)) (domain m)
    (NaryConcreteOp.ofTotal f) k

/-- Internal constructor for the KnownBits value describing one Boolean
coordinate vector exactly. -/
def boolConstant {n : Nat} (x : BoolVector n) : KnownBits n :=
  ((fun i ↦ BitKnowledge.known (x i)) : Fin n → BitKnowledge)

@[simp]
theorem mem_concretize_boolConstant {n : Nat} {x y : BoolVector n} :
    y ∈ concretize (boolConstant x) ↔ y = x := by
  constructor
  · intro h
    funext i
    exact BitKnowledge.mem_known.mp (h i)
  · rintro rfl i
    exact BitKnowledge.mem_known.mpr rfl

/-- The KnownBits value describing one concrete bitvector exactly. -/
def constant {n : Nat} (x : BitVec n) : KnownBits n :=
  boolConstant (BoolVector.ofBitVec x)

@[simp]
theorem mem_concretize_constant {n : Nat} {x y : BitVec n} :
    y ∈ (domain n).concretize (constant x) ↔ y = x := by
  rw [mem_domain_concretize, constant, mem_concretize_boolConstant]
  exact (boolVectorEquivBitVec n).symm.injective.eq_iff

end KnownBits

namespace BitDependency

/-- Toggle one coordinate of a Boolean product indexed by an arbitrary type. -/
def toggleIndex {I : Type*} [DecidableEq I] (x : I → Bool) (j : I) : I → Bool :=
  Function.update x j (!x j)

/-- An input coordinate is essential to an output coordinate when toggling it
can change that output in some context. -/
def IsEssentialIndex {I O : Type*} [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) (i : O) (j : I) : Prop :=
  ∃ x, f x i ≠ f (toggleIndex x j) i

/-- Toggle coordinate `j` of a Boolean vector. -/
abbrev toggle {n : Nat} (x : BoolVector n) (j : Fin n) : BoolVector n :=
  toggleIndex x j

@[simp]
theorem toggle_same {n : Nat} (x : BoolVector n) (j : Fin n) :
    toggle x j j = !x j := by
  simp [toggleIndex]

@[simp]
theorem toggle_of_ne {n : Nat} (x : BoolVector n) {i j : Fin n} (h : i ≠ j) :
    toggle x j i = x i := by
  simp [toggleIndex, h]

@[simp]
theorem toggle_toggle {n : Nat} (x : BoolVector n) (j : Fin n) :
    toggle (toggle x j) j = x := by
  funext i
  by_cases hij : i = j
  · subst i
    simp [toggle]
  · simp [toggle, hij]


/-- Input bit `j` is an essential dependency of output bit `i` when toggling
`j` can change output `i` in some context. -/
abbrev IsEssential {n m : Nat} (f : BoolVector n → BoolVector m)
    (i : Fin m) (j : Fin n) : Prop :=
  IsEssentialIndex f i j

/-- The essential input dependencies of an output bit. -/
def dependencies {n m : Nat} (f : BoolVector n → BoolVector m)
    (i : Fin m) : Set (Fin n) :=
  {j | IsEssential f i j}

/-- Toggle bit `j` of operand `k`, leaving every other operand unchanged. -/
def toggleOperand {ι : Type*} [DecidableEq ι] {width : ι → Nat}
    (x : (k : ι) → BoolVector (width k)) (k : ι) (j : Fin (width k)) :
    (l : ι) → BoolVector (width l) :=
  Function.update x k (toggle (x k) j)

/-- Operand-wise essential dependencies for a heterogeneous n-ary operation. -/
def IsEssentialAt {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (k : ι) (i : Fin m) (j : Fin (width k)) : Prop :=
  ∃ x, f x i ≠ f (toggleOperand x k j) i

/-- The dependencies of output bit `i` within operand `k`. -/
def dependenciesAt {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (k : ι) (i : Fin m) : Set (Fin (width k)) :=
  {j | IsEssentialAt f k i j}

/-- Distinct output bits have disjoint dependencies in every operand. -/
def BoolPairwiseDisjointDependencies {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) : Prop :=
  ∀ k i l, i ≠ l → Disjoint (dependenciesAt f k i) (dependenciesAt f k l)

/-- Distinct output bits of a unary operation have disjoint dependencies. -/
def BoolPairwiseDisjointDependenciesUnary {n m : Nat} (f : BoolVector n → BoolVector m) : Prop :=
  ∀ i l, i ≠ l → Disjoint (dependencies f i) (dependencies f l)


/-- A nonempty subset of a Boolean product is a box when independent choices
of every observed coordinate always produce another member of the set. -/
def IsBooleanBox {I : Type*} (s : Set (I → Bool)) : Prop :=
  s.Nonempty ∧ ∀ z, (∀ i, ∃ x ∈ s, x i = z i) → z ∈ s

/-- A function preserves Boolean boxes when the image of every nonempty box
is again a box. -/
def PreservesBooleanBoxes {I O : Type*} (f : (I → Bool) → (O → Bool)) : Prop :=
  ∀ s, IsBooleanBox s → IsBooleanBox (f '' s)

/-- Exactly representable KnownBits sets are either empty or nonempty Boolean
boxes. The empty case is represented by bottom. -/
def IsKnownBitsSet {I : Type*} (s : Set (I → Bool)) : Prop :=
  s = ∅ ∨ IsBooleanBox s

/-- Restrict a Boolean assignment to a selected family of coordinates. -/
def reindexCoordinates {I J : Type*} (e : J → I) (x : I → Bool) : J → Bool :=
  fun j ↦ x (e j)

/-- A projection of a Boolean box onto any injectively selected family of
coordinates is again a Boolean box. -/
theorem IsBooleanBox.image_reindexCoordinates {I J : Type*}
    {s : Set (I → Bool)} (hs : IsBooleanBox s)
    (e : J → I) (he : Function.Injective e) :
    IsBooleanBox (reindexCoordinates e '' s) := by
  classical
  constructor
  · exact hs.1.image (reindexCoordinates e)
  · intro z hz
    obtain ⟨base, hbase⟩ := hs.1
    let extended : I → Bool := fun i ↦
      if hi : ∃ j, e j = i then z (Classical.choose hi) else base i
    have hextended_apply (j : J) : extended (e j) = z j := by
      let hj : ∃ j', e j' = e j := ⟨j, rfl⟩
      rw [show extended (e j) = z (Classical.choose hj) by
        simp only [extended, dif_pos hj]]
      congr 1
      exact he (Classical.choose_spec hj)
    have hextended : extended ∈ s := by
      apply hs.2 extended
      intro i
      by_cases hi : ∃ j, e j = i
      · obtain ⟨j, rfl⟩ := hi
        obtain ⟨x, ⟨source, hsource, rfl⟩, hx⟩ := hz j
        refine ⟨source, hsource, ?_⟩
        exact hx.trans (hextended_apply j).symm
      · exact ⟨base, hbase, by simp [extended, hi]⟩
    refine ⟨extended, hextended, ?_⟩
    funext j
    exact hextended_apply j

@[simp]
theorem toggleIndex_same {I : Type*} [DecidableEq I]
    (x : I → Bool) (j : I) : toggleIndex x j j = !x j := by
  simp [toggleIndex]

@[simp]
theorem toggleIndex_of_ne {I : Type*} [DecidableEq I]
    (x : I → Bool) {i j : I} (h : i ≠ j) :
    toggleIndex x j i = x i := by
  simp [toggleIndex, h]

@[simp]
theorem toggleIndex_toggleIndex {I : Type*} [DecidableEq I]
    (x : I → Bool) (j : I) : toggleIndex (toggleIndex x j) j = x := by
  funext i
  by_cases hij : i = j
  · subst i
    simp
  · simp [hij]

theorem toggleIndex_comm {I : Type*} [DecidableEq I]
    (x : I → Bool) {j k : I} (hjk : j ≠ k) :
    toggleIndex (toggleIndex x j) k = toggleIndex (toggleIndex x k) j := by
  funext q
  by_cases hqj : q = j
  · subst q
    simp [toggleIndex, hjk, Ne.symm hjk]
  · by_cases hqk : q = k
    · subst q
      simp [toggleIndex, hjk, Ne.symm hjk]
    · simp [toggleIndex, hqj, hqk]

/-- No input coordinate is essential to two distinct output coordinates. -/
def PairwiseDisjointDependenciesIndex {I O : Type*} [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) : Prop :=
  ∀ i l, i ≠ l → Disjoint ({j | IsEssentialIndex f i j} : Set I)
    {j | IsEssentialIndex f l j}

/-- Extend an assignment on a selected finite set of coordinates, taking all
other coordinates from `base`. -/
def extendOn {I : Type*} [DecidableEq I] (free : Finset I) (base : I → Bool)
    (x : free → Bool) : I → Bool :=
  fun i ↦ if h : i ∈ free then x ⟨i, h⟩ else base i

@[simp]
theorem extendOn_apply_mem {I : Type*} [DecidableEq I]
    (free : Finset I) (base : I → Bool) (x : free → Bool) (i : free) :
    extendOn free base x i = x i := by
  simp [extendOn, i.property]

theorem extendOn_apply_not_mem {I : Type*} [DecidableEq I]
    (free : Finset I) (base : I → Bool) (x : free → Bool)
    {i : I} (hi : i ∉ free) :
    extendOn free base x i = base i := by
  simp [extendOn, hi]

/-- Restrict an operation to a face by fixing every coordinate outside
`free` to `base`. -/
def restrictToFace {I O : Type*} [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) (free : Finset I) (base : I → Bool) :
    (free → Bool) → (O → Bool) :=
  fun x ↦ f (extendOn free base x)

def differingCoordinates {I : Type*} [Fintype I] [DecidableEq I]
    (x y : I → Bool) : Finset I :=
  Finset.univ.filter fun i ↦ x i ≠ y i

@[simp]
theorem mem_differingCoordinates {I : Type*} [Fintype I] [DecidableEq I]
    {x y : I → Bool} {i : I} :
    i ∈ differingCoordinates x y ↔ x i ≠ y i := by
  simp [differingCoordinates]

theorem differingCoordinates_extendOn_lt {I : Type*} [Fintype I]
    [DecidableEq I] (a b : I → Bool)
    (z : differingCoordinates a b → Bool)
    (hz : extendOn (differingCoordinates a b) a z ≠ a) :
    (differingCoordinates (extendOn (differingCoordinates a b) a z) b).card <
      (differingCoordinates a b).card := by
  apply Finset.card_lt_card
  apply Finset.ssubset_iff_subset_ne.mpr
  constructor
  · intro i hi
    simp only [mem_differingCoordinates] at hi ⊢
    by_contra hai
    have hiNotMem : i ∉ differingCoordinates a b := by
      simpa using hai
    have hextend := extendOn_apply_not_mem
      (differingCoordinates a b) a z hiNotMem
    exact hi (hextend.trans hai)
  · intro heq
    have hexists : ∃ i, extendOn (differingCoordinates a b) a z i ≠ a i := by
      by_contra h
      push Not at h
      exact hz (funext h)
    obtain ⟨i, hiExtend⟩ := hexists
    have hi : i ∈ differingCoordinates a b := by
      by_contra hi
      exact hiExtend (extendOn_apply_not_mem _ _ _ hi)
    have hiChild : i ∈ differingCoordinates
        (extendOn (differingCoordinates a b) a z) b := by
      rw [heq]
      exact hi
    simp only [mem_differingCoordinates] at hi hiChild
    have bool_eq_of_two_ne : ∀ x a b : Bool, a ≠ b → x ≠ a → x = b := by
      decide
    exact hiChild (bool_eq_of_two_ne
      (extendOn (differingCoordinates a b) a z i) (a i) (b i) hi hiExtend)

theorem differingCoordinates_comm {I : Type*} [Fintype I] [DecidableEq I]
    (a b : I → Bool) :
    differingCoordinates a b = differingCoordinates b a := by
  ext i
  simp only [mem_differingCoordinates, ne_comm]

theorem differingCoordinates_extendOn_right_lt {I : Type*} [Fintype I]
    [DecidableEq I] (a b : I → Bool)
    (z : differingCoordinates a b → Bool)
    (hz : extendOn (differingCoordinates a b) b z ≠ b) :
    (differingCoordinates a (extendOn (differingCoordinates a b) b z)).card <
      (differingCoordinates a b).card := by
  let swapIndex : differingCoordinates b a → differingCoordinates a b :=
    fun i ↦ ⟨i, by
      simpa only [mem_differingCoordinates, ne_comm] using i.property⟩
  let z' : differingCoordinates b a → Bool := fun i ↦ z (swapIndex i)
  have hextend : extendOn (differingCoordinates b a) b z' =
      extendOn (differingCoordinates a b) b z := by
    funext i
    by_cases hi : i ∈ differingCoordinates a b
    · have hi' : i ∈ differingCoordinates b a := by
        simpa only [mem_differingCoordinates, ne_comm] using hi
      simp only [extendOn, dif_pos hi, dif_pos hi', z', swapIndex]
    · have hi' : i ∉ differingCoordinates b a := by
        simpa only [mem_differingCoordinates, ne_comm] using hi
      simp only [extendOn, dif_neg hi, dif_neg hi']
  have hz' : extendOn (differingCoordinates b a) b z' ≠ b := by
    rwa [hextend]
  have hlt := differingCoordinates_extendOn_lt b a z' hz'
  rw [hextend, differingCoordinates_comm
    (extendOn (differingCoordinates a b) b z) a,
    differingCoordinates_comm b a] at hlt
  exact hlt

theorem isBooleanBox_image_extendOn {I : Type*} [DecidableEq I]
    (free : Finset I) (base : I → Bool) {s : Set (free → Bool)}
    (hs : IsBooleanBox s) :
    IsBooleanBox (extendOn free base '' s) := by
  constructor
  · exact hs.1.image (extendOn free base)
  · intro z hz
    let x : free → Bool := fun i ↦ z i
    have hx : x ∈ s := by
      apply hs.2 x
      intro i
      obtain ⟨y, ⟨w, hw, rfl⟩, hy⟩ := hz i
      exact ⟨w, hw, by simpa [x] using hy⟩
    refine ⟨x, hx, ?_⟩
    funext i
    by_cases hi : i ∈ free
    · simp [extendOn, hi, x]
    · obtain ⟨y, ⟨w, hw, rfl⟩, hy⟩ := hz i
      simpa [extendOn, hi] using hy

theorem PreservesBooleanBoxes.restrictToFace {I O : Type*} [DecidableEq I]
    {f : (I → Bool) → (O → Bool)} (hf : PreservesBooleanBoxes f)
    (free : Finset I) (base : I → Bool) :
    PreservesBooleanBoxes (restrictToFace f free base) := by
  intro s hs
  have hextended := isBooleanBox_image_extendOn free base hs
  have himage := hf _ hextended
  change IsBooleanBox ((fun x ↦ f (extendOn free base x)) '' s)
  rw [← Set.image_image]
  exact himage

theorem isBooleanBox_pair_toggleIndex {I : Type*} [DecidableEq I]
    (x : I → Bool) (j : I) :
    IsBooleanBox ({x, toggleIndex x j} : Set (I → Bool)) := by
  constructor
  · exact ⟨x, by simp⟩
  · intro z hz
    by_cases hzj : z j = x j
    · left
      funext i
      by_cases hij : i = j
      · simpa [hij] using hzj
      · obtain ⟨y, hy, hyi⟩ := hz i
        rcases hy with rfl | rfl
        · exact hyi.symm
        · simpa [hij] using hyi.symm
    · right
      funext i
      by_cases hij : i = j
      · subst i
        have bool_eq_not_of_ne : ∀ a b : Bool, a ≠ b → a = !b := by decide
        have : z j = !x j := bool_eq_not_of_ne _ _ hzj
        simpa using this
      · obtain ⟨y, hy, hyi⟩ := hz i
        rcases hy with rfl | rfl
        · simpa [hij] using hyi.symm
        · simpa [hij] using hyi.symm

/-- A box-preserving Boolean map sends every input edge to either a point or
one output edge. -/
theorem pointwiseAtMostOne_of_preservesBooleanBoxes
    {I O : Type*} [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) (hf : PreservesBooleanBoxes f) :
    ∀ x j, ({i | f x i ≠ f (toggleIndex x j) i} : Set O).Subsingleton := by
  classical
  intro x j i hi l hl
  let tx := toggleIndex x j
  let outputs : Set (O → Bool) := {f x, f tx}
  have houtputs : IsBooleanBox outputs := by
    have himage := hf {x, tx} (by
      simpa [tx] using isBooleanBox_pair_toggleIndex x j)
    simpa [outputs, Set.image_pair] using himage
  by_contra hil
  let mixed : O → Bool := Function.update (f x) i (f tx i)
  have hmixed : mixed ∈ outputs := by
    apply houtputs.2 mixed
    intro q
    by_cases hqi : q = i
    · subst q
      exact ⟨f tx, by simp [outputs], by simp [mixed]⟩
    · exact ⟨f x, by simp [outputs], by simp [mixed, hqi]⟩
  rcases hmixed with hmixed | hmixed
  · have heq := congrArg (fun output ↦ output i) hmixed
    simp [mixed] at heq
    exact hi heq.symm
  · have heq := congrArg (fun output ↦ output l) hmixed
    have heq' : f x l = f tx l := by
      calc
        f x l = mixed l := by simp [mixed, Ne.symm hil]
        _ = f tx l := heq
    exact hl (by simpa [tx] using heq')

theorem eq_of_forall_toggleIndex_eq {I A : Type*} [Finite I]
    [DecidableEq I] (g : (I → Bool) → A)
    (hstable : ∀ x j, g x = g (toggleIndex x j)) :
    ∀ x y, g x = g y := by
  letI := Fintype.ofFinite I
  intro x y
  let splice (s : Finset I) : I → Bool :=
    Function.updateFinset x s fun i ↦ y i
  have hsplice : ∀ s : Finset I, g (splice s) = g x := by
    intro s
    induction s using Finset.induction with
    | empty => rfl
    | @insert j s hj ih =>
        have hinsert : splice (insert j s) =
            Function.update (splice s) j (y j) := by
          funext k
          by_cases hkj : k = j
          · subst k
            simp [splice, Function.updateFinset]
          · simp [splice, Function.updateFinset, hkj]
        rw [hinsert]
        by_cases heq : y j = splice s j
        · have : Function.update (splice s) j (y j) = splice s := by
            funext k
            by_cases hkj : k = j
            · subst k
              simp [heq]
            · simp [hkj]
          rw [this, ih]
        · have hnot : y j = !(splice s j) := by
            have bool_eq_not_of_ne : ∀ a b : Bool, a ≠ b → a = !b := by decide
            exact bool_eq_not_of_ne _ _ heq
          have : Function.update (splice s) j (y j) = toggleIndex (splice s) j := by
            simp [toggleIndex, hnot]
          rw [this, ← hstable, ih]
  have hall := hsplice Finset.univ
  have : splice Finset.univ = y := by
    funext i
    simp [splice, Function.updateFinset]
  rw [this] at hall
  exact hall.symm

theorem constant_of_no_essentialIndex {I O : Type*} [Finite I]
    [DecidableEq I] (f : (I → Bool) → (O → Bool)) (i : O)
    (h : ∀ j, ¬ IsEssentialIndex f i j) :
    ∀ x y, f x i = f y i := by
  apply eq_of_forall_toggleIndex_eq (fun x ↦ f x i)
  intro x j
  by_contra hne
  exact h j ⟨x, hne⟩

/-- An output coordinate depends only on its essential input coordinates. -/
theorem output_eq_of_agree_on_essentialIndices
    {I O : Type*} [Finite I] [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) (i : O) (x y : I → Bool)
    (hxy : ∀ j, IsEssentialIndex f i j → x j = y j) :
    f x i = f y i := by
  letI := Fintype.ofFinite I
  let splice (s : Finset I) : I → Bool :=
    Function.updateFinset x s fun j ↦ y j
  have hsplice : ∀ s : Finset I, f (splice s) i = f x i := by
    intro s
    induction s using Finset.induction with
    | empty => rfl
    | @insert j s hj ih =>
        have hinsert : splice (insert j s) =
            Function.update (splice s) j (y j) := by
          funext k
          by_cases hkj : k = j
          · subst k
            simp [splice, Function.updateFinset]
          · simp [splice, Function.updateFinset, hkj]
        rw [hinsert]
        by_cases hessential : IsEssentialIndex f i j
        · have hcurrent : splice s j = x j := by
            simp [splice, Function.updateFinset, hj]
          have hsame : Function.update (splice s) j (y j) = splice s := by
            funext k
            by_cases hkj : k = j
            · subst k
              simp [hxy j hessential, hcurrent]
            · simp [hkj]
          rw [hsame, ih]
        · by_cases heq : y j = splice s j
          · have hsame : Function.update (splice s) j (y j) = splice s := by
              funext k
              by_cases hkj : k = j
              · subst k
                simp [heq]
              · simp [hkj]
            rw [hsame, ih]
          · have hnot : y j = !(splice s j) := by
              have bool_eq_not_of_ne : ∀ a b : Bool, a ≠ b → a = !b := by decide
              exact bool_eq_not_of_ne _ _ heq
            have htoggle : Function.update (splice s) j (y j) =
                toggleIndex (splice s) j := by
              simp [toggleIndex, hnot]
            have hstable : f (splice s) i = f (toggleIndex (splice s) j) i := by
              by_contra hne
              exact hessential ⟨splice s, hne⟩
            rw [htoggle, ← hstable, ih]
  have huniv := hsplice Finset.univ
  have hsplice_univ : splice Finset.univ = y := by
    funext j
    simp [splice, Function.updateFinset]
  rw [hsplice_univ] at huniv
  exact huniv.symm

/-- Disjoint essential dependencies are sufficient for a Boolean map to send
every Boolean box to a Boolean box. -/
theorem preservesBooleanBoxes_of_pairwiseDisjointDependenciesIndex
    {I O : Type*} [Finite I] [DecidableEq I]
    (f : (I → Bool) → (O → Bool))
    (hdisjoint : PairwiseDisjointDependenciesIndex f) :
    PreservesBooleanBoxes f := by
  classical
  intro s hs
  constructor
  · exact hs.1.image f
  · intro z hz
    obtain ⟨default, hdefault⟩ := hs.1
    have hzObserved : ∀ i, ∃ x ∈ s, f x i = z i := by
      intro i
      obtain ⟨out, ⟨x, hx, rfl⟩, hout⟩ := hz i
      exact ⟨x, hx, hout⟩
    choose witness hwitness_mem hwitness_bit using hzObserved
    let combined : I → Bool := fun j ↦
      if h : ∃ i, IsEssentialIndex f i j then
        witness (Classical.choose h) j
      else
        default j
    have hcombined : combined ∈ s := by
      apply hs.2 combined
      intro j
      by_cases h : ∃ i, IsEssentialIndex f i j
      · exact ⟨witness (Classical.choose h), hwitness_mem _, by simp [combined, h]⟩
      · exact ⟨default, hdefault, by simp [combined, h]⟩
    refine ⟨combined, hcombined, ?_⟩
    funext i
    calc
      f combined i = f (witness i) i :=
        output_eq_of_agree_on_essentialIndices f i combined (witness i) (by
          intro j hj
          have hexists : ∃ l, IsEssentialIndex f l j := ⟨i, hj⟩
          rw [show combined j = witness (Classical.choose hexists) j by
            simp [combined, hexists]]
          have hchosen := Classical.choose_spec hexists
          have : Classical.choose hexists = i := by
            by_contra hne
            exact Set.disjoint_left.mp
              (hdisjoint (Classical.choose hexists) i hne) hchosen hj
          rw [this])
      _ = z i := hwitness_bit i

/-- Keep just two selected coordinates of a Boolean output. -/
def projectTwo {I O : Type*} (f : (I → Bool) → (O → Bool))
    (i l : O) : (I → Bool) → (Bool → Bool) :=
  fun x chooseSecond ↦ if chooseSecond then f x l else f x i

@[simp]
theorem projectTwo_false {I O : Type*}
    (f : (I → Bool) → (O → Bool)) (i l : O) (x : I → Bool) :
    projectTwo f i l x false = f x i := by
  simp [projectTwo]

@[simp]
theorem projectTwo_true {I O : Type*}
    (f : (I → Bool) → (O → Bool)) (i l : O) (x : I → Bool) :
    projectTwo f i l x true = f x l := by
  simp [projectTwo]

/-- Projecting a box-preserving map to two distinct output coordinates still
preserves Boolean boxes. -/
theorem PreservesBooleanBoxes.projectTwo {I O : Type*}
    {f : (I → Bool) → (O → Bool)} (hf : PreservesBooleanBoxes f)
    (i l : O) (hil : i ≠ l) : PreservesBooleanBoxes (projectTwo f i l) := by
  classical
  intro s hs
  have hfull := hf s hs
  constructor
  · obtain ⟨x, hx⟩ := hs.1
    exact ⟨BitDependency.projectTwo f i l x, x, hx, rfl⟩
  · intro z hz
    obtain ⟨zi, ⟨xi, hxi, rfl⟩, hzi⟩ := hz false
    obtain ⟨zl, ⟨xl, hxl, rfl⟩, hzl⟩ := hz true
    obtain ⟨base, hbase⟩ := hfull.1
    let mixed : O → Bool :=
      Function.update (Function.update base i (f xi i)) l (f xl l)
    have hmixed : mixed ∈ f '' s := by
      apply hfull.2 mixed
      intro o
      by_cases hoi : o = i
      · subst o
        exact ⟨f xi, ⟨xi, hxi, rfl⟩, by simp [mixed, hil]⟩
      · by_cases hol : o = l
        · subst o
          exact ⟨f xl, ⟨xl, hxl, rfl⟩, by simp [mixed]⟩
        · exact ⟨base, hbase, by simp [mixed, hoi, hol]⟩
    obtain ⟨x, hx, hfx⟩ := hmixed
    refine ⟨x, hx, ?_⟩
    funext b
    cases b
    · calc
        f x i = f xi i := by simpa [mixed, hil] using congrFun hfx i
        _ = z false := by simpa using hzi
    · calc
        f x l = f xl l := by simpa [mixed] using congrFun hfx l
        _ = z true := by simpa using hzl

/-- The two-output core of the necessity proof. If a map to a pair of bits
preserves Boolean boxes, no input coordinate can influence both bits. -/
theorem disjoint_two_outputs_of_preservesBooleanBoxes
    {I : Type*} [Finite I] [DecidableEq I]
    (f : (I → Bool) → (Bool → Bool)) (hf : PreservesBooleanBoxes f) :
    Disjoint ({j | IsEssentialIndex f false j} : Set I)
      {j | IsEssentialIndex f true j} := by
  classical
  letI := Fintype.ofFinite I
  let i : Bool := false
  let l : Bool := true
  have hil : i ≠ l := by simp [i, l]
  rw [Set.disjoint_left]
  intro j hji hjl
  rcases hji with ⟨x, hx⟩
  rcases hjl with ⟨y, hy⟩
  let free : Finset I := Finset.univ.erase j
  let embed (b : Bool) (z : free → Bool) : I → Bool :=
    extendOn free (fun _ ↦ b) z
  let layer (b : Bool) : (free → Bool) → (Bool → Bool) :=
    fun z ↦ f (embed b z)
  have hembed (z : I → Bool) : embed (z j) (fun k ↦ z k) = z := by
    funext k
    by_cases hkj : k = j
    · subst k
      simp [embed, extendOn, free]
    · simp [embed, extendOn, free, hkj]
  have hembed_toggle (z : I → Bool) :
      embed (!(z j)) (fun k ↦ z k) = toggleIndex z j := by
    funext k
    by_cases hkj : k = j
    · subst k
      simp [embed, extendOn, free]
    · simp [embed, extendOn, free, hkj, toggleIndex]
  let p : Finset (free → Bool) :=
    Finset.univ.filter fun z ↦ layer false z i ≠ layer true z i
  let q : Finset (free → Bool) :=
    Finset.univ.filter fun z ↦ layer false z l ≠ layer true z l
  have hp : p.Nonempty := by
    let z : free → Bool := fun k ↦ x k
    refine ⟨z, ?_⟩
    simp only [p, Finset.mem_filter, Finset.mem_univ, true_and]
    have hx' : f (embed (x j) (fun k ↦ x k)) i ≠
        f (embed (!(x j)) (fun k ↦ x k)) i := by
      simpa only [hembed x, hembed_toggle x] using hx
    cases hxj : x j
    · simpa [layer, z, hxj] using hx'
    · simpa [layer, z, hxj, ne_comm] using hx'
  have hq : q.Nonempty := by
    let z : free → Bool := fun k ↦ y k
    refine ⟨z, ?_⟩
    simp only [q, Finset.mem_filter, Finset.mem_univ, true_and]
    have hy' : f (embed (y j) (fun k ↦ y k)) l ≠
        f (embed (!(y j)) (fun k ↦ y k)) l := by
      simpa only [hembed y, hembed_toggle y] using hy
    cases hyj : y j
    · simpa [layer, z, hyj] using hy'
    · simpa [layer, z, hyj, ne_comm] using hy'
  obtain ⟨ab, hab, hminimal⟩ := Finset.exists_min_image (p ×ˢ q)
    (fun ab ↦ (differingCoordinates ab.1 ab.2).card) (hp.product hq)
  let a := ab.1
  let b := ab.2
  have ha : a ∈ p := (Finset.mem_product.mp hab).1
  have hb : b ∈ q := (Finset.mem_product.mp hab).2
  have hab_ne : a ≠ b := by
    intro habEq
    have hb' : a ∈ q := by simpa [habEq] using hb
    have hlocal := pointwiseAtMostOne_of_preservesBooleanBoxes f hf
    have hiMem : i ∈ {o | f (embed false a) o ≠
        f (toggleIndex (embed false a) j) o} := by
      have hjNotMem : j ∉ free := by simp [free]
      have htoggle : toggleIndex (embed false a) j = embed true a := by
        funext k
        by_cases hkj : k = j
        · subst k
          simp [embed, extendOn, free, toggleIndex]
        · simp [embed, extendOn, free, toggleIndex, hkj]
      simpa [p, layer, htoggle] using ha
    have hlMem : l ∈ {o | f (embed false a) o ≠
        f (toggleIndex (embed false a) j) o} := by
      have htoggle : toggleIndex (embed false a) j = embed true a := by
        funext k
        by_cases hkj : k = j
        · subst k
          simp [embed, extendOn, free, toggleIndex]
        · simp [embed, extendOn, free, toggleIndex, hkj]
      simpa [q, layer, htoggle] using hb'
    exact hil (hlocal (embed false a) j hiMem hlMem)
  let varying := differingCoordinates a b
  let context (z : varying → Bool) : free → Bool := extendOn varying a z
  let cornerA : varying → Bool := fun k ↦ a k
  let cornerB : varying → Bool := fun k ↦ b k
  have hcontextA : context cornerA = a := by
    funext k
    by_cases hk : k ∈ varying
    · simp [context, cornerA, extendOn, hk]
    · simp [context, extendOn, hk]
  have hcontextB : context cornerB = b := by
    funext k
    by_cases hk : k ∈ varying
    · simp [context, cornerB, extendOn, hk]
    · have hakb : a k = b k := by
        simpa [varying] using hk
      simp [context, extendOn, hk, hakb]
  have hiOnly : ∀ z, layer false (context z) i ≠ layer true (context z) i →
      z = cornerA := by
    intro z hz
    have hzP : context z ∈ p := by
      simp [p, layer, hz]
    have hcontext : context z = a := by
      by_contra hne
      have hlt := differingCoordinates_extendOn_lt a b z (by
        simpa [context, varying] using hne)
      have hle := hminimal (context z, b) (by
        exact Finset.mem_product.mpr ⟨hzP, hb⟩)
      exact (Nat.not_le_of_lt hlt) hle
    funext k
    have := congrFun hcontext k
    simpa [context, cornerA] using this
  have hcontext_eq_fromB (z : varying → Bool) :
      context z = extendOn varying b z := by
    funext k
    by_cases hk : k ∈ varying
    · simp [context, extendOn, hk]
    · have hakb : a k = b k := by
        simpa [varying] using hk
      simp [context, extendOn, hk, hakb]
  have hlOnly : ∀ z, layer false (context z) l ≠ layer true (context z) l →
      z = cornerB := by
    intro z hz
    have hzQ : context z ∈ q := by
      simp [q, layer, hz]
    have hcontext : context z = b := by
      by_contra hne
      have hne' : extendOn varying b z ≠ b := by
        simpa [hcontext_eq_fromB z] using hne
      have hlt := differingCoordinates_extendOn_right_lt a b z hne'
      have hle := hminimal (a, context z) (by
        exact Finset.mem_product.mpr ⟨ha, hzQ⟩)
      have hlt' : (differingCoordinates a (context z)).card <
          (differingCoordinates a b).card := by
        simpa [hcontext_eq_fromB z] using hlt
      exact (Nat.not_le_of_lt hlt') hle
    funext k
    have := congrFun hcontext k
    have hk := k.property
    simpa [context, cornerB, extendOn, hk] using this
  let faceLayer (head : Bool) : (varying → Bool) → (Bool → Bool) :=
    fun z ↦ layer head (context z)
  have hLayerPreserves (head : Bool) : PreservesBooleanBoxes (layer head) := by
    change PreservesBooleanBoxes (restrictToFace f free (fun _ ↦ head))
    exact hf.restrictToFace free (fun _ ↦ head)
  have hFaceLayerPreserves (head : Bool) :
      PreservesBooleanBoxes (faceLayer head) := by
    change PreservesBooleanBoxes (restrictToFace (layer head) varying a)
    exact (hLayerPreserves head).restrictToFace varying a
  have hvaryingCard : Fintype.card varying < Fintype.card I := by
    calc
      Fintype.card varying = varying.card := Fintype.card_coe _
      _ ≤ Fintype.card free := Finset.card_le_univ varying
      _ = free.card := Fintype.card_coe _
      _ < Fintype.card I := by
        simpa [free] using
          (Finset.card_erase_lt_of_mem (s := (Finset.univ : Finset I))
            (Finset.mem_univ j))
  have hFaceDisjoint (head : Bool) :
      Disjoint ({k | IsEssentialIndex (faceLayer head) false k} : Set varying)
        {k | IsEssentialIndex (faceLayer head) true k} :=
    disjoint_two_outputs_of_preservesBooleanBoxes
      (faceLayer head) (hFaceLayerPreserves head)
  have hHeadI : faceLayer false cornerA i ≠ faceLayer true cornerA i := by
    have := (Finset.mem_filter.mp ha).2
    simpa [faceLayer, hcontextA, p] using this
  have hHeadL : faceLayer false cornerB l ≠ faceLayer true cornerB l := by
    have := (Finset.mem_filter.mp hb).2
    simpa [faceLayer, hcontextB, q] using this
  have hNeighborI (k : varying) :
      faceLayer false (toggleIndex cornerA k) i =
        faceLayer true (toggleIndex cornerA k) i := by
    by_contra hne
    have heq := hiOnly (toggleIndex cornerA k) (by
      simpa [faceLayer] using hne)
    have := congrArg (fun z ↦ z k) heq
    simp at this
  have hNeighborL (k : varying) :
      faceLayer false (toggleIndex cornerB k) l =
        faceLayer true (toggleIndex cornerB k) l := by
    by_contra hne
    have heq := hlOnly (toggleIndex cornerB k) (by
      simpa [faceLayer] using hne)
    have := congrArg (fun z ↦ z k) heq
    simp at this
  let ownedByFalse : Finset varying := Finset.univ.filter fun k ↦
    faceLayer false cornerA i ≠ faceLayer false (toggleIndex cornerA k) i
  have hownedFalse {k : varying} (hk : k ∈ ownedByFalse) :
      IsEssentialIndex (faceLayer false) i k := by
    refine ⟨cornerA, ?_⟩
    simpa [ownedByFalse] using (Finset.mem_filter.mp hk).2
  have hnotLFalse {k : varying} (hk : k ∈ ownedByFalse) :
      ¬ IsEssentialIndex (faceLayer false) l k := by
    intro hlEss
    have hd := hFaceDisjoint false
    exact Set.disjoint_left.mp hd (hownedFalse hk) hlEss
  have hchangesLTrue {k : varying} (hk : k ∈ ownedByFalse) :
      faceLayer true cornerB l ≠
        faceLayer true (toggleIndex cornerB k) l := by
    have hfalseEq : faceLayer false cornerB l =
        faceLayer false (toggleIndex cornerB k) l := by
      by_contra hne
      exact hnotLFalse hk ⟨cornerB, hne⟩
    have hsquare : ∀ a₀ a₁ b : Bool, a₀ ≠ a₁ →
        a₀ = b → a₁ ≠ b := by decide
    apply hsquare _ _ _ hHeadL
    rw [hfalseEq, hNeighborL k]
  have hnotITrue {k : varying} (hk : k ∈ ownedByFalse) :
      ¬ IsEssentialIndex (faceLayer true) i k := by
    have hlEss : IsEssentialIndex (faceLayer true) l k :=
      ⟨cornerB, hchangesLTrue hk⟩
    intro hiEss
    have hd := hFaceDisjoint true
    exact Set.disjoint_left.mp hd hiEss hlEss
  have hnotOwnedChangesITrue {k : varying} (hk : k ∉ ownedByFalse) :
      faceLayer true cornerA i ≠
        faceLayer true (toggleIndex cornerA k) i := by
    have hfalseEq : faceLayer false cornerA i =
        faceLayer false (toggleIndex cornerA k) i := by
      have := Finset.mem_filter.not.mp hk
      simpa [ownedByFalse] using this
    have hsquare : ∀ a₀ a₁ b : Bool, a₀ ≠ a₁ →
        a₀ = b → a₁ ≠ b := by decide
    apply hsquare _ _ _ hHeadI
    rw [hfalseEq, hNeighborI k]
  have hnotLTrue {k : varying} (hk : k ∉ ownedByFalse) :
      ¬ IsEssentialIndex (faceLayer true) l k := by
    have hiEss : IsEssentialIndex (faceLayer true) i k :=
      ⟨cornerA, hnotOwnedChangesITrue hk⟩
    intro hlEss
    have hd := hFaceDisjoint true
    exact Set.disjoint_left.mp hd hiEss hlEss
  have hchangesLFalse {k : varying} (hk : k ∉ ownedByFalse) :
      faceLayer false cornerB l ≠
        faceLayer false (toggleIndex cornerB k) l := by
    have htrueEq : faceLayer true cornerB l =
        faceLayer true (toggleIndex cornerB k) l := by
      by_contra hne
      exact hnotLTrue hk ⟨cornerB, hne⟩
    have hsquare : ∀ a₀ a₁ b : Bool, a₀ ≠ a₁ →
        a₁ = b → a₀ ≠ b := by decide
    apply hsquare _ _ _ hHeadL
    rw [htrueEq, ← hNeighborL k]
  have hnotIFalse {k : varying} (hk : k ∉ ownedByFalse) :
      ¬ IsEssentialIndex (faceLayer false) i k := by
    have hlEss : IsEssentialIndex (faceLayer false) l k :=
      ⟨cornerB, hchangesLFalse hk⟩
    intro hiEss
    have hd := hFaceDisjoint false
    exact Set.disjoint_left.mp hd hiEss hlEss
  let inputFace : Set (I → Bool) :=
    {w | ∃ head z, w = embed head (context z)}
  have hInputFace : IsBooleanBox inputFace := by
    constructor
    · exact ⟨embed false (context cornerA), false, cornerA, rfl⟩
    · intro w hw
      let z : varying → Bool := fun k ↦ w k
      refine ⟨w j, z, ?_⟩
      funext k
      by_cases hkj : k = j
      · subst k
        simp [embed, extendOn, free]
      · let kFree : free := ⟨k, by simp [free, hkj]⟩
        by_cases hkVarying : kFree ∈ varying
        · simp [embed, context, extendOn, free, hkj, kFree, hkVarying, z]
        · obtain ⟨witness, ⟨head, witnessContext, hwitness⟩, hbit⟩ := hw k
          subst witness
          have hfixed : w k = a kFree := by
            simpa [embed, context, extendOn, free, hkj, kFree, hkVarying] using hbit.symm
          simp [embed, context, extendOn, free, hkj, kFree, hkVarying, hfixed]
  have hOutputFace : IsBooleanBox (f '' inputFace) := hf inputFace hInputFace
  by_cases hAll : ownedByFalse = Finset.univ
  · have hITrueConstant : ∀ u v,
        faceLayer true u i = faceLayer true v i := by
      apply constant_of_no_essentialIndex (faceLayer true) i
      intro k
      apply hnotITrue
      rw [hAll]
      simp
    have hLFalseConstant : ∀ u v,
        faceLayer false u l = faceLayer false v l := by
      apply constant_of_no_essentialIndex (faceLayer false) l
      intro k
      apply hnotLFalse
      rw [hAll]
      simp
    let outputA := faceLayer false cornerA
    let outputB := faceLayer true cornerB
    let mixed : Bool → Bool := Function.update outputA l (outputB l)
    have hOutputA : outputA ∈ f '' inputFace := by
      refine ⟨embed false (context cornerA), ⟨false, cornerA, rfl⟩, ?_⟩
      rfl
    have hOutputB : outputB ∈ f '' inputFace := by
      refine ⟨embed true (context cornerB), ⟨true, cornerB, rfl⟩, ?_⟩
      rfl
    have hMixed : mixed ∈ f '' inputFace := by
      apply hOutputFace.2 mixed
      intro o
      by_cases hol : o = l
      · subst o
        exact ⟨outputB, hOutputB, by simp [mixed]⟩
      · exact ⟨outputA, hOutputA, by simp [mixed, hol]⟩
    obtain ⟨w, ⟨head, z, rfl⟩, hresult⟩ := hMixed
    cases head
    · have heq : faceLayer false z l = outputB l := by
        simpa [faceLayer, layer, mixed] using congrArg (fun out ↦ out l) hresult
      apply hHeadL
      calc
        faceLayer false cornerB l = faceLayer false z l :=
          hLFalseConstant cornerB z
        _ = outputB l := heq
        _ = faceLayer true cornerB l := rfl
    · have heq : faceLayer true z i = outputA i := by
        simpa [faceLayer, layer, mixed, outputA, hil] using
          congrArg (fun out ↦ out i) hresult
      apply hHeadI
      calc
        faceLayer false cornerA i = outputA i := rfl
        _ = faceLayer true z i := heq.symm
        _ = faceLayer true cornerA i := hITrueConstant z cornerA
  · by_cases hEmpty : ownedByFalse = ∅
    · have hIFalseConstant : ∀ u v,
          faceLayer false u i = faceLayer false v i := by
        apply constant_of_no_essentialIndex (faceLayer false) i
        intro k
        apply hnotIFalse
        rw [hEmpty]
        simp
      have hLTrueConstant : ∀ u v,
          faceLayer true u l = faceLayer true v l := by
        apply constant_of_no_essentialIndex (faceLayer true) l
        intro k
        apply hnotLTrue
        rw [hEmpty]
        simp
      let outputA := faceLayer true cornerA
      let outputB := faceLayer false cornerB
      let mixed : Bool → Bool := Function.update outputA l (outputB l)
      have hOutputA : outputA ∈ f '' inputFace := by
        refine ⟨embed true (context cornerA), ⟨true, cornerA, rfl⟩, ?_⟩
        rfl
      have hOutputB : outputB ∈ f '' inputFace := by
        refine ⟨embed false (context cornerB), ⟨false, cornerB, rfl⟩, ?_⟩
        rfl
      have hMixed : mixed ∈ f '' inputFace := by
        apply hOutputFace.2 mixed
        intro o
        by_cases hol : o = l
        · subst o
          exact ⟨outputB, hOutputB, by simp [mixed]⟩
        · exact ⟨outputA, hOutputA, by simp [mixed, hol]⟩
      obtain ⟨w, ⟨head, z, rfl⟩, hresult⟩ := hMixed
      cases head
      · have heq : faceLayer false z i = outputA i := by
          simpa [faceLayer, layer, mixed, outputA, hil] using
            congrArg (fun out ↦ out i) hresult
        apply hHeadI
        calc
          faceLayer false cornerA i = faceLayer false z i :=
            hIFalseConstant cornerA z
          _ = outputA i := heq
          _ = faceLayer true cornerA i := rfl
      · have heq : faceLayer true z l = outputB l := by
          simpa [faceLayer, layer, mixed] using
            congrArg (fun out ↦ out l) hresult
        apply hHeadL
        calc
          faceLayer false cornerB l = outputB l := rfl
          _ = faceLayer true z l := heq.symm
          _ = faceLayer true cornerB l := hLTrueConstant z cornerB
    · have hOwnedNonempty : ownedByFalse.Nonempty :=
        Finset.nonempty_iff_ne_empty.mpr hEmpty
      obtain ⟨kFalse, hkFalse⟩ := hOwnedNonempty
      have hNotOwned : ∃ k, k ∉ ownedByFalse := by
        by_contra h
        push Not at h
        apply hAll
        ext k
        simp [h k]
      obtain ⟨kTrue, hkTrue⟩ := hNotOwned
      have hkNe : kFalse ≠ kTrue := by
        intro heq
        subst kTrue
        exact hkTrue hkFalse
      let zFalse := toggleIndex cornerA kFalse
      let zTrue := toggleIndex cornerA kTrue
      let zBoth := toggleIndex zFalse kTrue
      have hzFalse : zFalse ≠ cornerA := by
        intro heq
        have := congrArg (fun z ↦ z kFalse) heq
        simp [zFalse] at this
      have hzTrue : zTrue ≠ cornerA := by
        intro heq
        have := congrArg (fun z ↦ z kTrue) heq
        simp [zTrue] at this
      have hzBoth : zBoth ≠ cornerA := by
        intro heq
        have := congrArg (fun z ↦ z kFalse) heq
        simp [zBoth, zFalse, toggleIndex, hkNe] at this
      have hheadsFalse : faceLayer false zFalse i = faceLayer true zFalse i := by
        by_contra hne
        exact hzFalse (hiOnly zFalse (by simpa [faceLayer] using hne))
      have hheadsTrue : faceLayer false zTrue i = faceLayer true zTrue i := by
        by_contra hne
        exact hzTrue (hiOnly zTrue (by simpa [faceLayer] using hne))
      have hheadsBoth : faceLayer false zBoth i = faceLayer true zBoth i := by
        by_contra hne
        exact hzBoth (hiOnly zBoth (by simpa [faceLayer] using hne))
      have htrueFalse : faceLayer true cornerA i = faceLayer true zFalse i := by
        by_contra hne
        exact hnotITrue hkFalse ⟨cornerA, by simpa [zFalse] using hne⟩
      have htrueBoth : faceLayer true zTrue i = faceLayer true zBoth i := by
        by_contra hne
        exact hnotITrue hkFalse ⟨zTrue, by
          have hcomm : toggleIndex zTrue kFalse = zBoth := by
            simpa [zTrue, zBoth, zFalse] using
              (toggleIndex_comm cornerA (Ne.symm hkNe))
          simpa [hcomm] using hne⟩
      have hfalseTrue : faceLayer false cornerA i = faceLayer false zTrue i := by
        by_contra hne
        exact hnotIFalse hkTrue ⟨cornerA, by simpa [zTrue] using hne⟩
      have hfalseBoth : faceLayer false zFalse i = faceLayer false zBoth i := by
        by_contra hne
        exact hnotIFalse hkTrue ⟨zFalse, by simpa [zBoth] using hne⟩
      apply hHeadI
      calc
        faceLayer false cornerA i = faceLayer false zTrue i := hfalseTrue
        _ = faceLayer true zTrue i := hheadsTrue
        _ = faceLayer true zBoth i := htrueBoth
        _ = faceLayer false zBoth i := hheadsBoth.symm
        _ = faceLayer false zFalse i := hfalseBoth.symm
        _ = faceLayer true zFalse i := hheadsFalse
        _ = faceLayer true cornerA i := htrueFalse.symm
termination_by @Fintype.card I (Fintype.ofFinite I)

/-- Exact finite-cube characterization: a map sends every Boolean box to a
Boolean box only if no input coordinate influences two output coordinates. -/
theorem pairwiseDisjointDependenciesIndex_of_preservesBooleanBoxes
    {I O : Type*} [Finite I] [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) (hf : PreservesBooleanBoxes f) :
    PairwiseDisjointDependenciesIndex f := by
  classical
  intro i l hil
  have hproject := disjoint_two_outputs_of_preservesBooleanBoxes
    (projectTwo f i l) (hf.projectTwo i l hil)
  rw [Set.disjoint_left] at hproject ⊢
  intro j hji hjl
  apply hproject
  · rcases hji with ⟨x, hx⟩
    exact ⟨x, by simpa using hx⟩
  · rcases hjl with ⟨x, hx⟩
    exact ⟨x, by simpa using hx⟩

/-- Exact finite-cube characterization of Boolean-box preservation. -/
theorem preservesBooleanBoxes_iff_pairwiseDisjointDependenciesIndex
    {I O : Type*} [Finite I] [DecidableEq I]
    (f : (I → Bool) → (O → Bool)) :
    PreservesBooleanBoxes f ↔ PairwiseDisjointDependenciesIndex f := by
  constructor
  · exact pairwiseDisjointDependenciesIndex_of_preservesBooleanBoxes f
  · exact preservesBooleanBoxes_of_pairwiseDisjointDependenciesIndex f

/-- Fix all operands except `k`, obtaining a unary slice of an n-ary
operation. The value of `context k` is ignored. -/
def sliceAt {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (k : ι) (context : (l : ι) → BoolVector (width l)) :
    BoolVector (width k) → BoolVector m :=
  fun operand ↦ f (Function.update context k operand)

/-- Relational slice obtained by fixing every operand except `k`. -/
def relationalSliceAt {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m))
    (k : ι) (context : (l : ι) → BoolVector (width l)) :
    ConcreteOp (BoolVector (width k)) (BoolVector m) :=
  fun operand ↦ f (Function.update context k operand)

/-- The exact per-operand backward-completeness condition: in every concrete
context, each output bit depends on at most one bit of operand `k`. The chosen
bit may vary with the context. -/
def BoolContextwiseAtMostOneDependencyAt {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι) : Prop :=
  ∀ context i, (dependencies (sliceAt f k context) i).Subsingleton

/-- Every operand satisfies the contextwise condition for KnownBits backward
completeness. -/
def BoolContextwiseAtMostOneDependency {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) : Prop :=
  ∀ k, BoolContextwiseAtMostOneDependencyAt f k

/-- Every output bit of a unary operation has at most one essential input
dependency. -/
def BoolAtMostOneDependencyUnary {n m : Nat} (f : BoolVector n → BoolVector m) : Prop :=
  ∀ i, (dependencies f i).Subsingleton

/-- Public n-ary forward-completeness condition for a BitVec operation. -/
def PairwiseDisjointDependenciesNary
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) : Prop :=
  BoolPairwiseDisjointDependencies (BoolVector.ofBitVecNaryOp f)

/-- Public unary forward-completeness condition for a BitVec operation. -/
def PairwiseDisjointDependencies {n m : Nat}
    (f : BitVec n → BitVec m) : Prop :=
  BoolPairwiseDisjointDependenciesUnary (BoolVector.ofBitVecUnaryOp f)

/-- Public n-ary backward-completeness condition for a BitVec operation. -/
def ContextwiseAtMostOneDependencyNary
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) : Prop :=
  BoolContextwiseAtMostOneDependency (BoolVector.ofBitVecNaryOp f)

/-- Public unary backward-completeness condition for a BitVec operation. -/
def AtMostOneDependency {n m : Nat} (f : BitVec n → BitVec m) : Prop :=
  BoolAtMostOneDependencyUnary (BoolVector.ofBitVecUnaryOp f)

theorem not_isEssential_iff {n m : Nat} (f : BoolVector n → BoolVector m)
    (i : Fin m) (j : Fin n) :
    ¬ IsEssential f i j ↔ ∀ x, f x i = f (toggle x j) i := by
  simp only [IsEssentialIndex, not_exists, not_ne_iff]

theorem mem_dependencies_iff {n m : Nat} {f : BoolVector n → BoolVector m}
    {i : Fin m} {j : Fin n} :
    j ∈ dependencies f i ↔ ∃ x, f x i ≠ f (toggle x j) i :=
  Iff.rfl

theorem mem_dependenciesAt_iff {ι : Type*} [DecidableEq ι] {width : ι → Nat}
    {m : Nat}
    {f : ((k : ι) → BoolVector (width k)) → BoolVector m}
    {k : ι} {i : Fin m} {j : Fin (width k)} :
    j ∈ dependenciesAt f k i ↔ ∃ x, f x i ≠ f (toggleOperand x k j) i :=
  Iff.rfl

/-- An output coordinate depends only on its essential input coordinates. -/
theorem dependsOn_dependencies {n m : Nat} (f : BoolVector n → BoolVector m)
    (i : Fin m) : DependsOn (fun x ↦ f x i) (dependencies f i) := by
  intro x y hxy
  exact output_eq_of_agree_on_essentialIndices f i x y hxy

/-- A KnownBits closure contains every vector obtained by choosing each
coordinate from one of two members of the original set. -/
theorem update_mem_closure {n : Nat} {s : Set (BoolVector n)}
    {x y : BoolVector n} (hx : x ∈ s) (hy : y ∈ s) (j : Fin n) :
    Function.update x j (y j) ∈ (KnownBits.boolDomain n).closure s := by
  classical
  have hs : s.Nonempty := ⟨x, hx⟩
  change Function.update x j (y j) ∈
    KnownBits.concretize (KnownBits.abstract s)
  rw [KnownBits.abstract, dif_pos hs]
  intro q
  by_cases hqj : q = j
  · subst q
    exact ⟨y, hy, by simp⟩
  · exact ⟨x, hx, by simp [hqj]⟩


/-- For nonempty Boolean-vector sets, being a Cartesian box is exactly being
closed under the KnownBits closure operation. -/
theorem isBooleanBox_iff_closure_eq {n : Nat} {s : Set (BoolVector n)} :
    IsBooleanBox s ↔
      s.Nonempty ∧ (KnownBits.boolDomain n).closure s = s := by
  classical
  constructor
  · rintro ⟨hs, hbox⟩
    refine ⟨hs, Set.Subset.antisymm ?_ ((KnownBits.boolDomain n).subset_closure s)⟩
    intro z hz
    apply hbox z
    change z ∈ KnownBits.concretize (KnownBits.abstract s) at hz
    rw [KnownBits.abstract, dif_pos hs] at hz
    exact hz
  · rintro ⟨hs, hclosed⟩
    refine ⟨hs, ?_⟩
    intro z hz
    have hzClosure : z ∈ (KnownBits.boolDomain n).closure s := by
      change z ∈ KnownBits.concretize (KnownBits.abstract s)
      rw [KnownBits.abstract, dif_pos hs]
      exact hz
    rwa [hclosed] at hzClosure

/-- Empty sets and Boolean boxes are precisely the fixed points of KnownBits
closure. -/
theorem isKnownBitsSet_iff_closure_eq {n : Nat} {s : Set (BoolVector n)} :
    IsKnownBitsSet s ↔ (KnownBits.boolDomain n).closure s = s := by
  constructor
  · rintro (rfl | hs)
    · simp [AbstractDomain.closure, KnownBits.boolDomain]
    · exact (isBooleanBox_iff_closure_eq.mp hs).2
  · intro hclosed
    by_cases hs : s.Nonempty
    · exact Or.inr (isBooleanBox_iff_closure_eq.mpr ⟨hs, hclosed⟩)
    · exact Or.inl (Set.not_nonempty_iff_eq_empty.mp hs)

/-- Observable facts recorded by KnownBits: whether any result exists, and
whether a particular result bit can have a particular value. -/
abbrev OutputObservation (m : Nat) := Option (Fin m × Bool)

def SatisfiesObservation {m : Nat} (y : BoolVector m) :
    OutputObservation m → Prop
  | none => True
  | some (i, b) => y i = b

def HasObservation {m : Nat} (s : Set (BoolVector m))
    (observation : OutputObservation m) : Prop :=
  ∃ y ∈ s, SatisfiesObservation y observation

def CanProduceObservation {n m : Nat}
    (f : ConcreteOp (BoolVector n) (BoolVector m))
    (observation : OutputObservation m) (x : BoolVector n) : Prop :=
  HasObservation (f x) observation

private theorem hasObservation_of_mem_closure {m : Nat}
    {s : Set (BoolVector m)} {y : BoolVector m}
    (hy : y ∈ (KnownBits.boolDomain m).closure s)
    {observation : OutputObservation m}
    (hobs : SatisfiesObservation y observation) :
    HasObservation s observation := by
  have hs : s.Nonempty := by
    by_contra hs
    have : s = ∅ := Set.not_nonempty_iff_eq_empty.mp hs
    subst s
    simp [AbstractDomain.closure, KnownBits.boolDomain] at hy
  cases observation with
  | none =>
      obtain ⟨x, hx⟩ := hs
      exact ⟨x, hx, trivial⟩
  | some coordinate =>
      rcases coordinate with ⟨i, b⟩
      change y ∈ KnownBits.concretize (KnownBits.abstract s) at hy
      rw [KnownBits.abstract, dif_pos hs] at hy
      obtain ⟨x, hx, hxi⟩ := hy i
      exact ⟨x, hx, hxi.trans hobs⟩

/-- Two concrete result sets have the same KnownBits abstraction exactly when
they exhibit the same definedness and per-bit observations. -/
theorem abstract_eq_iff_hasObservation {m : Nat}
    (s t : Set (BoolVector m)) :
    KnownBits.abstract s = KnownBits.abstract t ↔
      ∀ observation, HasObservation s observation ↔
        HasObservation t observation := by
  constructor
  · intro habstract observation
    have hclosure : (KnownBits.boolDomain m).closure s =
        (KnownBits.boolDomain m).closure t :=
      congrArg KnownBits.concretize habstract
    constructor
    · rintro ⟨y, hy, hobs⟩
      apply hasObservation_of_mem_closure
        (s := t) (y := y) (observation := observation) _ hobs
      rw [← hclosure]
      exact (KnownBits.boolDomain m).subset_closure s hy
    · rintro ⟨y, hy, hobs⟩
      apply hasObservation_of_mem_closure
        (s := s) (y := y) (observation := observation) _ hobs
      rw [hclosure]
      exact (KnownBits.boolDomain m).subset_closure t hy
  · intro hobservations
    apply (KnownBits.boolDomain m).insertion.injective
    ext y
    constructor
    · intro hy
      have hsobs : HasObservation s none :=
        hasObservation_of_mem_closure hy trivial
      have htobs := (hobservations none).mp hsobs
      obtain ⟨default, ht, _⟩ := htobs
      change y ∈ KnownBits.concretize (KnownBits.abstract t)
      rw [KnownBits.abstract, dif_pos ⟨default, ht⟩]
      intro i
      have hsbit := hasObservation_of_mem_closure hy (observation := some (i, y i)) rfl
      exact (hobservations (some (i, y i))).mp hsbit
    · intro hy
      have htobs : HasObservation t none :=
        hasObservation_of_mem_closure hy trivial
      have hsobs := (hobservations none).mpr htobs
      obtain ⟨default, hs, _⟩ := hsobs
      change y ∈ KnownBits.concretize (KnownBits.abstract s)
      rw [KnownBits.abstract, dif_pos ⟨default, hs⟩]
      intro i
      have htbit := hasObservation_of_mem_closure hy (observation := some (i, y i)) rfl
      exact (hobservations (some (i, y i))).mpr htbit

/-- Exact relational replacement for the total-function at-most-one
dependency condition. For every observable result fact, the inputs unable to
produce that fact must form a KnownBits-representable set. -/
def ObservationFibersRepresentable {n m : Nat}
    (f : ConcreteOp (BoolVector n) (BoolVector m)) : Prop :=
  ∀ observation, IsKnownBitsSet
    {x | ¬ CanProduceObservation f observation x}

theorem boolBackwardComplete_iff_observationFibersRepresentable {n m : Nat}
    (f : ConcreteOp (BoolVector n) (BoolVector m)) :
    BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m) f ↔
      ObservationFibersRepresentable f := by
  constructor
  · intro hcomplete observation
    let unable : Set (BoolVector n) :=
      {x | ¬ CanProduceObservation f observation x}
    apply isKnownBitsSet_iff_closure_eq.mpr
    apply Set.Subset.antisymm
    · intro x hx
      change ¬ CanProduceObservation f observation x
      intro hcan
      obtain ⟨y, hyfx, hyobs⟩ := hcan
      have hEq := hcomplete unable
      have hobsEq := (abstract_eq_iff_hasObservation _ _).mp hEq observation
      have hclosedObs : HasObservation
          (ConcreteOp.lift f ((KnownBits.boolDomain n).closure unable))
          observation := ⟨y, ⟨x, hx, hyfx⟩, hyobs⟩
      obtain ⟨z, ⟨input, hinput, hz⟩, hzobs⟩ :=
        hobsEq.mp hclosedObs
      exact hinput ⟨z, hz, hzobs⟩
    · exact (KnownBits.boolDomain n).subset_closure unable
  · intro hcondition s
    apply (abstract_eq_iff_hasObservation _ _).mpr
    intro observation
    constructor
    · rintro ⟨y, ⟨x, hx, hyfx⟩, hyobs⟩
      by_contra horiginal
      have hsUnable : s ⊆
          {z | ¬ CanProduceObservation f observation z} := by
        intro z hzs hzcan
        obtain ⟨out, hzout, houtobs⟩ := hzcan
        exact horiginal ⟨out, ⟨z, hzs, hzout⟩, houtobs⟩
      have hunableClosed := isKnownBitsSet_iff_closure_eq.mp
        (hcondition observation)
      have hxUnable : x ∈
          {z | ¬ CanProduceObservation f observation z} := by
        rw [← hunableClosed]
        exact (KnownBits.boolDomain n).closure_mono hsUnable hx
      exact hxUnable ⟨y, hyfx, hyobs⟩
    · rintro ⟨y, ⟨x, hx, hyfx⟩, hyobs⟩
      exact ⟨y, ⟨x, (KnownBits.boolDomain n).subset_closure s hx, hyfx⟩,
        hyobs⟩

/-- Exact per-operand relational KnownBits backward condition. Definedness and
every possible output-bit value are checked in every concrete context. -/
def ObservationFibersRepresentableAt {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m))
    (k : ι) : Prop :=
  ∀ context, ObservationFibersRepresentable (relationalSliceAt f k context)

def ObservationFibersRepresentableNary {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m)) :
    Prop :=
  ∀ k, ObservationFibersRepresentableAt f k

/-- A relational n-ary operation preserves KnownBits-representable sets over
independent operands. This is the exact forward condition for partial and
nondeterministic operations; unlike the total-function dependency criterion,
it also accounts for empty and multi-result executions. -/
def PreservesKnownBitsSetsNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m)) :
    Prop :=
  ∀ xs, (∀ k, IsKnownBitsSet (xs k)) →
    IsKnownBitsSet (NaryConcreteOp.lift f xs)

def PreservesKnownBitsSets {n m : Nat}
    (f : ConcreteOp (BoolVector n) (BoolVector m)) : Prop :=
  ∀ s, IsKnownBitsSet s → IsKnownBitsSet (ConcreteOp.lift f s)

theorem boolForwardComplete_iff_preservesKnownBitsSets
    {n m : Nat} (f : ConcreteOp (BoolVector n) (BoolVector m)) :
    ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m) f ↔
      PreservesKnownBitsSets f := by
  rw [forwardComplete_iff_closure]
  constructor
  · intro hcomplete s hs
    apply isKnownBitsSet_iff_closure_eq.mpr
    simpa [isKnownBitsSet_iff_closure_eq.mp hs] using hcomplete s
  · intro hpreserves s
    apply isKnownBitsSet_iff_closure_eq.mp
    apply hpreserves
    apply isKnownBitsSet_iff_closure_eq.mpr
    exact (KnownBits.boolDomain n).closure_idempotent s

/-- Exact forward-completeness characterization for relational KnownBits
operations in the internal Boolean-coordinate model. -/
theorem boolForwardCompleteNary_iff_preservesKnownBitsSets
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m)) :
    NaryForwardComplete (fun k ↦ KnownBits.boolDomain (width k))
        (KnownBits.boolDomain m) f ↔
      PreservesKnownBitsSetsNary f := by
  rw [naryForwardComplete_iff_closure]
  constructor
  · intro hcomplete xs hxs
    apply isKnownBitsSet_iff_closure_eq.mpr
    have hclosed : ∀ k, (KnownBits.boolDomain (width k)).closure (xs k) =
        xs k := fun k ↦ isKnownBitsSet_iff_closure_eq.mp (hxs k)
    simpa [hclosed] using hcomplete xs
  · intro hpreserves xs
    apply isKnownBitsSet_iff_closure_eq.mp
    apply hpreserves
    intro k
    apply isKnownBitsSet_iff_closure_eq.mpr
    exact (KnownBits.boolDomain (width k)).closure_idempotent (xs k)

/-- Forward completeness is the concrete statement that every KnownBits box
has a box-shaped image. -/
theorem preservesBooleanBoxes_of_boolForwardComplete {n m : Nat}
    (f : BoolVector n → BoolVector m)
    (hcomplete : ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f)) :
    PreservesBooleanBoxes f := by
  intro s hs
  have hsClosed := (isBooleanBox_iff_closure_eq.mp hs).2
  have himageClosed :=
    (forwardComplete_iff_closure (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f)).mp hcomplete s
  simp only [ConcreteOp.lift_ofTotal, hsClosed] at himageClosed
  apply isBooleanBox_iff_closure_eq.mpr
  exact ⟨hs.1.image f, himageClosed⟩

/-- Forward completeness forces globally disjoint essential dependencies:
an input bit cannot be routed to different output bits in different contexts. -/
theorem pairwiseDisjointDependenciesUnary_of_boolForwardComplete {n m : Nat}
    (f : BoolVector n → BoolVector m)
    (hcomplete : ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f)) :
    BoolPairwiseDisjointDependenciesUnary f := by
  have hgeneric := pairwiseDisjointDependenciesIndex_of_preservesBooleanBoxes f
    (preservesBooleanBoxes_of_boolForwardComplete f hcomplete)
  intro i l hil
  exact hgeneric i l hil


/-- Under unary backward completeness, closing a nonempty fiber of one output
bit cannot introduce an input on which that output bit has another value. -/
theorem fiber_closed_of_boolBackwardComplete {n m : Nat}
    (f : BoolVector n → BoolVector m)
    (hcomplete : BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f))
    (i : Fin m) (b : Bool)
    (hs : ({x | f x i = b} : Set (BoolVector n)).Nonempty) :
    ∀ x ∈ (KnownBits.boolDomain n).closure {y | f y i = b}, f x i = b := by
  intro x hx
  let s : Set (BoolVector n) := {y | f y i = b}
  have hEq := hcomplete s
  simp only [bestTransformer, ConcreteOp.lift_ofTotal] at hEq
  change KnownBits.abstract (f '' (KnownBits.boolDomain n).closure s) =
    KnownBits.abstract (f '' s) at hEq
  have hmem : f x ∈ KnownBits.concretize
      (KnownBits.abstract (f '' (KnownBits.boolDomain n).closure s)) :=
    (KnownBits.boolDomain m).subset_concretize_abstract _ ⟨x, hx, rfl⟩
  rw [hEq] at hmem
  have hImage : (f '' s).Nonempty := hs.image f
  rw [KnownBits.abstract, dif_pos hImage] at hmem
  obtain ⟨out, ⟨y, hy, rfl⟩, hout⟩ := hmem i
  calc
    f x i = f y i := hout.symm
    _ = b := hy

private theorem exists_oriented_edge {n : Nat} (g : BoolVector n → Bool)
    (j : Fin n) (hessential : ∃ x, g x ≠ g (toggle x j)) (b : Bool) :
    ∃ x, g x = b ∧ g (toggle x j) ≠ b := by
  obtain ⟨x, hx⟩ := hessential
  by_cases hb : g x = b
  · exact ⟨x, hb, by simpa [hb] using hx.symm⟩
  · refine ⟨toggle x j, ?_, ?_⟩
    · cases h1 : g x <;> cases h2 : g (toggle x j) <;>
        cases b <;> simp_all
    · simpa using hb

/-- Unary KnownBits backward completeness forces every output bit to have at
most one essential input dependency. -/
theorem atMostOneDependencyUnary_of_boolBackwardComplete {n m : Nat}
    (f : BoolVector n → BoolVector m)
    (hcomplete : BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f)) :
    BoolAtMostOneDependencyUnary f := by
  intro i j hj q hq
  by_contra hjq
  obtain ⟨x, hxi, hxtoggle⟩ :=
    exists_oriented_edge (fun operand ↦ f operand i) j hj false
  obtain ⟨y, hyi, hytoggle⟩ :=
    exists_oriented_edge (fun operand ↦ f operand i) q hq false
  let other := f (toggle x j) i
  have hyOther : f (toggle y q) i = other := by
    dsimp only [other]
    cases hx : f (toggle x j) i <;> cases hy : f (toggle y q) i <;>
      simp_all
  let z : BoolVector n := Function.update x j (y j)
  have hzFalse : z ∈ (KnownBits.boolDomain n).closure
      {operand | f operand i = false} := by
    exact update_mem_closure hxi hyi j
  have htoggleEq :
      Function.update (toggle x j) j ((toggle y q) j) = z := by
    funext r
    by_cases hrj : r = j
    · subst r
      simp [z, toggle, hjq]
    · simp [z, toggle, hrj]
  have hzOther : z ∈ (KnownBits.boolDomain n).closure
      {operand | f operand i = other} := by
    have hmix := update_mem_closure
      (s := {operand | f operand i = other})
      (x := toggle x j) (y := toggle y q)
      (show f (toggle x j) i = other by rfl) hyOther j
    rwa [htoggleEq] at hmix
  have hfzFalse := fiber_closed_of_boolBackwardComplete f hcomplete i false
    ⟨x, hxi⟩ z hzFalse
  have hfzOther := fiber_closed_of_boolBackwardComplete f hcomplete i other
    ⟨toggle x j, rfl⟩ z hzOther
  have hotherNe : other ≠ false := by
    simpa [other] using hxtoggle
  exact hotherNe (hfzOther.symm.trans hfzFalse)

/-- If two n-ary inputs differ only in operand `k`, output bit `i` depends
only on the bits in its operand-wise dependency dependencies for `k`. -/
theorem dependsOn_dependenciesAt_of_eq_except {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (k : ι) (i : Fin m) (x y : (k : ι) → BoolVector (width k))
    (hExcept : ∀ l, l ≠ k → x l = y l)
    (hBits : ∀ j ∈ dependenciesAt f k i, x k j = y k j) :
    f x i = f y i := by
  let localOp : BoolVector (width k) → BoolVector m :=
    fun operand ↦ f (Function.update x k operand)
  have hlocal : localOp (x k) i = localOp (y k) i := dependsOn_dependencies localOp i (by
    intro j hj
    apply hBits j
    obtain ⟨operand, hoperand⟩ := hj
    refine ⟨Function.update x k operand, ?_⟩
    simpa [localOp, toggleOperand] using hoperand)
  calc
    f x i = localOp (x k) i := by simp [localOp]
    _ = localOp (y k) i := hlocal
    _ = f y i := by
      have hupdate : Function.update x k (y k) = y := by
        funext l
        by_cases hlk : l = k
        · subst l
          simp
        · simp [hlk, hExcept l hlk]
      simp only [localOp]
      rw [hupdate]

private def singletonContextSets {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} (k : ι)
    (context : (l : ι) → BoolVector (width l))
    (s : Set (BoolVector (width k))) :
    (l : ι) → Set (BoolVector (width l)) :=
  Function.update (fun l ↦ {context l}) k s

private theorem lift_singletonContextSets {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (k : ι) (context : (l : ι) → BoolVector (width l))
    (s : Set (BoolVector (width k))) :
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (singletonContextSets k context s) =
      sliceAt f k context '' s := by
  ext z
  constructor
  · rintro ⟨x, hx, hz⟩
    have hxk : x k ∈ s := by
      simpa [singletonContextSets] using hx k
    have hxeq : x = Function.update context k (x k) := by
      funext l
      by_cases hlk : l = k
      · subst l
        simp
      · have hxl : x l = context l := by
          simpa [singletonContextSets, hlk] using hx l
        simp [hlk, hxl]
    have hzEq : z = f x := Set.mem_singleton_iff.mp hz
    refine ⟨x k, hxk, ?_⟩
    simp only [sliceAt]
    rw [← hxeq, ← hzEq]
  · rintro ⟨operand, hoperand, rfl⟩
    let x := Function.update context k operand
    refine ⟨x, ?_, ?_⟩
    · intro l
      by_cases hlk : l = k
      · subst l
        simpa [x, singletonContextSets] using hoperand
      · simp [x, singletonContextSets, hlk]
    · simp [x, sliceAt, NaryConcreteOp.ofTotal]

private theorem lift_singletonContextSets_relational
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m))
    (k : ι) (context : (l : ι) → BoolVector (width l))
    (s : Set (BoolVector (width k))) :
    NaryConcreteOp.lift f (singletonContextSets k context s) =
      ConcreteOp.lift (relationalSliceAt f k context) s := by
  ext z
  constructor
  · rintro ⟨x, hx, hz⟩
    have hxk : x k ∈ s := by
      simpa [singletonContextSets] using hx k
    have hxeq : x = Function.update context k (x k) := by
      funext l
      by_cases hlk : l = k
      · subst l
        simp
      · have hxl : x l = context l := by
          simpa [singletonContextSets, hlk] using hx l
        simp [hlk, hxl]
    exact ⟨x k, hxk, by simpa [relationalSliceAt, ← hxeq] using hz⟩
  · rintro ⟨operand, hoperand, hz⟩
    let x := Function.update context k operand
    refine ⟨x, ?_, ?_⟩
    · intro l
      by_cases hlk : l = k
      · subst l
        simpa [x, singletonContextSets] using hoperand
      · simp [x, singletonContextSets, hlk]
    · simpa [x, relationalSliceAt] using hz

/-- Per-operand relational backward completeness specializes to every unary
concrete-context slice. -/
theorem relationalBackwardComplete_slice_of_at
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m))
    (k : ι)
    (hcomplete : NaryBackwardCompleteAt
      (fun l ↦ KnownBits.boolDomain (width l)) (KnownBits.boolDomain m) f k)
    (context : (l : ι) → BoolVector (width l)) :
    BackwardComplete (KnownBits.boolDomain (width k)) (KnownBits.boolDomain m)
      (relationalSliceAt f k context) := by
  intro s
  let xs := singletonContextSets k context s
  have hEq := hcomplete xs
  have hclose :
      closeOperand (fun l ↦ KnownBits.boolDomain (width l)) k xs =
        singletonContextSets k context
          ((KnownBits.boolDomain (width k)).closure s) := by
    funext l
    by_cases hlk : l = k
    · subst l
      simp [xs, singletonContextSets, closeOperand]
    · simp [xs, singletonContextSets, closeOperand, hlk]
  change KnownBits.abstract (NaryConcreteOp.lift f
      (closeOperand (fun l ↦ KnownBits.boolDomain (width l)) k xs)) =
    KnownBits.abstract (NaryConcreteOp.lift f xs) at hEq
  rw [hclose, lift_singletonContextSets_relational,
    lift_singletonContextSets_relational] at hEq
  exact hEq

/-- Exact per-operand relational KnownBits backward-completeness
characterization. -/
theorem backwardCompleteAt_iff_observationFibersRepresentable
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m))
    (k : ι) :
    NaryBackwardCompleteAt
        (fun l ↦ KnownBits.boolDomain (width l))
        (KnownBits.boolDomain m) f k ↔
      ObservationFibersRepresentableAt f k := by
  constructor
  · intro hcomplete context
    exact (boolBackwardComplete_iff_observationFibersRepresentable _).mp
      (relationalBackwardComplete_slice_of_at f k hcomplete context)
  · intro hcondition xs
    apply (abstract_eq_iff_hasObservation _ _).mpr
    intro observation
    constructor
    · rintro ⟨y, ⟨x, hx, hyfx⟩, hyobs⟩
      have hsliceComplete := (boolBackwardComplete_iff_observationFibersRepresentable
        (relationalSliceAt f k x)).mpr (hcondition x)
      have hsliceEq := hsliceComplete (xs k)
      have hobsEq := (abstract_eq_iff_hasObservation _ _).mp
        hsliceEq observation
      have hxk : x k ∈ (KnownBits.boolDomain (width k)).closure (xs k) := by
        simpa [closeOperand] using hx k
      have hsliceObs : HasObservation
          (ConcreteOp.lift (relationalSliceAt f k x)
            ((KnownBits.boolDomain (width k)).closure (xs k)))
          observation := by
        refine ⟨y, ⟨x k, hxk, ?_⟩, hyobs⟩
        simpa [relationalSliceAt] using hyfx
      obtain ⟨z, ⟨operand, hoperand, hz⟩, hzobs⟩ :=
        hobsEq.mp hsliceObs
      let args := Function.update x k operand
      refine ⟨z, ⟨args, ?_, ?_⟩, hzobs⟩
      · intro l
        by_cases hlk : l = k
        · subst l
          simpa [args] using hoperand
        · have hxl := hx l
          simpa [args, closeOperand, hlk] using hxl
      · simpa [args, relationalSliceAt] using hz
    · rintro ⟨y, ⟨x, hx, hyfx⟩, hyobs⟩
      refine ⟨y, ⟨x, ?_, hyfx⟩, hyobs⟩
      intro l
      by_cases hlk : l = k
      · subst l
        simpa [closeOperand] using
          (KnownBits.boolDomain (width k)).subset_closure (xs k) (hx k)
      · simpa [closeOperand, hlk] using hx l

/-- Exact finite-arity relational KnownBits backward-completeness
characterization. -/
theorem backwardCompleteNary_iff_observationFibersRepresentable
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m)) :
    NaryBackwardComplete
        (fun k ↦ KnownBits.boolDomain (width k))
        (KnownBits.boolDomain m) f ↔
      ObservationFibersRepresentableNary f := by
  constructor
  · intro hcomplete k
    apply (backwardCompleteAt_iff_observationFibersRepresentable f k).mp
    exact naryBackwardCompleteAt_of_complete
      (fun l ↦ KnownBits.boolDomain (width l))
      (KnownBits.boolDomain m) f hcomplete k
  · intro hcondition
    apply naryBackwardComplete_of_at
    intro k
    exact (backwardCompleteAt_iff_observationFibersRepresentable f k).mpr
      (hcondition k)

/-- Per-operand backward completeness specializes to unary backward
completeness in every concrete context. -/
theorem boolBackwardComplete_slice_of_at {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι)
    (hcomplete : KnownBits.BoolBackwardCompleteAt f k)
    (context : (l : ι) → BoolVector (width l)) :
    BackwardComplete (KnownBits.boolDomain (width k)) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal (sliceAt f k context)) := by
  intro s
  let xs := singletonContextSets k context s
  have hEq := hcomplete xs
  change KnownBits.abstract
      (NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (closeOperand (fun l ↦ KnownBits.boolDomain (width l)) k xs)) =
    KnownBits.abstract
      (NaryConcreteOp.lift (NaryConcreteOp.ofTotal f) xs) at hEq
  have hclose :
      closeOperand (fun l ↦ KnownBits.boolDomain (width l)) k xs =
        singletonContextSets k context
          ((KnownBits.boolDomain (width k)).closure s) := by
    funext l
    by_cases hlk : l = k
    · subst l
      simp [xs, singletonContextSets, closeOperand]
    · simp [xs, singletonContextSets, closeOperand, hlk]
  rw [hclose, lift_singletonContextSets, lift_singletonContextSets] at hEq
  simp only [bestTransformer, ConcreteOp.lift_ofTotal]
  change KnownBits.abstract
      (sliceAt f k context '' (KnownBits.boolDomain (width k)).closure s) =
    KnownBits.abstract (sliceAt f k context '' s)
  exact hEq

private def spliceOperands {ι : Type*} [DecidableEq ι]
    {width : ι → Nat}
    (x y : (k : ι) → BoolVector (width k)) (s : Finset ι) :
    (k : ι) → BoolVector (width k) :=
  fun k ↦ if k ∈ s then y k else x k

private theorem spliceOperands_insert {ι : Type*} [DecidableEq ι]
    {width : ι → Nat}
    (x y : (k : ι) → BoolVector (width k)) (s : Finset ι)
    (k : ι) :
    spliceOperands x y (insert k s) =
      Function.update (spliceOperands x y s) k (y k) := by
  funext l
  by_cases hlk : l = k
  · subst l
    simp [spliceOperands]
  · simp [spliceOperands, hlk]

/-- Treat all bits of all operands as one family of Boolean coordinates. -/
abbrev FlattenedIndex {ι : Type*} (width : ι → Nat) :=
  Σ k, Fin (width k)

/-- Flatten a heterogeneous family of Boolean-vector operands. -/
def flattenInput {ι : Type*} {width : ι → Nat}
    (x : (k : ι) → BoolVector (width k)) : FlattenedIndex width → Bool :=
  fun coordinate ↦ x coordinate.1 coordinate.2

/-- View an n-ary Boolean-vector operation as a unary operation on all of its
operand bits. -/
def flattenNaryOp {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) :
    (FlattenedIndex width → Bool) → BoolVector m :=
  fun x ↦ f (fun k j ↦ x ⟨k, j⟩)

@[simp]
theorem flattenNaryOp_flattenInput {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (x : (k : ι) → BoolVector (width k)) :
    flattenNaryOp f (flattenInput x) = f x := by
  rfl

theorem flattenInput_toggleOperand {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} (x : (k : ι) → BoolVector (width k))
    (k : ι) (j : Fin (width k)) :
    flattenInput (toggleOperand x k j) =
      toggleIndex (flattenInput x) ⟨k, j⟩ := by
  funext coordinate
  rcases coordinate with ⟨l, q⟩
  by_cases hlk : l = k
  · subst l
    by_cases hqj : q = j
    · subst q
      simp [flattenInput, toggleOperand, toggle, toggleIndex]
    · simp [flattenInput, toggleOperand, toggle, toggleIndex, hqj]
  · simp [flattenInput, toggleOperand, toggle, toggleIndex, hlk]

/-- An output coordinate of a finite-arity operation depends only on its
operand-wise essential dependency sets. -/
theorem dependsOn_dependenciesAt {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (i : Fin m) (x y : (k : ι) → BoolVector (width k))
    (hBits : ∀ k j, j ∈ dependenciesAt f k i → x k j = y k j) :
    f x i = f y i := by
  letI := Fintype.ofFinite ι
  have hsplice : ∀ s : Finset ι, f (spliceOperands x y s) i = f x i := by
    intro s
    induction s using Finset.induction with
    | empty => rfl
    | @insert k s hks ih =>
        rw [spliceOperands_insert]
        have hstep :
            f (spliceOperands x y s) i =
              f (Function.update (spliceOperands x y s) k (y k)) i := by
          apply dependsOn_dependenciesAt_of_eq_except f k i
          · intro l hlk
            simp [hlk]
          · intro j hj
            have hxj : x k j = y k j := hBits k j hj
            simp [spliceOperands, hks, hxj]
        rw [← hstep, ih]
  have huniv := hsplice Finset.univ
  have hsplice_univ : spliceOperands x y Finset.univ = y := by
    funext k
    simp [spliceOperands]
  rw [hsplice_univ] at huniv
  exact huniv.symm

/-- N-ary forward completeness says that the flattened operation sends every
Boolean box of operand bits to a Boolean box of output bits. -/
theorem preservesBooleanBoxes_of_boolForwardCompleteNary
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (hcomplete : KnownBits.BoolForwardCompleteNary f) :
    PreservesBooleanBoxes (flattenNaryOp f) := by
  classical
  intro s hs
  let xs : (k : ι) → Set (BoolVector (width k)) := fun k ↦
    reindexCoordinates (fun j : Fin (width k) ↦
      (⟨k, j⟩ : FlattenedIndex width)) '' s
  have hxsBox (k : ι) : IsBooleanBox (xs k) := by
    apply hs.image_reindexCoordinates
    intro j l hjl
    cases hjl
    rfl
  let a : (k : ι) → KnownBits (width k) := fun k ↦ KnownBits.abstract (xs k)
  have ha (k : ι) : KnownBits.concretize (a k) = xs k := by
    have hclosed := (isBooleanBox_iff_closure_eq.mp (hxsBox k)).2
    simpa [a, AbstractDomain.closure, KnownBits.boolDomain] using hclosed
  have hLift : NaryConcreteOp.lift (NaryConcreteOp.ofTotal f) xs =
      flattenNaryOp f '' s := by
    ext y
    constructor
    · rintro ⟨x, hx, hy⟩
      have hyEq : y = f x := Set.mem_singleton_iff.mp hy
      have hflat : flattenInput x ∈ s := by
        apply hs.2 (flattenInput x)
        rintro ⟨k, j⟩
        obtain ⟨source, hsource, hsourceEq⟩ := hx k
        refine ⟨source, hsource, ?_⟩
        exact congrFun hsourceEq j
      refine ⟨flattenInput x, hflat, ?_⟩
      simpa using hyEq.symm
    · rintro ⟨flat, hflat, rfl⟩
      let x : (k : ι) → BoolVector (width k) := fun k j ↦ flat ⟨k, j⟩
      refine ⟨x, ?_, ?_⟩
      · intro k
        exact ⟨flat, hflat, rfl⟩
      · simp [x, flattenNaryOp, NaryConcreteOp.ofTotal]
  have hEq := hcomplete a
  change KnownBits.concretize (KnownBits.abstract
      (NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (fun k ↦ KnownBits.concretize (a k)))) =
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
      (fun k ↦ KnownBits.concretize (a k)) at hEq
  have hsets : (fun k ↦ KnownBits.concretize (a k)) = xs := funext ha
  rw [hsets, hLift] at hEq
  apply isBooleanBox_iff_closure_eq.mpr
  exact ⟨hs.1.image (flattenNaryOp f), by
    simpa [AbstractDomain.closure, KnownBits.boolDomain] using hEq⟩

theorem essentialIndex_flattenNaryOp_of_essentialAt
    {ι : Type*} [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    {k : ι} {i : Fin m} {j : Fin (width k)}
    (h : IsEssentialAt f k i j) :
    IsEssentialIndex (flattenNaryOp f) i
      (⟨k, j⟩ : FlattenedIndex width) := by
  rcases h with ⟨x, hx⟩
  refine ⟨flattenInput x, ?_⟩
  rw [← flattenInput_toggleOperand x k j]
  simpa using hx

/-- N-ary KnownBits forward completeness forces distinct output bits to have
disjoint dependencies within every operand. -/
theorem pairwiseDisjointDependencies_of_boolForwardCompleteNary
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (hcomplete : KnownBits.BoolForwardCompleteNary f) : BoolPairwiseDisjointDependencies f := by
  classical
  letI := Fintype.ofFinite ι
  have hflattened := pairwiseDisjointDependenciesIndex_of_preservesBooleanBoxes
    (flattenNaryOp f) (preservesBooleanBoxes_of_boolForwardCompleteNary f hcomplete)
  intro k i l hil
  rw [Set.disjoint_left]
  intro j hji hjl
  have hi := essentialIndex_flattenNaryOp_of_essentialAt f hji
  have hl := essentialIndex_flattenNaryOp_of_essentialAt f hjl
  exact Set.disjoint_left.mp (hflattened i l hil) hi hl

/-- Operand-wise pairwise-disjoint essential dependencies are sufficient for
KnownBits forward completeness of a finite-arity operation. -/
theorem boolForwardCompleteNary_of_pairwiseDisjointDependencies {ι : Type*} [Finite ι]
    [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m)
    (hdisjoint : BoolPairwiseDisjointDependencies f) :
    KnownBits.BoolForwardCompleteNary f := by
  classical
  intro a
  let inputs : (k : ι) → Set (BoolVector (width k)) :=
    fun k ↦ KnownBits.concretize (a k)
  let outputs : Set (BoolVector m) :=
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f) inputs
  change KnownBits.concretize (KnownBits.abstract outputs) = outputs
  by_cases hall : ∀ k, (inputs k).Nonempty
  · let default : (k : ι) → BoolVector (width k) :=
      fun k ↦ Classical.choose (hall k)
    have hdefault : ∀ k, default k ∈ inputs k :=
      fun k ↦ Classical.choose_spec (hall k)
    have houtputs : outputs.Nonempty := by
      refine ⟨f default, default, hdefault, ?_⟩
      exact Set.mem_singleton (f default)
    apply Set.Subset.antisymm
    · intro z hz
      rw [KnownBits.abstract, dif_pos houtputs] at hz
      have hzObserved : ∀ i, ∃ x : (k : ι) → BoolVector (width k),
          (∀ k, x k ∈ inputs k) ∧ f x i = z i := by
        intro i
        obtain ⟨out, hout, houtBit⟩ := hz i
        obtain ⟨x, hx, hfx⟩ := hout
        have houtEq : out = f x := Set.mem_singleton_iff.mp hfx
        subst out
        exact ⟨x, hx, houtBit⟩
      choose witness hwitness_mem hwitness_bit using hzObserved
      let combined : (k : ι) → BoolVector (width k) := fun k j ↦
        if h : ∃ i, IsEssentialAt f k i j then
          witness (Classical.choose h) k j
        else
          default k j
      have hcombined_mem : ∀ k, combined k ∈ inputs k := by
        intro k
        induction hak : a k using WithBot.recBotCoe with
        | bot =>
            have : (inputs k).Nonempty := hall k
            simp [inputs, hak, KnownBits.concretize] at this
        | coe p =>
            have hinputEq : inputs k = KnownBits.concretize
                (p : KnownBits (width k)) := by simp [inputs, hak]
            rw [hinputEq]
            change ∀ j, combined k j ∈ (p j : Set Bool)
            intro j
            by_cases h : ∃ i, IsEssentialAt f k i j
            · change (if h' : ∃ i, IsEssentialAt f k i j then
                  witness (Classical.choose h') k j else default k j) ∈ _
              rw [dif_pos h]
              have hw := hwitness_mem (Classical.choose h) k
              rw [hinputEq] at hw
              exact hw j
            · change (if h' : ∃ i, IsEssentialAt f k i j then
                  witness (Classical.choose h') k j else default k j) ∈ _
              rw [dif_neg h]
              have hd := hdefault k
              rw [hinputEq] at hd
              exact hd j
      have hcombined_bit : ∀ i, f combined i = z i := by
        intro i
        calc
          f combined i = f (witness i) i := dependsOn_dependenciesAt f i combined (witness i) (by
            intro k j hj
            have hExists : ∃ l, IsEssentialAt f k l j := ⟨i, hj⟩
            rw [show combined k j = witness (Classical.choose hExists) k j by
              change (if h : ∃ l, IsEssentialAt f k l j then
                witness (Classical.choose h) k j else default k j) = _
              rw [dif_pos hExists]]
            have hchosen : IsEssentialAt f k (Classical.choose hExists) j :=
              Classical.choose_spec hExists
            have heq : Classical.choose hExists = i := by
              by_contra hne
              have hd := hdisjoint k (Classical.choose hExists) i hne
              exact Set.disjoint_left.mp hd hchosen hj
            rw [heq])
          _ = z i := hwitness_bit i
      refine ⟨combined, hcombined_mem, ?_⟩
      apply Set.mem_singleton_iff.mpr
      funext i
      exact (hcombined_bit i).symm
    · exact (KnownBits.boolDomain m).subset_concretize_abstract outputs
  · simp only [not_forall] at hall
    obtain ⟨k, hk⟩ := hall
    have hkempty : inputs k = ∅ := Set.not_nonempty_iff_eq_empty.mp hk
    have houtputsEmpty : outputs = ∅ := by
      ext z
      constructor
      · rintro ⟨x, hx, _⟩
        have : x k ∈ (∅ : Set (BoolVector (width k))) := by
          rw [← hkempty]
          exact hx k
        exact this.elim
      · simp
    rw [houtputsEmpty]
    simp [KnownBits.abstract, KnownBits.concretize]

/-- Exact finite-arity KnownBits forward-completeness characterization. -/
theorem boolForwardCompleteNary_iff_pairwiseDisjointDependencies
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) :
    KnownBits.BoolForwardCompleteNary f ↔ BoolPairwiseDisjointDependencies f := by
  constructor
  · exact pairwiseDisjointDependencies_of_boolForwardCompleteNary f
  · exact boolForwardCompleteNary_of_pairwiseDisjointDependencies f

/-- Pairwise-disjoint essential dependencies are sufficient for unary
KnownBits forward completeness. -/
theorem boolForwardComplete_of_pairwiseDisjointDependenciesUnary {n m : Nat}
    (f : BoolVector n → BoolVector m) (hdisjoint : BoolPairwiseDisjointDependenciesUnary f) :
    ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f) := by
  classical
  intro a
  induction a using WithBot.recBotCoe with
  | bot => simp [bestTransformer, KnownBits.boolDomain, KnownBits.concretize]
  | coe p =>
      let default : BoolVector n := fun j ↦ Classical.choose (p j).property
      have hdefault : default ∈ KnownBits.concretize (p : KnownBits n) :=
        fun j ↦ Classical.choose_spec (p j).property
      have hinputs : IsBooleanBox
          (KnownBits.concretize (p : KnownBits n)) :=
        isBooleanBox_iff_closure_eq.mpr ⟨⟨default, hdefault⟩, by
          change KnownBits.concretize (KnownBits.abstract
            (KnownBits.concretize (p : KnownBits n))) = _
          exact congrArg KnownBits.concretize
            ((KnownBits.boolDomain n).insertion (p : KnownBits n))⟩
      have houtputs :=
        preservesBooleanBoxes_of_pairwiseDisjointDependenciesIndex f hdisjoint
          _ hinputs
      simp only [bestTransformer, ConcreteOp.lift_ofTotal]
      exact (isBooleanBox_iff_closure_eq.mp houtputs).2

/-- Exact unary KnownBits forward-completeness characterization. -/
theorem boolForwardComplete_iff_pairwiseDisjointDependenciesUnary {n m : Nat}
    (f : BoolVector n → BoolVector m) :
    ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (ConcreteOp.ofTotal f) ↔
      BoolPairwiseDisjointDependenciesUnary f := by
  constructor
  · exact pairwiseDisjointDependenciesUnary_of_boolForwardComplete f
  · exact boolForwardComplete_of_pairwiseDisjointDependenciesUnary f

/-- The contextwise at-most-one condition is sufficient for KnownBits
backward completeness with respect to operand `k`. -/
theorem boolBackwardCompleteAt_of_contextwiseAtMostOneDependency {ι : Type*} [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι)
    (hatMostOne : BoolContextwiseAtMostOneDependencyAt f k) :
    KnownBits.BoolBackwardCompleteAt f k := by
  classical
  intro xs
  let closedInputs : (l : ι) → Set (BoolVector (width l)) :=
    closeOperand (fun l ↦ KnownBits.boolDomain (width l)) k xs
  let closedOutputs : Set (BoolVector m) :=
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f) closedInputs
  let outputs : Set (BoolVector m) :=
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f) xs
  change KnownBits.abstract closedOutputs = KnownBits.abstract outputs
  by_cases hall : ∀ l, (xs l).Nonempty
  · have hclosedAll : ∀ l, (closedInputs l).Nonempty := by
      intro l
      by_cases hlk : l = k
      · subst l
        obtain ⟨x, hx⟩ := hall k
        refine ⟨x, ?_⟩
        simpa [closedInputs, closeOperand] using
          (KnownBits.boolDomain (width k)).subset_closure (xs k) hx
      · simpa [closedInputs, closeOperand, hlk] using hall l
    let default : (l : ι) → BoolVector (width l) :=
      fun l ↦ Classical.choose (hall l)
    have hdefault : ∀ l, default l ∈ xs l :=
      fun l ↦ Classical.choose_spec (hall l)
    have houtputs : outputs.Nonempty := by
      refine ⟨f default, default, hdefault, ?_⟩
      exact Set.mem_singleton (f default)
    let closedDefault : (l : ι) → BoolVector (width l) :=
      fun l ↦ Classical.choose (hclosedAll l)
    have hclosedDefault : ∀ l, closedDefault l ∈ closedInputs l :=
      fun l ↦ Classical.choose_spec (hclosedAll l)
    have hclosedOutputs : closedOutputs.Nonempty := by
      refine ⟨f closedDefault, closedDefault, hclosedDefault, ?_⟩
      exact Set.mem_singleton (f closedDefault)
    rw [KnownBits.abstract, dif_pos hclosedOutputs,
      KnownBits.abstract, dif_pos houtputs, WithBot.coe_eq_coe]
    funext i
    apply Subtype.ext
    ext b
    constructor
    · rintro ⟨out, hout, houtBit⟩
      obtain ⟨x, hx, hfx⟩ := hout
      have houtEq : out = f x := Set.mem_singleton_iff.mp hfx
      subst out
      let localOp := sliceAt f k x
      have hlocalAtMostOne : (dependencies localOp i).Subsingleton := hatMostOne x i
      by_cases hdep : (dependencies localOp i).Nonempty
      · let j := Classical.choose hdep
        have hj : j ∈ dependencies localOp i := Classical.choose_spec hdep
        have hxk : x k ∈ (KnownBits.boolDomain (width k)).closure (xs k) := by
          simpa [closedInputs, closeOperand] using hx k
        have hxObserved : ∃ operand ∈ xs k, operand j = x k j := by
          change x k ∈ KnownBits.concretize (KnownBits.abstract (xs k)) at hxk
          rw [KnownBits.abstract, dif_pos (hall k)] at hxk
          exact hxk j
        obtain ⟨operand, hoperand, hoperandBit⟩ := hxObserved
        let y := Function.update x k operand
        have hy : ∀ l, y l ∈ xs l := by
          intro l
          by_cases hlk : l = k
          · subst l
            simpa [y] using hoperand
          · have hxl : x l ∈ xs l := by
              simpa [closedInputs, closeOperand, hlk] using hx l
            simpa [y, hlk] using hxl
        refine ⟨f y, ⟨y, hy, Set.mem_singleton (f y)⟩, ?_⟩
        rw [← houtBit]
        calc
          f y i = localOp operand i := by simp [y, localOp, sliceAt]
          _ = localOp (x k) i := (dependsOn_dependencies localOp i (by
            intro q hq
            have hqj : q = j := hlocalAtMostOne hq hj
            subst q
            exact hoperandBit.symm)).symm
          _ = f x i := by simp [localOp, sliceAt]
      · let y := Function.update x k (default k)
        have hy : ∀ l, y l ∈ xs l := by
          intro l
          by_cases hlk : l = k
          · subst l
            simpa [y] using hdefault k
          · have hxl : x l ∈ xs l := by
              simpa [closedInputs, closeOperand, hlk] using hx l
            simpa [y, hlk] using hxl
        refine ⟨f y, ⟨y, hy, Set.mem_singleton (f y)⟩, ?_⟩
        rw [← houtBit]
        calc
          f y i = localOp (default k) i := by simp [y, localOp, sliceAt]
          _ = localOp (x k) i := (dependsOn_dependencies localOp i (by
            intro q hq
            exact (hdep ⟨q, hq⟩).elim)).symm
          _ = f x i := by simp [localOp, sliceAt]
    · rintro ⟨out, hout, houtBit⟩
      obtain ⟨x, hx, hfx⟩ := hout
      refine ⟨out, ⟨x, ?_, hfx⟩, houtBit⟩
      intro l
      by_cases hlk : l = k
      · subst l
        simpa [closedInputs, closeOperand] using
          (KnownBits.boolDomain (width k)).subset_closure (xs k) (hx k)
      · simpa [closedInputs, closeOperand, hlk] using hx l
  · simp only [not_forall] at hall
    obtain ⟨l, hl⟩ := hall
    have hlempty : xs l = ∅ := Set.not_nonempty_iff_eq_empty.mp hl
    have hclosedEmpty : closedInputs l = ∅ := by
      by_cases hlk : l = k
      · subst l
        simp [closedInputs, closeOperand, hlempty, AbstractDomain.closure,
          KnownBits.boolDomain, KnownBits.concretize]
      · simpa [closedInputs, closeOperand, hlk] using hlempty
    have houtputsEmpty : outputs = ∅ := by
      ext z
      constructor
      · rintro ⟨x, hx, _⟩
        have hxl := hx l
        rw [hlempty] at hxl
        exact hxl.elim
      · simp
    have hclosedOutputsEmpty : closedOutputs = ∅ := by
      ext z
      constructor
      · rintro ⟨x, hx, _⟩
        have hxl := hx l
        rw [hclosedEmpty] at hxl
        exact hxl.elim
      · simp
    rw [houtputsEmpty, hclosedOutputsEmpty]

/-- Per-operand KnownBits backward completeness forces the contextwise
at-most-one condition. -/
theorem contextwiseAtMostOneDependency_of_boolBackwardCompleteAt {ι : Type*}
    [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι)
    (hcomplete : KnownBits.BoolBackwardCompleteAt f k) :
    BoolContextwiseAtMostOneDependencyAt f k := by
  intro context
  exact atMostOneDependencyUnary_of_boolBackwardComplete (sliceAt f k context)
    (boolBackwardComplete_slice_of_at f k hcomplete context)

/-- Exact characterization of KnownBits backward completeness in one operand:
each concrete slice may depend on at most one bit of that operand per output
bit. The selected bit may vary between slices. -/
theorem boolBackwardCompleteAt_iff_contextwiseAtMostOneDependency {ι : Type*}
    [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) (k : ι) :
    KnownBits.BoolBackwardCompleteAt f k ↔ BoolContextwiseAtMostOneDependencyAt f k := by
  constructor
  · exact contextwiseAtMostOneDependency_of_boolBackwardCompleteAt f k
  · exact boolBackwardCompleteAt_of_contextwiseAtMostOneDependency f k

/-- Exact finite-arity characterization of KnownBits backward completeness. -/
theorem boolBackwardCompleteNary_iff_contextwiseAtMostOneDependency {ι : Type*} [Finite ι]
    [DecidableEq ι] {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BoolVector (width k)) → BoolVector m) :
    KnownBits.BoolBackwardCompleteNary f ↔ BoolContextwiseAtMostOneDependency f := by
  constructor
  · intro hcomplete k
    apply contextwiseAtMostOneDependency_of_boolBackwardCompleteAt f k
    exact naryBackwardCompleteAt_of_complete
      (fun l ↦ KnownBits.boolDomain (width l)) (KnownBits.boolDomain m)
      (NaryConcreteOp.ofTotal f) hcomplete k
  · intro hcontext
    apply naryBackwardComplete_of_at
    intro k
    exact boolBackwardCompleteAt_of_contextwiseAtMostOneDependency f k (hcontext k)

/-- Exact finite-arity backward-completeness characterization stated directly
for heterogeneous operations on ordinary Lean bitvectors. -/
theorem backwardCompleteNary_iff_contextwiseAtMostOneDependency
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    KnownBits.BackwardCompleteNary f ↔
      ContextwiseAtMostOneDependencyNary f := by
  calc
    _ ↔ KnownBits.BoolBackwardCompleteNary
        (NaryConcreteOp.transportTotal
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f) := by
      simpa [KnownBits.domain, KnownBits.BackwardCompleteNary,
        KnownBits.BoolBackwardCompleteNary] using
        (naryBackwardComplete_transportTotal_iff
          (fun k ↦ KnownBits.boolDomain (width k)) (KnownBits.boolDomain m)
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ := by
      simpa [ContextwiseAtMostOneDependencyNary] using
        boolBackwardCompleteNary_iff_contextwiseAtMostOneDependency
        (BoolVector.ofBitVecNaryOp f)

/-- Operand-wise disjoint Boolean-coordinate dependencies imply forward
completeness directly for a heterogeneous operation on ordinary bitvectors. -/
theorem forwardCompleteNary_of_pairwiseDisjointDependencies
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m)
    (hdisjoint : PairwiseDisjointDependenciesNary f) :
    KnownBits.ForwardCompleteNary f := by
  apply (naryForwardComplete_transportTotal_iff
    (fun k ↦ KnownBits.boolDomain (width k)) (KnownBits.boolDomain m)
    (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
    (boolVectorEquivBitVec m).symm f).mpr
  rw [transportTotal_eq_ofBitVecNaryOp]
  exact boolForwardCompleteNary_of_pairwiseDisjointDependencies
    (BoolVector.ofBitVecNaryOp f) hdisjoint

/-- Exact finite-arity forward-completeness characterization stated directly
for heterogeneous operations on ordinary Lean bitvectors. -/
theorem forwardCompleteNary_iff_pairwiseDisjointDependencies
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    KnownBits.ForwardCompleteNary f ↔
      PairwiseDisjointDependenciesNary f := by
  calc
    _ ↔ KnownBits.BoolForwardCompleteNary
        (NaryConcreteOp.transportTotal
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f) := by
      simpa [KnownBits.domain, KnownBits.ForwardCompleteNary,
        KnownBits.BoolForwardCompleteNary] using
        (naryForwardComplete_transportTotal_iff
          (fun k ↦ KnownBits.boolDomain (width k)) (KnownBits.boolDomain m)
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ := by
      rw [transportTotal_eq_ofBitVecNaryOp]
      exact boolForwardCompleteNary_iff_pairwiseDisjointDependencies
        (BoolVector.ofBitVecNaryOp f)

/-- At most one essential dependency per output bit is sufficient for unary
KnownBits backward completeness. -/
theorem boolBackwardComplete_of_atMostOneDependencyUnary {n m : Nat}
    (f : BoolVector n → BoolVector m) (hatMostOne : BoolAtMostOneDependencyUnary f) :
    BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
      (ConcreteOp.ofTotal f) := by
  classical
  intro s
  by_cases hs : s.Nonempty
  · let closed := (KnownBits.boolDomain n).closure s
    have hsClosed : closed.Nonempty := ⟨Classical.choose hs,
      (KnownBits.boolDomain n).subset_closure s (Classical.choose_spec hs)⟩
    have hImage : (f '' s).Nonempty := hs.image f
    have hClosedImage : (f '' closed).Nonempty := hsClosed.image f
    simp only [bestTransformer, ConcreteOp.lift_ofTotal]
    change KnownBits.abstract (f '' closed) = KnownBits.abstract (f '' s)
    rw [KnownBits.abstract, dif_pos hClosedImage, KnownBits.abstract, dif_pos hImage,
      WithBot.coe_eq_coe]
    funext i
    apply Subtype.ext
    ext b
    constructor
    · rintro ⟨_, ⟨x, hxClosed, rfl⟩, hfx⟩
      by_cases hdep : (dependencies f i).Nonempty
      · let j := Classical.choose hdep
        have hj : j ∈ dependencies f i := Classical.choose_spec hdep
        have hxObserved : ∃ y ∈ s, y j = x j := by
          have hx := hxClosed
          change x ∈ KnownBits.concretize (KnownBits.abstract s) at hx
          rw [KnownBits.abstract, dif_pos hs] at hx
          exact hx j
        obtain ⟨y, hys, hyj⟩ := hxObserved
        refine ⟨f y, ⟨y, hys, rfl⟩, ?_⟩
        rw [← hfx]
        apply dependsOn_dependencies f i
        intro k hk
        have hkj : k = j := hatMostOne i hk hj
        subst k
        exact hyj
      · let y := Classical.choose hs
        have hys : y ∈ s := Classical.choose_spec hs
        refine ⟨f y, ⟨y, hys, rfl⟩, ?_⟩
        rw [← hfx]
        apply dependsOn_dependencies f i
        intro k hk
        exact (hdep ⟨k, hk⟩).elim
    · rintro ⟨_, ⟨x, hxs, rfl⟩, hfx⟩
      exact ⟨f x, ⟨x, (KnownBits.boolDomain n).subset_closure s hxs, rfl⟩, hfx⟩
  · have hempty : s = ∅ := by
      ext x
      constructor
      · intro hxs
        exact (hs ⟨x, hxs⟩).elim
      · simp
    subst s
    simp [bestTransformer, KnownBits.boolDomain, KnownBits.concretize]

/-- Exact unary characterization of KnownBits backward completeness. -/
theorem boolBackwardComplete_iff_atMostOneDependencyUnary {n m : Nat}
    (f : BoolVector n → BoolVector m) :
    BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (ConcreteOp.ofTotal f) ↔
      BoolAtMostOneDependencyUnary f := by
  constructor
  · exact atMostOneDependencyUnary_of_boolBackwardComplete f
  · exact boolBackwardComplete_of_atMostOneDependencyUnary f

/-- Pairwise-disjoint Boolean-coordinate dependencies imply forward
completeness of an ordinary bitvector operation in KnownBits. -/
theorem forwardComplete_of_pairwiseDisjointDependencies {n m : Nat}
    (f : BitVec n → BitVec m)
    (hdisjoint : PairwiseDisjointDependencies f) :
    ForwardComplete (KnownBits.domain n) (KnownBits.domain m)
      (ConcreteOp.ofTotal f) := by
  apply (forwardComplete_transportTotal_iff
    (KnownBits.boolDomain n) (KnownBits.boolDomain m)
    (boolVectorEquivBitVec n).symm (boolVectorEquivBitVec m).symm f).mpr
  simpa using boolForwardComplete_of_pairwiseDisjointDependenciesUnary
    (BoolVector.ofBitVecUnaryOp f) hdisjoint

/-- Exact unary forward-completeness characterization stated directly for
ordinary Lean bitvectors. -/
theorem forwardComplete_iff_pairwiseDisjointDependencies {n m : Nat}
    (f : BitVec n → BitVec m) :
    ForwardComplete (KnownBits.domain n) (KnownBits.domain m)
        (ConcreteOp.ofTotal f) ↔
      PairwiseDisjointDependencies f := by
  calc
    _ ↔ ForwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (ConcreteOp.ofTotal (AbstractDomain.transportUnary
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)) := by
      simpa [KnownBits.domain] using
        (forwardComplete_transportTotal_iff
          (KnownBits.boolDomain n) (KnownBits.boolDomain m)
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)
    _ ↔ BoolPairwiseDisjointDependenciesUnary (BoolVector.ofBitVecUnaryOp f) := by
      simpa using boolForwardComplete_iff_pairwiseDisjointDependenciesUnary
        (BoolVector.ofBitVecUnaryOp f)

/-- Exact unary backward-completeness characterization stated directly for
ordinary Lean bitvectors. -/
theorem backwardComplete_iff_atMostOneDependency {n m : Nat}
    (f : BitVec n → BitVec m) :
    BackwardComplete (KnownBits.domain n) (KnownBits.domain m)
        (ConcreteOp.ofTotal f) ↔
      AtMostOneDependency f := by
  calc
    _ ↔ BackwardComplete (KnownBits.boolDomain n) (KnownBits.boolDomain m)
        (ConcreteOp.ofTotal (AbstractDomain.transportUnary
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)) := by
      simpa [KnownBits.domain] using
        (backwardComplete_transportTotal_iff
          (KnownBits.boolDomain n) (KnownBits.boolDomain m)
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ := by
      simpa [AtMostOneDependency] using
        boolBackwardComplete_iff_atMostOneDependencyUnary
        (BoolVector.ofBitVecUnaryOp f)

end BitDependency

namespace KnownBits

/-- Internal Boolean-coordinate presentation of a public relational unary
BitVec operation. -/
def relationalBoolModel {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    ConcreteOp (BoolVector n) (BoolVector m) :=
  ConcreteOp.transport (boolVectorEquivBitVec n).symm
    (boolVectorEquivBitVec m).symm f

/-- Internal Boolean-coordinate presentation of a public relational n-ary
BitVec operation. -/
def relationalBoolModelNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryConcreteOp ι (fun k ↦ BoolVector (width k)) (BoolVector m) :=
  NaryConcreteOp.transport
    (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
    (boolVectorEquivBitVec m).symm f

theorem forwardComplete_iff_preservesKnownBitsSets {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    SynthXfer.ForwardComplete (domain n) (domain m) f ↔
      BitDependency.PreservesKnownBitsSets (relationalBoolModel f) := by
  calc
    _ ↔ ForwardComplete (boolDomain n) (boolDomain m)
        (relationalBoolModel f) := by
      simpa [domain, relationalBoolModel] using
        (forwardComplete_transport_iff
          (boolDomain n) (boolDomain m)
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ :=
      BitDependency.boolForwardComplete_iff_preservesKnownBitsSets _

theorem backwardComplete_iff_observationFibersRepresentable {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    SynthXfer.BackwardComplete (domain n) (domain m) f ↔
      BitDependency.ObservationFibersRepresentable (relationalBoolModel f) := by
  calc
    _ ↔ BackwardComplete (boolDomain n) (boolDomain m)
        (relationalBoolModel f) := by
      simpa [domain, relationalBoolModel] using
        (backwardComplete_transport_iff
          (boolDomain n) (boolDomain m)
          (boolVectorEquivBitVec n).symm
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ :=
      BitDependency.boolBackwardComplete_iff_observationFibersRepresentable _

theorem forwardCompleteNary_iff_preservesKnownBitsSets
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    SynthXfer.NaryForwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      BitDependency.PreservesKnownBitsSetsNary
        (relationalBoolModelNary f) := by
  calc
    _ ↔ NaryForwardComplete (fun k ↦ boolDomain (width k))
        (boolDomain m) (relationalBoolModelNary f) := by
      simpa [domain,
        relationalBoolModelNary] using
        (naryForwardComplete_transport_iff
          (fun k ↦ boolDomain (width k)) (boolDomain m)
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ :=
      BitDependency.boolForwardCompleteNary_iff_preservesKnownBitsSets _

theorem backwardCompleteNary_iff_observationFibersRepresentable
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    SynthXfer.NaryBackwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      BitDependency.ObservationFibersRepresentableNary
        (relationalBoolModelNary f) := by
  calc
    _ ↔ NaryBackwardComplete (fun k ↦ boolDomain (width k))
        (boolDomain m) (relationalBoolModelNary f) := by
      simpa [domain,
        relationalBoolModelNary] using
        (naryBackwardComplete_transport_iff
          (fun k ↦ boolDomain (width k)) (boolDomain m)
          (fun k ↦ (boolVectorEquivBitVec (width k)).symm)
          (boolVectorEquivBitVec m).symm f)
    _ ↔ _ :=
      BitDependency.backwardCompleteNary_iff_observationFibersRepresentable _

/-- For total unary operations, the relational forward condition reduces to
the ordinary pairwise-disjoint dependency condition. -/
theorem preservesKnownBitsSets_ofTotal_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec m) :
    BitDependency.PreservesKnownBitsSets
        (relationalBoolModel (ConcreteOp.ofTotal f)) ↔
      BitDependency.PairwiseDisjointDependencies f := by
  calc
    _ ↔ SynthXfer.ForwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f) :=
      (forwardComplete_iff_preservesKnownBitsSets _).symm
    _ ↔ _ := BitDependency.forwardComplete_iff_pairwiseDisjointDependencies f

/-- For total unary operations, the relational backward condition reduces to
the ordinary at-most-one dependency condition. -/
theorem observationFibersRepresentable_ofTotal_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec m) :
    BitDependency.ObservationFibersRepresentable
        (relationalBoolModel (ConcreteOp.ofTotal f)) ↔
      BitDependency.AtMostOneDependency f := by
  calc
    _ ↔ SynthXfer.BackwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f) :=
      (backwardComplete_iff_observationFibersRepresentable _).symm
    _ ↔ _ := BitDependency.backwardComplete_iff_atMostOneDependency f

/-- The relational n-ary forward condition specializes to the existing total
dependency theorem. -/
theorem preservesKnownBitsSetsNary_ofTotal_iff_dependencies
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    BitDependency.PreservesKnownBitsSetsNary
        (relationalBoolModelNary (NaryConcreteOp.ofTotal f)) ↔
      BitDependency.PairwiseDisjointDependenciesNary f := by
  calc
    _ ↔ SynthXfer.NaryForwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) :=
      (forwardCompleteNary_iff_preservesKnownBitsSets _).symm
    _ ↔ _ :=
      BitDependency.forwardCompleteNary_iff_pairwiseDisjointDependencies f

/-- The relational n-ary backward condition specializes to the existing
contextwise total dependency theorem. -/
theorem observationFibersRepresentableNary_ofTotal_iff_dependencies
    {ι : Type*} [Finite ι] [DecidableEq ι]
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    BitDependency.ObservationFibersRepresentableNary
        (relationalBoolModelNary (NaryConcreteOp.ofTotal f)) ↔
      BitDependency.ContextwiseAtMostOneDependencyNary f := by
  calc
    _ ↔ SynthXfer.NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) :=
      (backwardCompleteNary_iff_observationFibersRepresentable _).symm
    _ ↔ _ :=
      BitDependency.backwardCompleteNary_iff_contextwiseAtMostOneDependency f

/-- Convenient unary interface. This is only a specialization of the generic
one-operand completeness theory. -/
abbrev UnaryForwardComplete {n m : Nat} (f : BitVec n → BitVec m) : Prop :=
  SynthXfer.ForwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f)

/-- Convenient unary backward-completeness interface. -/
abbrev UnaryBackwardComplete {n m : Nat} (f : BitVec n → BitVec m) : Prop :=
  SynthXfer.BackwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f)

/-- View a homogeneous binary bitvector operation in the canonical two-index
n-ary form. -/
def binaryAsNary {n m : Nat} (f : BitVec n → BitVec n → BitVec m) :
    (BinaryOperand → BitVec n) → BitVec m :=
  fun x ↦ f (x BinaryOperand.left) (x BinaryOperand.right)

/-- Convenient binary interface for two independently varying operands. The
definition is equivalent to the `BinaryOperand` instance of `ForwardCompleteNary`. -/
abbrev BinaryForwardComplete {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) : Prop :=
  SynthXfer.BinaryForwardComplete (domain n) (domain n) (domain m)
    (BinaryConcreteOp.ofTotal f)

/-- Convenient binary backward-completeness interface. -/
abbrev BinaryBackwardComplete {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) : Prop :=
  SynthXfer.BinaryBackwardComplete (domain n) (domain n) (domain m)
    (BinaryConcreteOp.ofTotal f)

theorem unaryForwardComplete_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec m) :
    UnaryForwardComplete f ↔
      BitDependency.PairwiseDisjointDependencies f :=
  BitDependency.forwardComplete_iff_pairwiseDisjointDependencies f

theorem unaryBackwardComplete_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec m) :
    UnaryBackwardComplete f ↔ BitDependency.AtMostOneDependency f :=
  BitDependency.backwardComplete_iff_atMostOneDependency f

theorem binaryForwardComplete_iff_nary {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) :
    BinaryForwardComplete f ↔ ForwardCompleteNary (binaryAsNary f) := by
  have hop : (BinaryConcreteOp.ofTotal f).asNary =
      NaryConcreteOp.ofTotal (binaryAsNary f) := by
    rfl
  change SynthXfer.BinaryForwardComplete (domain n) (domain n) (domain m)
      (BinaryConcreteOp.ofTotal f) ↔
    NaryForwardComplete (fun _ : BinaryOperand ↦ domain n) (domain m)
      (NaryConcreteOp.ofTotal (binaryAsNary f))
  rw [← hop]
  exact SynthXfer.binaryForwardComplete_iff_nary
    (domain n) (domain m) (BinaryConcreteOp.ofTotal f)

theorem binaryBackwardComplete_iff_nary {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) :
    BinaryBackwardComplete f ↔ BackwardCompleteNary (binaryAsNary f) := by
  have hop : (BinaryConcreteOp.ofTotal f).asNary =
      NaryConcreteOp.ofTotal (binaryAsNary f) := by
    rfl
  change SynthXfer.BinaryBackwardComplete (domain n) (domain n) (domain m)
      (BinaryConcreteOp.ofTotal f) ↔
    NaryBackwardComplete (fun _ : BinaryOperand ↦ domain n) (domain m)
      (NaryConcreteOp.ofTotal (binaryAsNary f))
  rw [← hop]
  exact SynthXfer.binaryBackwardComplete_iff_nary
    (domain n) (domain m) (BinaryConcreteOp.ofTotal f)

/-- Binary forward completeness, exposed through the canonical n-ary
dependency characterization. -/
theorem binaryForwardComplete_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) :
    BinaryForwardComplete f ↔
      BitDependency.PairwiseDisjointDependenciesNary (binaryAsNary f) := by
  rw [binaryForwardComplete_iff_nary]
  exact BitDependency.forwardCompleteNary_iff_pairwiseDisjointDependencies _

/-- Binary backward completeness, exposed through the canonical contextwise
n-ary dependency characterization. -/
theorem binaryBackwardComplete_iff_dependencies {n m : Nat}
    (f : BitVec n → BitVec n → BitVec m) :
    BinaryBackwardComplete f ↔
      BitDependency.ContextwiseAtMostOneDependencyNary (binaryAsNary f) := by
  rw [binaryBackwardComplete_iff_nary]
  exact BitDependency.backwardCompleteNary_iff_contextwiseAtMostOneDependency _

end KnownBits

end SynthXfer
