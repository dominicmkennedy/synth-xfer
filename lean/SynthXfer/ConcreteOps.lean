import SynthXfer.AbstractDomain
import Mathlib.Data.Finset.Update
import Mathlib.Data.Fintype.EquivFin

/-!
# Concrete operations with independent operands

The canonical theory in this file uses indexed, heterogeneous n-ary operations.
Each operand ranges independently over its concretization, so correlations
between operands are intentionally not represented.

Unary and binary definitions are convenience interfaces for the common
operation shapes. Mathematical characterizations should be proved for the
n-ary theory and exposed through these smaller interfaces when that improves
the ergonomics of concrete-operation proofs.

An n-ary abstract input is a family of abstract values, not one abstract value
for a product domain. Consequently, several families may denote the empty
Cartesian product: for example, either operand of a binary input may be
bottom. These families have identical collecting semantics even though they
are not definitionally equal as functions. Completeness is stated through
their collecting semantics and therefore does not distinguish these bottom
placements.
-/

namespace SynthXfer

universe u v w x

/-- A relational concrete operation with an arbitrary, possibly heterogeneous,
family of operands. -/
abbrev NaryConcreteOp (ι : Type u) (C : ι → Type v) (D : Type w) :=
  ((i : ι) → C i) → Set D

namespace NaryConcreteOp

variable {ι : Type u} {C : ι → Type v} {D : Type w}

/-- Collect results over the Cartesian product of a family of operand sets. -/
def lift (f : NaryConcreteOp ι C D) (xs : (i : ι) → Set (C i)) : Set D :=
  {y | ∃ x : (i : ι) → C i, (∀ i, x i ∈ xs i) ∧ y ∈ f x}

/-- Embed a total n-ary function in relational semantics. -/
def ofTotal (f : ((i : ι) → C i) → D) : NaryConcreteOp ι C D :=
  fun x ↦ {f x}

