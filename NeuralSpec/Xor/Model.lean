import NN.API.Macros
import NN.API.Seeded
import NN.API.Trainer.Constructor

namespace NeuralSpec.Xor

open TorchLean

/-- Two inputs, four ReLU units, two logits: 22 trainable parameters. -/
def model : nn.Builder (nn.Sequential [2] [2]) :=
  nn.Sequential![nn.linear 2 4, nn.relu, nn.linear 4 2]

def trainer (seed : Nat := 7) : TorchLean.Trainer [2] [2] :=
  Trainer.new model
    { objective := .meanSquaredError
      optimizer := optim.adam { learningRate := 0.03 }
      seed := seed
      execution := .typedGraph
      arithmetic := .native
      device := .cpu }

end NeuralSpec.Xor
