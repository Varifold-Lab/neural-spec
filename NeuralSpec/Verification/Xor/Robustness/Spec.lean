import NeuralSpec.Model.Xor.Types
import NeuralSpec.Verification.Shared.Properties.Robustness.Margin
import Mathlib.Tactic.NormNum

/-! Exact-real specification of XOR on four closed input boxes. -/

namespace NeuralSpec.Xor

/-- `false` denotes the low band, `true` the high band. -/
def InBand (high : Bool) (x : ℝ) : Prop :=
  if high then 4 / 5 ≤ x ∧ x ≤ 1 else 0 ≤ x ∧ x ≤ 1 / 5

def InRegion (highX highY : Bool) (x : Point) : Prop :=
  InBand highX x.1 ∧ InBand highY x.2

def expectedLabel (highX highY : Bool) : Bool := highX != highY

def score (network : Network) (x : Point) (label : Bool) : ℝ :=
  network x (if label then 1 else 0)

def margin (network : Network) (x : Point) (label : Bool) : ℝ :=
  score network x label - score network x (!label)

/-- Every point in each box has the correct label with a margin of at least 1/4. -/
def XorSpec (network : Network) : Prop :=
  ∀ highX highY x, InRegion highX highY x →
    (1 / 4 : ℝ) ≤ margin network x (expectedLabel highX highY)

/-- The margin specification implies strict classification, without a tie-breaking rule. -/
theorem XorSpec.correct_label {network : Network} (h : XorSpec network)
    (highX highY : Bool) (x : Point) (hx : InRegion highX highY x) :
    score network x (!(expectedLabel highX highY)) <
      score network x (expectedLabel highX highY) := by
  have hm := h highX highY x hx
  unfold margin at hm
  exact Robustness.correct_of_margin (by norm_num) hm

end NeuralSpec.Xor
