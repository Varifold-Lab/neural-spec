import NN.API.Macros
import NN.API.Seeded

/-! Reusable MLP builders, independent of examples, training, and verification. -/

namespace NeuralSpec.MLP

open TorchLean

/-- An affine layer, coordinatewise ReLU, and an affine output layer. -/
def oneHiddenLayer (inputWidth hiddenWidth outputWidth : Nat) :
    nn.Builder (nn.Sequential [inputWidth] [outputWidth]) :=
  nn.Sequential![nn.linear inputWidth hiddenWidth, nn.relu, nn.linear hiddenWidth outputWidth]

end NeuralSpec.MLP
