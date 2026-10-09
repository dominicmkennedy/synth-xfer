import Mathlib.Order.GaloisConnection.Basic

/-!
# Abstract domains and completeness

This file develops the domain-independent part of the formalization. Concrete
operations have relational semantics, so the same definitions cover total,
partial, and nondeterministic operations.
-/

namespace SynthXfer

universe u v w

/-- An abstract domain presented as a Galois insertion into the powerset of its
concrete carrier. -/
structure AbstractDomain (C : Type u) (A : Type v) [PartialOrder A] where
  /-- The best abstraction of a concrete set. -/
  abstract : Set C → A
  /-- The concrete states represented by an abstract value. -/
  concretize : A → Set C
  /-- Abstraction and concretization form a Galois connection. -/
  gc : GaloisConnection abstract concretize
  /-- Every abstract value is the best abstraction of its concretization. -/
  insertion : Function.LeftInverse abstract concretize

namespace AbstractDomain

variable {C : Type u} {A : Type v} [PartialOrder A]

@[simp]
theorem abstract_concretize (d : AbstractDomain C A) (a : A) :
    d.abstract (d.concretize a) = a :=
  d.insertion a

theorem subset_concretize_abstract (d : AbstractDomain C A) (s : Set C) :
    s ⊆ d.concretize (d.abstract s) :=
  d.gc.le_u_l s

theorem abstract_mono (d : AbstractDomain C A) : Monotone d.abstract :=
  d.gc.monotone_l

theorem concretize_mono (d : AbstractDomain C A) : Monotone d.concretize :=
  d.gc.monotone_u

/-- The closure of a concrete set induced by an abstract domain. -/
def closure (d : AbstractDomain C A) (s : Set C) : Set C :=
  d.concretize (d.abstract s)

theorem subset_closure (d : AbstractDomain C A) (s : Set C) :
    s ⊆ d.closure s :=
  d.subset_concretize_abstract s

theorem closure_mono (d : AbstractDomain C A) : Monotone d.closure :=
  d.concretize_mono.comp d.abstract_mono

@[simp]
theorem closure_idempotent (d : AbstractDomain C A) (s : Set C) :
    d.closure (d.closure s) = d.closure s := by
  simp [closure]

@[simp]
theorem closure_concretize (d : AbstractDomain C A) (a : A) :
    d.closure (d.concretize a) = d.concretize a := by
  simp [closure]

@[simp]
theorem abstract_empty (d : AbstractDomain C A) [OrderBot A] :
    d.abstract ∅ = ⊥ := by
  apply le_antisymm
  · exact (d.gc ∅ ⊥).2 (Set.empty_subset _)
  · exact bot_le

