# Newton–Schulz: proof scope

[Website explanation](https://varifold-lab.github.io/neural-spec/newton-schulz.html) · [Muon article](https://kellerjordan.github.io/posts/muon/)

## Algorithm layer

The object is a supplied real matrix, not a trained checkpoint. [Model/NewtonSchulz.lean](../NeuralSpec/Model/NewtonSchulz.lean) defines the generic quintic iteration:

```text
A = X Xᵀ
F(X) = a X + (b A + c A²) X
φ(x) = a x + b x³ + c x⁵
```

[Muon.lean](../NeuralSpec/Model/NewtonSchulz/Muon.lean) selects five steps and `(a, b, c) = (34445/10000, -47750/10000, 20315/10000)`, defined once as exact rationals. All matrix arithmetic is over exact reals. This models the iteration core used to process an update matrix inside Muon.

[Cost.lean](../NeuralSpec/Model/NewtonSchulz/Cost.lean) separately assigns `2pqr` FLOPs to a dense `p × q` by `q × r` multiplication. For an oriented `m × n` input with `m ≤ n`, the factored schedule costs `4nm² + 2m³` per step. An alternative shares `Y = AX` and computes `aX + bY + cAY`, costing `6nm²` per step. Only these three matrix multiplication calls are charged.

## Verification layer

Generic matrix and scalar theorems live in [Shared/Arithmetic/NewtonSchulz.lean](../NeuralSpec/Verification/Shared/Arithmetic/NewtonSchulz.lean), and generic cost identities in [NewtonSchulzCost.lean](../NeuralSpec/Verification/Shared/Arithmetic/NewtonSchulzCost.lean). Neither imports the Muon configuration or XOR.

The concrete cases import those definitions and discharge their premises. The theorem names below are in `NeuralSpec.NewtonSchulz`.

| Specification or theorem | Guarantee |
| --- | --- |
| [`MuonIterationSpec`](../NeuralSpec/Verification/NewtonSchulz/Iteration/Spec.lean) | Five steps preserve a supplied orthonormal factorization, commute with transpose, and preserve every vector in the input kernel. |
| [`muonIteration_satisfies_spec`](../NeuralSpec/Verification/NewtonSchulz/Iteration/Correctness.lean) | Proves the iteration specification without assuming it. |
| `exists_small_positive_input` | Every finite step count admits a positive input at most one with arbitrarily small output magnitude. |
| `muon_not_tendsto_one` | No scalar trajectory with the tuned coefficients converges to exactly one; a limit must be fixed, but `φ(1) = 701/1000`. |
| [`MuonCostSpec`](../NeuralSpec/Verification/NewtonSchulz/Cost/Spec.lean) | Five-step matrix multiplication cost is at most `30nm²` when `m ≤ n`. |
| [`muonMatmulFlops_saving`](../NeuralSpec/Verification/NewtonSchulz/Cost/Correctness.lean) | The factored schedule saves `10m²(n−m)` FLOPs over five steps, while `matrixStep_eq_expanded` proves the real-arithmetic evaluation schemes equal. |

The factorization premise is `UᵀU = VᵀV = I`; it does not assume orthogonalization or construct an SVD. Nonnegative diagonal entries permit a singular-value interpretation, and zero entries stay zero. The scalar limitations require a finite-step error guarantee to specify a spectral range and an attainable tolerance.

## Remaining boundary

Frobenius normalization with `eps`, momentum, parameter updates, quantitative spectral approximation bounds, and bfloat16 execution are unverified. The cost model excludes scalar operations, storage, data movement, and communication. Mathematical equivalence does not imply floating-point equality under changed association. GPU/compiler correspondence, training convergence, and shorter wall-clock time are not established.

The results are kernel-checked theorems, distinct from numerical reports or executable checker results. They concern an algorithm core; the [XOR case](PROOF.md) concerns a frozen model's output margin.

## Validation

Both cases are imported by `NeuralSpec` and included in the full build. Reproduce from the repository root:

```sh
lake build NeuralSpec.Network
lake env lean scripts/CheckImports.lean
lake env lean scripts/CheckShared.lean
lake build
lake env lean scripts/Audit.lean
```

Validation on 2026-10-01: the network and full builds, both import checks, and theorem audit passed. The 16 audited Newton–Schulz results use only `propext`, `Classical.choice`, and `Quot.sound`, with no `sorryAx` or native-evaluation axioms. The two-page website build, nine website tests, local links, and browser case navigation also passed.
