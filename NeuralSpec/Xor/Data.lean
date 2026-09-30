import NN.API.Data.Training

namespace NeuralSpec.Xor

open TorchLean

/-- A named numerical box; its exact-real counterpart is defined in `Spec.lean`. -/
structure Region where
  name : String
  highX : Bool
  highY : Bool

def regions : Array Region :=
  #[⟨"low-low", false, false⟩, ⟨"low-high", false, true⟩,
    ⟨"high-low", true, false⟩, ⟨"high-high", true, true⟩]

def Region.label (region : Region) : Nat :=
  if region.highX != region.highY then 1 else 0

def Region.center (region : Region) : Tensor Float [2] :=
  [if region.highX then 0.9 else 0.1, if region.highY then 0.9 else 0.1]

/-- A deterministic 3×3 grid in each box, interleaved by class: 36 training samples.
This finite dataset is training evidence, not a proof over the input boxes. -/
def samples : Array (Sample.Supervised Float [2] [2]) := Id.run do
  let mut result := #[]
  for i in [0:3] do
    for j in [0:3] do
      for region in regions do
        let x := (if region.highX then 0.8 else 0.0) + i.toFloat * 0.1
        let y := (if region.highY then 0.8 else 0.0) + j.toFloat * 0.1
        let target : Tensor Float [2] :=
          if region.label == 1 then [0.0, 1.0] else [1.0, 0.0]
        result := result.push { input := [x, y], target := target }
  return result

def dataset : Trainer.Dataset [2] [2] := Data.fromSamples samples

end NeuralSpec.Xor
