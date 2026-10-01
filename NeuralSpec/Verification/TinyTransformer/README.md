# TinyTransformer verification

Reserved verification cases:

| Directory | Property |
| --- | --- |
| `Causality/` | Outputs through a position depend only on the input prefix |
| `CacheEquivalence/` | Cached inference agrees with recomputation under specified semantics |
| `Quantization/` | Deployment error bounds and conditional preservation of output margins |

Each case will contain `Spec.lean` and `Correctness.lean` when implemented; numerical reports and floating-point proofs will use separate modules. Cases import the network and discharge shared-theory hypotheses. No trained instance, checker result, or kernel-checked theorem exists yet.
