import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.Linarith

/-! Exact-real margin consequences, independent of a network architecture or example. -/

namespace NeuralSpec.Robustness

/-- A positive lower margin bound makes the correct score strictly larger. -/
theorem correct_of_margin {correct other threshold : ℝ}
    (hpositive : 0 < threshold) (hmargin : threshold ≤ correct - other) :
    other < correct := by
  linarith

end NeuralSpec.Robustness
