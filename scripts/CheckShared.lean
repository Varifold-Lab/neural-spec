import NeuralSpec.Network.Architectures.MLP.Architecture
import NeuralSpec.Network.Architectures.MLP.ScalarOps
import NeuralSpec.Verification.Shared.Arithmetic.FloatingError
import NeuralSpec.Verification.Shared.Arithmetic.NewtonSchulz
import NeuralSpec.Verification.Shared.Arithmetic.NewtonSchulzCost
import NeuralSpec.Verification.Shared.Properties.Robustness.Margin

-- Generic architectures and shared proofs must not import the XOR example.
assert_not_exists NeuralSpec.Xor.model
assert_not_exists NeuralSpec.Xor.trainedNetwork
assert_not_exists NeuralSpec.Xor.floatLibNetwork
assert_not_exists NeuralSpec.Xor.Checkpoint.parameters
assert_not_exists NeuralSpec.Xor.XorSpec
assert_not_exists NeuralSpec.Xor.trainer
assert_not_exists NeuralSpec.NewtonSchulz.muonCoefficients
assert_not_exists NeuralSpec.NewtonSchulz.MuonIterationSpec
assert_not_exists NeuralSpec.NewtonSchulz.muonIteration_satisfies_spec
assert_not_exists NeuralSpec.NewtonSchulz.muon_not_tendsto_one

#check NeuralSpec.FloatingError.Approx
#check NeuralSpec.FloatingError.Approx.add
#check NeuralSpec.FloatingError.Approx.mul_parameter
#check NeuralSpec.FloatingError.Approx.relu
#check NeuralSpec.MLP.oneHiddenLayer
#check NeuralSpec.MLP.ScalarOps
#check NeuralSpec.Robustness.correct_of_margin
#check NeuralSpec.NewtonSchulz.matrixIterate_factorization
#check NeuralSpec.NewtonSchulz.matrixIterate_preserves_kernel
#check NeuralSpec.NewtonSchulz.exists_small_positive_input
#check NeuralSpec.NewtonSchulz.matrixStep_eq_expanded
#check NeuralSpec.NewtonSchulz.factoredStepMatmulFlops_saving
