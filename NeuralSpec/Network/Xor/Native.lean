import NeuralSpec.Network.Xor.Forward
import NeuralSpec.Network.Xor.Parameters

/-! Native Float32 inference for the frozen checkpoint, using Lean's ordinary operations. -/

namespace NeuralSpec.Xor

def parameterBits32 (index : Nat) : UInt32 :=
  (Checkpoint.sourceBits32[index]?).getD 0

def nativeParameter (index : Nat) : Float32 :=
  Float32.ofBits (parameterBits32 index)

/-- ReLU propagates NaN, preserves positive values, and returns positive zero otherwise. -/
def nativeRelu (x : Float32) : Float32 :=
  if x.isNaN then x
  else if Float32.ofBits 0 < x then x else Float32.ofBits 0

def nativeOps : MLP.ScalarOps Float32 :=
  ⟨(· + ·), (· * ·), nativeRelu⟩

def nativeNetwork (x : Float32 × Float32) : Fin 2 → Float32 :=
  forward nativeOps nativeParameter x

end NeuralSpec.Xor
