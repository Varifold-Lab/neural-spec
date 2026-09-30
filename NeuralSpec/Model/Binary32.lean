import FloatLib.Floats.Formats.IEEE754.Native
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Plan.Instances
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Instances
import FloatLib.Floats.ExecFloat.Instances

/-! Shared binary32 type and ReLU definition. No network, training, or project proofs. -/

namespace NeuralSpec

open FloatLib.Floats

abbrev Binary32 := ExecFloat.Binary 8 23

/-- ReLU propagates NaN, preserves positive values, and returns positive zero otherwise. -/
def floatLibRelu (x : Binary32) : Binary32 :=
  if ExecFloat.Binary.isNaN x then x
  else if ExecFloat.compareLess (ExecFloat.Binary.ofBits32 0) x then x
  else ExecFloat.Binary.ofBits32 0

end NeuralSpec
