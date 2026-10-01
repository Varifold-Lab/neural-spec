# TinyTransformer network

Reserved for a small causal Transformer instance; no configuration, trained parameters, or evaluator yet.

`Architecture.lean` will configure the pinned upstream causal Transformer, using local adapters only where necessary. `Parameters.lean` will contain one frozen trained parameter set; arithmetic-specific evaluators will import it. Specifications and parameter-decoding proofs belong in `../../Verification/TinyTransformer/`.
