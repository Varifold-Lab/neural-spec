# Transformer architectures

Reserved for adapters to the pinned upstream Transformer definitions; no local implementation yet. Reuse existing components rather than duplicate the model library. Add a Lean module only when a concrete example requires an adapter or an explicit evaluator.

Candidate adapter modules, subject to upstream coverage:

| Module | Scope |
| --- | --- |
| `Attention.lean` | Adapt existing attention and mask definitions to the selected evaluator |
| `Normalization.lean` | Select token-wise normalization and an explicit positive regularization constant |
| `FeedForward.lean` | Configure existing position-wise layers and an explicitly selected activation |
| `Position.lean` | Select existing position encoding and an explicit position-index convention |
| `Block.lean` | Configure residual composition and an explicit normalization order |
| `KVCache.lean` | Adapt an available cache implementation or define a missing reference evaluator |

Arithmetic and evaluation order must be explicit in each evaluator. Network definitions import neither training nor verification. Family-specific theory belongs in `../../../Verification/Shared/Architectures/Transformer/`.

Upstream coverage: `NN.API.Models.CausalTransformer.Architecture` supplies causal model constructors; `NN.Spec.Models.Transformer` supplies model semantics. Import these directly when no adapter is needed.