/-- Transport a heterogeneous total operation along an equivalence for every
operand and an equivalence for its result. -/
def transportTotal {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : ((i : ι) → C i) → D) : ((i : ι) → C' i) → D' :=
  fun x ↦ dstEquiv (f fun i ↦ (equiv i).symm (x i))

/-- Embed an `Option`-valued partial n-ary function. -/
def ofOption (f : ((i : ι) → C i) → Option D) : NaryConcreteOp ι C D :=
  fun x ↦ {y | f x = some y}

@[simp]
theorem mem_ofTotal {f : ((i : ι) → C i) → D}
    {x : (i : ι) → C i} {y : D} :
    y ∈ ofTotal f x ↔ y = f x :=
  Set.mem_singleton_iff

@[simp]
theorem mem_ofOption {f : ((i : ι) → C i) → Option D}
    {x : (i : ι) → C i} {y : D} :
    y ∈ ofOption f x ↔ f x = some y :=
  Iff.rfl

/-- Transport a relational n-ary operation along an equivalence for every
operand and an equivalence for its result. -/
def transport {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : NaryConcreteOp ι C D) : NaryConcreteOp ι C' D' :=
  fun x ↦ dstEquiv '' f (fun i ↦ (equiv i).symm (x i))

@[simp]
theorem mem_lift {f : NaryConcreteOp ι C D} {xs : (i : ι) → Set (C i)}
    {y : D} :
    y ∈ lift f xs ↔ ∃ x : (i : ι) → C i, (∀ i, x i ∈ xs i) ∧ y ∈ f x :=
  Iff.rfl

theorem lift_mono (f : NaryConcreteOp ι C D)
    {xs ys : (i : ι) → Set (C i)} (h : ∀ i, xs i ⊆ ys i) :
    lift f xs ⊆ lift f ys := by
  rintro y ⟨x, hx, hy⟩
  exact ⟨x, fun i ↦ h i (hx i), hy⟩

@[simp]
theorem lift_ofTotal (f : ((i : ι) → C i) → D)
    (xs : (i : ι) → Set (C i)) :
    lift (ofTotal f) xs = {y | ∃ x, (∀ i, x i ∈ xs i) ∧ f x = y} := by
  ext y
  simp [lift, ofTotal, eq_comm]

theorem lift_empty_of_empty_operand (f : NaryConcreteOp ι C D)
    (xs : (i : ι) → Set (C i)) (k : ι) (hk : xs k = ∅) :
    lift f xs = ∅ := by
  ext y
  constructor
  · rintro ⟨x, hx, _⟩
    have := hx k
    rw [hk] at this
    exact this.elim
  · simp

theorem lift_ofTotal_nonempty (f : ((i : ι) → C i) → D)
    {xs : (i : ι) → Set (C i)} (hxs : ∀ i, (xs i).Nonempty) :
    (lift (ofTotal f) xs).Nonempty := by
  classical
  let x : (i : ι) → C i := fun i ↦ Classical.choose (hxs i)
  exact ⟨f x, x, fun i ↦ Classical.choose_spec (hxs i), Set.mem_singleton _⟩

theorem lift_ofOption_eq_empty {f : ((i : ι) → C i) → Option D}
    {xs : (i : ι) → Set (C i)}
    (h : ∀ x, (∀ i, x i ∈ xs i) → f x = none) :
    lift (ofOption f) xs = ∅ := by
  ext y
  simp only [mem_lift, Set.mem_empty_iff_false, iff_false]
  rintro ⟨x, hx, hresult⟩
  simp [ofOption, h x hx] at hresult

theorem lift_transport {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : NaryConcreteOp ι C D) (xs : (i : ι) → Set (C' i)) :
    lift (transport equiv dstEquiv f) xs =
      dstEquiv '' lift f (fun i ↦ equiv i ⁻¹' xs i) := by
  ext y
  constructor
  · rintro ⟨x, hx, z, hz, rfl⟩
    exact ⟨z, ⟨fun i ↦ (equiv i).symm (x i),
      fun i ↦ by simpa using hx i, hz⟩, rfl⟩
  · rintro ⟨z, ⟨x, hx, hz⟩, rfl⟩
    refine ⟨fun i ↦ equiv i (x i), fun i ↦ hx i, z, ?_, rfl⟩
    simpa using hz

theorem lift_transport_image {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : NaryConcreteOp ι C D) (xs : (i : ι) → Set (C i)) :
    lift (transport equiv dstEquiv f) (fun i ↦ equiv i '' xs i) =
      dstEquiv '' lift f xs := by
  rw [lift_transport]
  congr 2
  funext i
  exact Set.preimage_image_eq _ (equiv i).injective

theorem image_lift_preimage_equiv {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : ((i : ι) → C i) → D) (xs : (i : ι) → Set (C' i)) :
    dstEquiv '' lift (ofTotal f) (fun i ↦ equiv i ⁻¹' xs i) =
      lift (ofTotal (transportTotal equiv dstEquiv f)) xs := by
  ext y
  constructor
  · rintro ⟨_, ⟨x, hx, hresult⟩, rfl⟩
    have hresultEq := Set.mem_singleton_iff.mp hresult
    refine ⟨fun i ↦ equiv i (x i), ?_, ?_⟩
    · exact fun i ↦ hx i
    · simpa [ofTotal, transportTotal] using hresultEq
  · rintro ⟨x, hx, hresult⟩
    have hresultEq := Set.mem_singleton_iff.mp hresult
    refine ⟨f (fun i ↦ (equiv i).symm (x i)), ?_, ?_⟩
    · refine ⟨fun i ↦ (equiv i).symm (x i), ?_, Set.mem_singleton _⟩
      exact fun i ↦ by simpa using hx i
    · simp [transportTotal, hresultEq]

theorem preimage_lift_transportTotal {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : ((i : ι) → C i) → D) (xs : (i : ι) → Set (C' i)) :
    dstEquiv ⁻¹' lift (ofTotal (transportTotal equiv dstEquiv f)) xs =
      lift (ofTotal f) (fun i ↦ equiv i ⁻¹' xs i) := by
  rw [← image_lift_preimage_equiv equiv dstEquiv f xs]
  exact Set.preimage_image_eq _ dstEquiv.injective

theorem image_lift_image_equiv {C' : ι → Type v} {D' : Type w}
    (equiv : ∀ i, C i ≃ C' i) (dstEquiv : D ≃ D')
    (f : ((i : ι) → C i) → D) (xs : (i : ι) → Set (C i)) :
    dstEquiv '' lift (ofTotal f) xs =
      lift (ofTotal (transportTotal equiv dstEquiv f))
        (fun i ↦ equiv i '' xs i) := by
  rw [← image_lift_preimage_equiv equiv dstEquiv f
    (fun i ↦ equiv i '' xs i)]
  congr 2
  funext i
  exact (Set.preimage_image_eq _ (equiv i).injective).symm

end NaryConcreteOp

section NaryCompleteness

variable {ι : Type u} {C : ι → Type v} {D : Type w}
variable {A : ι → Type x} {AD : Type*}
variable [∀ i, PartialOrder (A i)] [PartialOrder AD]

/-- Close one concrete operand set while leaving every other operand set
unchanged. -/
def closeOperand (domains : ∀ i, AbstractDomain (C i) (A i))
    [DecidableEq ι] (k : ι) (xs : (i : ι) → Set (C i)) :
    (i : ι) → Set (C i) :=
  Function.update xs k ((domains k).closure (xs k))

/-- The most precise abstract transformer for independently varying operands. -/
def bestNaryTransformer (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D) :
    ((i : ι) → A i) → AD :=
  fun a ↦ dst.abstract (NaryConcreteOp.lift f fun i ↦ (domains i).concretize (a i))

theorem bestNaryTransformer_mono
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    {a b : (i : ι) → A i} (h : ∀ i, a i ≤ b i) :
    bestNaryTransformer domains dst f a ≤
      bestNaryTransformer domains dst f b :=
  dst.abstract_mono <| NaryConcreteOp.lift_mono f fun i ↦
    (domains i).concretize_mono (h i)

/-- Every result set over represented, independently varying operands is
represented exactly by the destination domain. -/
def NaryForwardComplete (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D) : Prop :=
  ∀ a, dst.concretize (bestNaryTransformer domains dst f a) =
    NaryConcreteOp.lift f fun i ↦ (domains i).concretize (a i)

/-- Independently abstracting every operand loses no destination-domain
information. -/
def NaryBackwardComplete (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D) : Prop :=
  ∀ xs, dst.abstract
      (NaryConcreteOp.lift f fun i ↦ (domains i).closure (xs i)) =
    dst.abstract (NaryConcreteOp.lift f xs)

/-- Abstracting operand `k` alone loses no destination-domain information.
All other operands remain arbitrary concrete sets. -/
def NaryBackwardCompleteAt (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    [DecidableEq ι] (k : ι) : Prop :=
  ∀ xs, dst.abstract (NaryConcreteOp.lift f (closeOperand domains k xs)) =
    dst.abstract (NaryConcreteOp.lift f xs)

theorem naryForwardComplete_iff_closure
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D) :
    NaryForwardComplete domains dst f ↔
      ∀ xs : (i : ι) → Set (C i), dst.closure
          (NaryConcreteOp.lift f (fun i ↦ (domains i).closure (xs i))) =
        NaryConcreteOp.lift f (fun i ↦ (domains i).closure (xs i)) := by
  constructor
  · intro h xs
    simpa only [AbstractDomain.closure, bestNaryTransformer] using
      h (fun i ↦ (domains i).abstract (xs i))
  · intro h a
    simpa only [AbstractDomain.closure, AbstractDomain.abstract_concretize,
      bestNaryTransformer] using h (fun i ↦ (domains i).concretize (a i))

theorem naryBackwardComplete_iff_closure
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D) :
    NaryBackwardComplete domains dst f ↔
      ∀ xs : (i : ι) → Set (C i), dst.closure
          (NaryConcreteOp.lift f (fun i ↦ (domains i).closure (xs i))) =
        dst.closure (NaryConcreteOp.lift f xs) := by
  constructor
  · intro h xs
    have := congrArg dst.concretize (h xs)
    simpa only [AbstractDomain.closure] using this
  · intro h xs
    apply dst.insertion.injective
    simpa only [AbstractDomain.closure] using h xs

/-- A destination-closure member missing from an independently closed result
set witnesses failure of n-ary forward completeness. -/
theorem naryForwardIncomplete_of_witness
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    (xs : (i : ι) → Set (C i)) (y : D)
    (hyClosed : y ∈ dst.closure (NaryConcreteOp.lift f
      (fun i ↦ (domains i).closure (xs i))))
    (hyMissing : y ∉ NaryConcreteOp.lift f
      (fun i ↦ (domains i).closure (xs i))) :
    ¬ NaryForwardComplete domains dst f := by
  intro hcomplete
  have hEq := (naryForwardComplete_iff_closure domains dst f).mp
    hcomplete xs
  exact hyMissing (hEq ▸ hyClosed)

/-- A destination fact introduced by independently closing the operands is a
checkable witness that n-ary backward completeness fails. -/
theorem naryBackwardIncomplete_of_witness
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    (xs : (i : ι) → Set (C i)) (y : D)
    (hyClosedInputs : y ∈ dst.closure (NaryConcreteOp.lift f
      (fun i ↦ (domains i).closure (xs i))))
    (hyOriginal : y ∉ dst.closure (NaryConcreteOp.lift f xs)) :
    ¬ NaryBackwardComplete domains dst f := by
  intro hcomplete
  have hEq := (naryBackwardComplete_iff_closure domains dst f).mp
    hcomplete xs
  exact hyOriginal (hEq ▸ hyClosedInputs)

theorem bestNaryTransformer_eq_bot_of_undefined
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) [OrderBot AD]
    (f : ((i : ι) → C i) → Option D) (a : (i : ι) → A i)
    (h : ∀ x, (∀ i, x i ∈ (domains i).concretize (a i)) → f x = none) :
    bestNaryTransformer domains dst (NaryConcreteOp.ofOption f) a = ⊥ := by
  simp only [bestNaryTransformer, NaryConcreteOp.lift_ofOption_eq_empty h]
  exact dst.abstract_empty

/-- Forward completeness of a heterogeneous total operation is unchanged
when every concrete operand and the result use equivalent representations. -/
theorem naryForwardComplete_transportTotal_iff
    {C' : ι → Type v} {D' : Type w}
    (domains : ∀ i, AbstractDomain (C' i) (A i))
    (dst : AbstractDomain D' AD) (equiv : ∀ i, C i ≃ C' i)
    (dstEquiv : D ≃ D') (f : ((i : ι) → C i) → D) :
    NaryForwardComplete
        (fun i ↦ (domains i).comapEquiv (equiv i))
        (dst.comapEquiv dstEquiv) (NaryConcreteOp.ofTotal f) ↔
      NaryForwardComplete domains dst
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f)) := by
  constructor
  · intro hcomplete a
    have hEq := hcomplete a
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
          (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)))) =
      NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)) at hEq
    apply dstEquiv.surjective.preimage_injective
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (NaryConcreteOp.lift
          (NaryConcreteOp.ofTotal
            (NaryConcreteOp.transportTotal equiv dstEquiv f))
          (fun i ↦ (domains i).concretize (a i)))) =
      dstEquiv ⁻¹' NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f))
        (fun i ↦ (domains i).concretize (a i))
    rw [NaryConcreteOp.preimage_lift_transportTotal]
    rw [← NaryConcreteOp.image_lift_preimage_equiv]
    exact hEq
  · intro hcomplete a
    have hEq := hcomplete a
    change dst.concretize (dst.abstract
        (NaryConcreteOp.lift
          (NaryConcreteOp.ofTotal
            (NaryConcreteOp.transportTotal equiv dstEquiv f))
          (fun i ↦ (domains i).concretize (a i)))) =
      NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f))
        (fun i ↦ (domains i).concretize (a i)) at hEq
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
          (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)))) =
      NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i))
    rw [NaryConcreteOp.image_lift_preimage_equiv]
    rw [hEq]
    exact NaryConcreteOp.preimage_lift_transportTotal equiv dstEquiv f
      (fun i ↦ (domains i).concretize (a i))

