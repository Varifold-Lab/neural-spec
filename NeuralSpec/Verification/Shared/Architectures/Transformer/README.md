# Transformer verification theory

Reserved for reusable proof adapters and missing family-specific lemmas required by project cases; no local Transformer theorem yet. Import existing upstream results before adding a new theorem.

| Planned module | Scope |
| --- | --- |
| `Causality.lean` | Compose available component results into the required prefix-agreement statement |
| `KVCache.lean` | Establish cache-state invariants and recomputation equivalence beyond available upstream coverage |

These modules will import generic network definitions without importing an example or training. Cache results must specify position indices, valid entries, and evaluation mode. Exact-real equivalence and finite-precision guarantees require separate statements; numerical premises remain explicit.

`NN.Proofs.Models.Attention.CausalMask` already proves causal mask laws and zero attention weight at blocked future positions. These results alone do not constitute the concrete model's prefix-agreement proof.
