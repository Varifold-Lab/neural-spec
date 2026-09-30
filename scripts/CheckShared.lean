import NeuralSpec.Verification.Shared.FloatingError

-- Shared arithmetic proofs must be usable without importing the XOR example.
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
