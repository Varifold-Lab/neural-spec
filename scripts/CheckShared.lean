import NeuralSpec.Network.Architectures.MLP.Architecture
import NeuralSpec.Network.Architectures.MLP.ScalarOps
import NeuralSpec.Verification.Shared.Arithmetic.FloatingError
import NeuralSpec.Verification.Shared.Properties.Robustness.Margin

-- Generic architectures and shared proofs must not import the XOR example.
assert_not_exists NeuralSpec.Xor.model
assert_not_exists NeuralSpec.Xor.trainedNetwork
assert_not_exists NeuralSpec.Xor.floatLibNetwork
assert_not_exists NeuralSpec.Xor.Checkpoint.parameters
assert_not_exists NeuralSpec.Xor.XorSpec
assert_not_exists NeuralSpec.Xor.trainer

#check NeuralSpec.FloatingError.Approx
#check NeuralSpec.FloatingError.Approx.add
#check NeuralSpec.FloatingError.Approx.mul_parameter
#check NeuralSpec.FloatingError.Approx.relu
#check NeuralSpec.MLP.oneHiddenLayer
#check NeuralSpec.MLP.ScalarOps
#check NeuralSpec.Robustness.correct_of_margin
