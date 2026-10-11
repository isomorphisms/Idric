# Rocq quotation corpus for the Idriç emitter

**Destination: Idriç only.** This corpus accompanies [the Rocq→Idriç translation design](../../../notes/rocq-to-idric-proof-preserving-translation.md). Idris 2 and the experimental Oodriç, Adriç and Odriç lines are references, not alternate output targets.

**Status: UNRUN.** Source and quotation test inputs have been written but no Rocq, MetaRocq or Idriç tests were run in this task. They are not evidence of a working emitter.

- `ProofTerms.v` is proposed Rocq input: a universe-polymorphic identity, an indexed inductive family, constructors, an inhabitant, successor injectivity and a structurally recursive equality proof.
- `QuoteProofTerms.v` is a proposed pre-erasure MetaRocq quotation driver. Import paths, recursive quotation, opaque dependencies, universe identities and plugin compatibility must be checked with pinned source revisions.
- The required output is actual maintained `.idric` source (or later an explicitly justified, checked Idriç core import). No such output has been generated yet.

## Qualification sequence

1. Pin Rocq and MetaRocq commits/versions; compile `ProofTerms.v` with Rocq and retain the source environment and axiom receipt.
2. Compile/run `QuoteProofTerms.v` against that exact kernel/plugin pairing; inspect all required bodies, declarations, universes and dependency identities. Report missing material as blocked.
3. Serialize and validate a source-faithful, pre-erasure Rocq package. Do not confuse ordinary proof-erasing extraction with proof transport.
4. Map all source declarations and obligations **into Idriç**. Preserve semantic distinctions or explicitly report an unsupported construct; never substitute a proof hole or invented postulate.
5. Emit `.idric` source and check with a pinned, *actual* Idriç compiler. The Idris 2 compatibility compiler, another experimental branch, a generated file, or a target-native fallback is not a replacement for Idriç acceptance.
6. Separately establish whatever proof-preservation claim is made. Idriç typechecking alone does not certify equivalence to Rocq's logic.
7. Record `PASS`, `FAILED`, `BLOCKED` and `UNRUN` accurately with Flexible Pipes / ai-ci receipts; keep application execution evidence separate.

The corpus must expand with negative cases for axioms, opaque inaccessible proofs, unresolved existentials, universe mismatch, proof-irrelevant eliminations, and positive cases for cofixpoints and larger mathematical dependencies. Those cases are not yet implemented.
