import NeuralSpec.Model.Xor.Types
import NeuralSpec.Network.Xor.Parameters

/-!
# Exact-real interpretation of the trained 2 → 4 ReLU → 2 network

Every coefficient is the exact rational value of a parameter from the frozen
checkpoint. Affine maps and ReLU are evaluated over the reals, without rounding.
The matrix layout follows TorchLean's `[outputWidth, inputWidth]` convention.
-/

noncomputable section

namespace NeuralSpec.Xor

open Checkpoint

def pre0 (x : Point) : ℝ := (w1_00 : ℝ) * x.1 + (w1_01 : ℝ) * x.2 + (b1_0 : ℝ)
def pre1 (x : Point) : ℝ := (w1_10 : ℝ) * x.1 + (w1_11 : ℝ) * x.2 + (b1_1 : ℝ)
def pre2 (x : Point) : ℝ := (w1_20 : ℝ) * x.1 + (w1_21 : ℝ) * x.2 + (b1_2 : ℝ)
def pre3 (x : Point) : ℝ := (w1_30 : ℝ) * x.1 + (w1_31 : ℝ) * x.2 + (b1_3 : ℝ)

/-- The frozen trained network. Output 0 means same band; output 1 means different bands. -/
def trainedNetwork (x : Point) (label : Fin 2) : ℝ :=
  if label = 0 then
    (w2_00 : ℝ) * max 0 (pre0 x) + (w2_01 : ℝ) * max 0 (pre1 x) +
      (w2_02 : ℝ) * max 0 (pre2 x) + (w2_03 : ℝ) * max 0 (pre3 x) + (b2_0 : ℝ)
  else
    (w2_10 : ℝ) * max 0 (pre0 x) + (w2_11 : ℝ) * max 0 (pre1 x) +
      (w2_12 : ℝ) * max 0 (pre2 x) + (w2_13 : ℝ) * max 0 (pre3 x) + (b2_1 : ℝ)

end NeuralSpec.Xor
