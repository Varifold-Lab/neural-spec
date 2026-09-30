import NN.API.Data.Training

namespace NeuralSpec.Xor

open TorchLean

/-- A named numerical box; its exact-real counterpart is defined in `Verification.Xor.Spec`. -/
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

end NeuralSpec.Xor
