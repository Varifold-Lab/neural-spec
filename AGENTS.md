# Working on neural-spec

- Use the pinned Lean and TorchLean revisions. Keep `lake-manifest.json` committed.
- Keep the four exact input regions and the 1/4 margin aligned with `Spec.lean`.
- Distinguish a numerical report, a checker result, and a kernel-checked theorem.
- Do not use `sorry`, `admit`, or assume the target network property to complete a proof.
- State whether a theorem describes exact real arithmetic or a particular floating-point model.
- Use trained parameters for post-training checks; do not accidentally verify initialization.
- Build with `lake build`; smoke-test training with `lake exe xor smoke` when changing runtime code.
- Generated checkpoints and logs belong in `artifacts/`, which is not committed.
