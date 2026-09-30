import NeuralSpec.Model.Binary32
import NeuralSpec.Network.Xor.Native

/-!
# FloatLib binary32 reference inference

This uses the configured certified software backend, not the unchecked host-FPU
backend. It interprets the same forward program and the same parameter words as
native inference. Agreement with native arithmetic is a separate proof obligation.
-/

namespace NeuralSpec.Xor

open FloatLib.Floats

def floatLibParameter (index : Nat) : Binary32 :=
  ExecFloat.Binary.ofBits32 (parameterBits32 index)

def floatLibOps : ForwardOps Binary32 :=
  ⟨(· + ·), (· * ·), floatLibRelu⟩

def floatLibNetwork (x : Binary32 × Binary32) : Fin 2 → Binary32 :=
  forward floatLibOps floatLibParameter x

end NeuralSpec.Xor
