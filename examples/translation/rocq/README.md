# Rocq quotation corpus for the Idris-family bridge

This corpus accompanies [the source-faithful translation design](../../../notes/rocq-proof-preserving-family-translation.md). **No tests were run** for this corpus in the authoring environment (neither `rocq` nor `idris2` was installed). It is not evidence of a working emitter.

- `ProofTerms.v` is a proposed Rocq source corpus: universe-polymorphic identity, an indexed inductive family with constructors, an inhabitant, a successor-injectivity proof, and structurally recursive equality proof. Its terms are the *input* to translation, not the target spelling.
- `QuoteProofTerms.v` is a proposed MetaRocq driver using recursive quotation. Its dependency loading, generated quoted environment, universe information, treatment of opaque constants, and generated term identities must be checked with a pinned MetaRocq version before acceptance.

## Required independent qualification

1. Pin Rocq and MetaRocq commits / versions; prove that `ProofTerms.v` compiles in Rocq under those pins.
2. Compile `QuoteProofTerms.v` with the same pinned kernel and plugin. Inspect whether its recursive quotation includes every required body, declaration, universe constraint and dependency; report missing material, not assumed completeness.
3. Produce a versioned source-faithful quote with explicit checksums, environment identity and assumption/axiom audit; no proof erasure.
4. Translate into **each** selected target independently (Idris 2, Idriç, Oodriç, Adriç and/or Odriç as actual capabilities permit). Do not substitute successful acceptance from a different target.
5. Check generated artifacts with exact target compiler revisions. Record separately whether the mathematical correspondence has any independently established proof; target compilation alone is insufficient.
6. Report `BLOCKED` for unsupported constructs, and `UNRUN` for stages that were never attempted. An emitted source file is not automatically `TARGET_CHECKED` or `PROOF_PRESERVED`.

The corpus will ultimately need negative cases for assumptions, inaccessible opaque proofs, unresolved existentials, proof-irrelevant elimination, and incompatible universe constraints, and positive cases for cofixpoints and larger library/module dependencies. Those are not implemented here.
