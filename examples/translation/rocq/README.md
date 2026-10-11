# Rocq quotation and candidate Idriç emitter

**One destination: Idriç.** This tree implements the first Rocq-side translation stage described in [the Rocq→Idriç architecture](../../../notes/rocq-to-idric-proof-preserving-translation.md).

## Implementation state

**Source committed; compilation UNRUN.** This is not yet a proved or fully functioning Rocq→Idriç compiler.

| File | Role |
| --- | --- |
| `ProofTerms.v` | Rocq source declarations: polymorphic identity, dependent list, equality and recursion examples |
| `IdricEmitter.v` | Gallina translator from MetaRocq `Ast.term` to candidate Idriç `.idric` text, with explicit obligations/rejections |
| `QuoteIdric.v` | `MetaRocq Run` uses `tmQuoteRec` to quote the **named** `polymorphic_identity`; looks up its real type and body in the quoted environment and prints candidate text + obligations |
| `IdricEmitterTests.v` | Rocq `Example` statements exercising candidate rendering, de Bruijn scope, and fail-closed treatment of holes, loose references, `Prop` and `SProp` |
| `expected/RocqBridge.idric` | **Handwritten expectation** for the first quotation—not an actually emitted output or checked Idriç compiler result |
| `QuoteProofTerms.v` | Earlier standalone MetaRocq quotation probe (still proposed/unrun), independent of the candidate emitter |

The candidate emission includes explicit obligations for Rocq universe sorts, binder irrelevance, and the equality constructor correspondence. It does **not** silently turn those into proved equivalences.

Current supported term shapes: locally bound variables, dependent Π-types, lambdas, typed lets, nonempty application, and **conditional candidate** rendering of the known Rocq equality family/`eq_refl`. Other MetaRocq constructors reject with named diagnostics, including free variables, existentials, opaque/unknown constants, inductive families other than the explicit equality pattern, elimination, fix/cofix, primitives, and arrays.

These are explicit **current implementation limits**, not the intended eventual scope of Idriç or the emitter.

## Building the Rocq side

Requires a **pinned, matching** Rocq 9.1 and MetaRocq 9.1 development environment. The current work has not executed the following commands in such an environment; treat them as an acceptance procedure to be qualified, not receipts.

From this directory, with MetaRocq available on Rocq's load path:

```sh
rocq compile ProofTerms.v
rocq compile IdricEmitter.v
rocq compile IdricEmitterTests.v
rocq compile QuoteIdric.v
```

The commands must be run with a consistent `-Q`/`-R` logical load path or project file appropriate to the pinned installation. The `Require Import`s in the local files assume that this directory is mapped into Rocq's load path. If the first commands fail, record the exact failure rather than assuming compatibility.

The `QuoteIdric.v` transcript deliberately labels:

```text
IDRIC_SOURCE_BEGIN
... proposed .idric source ...
IDRIC_SOURCE_END
IDRIC_UNRESOLVED_OBLIGATIONS_BEGIN
... source/target semantic obligations ...
IDRIC_UNRESOLVED_OBLIGATIONS_END
```

**Do not treat this transcript as an automatic safe file exporter.** Before automating extraction of the marked source region, inspect Rocq's actual output framing, enforce exactly one balanced marked region, preserve all obligations as an inseparable receipt, and reject unexpected text. Forbid overwriting existing source before the transcript is validated.

## Checking the Idriç target

Only after quotation has actually succeeded:

1. Compare the marked Idriç source text with `expected/RocqBridge.idric`. The checked expectation should be deterministic for the pinned input; if the generated source differs, investigate rather than rewrite the golden to make it pass.
2. Check the actual generated `.idric` file using the pinned **Idriç compiler** on branch `Idriç` or an explicit integration revision, not a substitute upstream Idris 2 checker.
3. Audit the quoted global context, required dependency closure, source axioms, opacity, universe polymorphism, and binder relevance. The existing emitter records obligations but **does not discharge** them.
4. Separately establish whichever semantic correspondence theorem is claimed. An Idriç typecheck of proposed output is not equivalent to preserving Rocq's kernel proof.
5. Bind every source, plugin, emitter, Idriç and output revision plus the actual stages and exits into a Flexible Pipes / ai-ci acceptance receipt.

The present authoring environment had no Rocq or Idriç compiler installed and no outbound Git checkout access. Therefore **Rocq compilation, MetaRocq quotation, output comparison, Idriç typechecking, and preservation are UNRUN**. The only checks performed here were source/API inspection and repository-file/diff verification.

## Negative cases to expand

The pure emitter tests currently reject `Prop`/`SProp` sort collapse, unresolved existential holes, unmatched globals, and out-of-scope de Bruijn indices. Future qualification needs end-to-end fixtures for axioms, `Qed` opacity, incomplete dependencies, universe mismatch, equality elimination, dependent pattern matching, induction, guarded/coinductive recursion, and the larger mathematical library corpus, including Dirichlet characters and Euler-product arguments.

All source files are additional groundwork for **one** destination, Idriç. No extra Idris 2, Oodriç, Adriç or Odriç output adapters are planned.
