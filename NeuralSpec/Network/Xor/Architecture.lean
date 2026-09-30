import NN.API.Macros
import NN.API.Seeded

/-! Network architecture only; optimizer and training settings live under Training. -/

namespace NeuralSpec.Xor

open TorchLean

/-- Two inputs, four ReLU units, two logits: 22 trainable parameters. -/
def model : nn.Builder (nn.Sequential [2] [2]) :=
  nn.Sequential![nn.linear 2 4, nn.relu, nn.linear 4 2]

end NeuralSpec.Xor
