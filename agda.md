# Agda reference notes for Idriç

Status: **RESEARCH_REFERENCE**. Recorded 2026-09-06. Notes only; no compiler or editor changes.

## Position

Keep Idris 2 as the primary implementation reference. Use Agda as a second reference for typechecker-driven editor feedback, interaction with incomplete terms, and dependent-language notation. This is a source map, not a decision to port Agda or a roadmap from current Edriç to a replacement architecture. The adaptation path is still unresolved.

Upstream: [agda/agda](https://github.com/agda/agda). Source links below are pinned to the observed `master` commit [`28cbf0e697b23411779b72b6f0357dc995a2fcc2`](https://github.com/agda/agda/commit/28cbf0e697b23411779b72b6f0357dc995a2fcc2), not a claim about the latest release.

## Specific code worth reading

| Subject | Source and entry points | Relevance to Idriç |
| --- | --- | --- |
| Structured interaction | [`Interaction/JSONTop.hs`, lines 1–150](https://github.com/agda/agda/blob/28cbf0e697b23411779b72b6f0357dc995a2fcc2/src/full/Agda/Interaction/JSONTop.hs#L1-L150): `jsonREPL`, context entries, positions, ranges, interaction identifiers | Separates information emitted by the checker from its rendering in an editor. Important caveat: this entry point reads Haskell-style `IOTCM` commands and emits JSON. It is not a JSON-in/JSON-out protocol or an LSP implementation merely because its name contains JSON. |
| Precise highlighting | [`Interaction/Highlighting/Generate.hs`, lines 1–90](https://github.com/agda/agda/blob/28cbf0e697b23411779b72b6f0357dc995a2fcc2/src/full/Agda/Interaction/Highlighting/Generate.hs#L1-L90): `generateAndPrintSyntaxInfo`, `highlightAsTypeChecked`, `printUnsolvedInfo`, `storeDisambiguatedConstructor` | Entry points for distinguishing token-level coloring from checker-informed highlighting, unresolved information, and resolved names. The exported interface is inspected here; the complete generation pipeline has not been traced. |
| Mixfix/operator parsing | [`Syntax/Concrete/Operators.hs`, lines 1–95](https://github.com/agda/agda/blob/28cbf0e697b23411779b72b6f0357dc995a2fcc2/src/full/Agda/Syntax/Concrete/Operators.hs#L1-L95): `parseApplication`, `parseLHS`, `parsePattern` | The initial parser leaves applications for a later operator-parsing stage. Useful comparison for Unicode notation and precedence without assuming every notation decision belongs in the lexer. This does not establish support for Idriç's proposed ordinary-space identifiers or distinct Tab separator. |

## What already exists locally

At the branch base, [`Protocol/IDE.idr`](https://github.com/isomorphisms/Idric/blob/d2463ec8a3a0dd4ac167029927452f3e83805dc3/Protocol/IDE.idr#L1-L104) already imports hole/highlighting message modules, defines highlighting spans, and serializes replies including `HighlightSource` through S-expressions. Do not describe Edriç as having no editor protocol or assume Agda's protocol must replace it.

That source evidence is **not** an end-to-end receipt showing that the present executable emits everything needed or that Vim consumes it correctly.

## Open questions, not selected implementation tasks

- Which useful metadata is already produced by the current Edriç executable, and which part is missing between compiler output and Vim display?
- What are the exact position units and range conventions across Unicode source, compiler messages, and Vim? What information survives an incomplete or failed check?
- Can notation experiments be isolated from elaboration and QTT usage rules rather than importing Agda's surrounding design wholesale?

Idris remains the reference for execution, backends, foreign interfaces, and QTT. Agda's interaction model is a comparison, not evidence that its core can substitute for that resource discipline.

## Scope and provenance

Created independently from default branch `Idriç` at [`d2463ec8a3a0dd4ac167029927452f3e83805dc3`](https://github.com/isomorphisms/Idric/commit/d2463ec8a3a0dd4ac167029927452f3e83805dc3). Inspected the linked source excerpts; did not build Agda, test Vim integration, or establish an implementation sequence. No upstream code was copied.

Other reference branches: [Coq](https://github.com/isomorphisms/Idric/blob/coq/coq.md), [Rocq](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md), [Lean](https://github.com/isomorphisms/Idric/blob/lean/lean.md).