/-- Transport the concrete carrier of an abstract domain along an equivalence. -/
def comapEquiv {D : Type*} (d : AbstractDomain D A) (e : C ≃ D) :
    AbstractDomain C A where
  abstract s := d.abstract (e '' s)
  concretize a := e ⁻¹' d.concretize a
  gc s a := (d.gc (e '' s) a).trans Set.image_subset_iff
  insertion a := by
    have himage : e '' (e ⁻¹' d.concretize a) = d.concretize a := by
      ext y
      constructor
      · rintro ⟨x, hx, rfl⟩
        exact hx
      · intro hy
        exact ⟨e.symm y, by simpa, by simp⟩
    change d.abstract (e '' (e ⁻¹' d.concretize a)) = a
    rw [himage]
    exact d.insertion a

@[simp]
theorem comapEquiv_abstract {D : Type*} (d : AbstractDomain D A) (e : C ≃ D)
    (s : Set C) : (d.comapEquiv e).abstract s = d.abstract (e '' s) :=
  rfl

@[simp]
theorem comapEquiv_concretize {D : Type*} (d : AbstractDomain D A) (e : C ≃ D)
    (a : A) : (d.comapEquiv e).concretize a = e ⁻¹' d.concretize a :=
  rfl

/-- Transport a unary total operation along equivalences of its source and
destination concrete carriers. -/
def transportUnary {C' D D' : Type*} (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : C → D) : C' → D' :=
  fun x ↦ dstEquiv (f (srcEquiv.symm x))

theorem transportUnary_image {C' D D' : Type*} (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : C → D) (s : Set C') :
    dstEquiv '' (f '' (srcEquiv ⁻¹' s)) =
      transportUnary srcEquiv dstEquiv f '' s := by
  ext y
  constructor
  · rintro ⟨_, ⟨x, hx, rfl⟩, rfl⟩
    exact ⟨srcEquiv x, hx, by simp [transportUnary]⟩
  · rintro ⟨x, hx, rfl⟩
    exact ⟨f (srcEquiv.symm x),
      ⟨srcEquiv.symm x, by simpa, rfl⟩, by simp [transportUnary]⟩

theorem preimage_transportUnary_image {C' D D' : Type*}
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : C → D) (s : Set C') :
    dstEquiv ⁻¹' (transportUnary srcEquiv dstEquiv f '' s) =
      f '' (srcEquiv ⁻¹' s) := by
  rw [← transportUnary_image srcEquiv dstEquiv f s]
  exact Set.preimage_image_eq _ dstEquiv.injective

theorem transportUnary_image_image {C' D D' : Type*}
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : C → D) (s : Set C) :
    dstEquiv '' (f '' s) =
      transportUnary srcEquiv dstEquiv f '' (srcEquiv '' s) := by
  rw [← transportUnary_image srcEquiv dstEquiv f (srcEquiv '' s)]
  rw [Set.preimage_image_eq _ srcEquiv.injective]

end AbstractDomain

/-- A concrete operation with relational semantics. `f x` is the set of
results produced from `x`. -/
abbrev ConcreteOp (C : Type u) (D : Type v) := C → Set D

namespace ConcreteOp

variable {C : Type u} {D : Type v} {E : Type w}

/-- Collect all results of an operation over a set of inputs. -/
def lift (f : ConcreteOp C D) (s : Set C) : Set D :=
  {y | ∃ x ∈ s, y ∈ f x}

/-- Relational composition. In `f.comp g`, `g` executes first. -/
def comp (f : ConcreteOp D E) (g : ConcreteOp C D) : ConcreteOp C E :=
  fun x ↦ lift f (g x)

/-- Embed a total function in relational semantics. -/
def ofTotal (f : C → D) : ConcreteOp C D :=
  fun x ↦ {f x}

/-- Embed an `Option`-valued partial function in relational semantics.
Undefined inputs produce no result. -/
def ofOption (f : C → Option D) : ConcreteOp C D :=
  fun x ↦ {y | f x = some y}

@[simp]
theorem mem_ofTotal {f : C → D} {x : C} {y : D} :
    y ∈ ofTotal f x ↔ y = f x :=
  Set.mem_singleton_iff

@[simp]
theorem mem_ofOption {f : C → Option D} {x : C} {y : D} :
    y ∈ ofOption f x ↔ f x = some y :=
  Iff.rfl

/-- Transport a relational operation along equivalences of its source and
destination carriers. -/
def transport {C' D' : Type*} (srcEquiv : C ≃ C') (dstEquiv : D ≃ D')
    (f : ConcreteOp C D) : ConcreteOp C' D' :=
  fun x ↦ dstEquiv '' f (srcEquiv.symm x)

@[simp]
theorem mem_lift {f : ConcreteOp C D} {s : Set C} {y : D} :
    y ∈ lift f s ↔ ∃ x ∈ s, y ∈ f x :=
  Iff.rfl

@[simp]
theorem lift_empty (f : ConcreteOp C D) : lift f ∅ = ∅ := by
  ext y
  simp [lift]

theorem lift_mono (f : ConcreteOp C D) : Monotone (lift f) := by
  intro s t hst y hy
  obtain ⟨x, hxs, hyfx⟩ := hy
  exact ⟨x, hst hxs, hyfx⟩

@[simp]
theorem lift_comp (f : ConcreteOp D E) (g : ConcreteOp C D) (s : Set C) :
    lift (f.comp g) s = lift f (lift g s) := by
  ext z
  simp only [mem_lift, comp]
  constructor
  · rintro ⟨x, hxs, y, hygx, hzfy⟩
    exact ⟨y, ⟨x, hxs, hygx⟩, hzfy⟩
  · rintro ⟨y, ⟨x, hxs, hygx⟩, hzfy⟩
    exact ⟨x, hxs, y, hygx, hzfy⟩

@[simp]
theorem lift_ofTotal (f : C → D) (s : Set C) :
    lift (ofTotal f) s = f '' s := by
  ext y
  constructor
  · rintro ⟨x, hxs, hxy⟩
    exact ⟨x, hxs, hxy.symm⟩
  · rintro ⟨x, hxs, hxy⟩
    exact ⟨x, hxs, hxy.symm⟩

@[simp]
theorem ofOption_none {f : C → Option D} {x : C} (h : f x = none) :
    ofOption f x = ∅ := by
  ext y
  simp [ofOption, h]

@[simp]
theorem ofOption_some {f : C → Option D} {x : C} {y : D}
    (h : f x = some y) : ofOption f x = {y} := by
  ext z
  simp [ofOption, h]

theorem lift_ofOption_eq_empty {f : C → Option D} {s : Set C}
    (h : ∀ x ∈ s, f x = none) : lift (ofOption f) s = ∅ := by
  ext y
  simp only [mem_lift, Set.mem_empty_iff_false, iff_false]
  rintro ⟨x, hxs, hresult⟩
  simp [ofOption, h x hxs] at hresult

theorem lift_transport {C' D' : Type*} (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : ConcreteOp C D) (s : Set C') :
    lift (transport srcEquiv dstEquiv f) s =
      dstEquiv '' lift f (srcEquiv ⁻¹' s) := by
  ext y
  constructor
  · rintro ⟨x, hx, z, hz, rfl⟩
    exact ⟨z, ⟨srcEquiv.symm x, by simpa, hz⟩, rfl⟩
  · rintro ⟨z, ⟨x, hx, hz⟩, rfl⟩
    exact ⟨srcEquiv x, by simpa, z, by simpa, rfl⟩

theorem lift_transport_image {C' D' : Type*} (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : ConcreteOp C D) (s : Set C) :
    lift (transport srcEquiv dstEquiv f) (srcEquiv '' s) =
      dstEquiv '' lift f s := by
  rw [lift_transport, Set.preimage_image_eq _ srcEquiv.injective]

end ConcreteOp

section Completeness

variable {C : Type u} {D : Type v} {E : Type w}
variable {AC : Type*} {AD : Type*} {AE : Type*}
variable [PartialOrder AC] [PartialOrder AD] [PartialOrder AE]

/-- The most precise abstract transformer for a concrete operation. -/
def bestTransformer (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) : AC → AD :=
  fun a ↦ dst.abstract (ConcreteOp.lift f (src.concretize a))

theorem bestTransformer_mono (src : AbstractDomain C AC)
    (dst : AbstractDomain D AD) (f : ConcreteOp C D) :
    Monotone (bestTransformer src dst f) :=
  dst.abstract_mono.comp (ConcreteOp.lift_mono f |>.comp src.concretize_mono)

/-- Applying `f` to a represented concrete set always produces another set
represented exactly by the destination domain. -/
def ForwardComplete (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) : Prop :=
  ∀ a, dst.concretize (bestTransformer src dst f a) =
    ConcreteOp.lift f (src.concretize a)

/-- Abstracting an input before applying `f` loses no destination-domain
information about its result. -/
def BackwardComplete (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) : Prop :=
  ∀ s, bestTransformer src dst f (src.abstract s) =
    dst.abstract (ConcreteOp.lift f s)

theorem forwardComplete_iff_closure
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) :
    ForwardComplete src dst f ↔
      ∀ s, dst.closure (ConcreteOp.lift f (src.closure s)) =
        ConcreteOp.lift f (src.closure s) := by
  constructor
  · intro h s
    simpa only [AbstractDomain.closure, bestTransformer] using h (src.abstract s)
  · intro h a
    simpa only [AbstractDomain.closure, AbstractDomain.abstract_concretize,
      bestTransformer] using h (src.concretize a)

theorem backwardComplete_iff_closure
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) :
    BackwardComplete src dst f ↔
      ∀ s, dst.closure (ConcreteOp.lift f (src.closure s)) =
        dst.closure (ConcreteOp.lift f s) := by
  constructor
  · intro h s
    have := congrArg dst.concretize (h s)
    simpa only [bestTransformer, AbstractDomain.closure] using this
  · intro h s
    apply dst.insertion.injective
    simpa only [bestTransformer, AbstractDomain.closure] using h s

/-- A concrete member added by destination closure is a checkable witness that
forward completeness fails. -/
theorem forwardIncomplete_of_witness
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) (s : Set C) (y : D)
    (hyClosed : y ∈ dst.closure
      (ConcreteOp.lift f (src.closure s)))
    (hyMissing : y ∉ ConcreteOp.lift f (src.closure s)) :
    ¬ ForwardComplete src dst f := by
  intro hcomplete
  have hEq := (forwardComplete_iff_closure src dst f).mp hcomplete s
  exact hyMissing (hEq ▸ hyClosed)

/-- A result distinguished after closing the source but not before it is a
checkable witness that backward completeness fails. -/
theorem backwardIncomplete_of_witness
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD)
    (f : ConcreteOp C D) (s : Set C) (y : D)
    (hyClosedInput : y ∈ dst.closure
      (ConcreteOp.lift f (src.closure s)))
    (hyOriginal : y ∉ dst.closure (ConcreteOp.lift f s)) :
    ¬ BackwardComplete src dst f := by
  intro hcomplete
  have hEq := (backwardComplete_iff_closure src dst f).mp hcomplete s
  exact hyOriginal (hEq ▸ hyClosedInput)

/-- Relational forward completeness is unchanged when the concrete source and
destination carriers are replaced by equivalent representations. -/
theorem forwardComplete_transport_iff
    {C' D' : Type*} (src : AbstractDomain C' AC)
    (dst : AbstractDomain D' AD) (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : ConcreteOp C D) :
    ForwardComplete (src.comapEquiv srcEquiv) (dst.comapEquiv dstEquiv) f ↔
      ForwardComplete src dst
        (ConcreteOp.transport srcEquiv dstEquiv f) := by
  constructor
  · intro hcomplete a
    have hEq := hcomplete a
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' ConcreteOp.lift f
          (srcEquiv ⁻¹' src.concretize a))) =
      ConcreteOp.lift f (srcEquiv ⁻¹' src.concretize a) at hEq
    change dst.concretize (dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f) (src.concretize a))) =
      ConcreteOp.lift (ConcreteOp.transport srcEquiv dstEquiv f)
        (src.concretize a)
    rw [ConcreteOp.lift_transport]
    apply dstEquiv.surjective.preimage_injective
    simpa using hEq
  · intro hcomplete a
    have hEq := hcomplete a
    change dst.concretize (dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f) (src.concretize a))) =
      ConcreteOp.lift (ConcreteOp.transport srcEquiv dstEquiv f)
        (src.concretize a) at hEq
    change dstEquiv ⁻¹' dst.concretize (dst.abstract
        (dstEquiv '' ConcreteOp.lift f
          (srcEquiv ⁻¹' src.concretize a))) =
      ConcreteOp.lift f (srcEquiv ⁻¹' src.concretize a)
    rw [ConcreteOp.lift_transport] at hEq
    rw [hEq]
    exact Set.preimage_image_eq _ dstEquiv.injective

/-- Relational backward completeness is unchanged when the concrete source
and destination carriers are replaced by equivalent representations. -/
theorem backwardComplete_transport_iff
    {C' D' : Type*} (src : AbstractDomain C' AC)
    (dst : AbstractDomain D' AD) (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : ConcreteOp C D) :
    BackwardComplete (src.comapEquiv srcEquiv) (dst.comapEquiv dstEquiv) f ↔
      BackwardComplete src dst
        (ConcreteOp.transport srcEquiv dstEquiv f) := by
  constructor
  · intro hcomplete t
    let s : Set C := srcEquiv.symm '' t
    have hEq := hcomplete s
    change dst.abstract (dstEquiv '' ConcreteOp.lift f
        (srcEquiv ⁻¹' src.concretize (src.abstract (srcEquiv '' s)))) =
      dst.abstract (dstEquiv '' ConcreteOp.lift f s) at hEq
    rw [← ConcreteOp.lift_transport srcEquiv dstEquiv f,
      ← ConcreteOp.lift_transport_image srcEquiv dstEquiv f s] at hEq
    change dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f)
          (src.concretize (src.abstract t))) =
      dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f) t)
    simpa [s] using hEq
  · intro hcomplete s
    have hEq := hcomplete (srcEquiv '' s)
    change dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f)
          (src.concretize (src.abstract (srcEquiv '' s)))) =
      dst.abstract (ConcreteOp.lift
        (ConcreteOp.transport srcEquiv dstEquiv f) (srcEquiv '' s)) at hEq
    change dst.abstract (dstEquiv '' ConcreteOp.lift f
        (srcEquiv ⁻¹' src.concretize (src.abstract (srcEquiv '' s)))) =
      dst.abstract (dstEquiv '' ConcreteOp.lift f s)
    rw [← ConcreteOp.lift_transport srcEquiv dstEquiv f,
      ← ConcreteOp.lift_transport_image srcEquiv dstEquiv f s]
    exact hEq

/-- Unary total forward completeness is invariant under equivalences of both
concrete carriers. -/
theorem forwardComplete_transportTotal_iff
    {C' D' : Type*} (src : AbstractDomain C' AC)
    (dst : AbstractDomain D' AD) (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : C → D) :
    ForwardComplete (src.comapEquiv srcEquiv) (dst.comapEquiv dstEquiv)
        (ConcreteOp.ofTotal f) ↔
      ForwardComplete src dst
        (ConcreteOp.ofTotal
          (AbstractDomain.transportUnary srcEquiv dstEquiv f)) := by
  constructor
  · intro hcomplete a
    have hEq := hcomplete a
    simp only [bestTransformer, ConcreteOp.lift_ofTotal] at hEq ⊢
    change dstEquiv ⁻¹' dst.concretize
        (dst.abstract (dstEquiv ''
          (f '' (srcEquiv ⁻¹' src.concretize a)))) =
      f '' (srcEquiv ⁻¹' src.concretize a) at hEq
    apply dstEquiv.surjective.preimage_injective
    change dstEquiv ⁻¹' dst.concretize
        (dst.abstract
          (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
            src.concretize a)) =
      dstEquiv ⁻¹'
        (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
          src.concretize a)
    rw [AbstractDomain.preimage_transportUnary_image]
    rw [← AbstractDomain.transportUnary_image]
    exact hEq
  · intro hcomplete a
    have hEq := hcomplete a
    simp only [bestTransformer, ConcreteOp.lift_ofTotal] at hEq ⊢
    change dst.concretize
        (dst.abstract
          (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
            src.concretize a)) =
      AbstractDomain.transportUnary srcEquiv dstEquiv f ''
        src.concretize a at hEq
    change dstEquiv ⁻¹' dst.concretize
        (dst.abstract (dstEquiv ''
          (f '' (srcEquiv ⁻¹' src.concretize a)))) =
      f '' (srcEquiv ⁻¹' src.concretize a)
    rw [AbstractDomain.transportUnary_image]
    rw [hEq]
    exact AbstractDomain.preimage_transportUnary_image
      srcEquiv dstEquiv f (src.concretize a)

/-- Unary total backward completeness is invariant under equivalences of both
concrete carriers. -/
theorem backwardComplete_transportTotal_iff
    {C' D' : Type*} (src : AbstractDomain C' AC)
    (dst : AbstractDomain D' AD) (srcEquiv : C ≃ C')
    (dstEquiv : D ≃ D') (f : C → D) :
    BackwardComplete (src.comapEquiv srcEquiv) (dst.comapEquiv dstEquiv)
        (ConcreteOp.ofTotal f) ↔
      BackwardComplete src dst
        (ConcreteOp.ofTotal
          (AbstractDomain.transportUnary srcEquiv dstEquiv f)) := by
  constructor
  · intro hcomplete t
    let s : Set C := srcEquiv.symm '' t
    have hEq := hcomplete s
    simp only [bestTransformer, ConcreteOp.lift_ofTotal] at hEq ⊢
    change dst.abstract (dstEquiv ''
        (f '' (srcEquiv ⁻¹'
          src.concretize (src.abstract (srcEquiv '' s))))) =
      dst.abstract (dstEquiv '' (f '' s)) at hEq
    rw [AbstractDomain.transportUnary_image srcEquiv dstEquiv f
        (src.concretize (src.abstract (srcEquiv '' s))),
      AbstractDomain.transportUnary_image_image srcEquiv dstEquiv f s] at hEq
    change dst.abstract
        (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
          src.concretize (src.abstract t)) =
      dst.abstract
        (AbstractDomain.transportUnary srcEquiv dstEquiv f '' t)
    simpa [s] using hEq
  · intro hcomplete s
    have hEq := hcomplete (srcEquiv '' s)
    simp only [bestTransformer, ConcreteOp.lift_ofTotal] at hEq ⊢
    change dst.abstract
        (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
          src.concretize (src.abstract (srcEquiv '' s))) =
      dst.abstract
        (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
          (srcEquiv '' s)) at hEq
    change dst.abstract (dstEquiv ''
        (f '' (srcEquiv ⁻¹'
          src.concretize (src.abstract (srcEquiv '' s))))) =
      dst.abstract (dstEquiv '' (f '' s))
    rw [AbstractDomain.transportUnary_image srcEquiv dstEquiv f
        (src.concretize (src.abstract (srcEquiv '' s))),
      AbstractDomain.transportUnary_image_image srcEquiv dstEquiv f s]
    exact hEq

theorem sequential_eq_composite_of_forward
    (src : AbstractDomain C AC) (mid : AbstractDomain D AD)
    (dst : AbstractDomain E AE) (g : ConcreteOp C D) (f : ConcreteOp D E)
    (hg : ForwardComplete src mid g) :
    (bestTransformer mid dst f) ∘ (bestTransformer src mid g) =
      bestTransformer src dst (f.comp g) := by
  funext a
  simp only [Function.comp_apply, bestTransformer]
  have hg' := hg a
  simp only [bestTransformer] at hg'
  rw [hg', ConcreteOp.lift_comp]

theorem sequential_eq_composite_of_backward
    (src : AbstractDomain C AC) (mid : AbstractDomain D AD)
    (dst : AbstractDomain E AE) (g : ConcreteOp C D) (f : ConcreteOp D E)
    (hf : BackwardComplete mid dst f) :
    (bestTransformer mid dst f) ∘ (bestTransformer src mid g) =
      bestTransformer src dst (f.comp g) := by
  funext a
  change bestTransformer mid dst f
      (mid.abstract (ConcreteOp.lift g (src.concretize a))) = _
  rw [hf, bestTransformer, ConcreteOp.lift_comp]

theorem bestTransformer_eq_bot_of_undefined
    (src : AbstractDomain C AC) (dst : AbstractDomain D AD) [OrderBot AD]
    (f : C → Option D) (a : AC)
    (h : ∀ x ∈ src.concretize a, f x = none) :
    bestTransformer src dst (ConcreteOp.ofOption f) a = ⊥ := by
  simp only [bestTransformer, ConcreteOp.lift_ofOption_eq_empty h]
  exact dst.abstract_empty

end Completeness

end SynthXfer
