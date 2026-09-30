import NeuralSpec.Network.Xor.Architecture
import NN.API.Trainer.Constructor

/-! Optimizer, initialization seed, arithmetic, and device configuration. -/

namespace NeuralSpec.Xor

open TorchLean

def trainer (seed : Nat := 7) : TorchLean.Trainer [2] [2] :=
  Trainer.new model
    { objective := .meanSquaredError
      optimizer := optim.adam { learningRate := 0.03 }
      seed := seed
      execution := .typedGraph
      arithmetic := .native
      device := .cpu }

end NeuralSpec.Xor
