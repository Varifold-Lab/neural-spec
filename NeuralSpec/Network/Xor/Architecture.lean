import NeuralSpec.Network.Architectures.MLP.Architecture

/-! Network architecture only; optimizer and training settings live under Training. -/

namespace NeuralSpec.Xor

open TorchLean

/-- Two inputs, four ReLU units, two logits: 22 trainable parameters. -/
def model : nn.Builder (nn.Sequential [2] [2]) :=
  MLP.oneHiddenLayer 2 4 2

end NeuralSpec.Xor
