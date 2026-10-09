import SynthXfer.Interval

/-!
# Arithmetic inside natural-number boxes
-/

namespace SynthXfer.NatBox

theorem exists_add
    {x₁ x₂ y₁ y₂ z : Nat}
    (hlower : x₁ + y₁ ≤ z) (hupper : z ≤ x₂ + y₂) :
    ∃ x y,
      min x₁ x₂ ≤ x ∧ x ≤ max x₁ x₂ ∧
      min y₁ y₂ ≤ y ∧ y ≤ max y₁ y₂ ∧ x + y = z := by
  have hlo : min x₁ x₂ + min y₁ y₂ ≤ z :=
    (Nat.add_le_add (min_le_left _ _) (min_le_left _ _)).trans hlower
  have hhi : z ≤ max x₁ x₂ + max y₁ y₂ :=
    hupper.trans (Nat.add_le_add (le_max_right _ _) (le_max_right _ _))
  by_cases hfirst : z ≤ max x₁ x₂ + min y₁ y₂
  · refine ⟨z - min y₁ y₂, min y₁ y₂, ?_⟩
    omega
  · refine ⟨max x₁ x₂, z - max x₁ x₂, ?_⟩
    omega

theorem exists_sub
    {x₁ x₂ y₁ y₂ z : Nat}
    (hy₂x₂ : y₂ ≤ x₂)
    (hlower : x₁ - y₁ ≤ z) (hupper : z ≤ x₂ - y₂) :
    ∃ x y,
      min x₁ x₂ ≤ x ∧ x ≤ max x₁ x₂ ∧
      min y₁ y₂ ≤ y ∧ y ≤ max y₁ y₂ ∧
      y ≤ x ∧ x - y = z := by
  have hlo : min x₁ x₂ ≤ z + max y₁ y₂ := by
    have hx₁Le : x₁ ≤ z + y₁ := Nat.sub_le_iff_le_add.mp hlower
    exact (min_le_left x₁ x₂).trans <|
      hx₁Le.trans (Nat.add_le_add_left (le_max_left y₁ y₂) z)
  have hhi : z + min y₁ y₂ ≤ max x₁ x₂ := by
    have hzAdd : z + y₂ ≤ x₂ := (Nat.le_sub_iff_add_le hy₂x₂).mp hupper
    exact (Nat.add_le_add_left (min_le_right y₁ y₂) z).trans <|
      hzAdd.trans (le_max_right x₁ x₂)
  by_cases hfirst : min x₁ x₂ ≤ z + min y₁ y₂
  · refine ⟨z + min y₁ y₂, min y₁ y₂, ?_⟩
    omega
  · refine ⟨min x₁ x₂, min x₁ x₂ - z, ?_⟩
    omega

end SynthXfer.NatBox