/-- Backward completeness of a heterogeneous total operation is unchanged
when every concrete operand and the result are represented by equivalent
types. -/
theorem naryBackwardComplete_transportTotal_iff
    {C' : ι → Type v} {D' : Type w}
    (domains : ∀ i, AbstractDomain (C' i) (A i))
    (dst : AbstractDomain D' AD) (equiv : ∀ i, C i ≃ C' i)
    (dstEquiv : D ≃ D') (f : ((i : ι) → C i) → D) :
    NaryBackwardComplete
        (fun i ↦ (domains i).comapEquiv (equiv i))
        (dst.comapEquiv dstEquiv) (NaryConcreteOp.ofTotal f) ↔
      NaryBackwardComplete domains dst
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f)) := by
  constructor
  · intro hcomplete t
    let xs : (i : ι) → Set (C i) :=
      fun i ↦ (equiv i).symm '' t i
    have hEq := hcomplete xs
    change dst.abstract (dstEquiv '' NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal f)
        (fun i ↦ equiv i ⁻¹'
          (domains i).concretize ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (dstEquiv '' NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal f) xs) at hEq
    rw [NaryConcreteOp.image_lift_preimage_equiv equiv dstEquiv f,
      NaryConcreteOp.image_lift_image_equiv equiv dstEquiv f xs] at hEq
    simpa [AbstractDomain.closure, xs] using hEq
  · intro hcomplete xs
    have hEq := hcomplete (fun i ↦ equiv i '' xs i)
    change dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f))
        (fun i ↦ (domains i).concretize
          ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal
          (NaryConcreteOp.transportTotal equiv dstEquiv f))
        (fun i ↦ equiv i '' xs i)) at hEq
    change dst.abstract (dstEquiv '' NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal f)
        (fun i ↦ equiv i ⁻¹'
          (domains i).concretize ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (dstEquiv '' NaryConcreteOp.lift
        (NaryConcreteOp.ofTotal f) xs)
    rw [NaryConcreteOp.image_lift_preimage_equiv equiv dstEquiv f,
      NaryConcreteOp.image_lift_image_equiv equiv dstEquiv f xs]
    exact hEq

/-- N-ary relational forward completeness is invariant under equivalent
representations of every concrete carrier. -/
theorem naryForwardComplete_transport_iff
    {C' : ι → Type v} {D' : Type w}
    (domains : ∀ i, AbstractDomain (C' i) (A i))
    (dst : AbstractDomain D' AD) (equiv : ∀ i, C i ≃ C' i)
    (dstEquiv : D ≃ D') (f : NaryConcreteOp ι C D) :
    NaryForwardComplete
        (fun i ↦ (domains i).comapEquiv (equiv i))
        (dst.comapEquiv dstEquiv) f ↔
      NaryForwardComplete domains dst
        (NaryConcreteOp.transport equiv dstEquiv f) := by
  constructor
  · intro hcomplete a
    have hEq := hcomplete a
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' NaryConcreteOp.lift f
          (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)))) =
      NaryConcreteOp.lift f
        (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)) at hEq
    change dst.concretize (dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.transport equiv dstEquiv f)
          (fun i ↦ (domains i).concretize (a i)))) =
      NaryConcreteOp.lift (NaryConcreteOp.transport equiv dstEquiv f)
        (fun i ↦ (domains i).concretize (a i))
    rw [NaryConcreteOp.lift_transport]
    apply dstEquiv.surjective.preimage_injective
    simpa using hEq
  · intro hcomplete a
    have hEq := hcomplete a
    change dst.concretize (dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.transport equiv dstEquiv f)
          (fun i ↦ (domains i).concretize (a i)))) =
      NaryConcreteOp.lift (NaryConcreteOp.transport equiv dstEquiv f)
        (fun i ↦ (domains i).concretize (a i)) at hEq
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' NaryConcreteOp.lift f
          (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i)))) =
      NaryConcreteOp.lift f
        (fun i ↦ equiv i ⁻¹' (domains i).concretize (a i))
    rw [NaryConcreteOp.lift_transport] at hEq
    rw [hEq]
    exact Set.preimage_image_eq _ dstEquiv.injective

/-- N-ary relational backward completeness is invariant under equivalent
representations of every concrete carrier. -/
theorem naryBackwardComplete_transport_iff
    {C' : ι → Type v} {D' : Type w}
    (domains : ∀ i, AbstractDomain (C' i) (A i))
    (dst : AbstractDomain D' AD) (equiv : ∀ i, C i ≃ C' i)
    (dstEquiv : D ≃ D') (f : NaryConcreteOp ι C D) :
    NaryBackwardComplete
        (fun i ↦ (domains i).comapEquiv (equiv i))
        (dst.comapEquiv dstEquiv) f ↔
      NaryBackwardComplete domains dst
        (NaryConcreteOp.transport equiv dstEquiv f) := by
  constructor
  · intro hcomplete t
    let xs : (i : ι) → Set (C i) := fun i ↦ (equiv i).symm '' t i
    have hEq := hcomplete xs
    change dst.abstract (dstEquiv '' NaryConcreteOp.lift f
        (fun i ↦ equiv i ⁻¹'
          (domains i).concretize ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (dstEquiv '' NaryConcreteOp.lift f xs) at hEq
    rw [← NaryConcreteOp.lift_transport equiv dstEquiv f,
      ← NaryConcreteOp.lift_transport_image equiv dstEquiv f xs] at hEq
    simpa [xs, AbstractDomain.closure] using hEq
  · intro hcomplete xs
    have hEq := hcomplete (fun i ↦ equiv i '' xs i)
    change dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.transport equiv dstEquiv f)
        (fun i ↦ (domains i).concretize
          ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (NaryConcreteOp.lift
        (NaryConcreteOp.transport equiv dstEquiv f)
        (fun i ↦ equiv i '' xs i)) at hEq
    change dst.abstract (dstEquiv '' NaryConcreteOp.lift f
        (fun i ↦ equiv i ⁻¹'
          (domains i).concretize ((domains i).abstract (equiv i '' xs i)))) =
      dst.abstract (dstEquiv '' NaryConcreteOp.lift f xs)
    rw [← NaryConcreteOp.lift_transport equiv dstEquiv f,
      ← NaryConcreteOp.lift_transport_image equiv dstEquiv f xs]
    exact hEq

/-- Full n-ary backward completeness implies backward completeness with
respect to each individual operand. -/
theorem naryBackwardCompleteAt_of_complete [DecidableEq ι]
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    (hcomplete : NaryBackwardComplete domains dst f) (k : ι) :
    NaryBackwardCompleteAt domains dst f k := by
  intro xs
  let closed : (i : ι) → Set (C i) := fun i ↦ (domains i).closure (xs i)
  have horiginal_subset : ∀ i, xs i ⊆ closeOperand domains k xs i := by
    intro i
    by_cases hik : i = k
    · subst i
      simpa [closeOperand] using (domains k).subset_closure (xs k)
    · simp [closeOperand, hik]
  have hone_subset : ∀ i, closeOperand domains k xs i ⊆ closed i := by
    intro i
    by_cases hik : i = k
    · subst i
      simp [closeOperand, closed]
    · simpa [closeOperand, closed, hik] using
        (domains i).subset_closure (xs i)
  apply le_antisymm
  · calc
      dst.abstract (NaryConcreteOp.lift f (closeOperand domains k xs)) ≤
          dst.abstract (NaryConcreteOp.lift f closed) :=
        dst.abstract_mono (NaryConcreteOp.lift_mono f hone_subset)
      _ = dst.abstract (NaryConcreteOp.lift f xs) := hcomplete xs
  · exact dst.abstract_mono
      (NaryConcreteOp.lift_mono f horiginal_subset)

/-- For a finite family of operands, backward completeness in every operand
separately implies backward completeness after closing all operands. -/
theorem naryBackwardComplete_of_at [Finite ι] [DecidableEq ι]
    (domains : ∀ i, AbstractDomain (C i) (A i))
    (dst : AbstractDomain D AD) (f : NaryConcreteOp ι C D)
    (hcomplete : ∀ k, NaryBackwardCompleteAt domains dst f k) :
    NaryBackwardComplete domains dst f := by
  classical
  letI := Fintype.ofFinite ι
  intro xs
  let closeMany (s : Finset ι) : (i : ι) → Set (C i) :=
    fun i ↦ if i ∈ s then (domains i).closure (xs i) else xs i
  have hstep (s : Finset ι) (k : ι) (hks : k ∉ s) :
      dst.abstract (NaryConcreteOp.lift f (closeMany (insert k s))) =
        dst.abstract (NaryConcreteOp.lift f (closeMany s)) := by
    have hk := hcomplete k (closeMany s)
    have hclose : closeMany (insert k s) =
        closeOperand domains k (closeMany s) := by
      funext i
      by_cases hik : i = k
      · subst i
        simp [closeMany, closeOperand, hks]
      · simp [closeMany, closeOperand, hik]
    rw [hclose]
    exact hk
  have hall : ∀ s : Finset ι,
      dst.abstract (NaryConcreteOp.lift f (closeMany s)) =
        dst.abstract (NaryConcreteOp.lift f xs) := by
    intro s
    induction s using Finset.induction with
    | empty => rfl
    | @insert k s hks ih => exact (hstep s k hks).trans ih
  simpa [closeMany] using hall Finset.univ

end NaryCompleteness

namespace ConcreteOp

variable {C : Type u} {D : Type v}

/-- Regard a unary operation as a one-operand instance of the canonical n-ary
semantics. -/
def asNary (f : ConcreteOp C D) :
    NaryConcreteOp (Fin 1) (fun _ ↦ C) D :=
  fun x ↦ f (x 0)

@[simp]
theorem nary_lift_asNary (f : ConcreteOp C D)
    (xs : Fin 1 → Set C) :
    NaryConcreteOp.lift (asNary f) xs = lift f (xs 0) := by
  ext y
  constructor
  · rintro ⟨x, hx, hy⟩
    exact ⟨x 0, hx 0, hy⟩
  · rintro ⟨x, hx, hy⟩
    refine ⟨fun _ ↦ x, ?_, hy⟩
    intro i
    simpa [Fin.eq_zero i] using hx

end ConcreteOp

/-- The unary completeness API is exactly the one-operand specialization of
the canonical n-ary definitions. -/
theorem forwardComplete_iff_nary
    {C : Type u} {D : Type v} {AC AD : Type*}
    [PartialOrder AC] [PartialOrder AD]
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) :
    ForwardComplete src dst f ↔
      NaryForwardComplete (fun _ : Fin 1 ↦ src) dst f.asNary := by
  constructor
  · intro h a
    simpa [bestNaryTransformer, bestTransformer] using h (a 0)
  · intro h a
    simpa [bestNaryTransformer, bestTransformer] using h (fun _ ↦ a)

/-- Unary backward completeness is exactly one-operand n-ary backward
completeness. -/
theorem backwardComplete_iff_nary
    {C : Type u} {D : Type v} {AC AD : Type*}
    [PartialOrder AC] [PartialOrder AD]
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) :
    BackwardComplete src dst f ↔
      NaryBackwardComplete (fun _ : Fin 1 ↦ src) dst f.asNary := by
  constructor
  · intro h xs
    simpa [bestTransformer, AbstractDomain.closure] using h (xs 0)
  · intro h xs
    simpa [bestTransformer, AbstractDomain.closure] using h (fun _ ↦ xs)

/-- A relational concrete operation with two operands. -/
abbrev BinaryConcreteOp (C : Type u) (D : Type v) (E : Type w) :=
  C → D → Set E

/-- The two indices used by the homogeneous binary façade. -/
abbrev BinaryOperand : Type := Fin 2

namespace BinaryOperand

/-- Index of the left operand. -/
abbrev left : BinaryOperand := 0

/-- Index of the right operand. -/
abbrev right : BinaryOperand := 1

theorem eq_left_or_right (operand : BinaryOperand) :
    operand = left ∨ operand = right := by
  have hle : operand.val ≤ 1 := Nat.le_of_lt_succ operand.isLt
  rcases Nat.le_one_iff_eq_zero_or_eq_one.mp hle with h | h
  · exact Or.inl (Fin.ext h)
  · exact Or.inr (Fin.ext h)

end BinaryOperand

namespace BinaryConcreteOp

variable {C : Type u} {D : Type v} {E : Type w}

/-- Collect the results obtained from the Cartesian product `xs ×ˢ ys`. -/
def lift (f : BinaryConcreteOp C D E) (xs : Set C) (ys : Set D) : Set E :=
  {z | ∃ x ∈ xs, ∃ y ∈ ys, z ∈ f x y}

/-- Embed a total binary function in relational semantics. -/
def ofTotal (f : C → D → E) : BinaryConcreteOp C D E :=
  fun x y ↦ {f x y}

/-- Embed an `Option`-valued partial binary function in relational semantics.
An undefined input pair produces no result. -/
def ofOption (f : C → D → Option E) : BinaryConcreteOp C D E :=
  fun x y ↦ {z | f x y = some z}

@[simp]
theorem mem_ofTotal {f : C → D → E} {x : C} {y : D} {z : E} :
    z ∈ ofTotal f x y ↔ z = f x y :=
  Set.mem_singleton_iff

@[simp]
theorem mem_ofOption {f : C → D → Option E}
    {x : C} {y : D} {z : E} :
    z ∈ ofOption f x y ↔ f x y = some z :=
  Iff.rfl

/-- Regard a homogeneous binary operation as a two-operand instance of the
canonical n-ary semantics. -/
def asNary (f : BinaryConcreteOp C C E) :
    NaryConcreteOp BinaryOperand (fun _ ↦ C) E :=
  fun x ↦ f (x BinaryOperand.left) (x BinaryOperand.right)

@[simp]
theorem mem_lift {f : BinaryConcreteOp C D E} {xs : Set C} {ys : Set D}
    {z : E} :
    z ∈ lift f xs ys ↔ ∃ x ∈ xs, ∃ y ∈ ys, z ∈ f x y :=
  Iff.rfl

@[simp]
theorem lift_empty_left (f : BinaryConcreteOp C D E) (ys : Set D) :
    lift f ∅ ys = ∅ := by
  ext z
  simp [lift]

@[simp]
theorem lift_empty_right (f : BinaryConcreteOp C D E) (xs : Set C) :
    lift f xs ∅ = ∅ := by
  ext z
  simp [lift]

theorem lift_mono (f : BinaryConcreteOp C D E) {xs xs' : Set C}
    {ys ys' : Set D} (hx : xs ⊆ xs') (hy : ys ⊆ ys') :
    lift f xs ys ⊆ lift f xs' ys' := by
  rintro z ⟨x, hxs, y, hys, hz⟩
  exact ⟨x, hx hxs, y, hy hys, hz⟩

@[simp]
theorem lift_ofTotal (f : C → D → E) (xs : Set C) (ys : Set D) :
    lift (ofTotal f) xs ys = {z | ∃ x ∈ xs, ∃ y ∈ ys, f x y = z} := by
  ext z
  constructor
  · rintro ⟨x, hxs, y, hys, hz⟩
    exact ⟨x, hxs, y, hys, hz.symm⟩
  · rintro ⟨x, hxs, y, hys, hz⟩
    exact ⟨x, hxs, y, hys, hz.symm⟩

@[simp]
theorem ofOption_none {f : C → D → Option E} {x : C} {y : D}
    (h : f x y = none) : ofOption f x y = ∅ := by
  ext z
  simp [ofOption, h]

@[simp]
theorem ofOption_some {f : C → D → Option E} {x : C} {y : D} {z : E}
    (h : f x y = some z) : ofOption f x y = {z} := by
  ext z'
  simp [ofOption, h]

theorem lift_ofOption_eq_empty {f : C → D → Option E}
    {xs : Set C} {ys : Set D}
    (h : ∀ x ∈ xs, ∀ y ∈ ys, f x y = none) :
    lift (ofOption f) xs ys = ∅ := by
  ext z
  simp only [mem_lift, Set.mem_empty_iff_false, iff_false]
  rintro ⟨x, hxs, y, hys, hresult⟩
  simp [ofOption, h x hxs y hys] at hresult

@[simp]
theorem nary_lift_asNary (f : BinaryConcreteOp C C E)
    (xs : BinaryOperand → Set C) :
    NaryConcreteOp.lift (asNary f) xs =
      lift f (xs BinaryOperand.left) (xs BinaryOperand.right) := by
  ext z
  constructor
  · rintro ⟨x, hx, hz⟩
    exact ⟨x 0, hx 0, x 1, hx 1, hz⟩
  · rintro ⟨x, hx, y, hy, hz⟩
    let args : BinaryOperand → C := fun i ↦ Fin.cases x (fun _ ↦ y) i
    have hargs0 : args 0 = x := rfl
    have hargs1 : args 1 = y := rfl
    refine ⟨args, ?_, ?_⟩
    · intro i
      have hi : i = 0 ∨ i = 1 := by
        rcases Nat.le_one_iff_eq_zero_or_eq_one.mp
            (Nat.le_of_lt_succ i.isLt) with hi | hi
        · exact Or.inl (Fin.ext hi)
        · exact Or.inr (Fin.ext hi)
      rcases hi with rfl | rfl
      · simpa [hargs0] using hx
      · simpa [hargs1] using hy
    · change z ∈ f (args 0) (args 1)
      simpa [hargs0, hargs1] using hz

end BinaryConcreteOp

section Completeness

variable {C : Type u} {D : Type v} {E : Type w}
variable {AC AD AE : Type*}
variable [PartialOrder AC] [PartialOrder AD] [PartialOrder AE]

/-- The most precise abstract transformer for a binary operation whose
operands vary independently. -/
def bestBinaryTransformer (lhs : AbstractDomain C AC)
    (rhs : AbstractDomain D AD) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C D E) : AC → AD → AE :=
  fun a b ↦ dst.abstract
    (BinaryConcreteOp.lift f (lhs.concretize a) (rhs.concretize b))

theorem bestBinaryTransformer_mono (lhs : AbstractDomain C AC)
    (rhs : AbstractDomain D AD) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C D E) {a a' : AC} {b b' : AD}
    (ha : a ≤ a') (hb : b ≤ b') :
    bestBinaryTransformer lhs rhs dst f a b ≤
      bestBinaryTransformer lhs rhs dst f a' b' :=
  dst.abstract_mono <| BinaryConcreteOp.lift_mono f
    (lhs.concretize_mono ha) (rhs.concretize_mono hb)

/-- Every result set over a Cartesian product of represented operands is
represented exactly by the destination domain. -/
def BinaryForwardComplete (lhs : AbstractDomain C AC)
    (rhs : AbstractDomain D AD) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C D E) : Prop :=
  ∀ a b, dst.concretize (bestBinaryTransformer lhs rhs dst f a b) =
    BinaryConcreteOp.lift f (lhs.concretize a) (rhs.concretize b)

/-- Independently abstracting both operands before applying `f` loses no
destination-domain information. -/
def BinaryBackwardComplete (lhs : AbstractDomain C AC)
    (rhs : AbstractDomain D AD) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C D E) : Prop :=
  ∀ xs ys,
    bestBinaryTransformer lhs rhs dst f (lhs.abstract xs) (rhs.abstract ys) =
      dst.abstract (BinaryConcreteOp.lift f xs ys)

/-- Abstracting only the left operand loses no destination-domain
information, while the right operand remains an arbitrary concrete set. -/
def BinaryBackwardCompleteInLeft (lhs : AbstractDomain C AC)
    (dst : AbstractDomain E AE) (f : BinaryConcreteOp C D E) : Prop :=
  ∀ xs ys,
    dst.abstract (BinaryConcreteOp.lift f (lhs.closure xs) ys) =
      dst.abstract (BinaryConcreteOp.lift f xs ys)

/-- Abstracting only the right operand loses no destination-domain
information, while the left operand remains an arbitrary concrete set. -/
def BinaryBackwardCompleteInRight (rhs : AbstractDomain D AD)
    (dst : AbstractDomain E AE) (f : BinaryConcreteOp C D E) : Prop :=
  ∀ xs ys,
    dst.abstract (BinaryConcreteOp.lift f xs (rhs.closure ys)) =
      dst.abstract (BinaryConcreteOp.lift f xs ys)

theorem binaryForwardComplete_iff_closure
    (lhs : AbstractDomain C AC) (rhs : AbstractDomain D AD)
    (dst : AbstractDomain E AE) (f : BinaryConcreteOp C D E) :
    BinaryForwardComplete lhs rhs dst f ↔
      ∀ xs ys,
        dst.closure (BinaryConcreteOp.lift f (lhs.closure xs) (rhs.closure ys)) =
          BinaryConcreteOp.lift f (lhs.closure xs) (rhs.closure ys) := by
  constructor
  · intro h xs ys
    simpa only [AbstractDomain.closure, bestBinaryTransformer] using
      h (lhs.abstract xs) (rhs.abstract ys)
  · intro h a b
    simpa only [AbstractDomain.closure, AbstractDomain.abstract_concretize,
      bestBinaryTransformer] using h (lhs.concretize a) (rhs.concretize b)

theorem binaryBackwardComplete_iff_closure
    (lhs : AbstractDomain C AC) (rhs : AbstractDomain D AD)
    (dst : AbstractDomain E AE) (f : BinaryConcreteOp C D E) :
    BinaryBackwardComplete lhs rhs dst f ↔
      ∀ xs ys,
        dst.closure (BinaryConcreteOp.lift f (lhs.closure xs) (rhs.closure ys)) =
          dst.closure (BinaryConcreteOp.lift f xs ys) := by
  constructor
  · intro h xs ys
    have := congrArg dst.concretize (h xs ys)
    simpa only [bestBinaryTransformer, AbstractDomain.closure] using this
  · intro h xs ys
    apply dst.insertion.injective
    simpa only [bestBinaryTransformer, AbstractDomain.closure] using h xs ys

theorem bestBinaryTransformer_eq_bot_of_undefined
    (lhs : AbstractDomain C AC) (rhs : AbstractDomain D AD)
    (dst : AbstractDomain E AE) [OrderBot AE]
    (f : C → D → Option E) (a : AC) (b : AD)
    (h : ∀ x ∈ lhs.concretize a, ∀ y ∈ rhs.concretize b,
      f x y = none) :
    bestBinaryTransformer lhs rhs dst (BinaryConcreteOp.ofOption f) a b = ⊥ := by
  simp only [bestBinaryTransformer, BinaryConcreteOp.lift_ofOption_eq_empty h]
  exact dst.abstract_empty

/-- For homogeneous operands, the binary forward-completeness API is exactly
the two-operand specialization of the canonical n-ary definition. -/
theorem binaryForwardComplete_iff_nary
    {C : Type u} {E : Type w} {AC AE : Type*}
    [PartialOrder AC] [PartialOrder AE]
    (src : AbstractDomain C AC) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C C E) :
    BinaryForwardComplete src src dst f ↔
      NaryForwardComplete (fun _ : BinaryOperand ↦ src) dst f.asNary := by
  constructor
  · intro h a
    simpa [bestNaryTransformer, bestBinaryTransformer] using h (a 0) (a 1)
  · intro h a b
    let args : BinaryOperand → AC := fun i ↦ Fin.cases a (fun _ ↦ b) i
    have hargs0 : args 0 = a := rfl
    have hargs1 : args 1 = b := rfl
    simpa [bestNaryTransformer, bestBinaryTransformer, hargs0, hargs1] using
      h args

/-- For homogeneous operands, the binary backward-completeness API is exactly
the two-operand specialization of the canonical n-ary definition. -/
theorem binaryBackwardComplete_iff_nary
    {C : Type u} {E : Type w} {AC AE : Type*}
    [PartialOrder AC] [PartialOrder AE]
    (src : AbstractDomain C AC) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C C E) :
    BinaryBackwardComplete src src dst f ↔
      NaryBackwardComplete (fun _ : BinaryOperand ↦ src) dst f.asNary := by
  constructor
  · intro h xs
    simpa [bestBinaryTransformer, AbstractDomain.closure] using
      h (xs 0) (xs 1)
  · intro h xs ys
    let operands : BinaryOperand → Set C :=
      fun i ↦ Fin.cases xs (fun _ ↦ ys) i
    have hoperands0 : operands 0 = xs := rfl
    have hoperands1 : operands 1 = ys := rfl
    simpa [bestBinaryTransformer, AbstractDomain.closure, hoperands0,
      hoperands1] using h operands

