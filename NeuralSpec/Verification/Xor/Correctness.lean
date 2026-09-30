import NeuralSpec.Network.Xor.Real
import NeuralSpec.Verification.Xor.Spec
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.SplitIfs

/-!
# The trained network satisfies the XOR specification

There is no hypothesis assuming any safety property of the trained network.
We consider all four input regions and every ReLU activation pattern. In each
case the goal is a rational linear inequality, discharged by `linarith`.
All arithmetic and the resulting proof terms are checked by the Lean kernel.
-/

namespace NeuralSpec.Xor.Checkpoint

/-- Mathematical decoding of a finite IEEE binary64 word; invalid words are rejected.
This definition uses only exact integers and rationals, never native Float operations. -/
def decodeBinary64 (bits : Nat) : Option ℚ :=
  if bits ≥ 2 ^ 64 then none else
  let exponent : Nat := bits / 2 ^ 52 % 2 ^ 11
  let fraction : Nat := bits % 2 ^ 52
  if exponent = 2047 then none else
  let significand : Nat := if exponent = 0 then fraction else 2 ^ 52 + fraction
  let magnitude : ℚ :=
    if exponent = 0 then (significand : ℚ) / (2 : ℚ) ^ 1074
    else if exponent ≤ 1075 then (significand : ℚ) / (2 : ℚ) ^ (1075 - exponent)
    else (significand : ℚ) * (2 : ℚ) ^ (exponent - 1075)
  some (if bits / 2 ^ 63 = 0 then magnitude else -magnitude)

set_option maxRecDepth 4096 in
set_option maxHeartbeats 800000 in
/-- Kernel-checked equality between every stored bit pattern and its rational value. -/
theorem parameters_match_source_bits :
    sourceBits.map decodeBinary64 = parameters.map some := by
  norm_num [sourceBits, parameters, decodeBinary64, w1_00, w1_01, w1_10, w1_11, w1_20, w1_21, w1_30, w1_31, b1_0, b1_1, b1_2, b1_3, w2_00, w2_01, w2_02, w2_03, w2_10, w2_11, w2_12, w2_13, b2_0, b2_1]

end NeuralSpec.Xor.Checkpoint

namespace NeuralSpec.Xor

open Checkpoint

set_option maxHeartbeats 4000000 in
/-- A stronger exact-real margin leaves room for floating-point rounding error. -/
theorem trainedNetwork_margin_half :
    ∀ highX highY x, InRegion highX highY x →
      (1 / 2 : ℝ) ≤ margin trainedNetwork x (expectedLabel highX highY) := by
  intro highX highY x hx
  rcases x with ⟨x, y⟩
  cases highX <;> cases highY <;>
    simp only [InRegion, InBand, Bool.false_eq_true, ↓reduceIte] at hx <;>
    rcases hx with ⟨⟨hxlo, hxhi⟩, ⟨hylo, hyhi⟩⟩ <;>
    norm_num [margin, score, expectedLabel, trainedNetwork, pre0, pre1, pre2, pre3,
      w1_00, w1_01, w1_10, w1_11, w1_20, w1_21, w1_30, w1_31,
      b1_0, b1_1, b1_2, b1_3,
      w2_00, w2_01, w2_02, w2_03, w2_10, w2_11, w2_12, w2_13,
      b2_0, b2_1, max_def] <;>
    split_ifs <;> linarith

/-- Every real input in the four closed boxes has correct-class margin at least 1/4. -/
theorem trainedNetwork_satisfies_spec : XorSpec trainedNetwork := by
  intro highX highY x hx
  have h := trainedNetwork_margin_half highX highY x hx
  linarith

/-- Classification correctness for this specific trained network, with no spec premise. -/
theorem trainedNetwork_correct_label (highX highY : Bool) (x : Point)
    (hx : InRegion highX highY x) :
    score trainedNetwork x (!(expectedLabel highX highY)) <
      score trainedNetwork x (expectedLabel highX highY) :=
  trainedNetwork_satisfies_spec.correct_label highX highY x hx

end NeuralSpec.Xor
