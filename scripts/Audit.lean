import NeuralSpec

#print axioms NeuralSpec.Robustness.correct_of_margin
#print axioms NeuralSpec.Xor.Checkpoint.parameters_match_source_bits
#print axioms NeuralSpec.Xor.trainedNetwork_satisfies_spec
#print axioms NeuralSpec.Xor.trainedNetwork_correct_label

#print axioms NeuralSpec.Xor.floatLib_parameters_exact
#print axioms NeuralSpec.Xor.native_parameters_import_exact
#print axioms NeuralSpec.Xor.native_roundtrip
#print axioms NeuralSpec.Xor.floatLib_network_eq_operationSpec
#print axioms NeuralSpec.Xor.native_add_import
#print axioms NeuralSpec.Xor.forward_real_eq_trainedNetwork

#print axioms NeuralSpec.Xor.trainedNetwork_margin_half
#print axioms NeuralSpec.Xor.floatLibNetwork_error
#print axioms NeuralSpec.Xor.roundBinary32_input
#print axioms NeuralSpec.Xor.floatLibNetwork_satisfies_spec
#print axioms NeuralSpec.Xor.floatLibNetwork_margin_real
#print axioms NeuralSpec.Xor.floatLibNetwork_sub_margin
#print axioms NeuralSpec.Xor.floatLibNetwork_sub_margin_real

#print axioms NeuralSpec.NewtonSchulz.scalarIterate_zero
#print axioms NeuralSpec.NewtonSchulz.matrixIterate_zero
#print axioms NeuralSpec.NewtonSchulz.matrixIterate_transpose
#print axioms NeuralSpec.NewtonSchulz.matrixStep_factorization
#print axioms NeuralSpec.NewtonSchulz.matrixIterate_factorization
#print axioms NeuralSpec.NewtonSchulz.matrixIterate_preserves_kernel
#print axioms NeuralSpec.NewtonSchulz.exists_small_positive_input
#print axioms NeuralSpec.NewtonSchulz.scalarIterate_limit_fixed
#print axioms NeuralSpec.NewtonSchulz.muon_one
#print axioms NeuralSpec.NewtonSchulz.muon_not_tendsto_one
#print axioms NeuralSpec.NewtonSchulz.matrixStep_eq_expanded
#print axioms NeuralSpec.NewtonSchulz.factoredStepMatmulFlops_saving
#print axioms NeuralSpec.NewtonSchulz.muonIteration_satisfies_spec
#print axioms NeuralSpec.NewtonSchulz.muonMatmulFlops_eq
#print axioms NeuralSpec.NewtonSchulz.muonMatmulFlops_saving
#print axioms NeuralSpec.NewtonSchulz.muonCost_satisfies_spec