/-- The binary left-operand API is exactly n-ary backward completeness at the
left operand. It is retained as an ergonomic name for the planned
operand-by-operand classifications. -/
theorem binaryBackwardCompleteInLeft_iff_naryAt
    {C : Type u} {E : Type w} {AC AE : Type*}
    [PartialOrder AC] [PartialOrder AE]
    (src : AbstractDomain C AC) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C C E) :
    BinaryBackwardCompleteInLeft src dst f ↔
      NaryBackwardCompleteAt (fun _ : BinaryOperand ↦ src) dst f.asNary
        BinaryOperand.left := by
  constructor
  · intro h operands
    simpa [BinaryBackwardCompleteInLeft, NaryBackwardCompleteAt, closeOperand,
      BinaryOperand.left, BinaryOperand.right] using
      h (operands BinaryOperand.left) (operands BinaryOperand.right)
  · intro h xs ys
    let operands : BinaryOperand → Set C := fun i ↦
      if i = BinaryOperand.left then xs else ys
    have hcomplete := h operands
    simpa [NaryBackwardCompleteAt, closeOperand, operands,
      BinaryOperand.left, BinaryOperand.right] using hcomplete

/-- The binary right-operand API is exactly n-ary backward completeness at
the right operand. -/
theorem binaryBackwardCompleteInRight_iff_naryAt
    {C : Type u} {E : Type w} {AC AE : Type*}
    [PartialOrder AC] [PartialOrder AE]
    (src : AbstractDomain C AC) (dst : AbstractDomain E AE)
    (f : BinaryConcreteOp C C E) :
    BinaryBackwardCompleteInRight src dst f ↔
      NaryBackwardCompleteAt (fun _ : BinaryOperand ↦ src) dst f.asNary
        BinaryOperand.right := by
  constructor
  · intro h operands
    simpa [BinaryBackwardCompleteInRight, NaryBackwardCompleteAt, closeOperand,
      BinaryOperand.left, BinaryOperand.right] using
      h (operands BinaryOperand.left) (operands BinaryOperand.right)
  · intro h xs ys
    let operands : BinaryOperand → Set C := fun i ↦
      if i = BinaryOperand.left then xs else ys
    have hcomplete := h operands
    simpa [NaryBackwardCompleteAt, closeOperand, operands,
      BinaryOperand.left, BinaryOperand.right] using hcomplete

end Completeness

end SynthXfer
