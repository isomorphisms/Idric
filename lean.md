# Lean reference notes for Idriç

Status: **RESEARCH_REFERENCE**. Recorded 2026-09-06. Notes only; no implementation changes.

## Position

Use Lean 4 as a reference for elaborator metadata, extensibility, incremental feedback, and editor interaction. Keep Idris 2 as Idriç's primary implementation reference. This is a selective comparison, not a proposal to migrate to Lean or adopt its complete compiler, runtime, server, or tactic system.

Upstream: [leanprover/lean4](https://github.com/leanprover/lean4). Source links below are pinned to the observed `master` commit [`c155094f54eab345cca3da867dbd888a34fbf0d2`](https://github.com/leanprover/lean4/commit/c155094f54eab345cca3da867dbd888a34fbf0d2), not a claim about the latest release.

The official [elaboration and compilation reference](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/) provides the larger context: syntax, elaboration including macro expansion, kernel checking, and compilation are distinct responsibilities. That documentation link is live; the code references below identify the exact snapshot inspected.

## Specific code worth reading

| Subject | Source and entry points | Relevance to Idriç |
| --- | --- | --- |
| Elaboration information tied to source | [`src/Lean/Elab/InfoTree/Types.lean`, lines 1–135](https://github.com/leanprover/lean4/blob/c155094f54eab345cca3da867dbd888a34fbf0d2/src/Lean/Elab/InfoTree/Types.lean#L1-L135): `CommandContextInfo`, `TermInfo`, `PartialTermInfo`, `CompletionInfo` | Records syntax positions, local context, expected types, expressions, and metavariable context. `PartialTermInfo` explicitly preserves useful information when elaboration fails, so the language server need not lose all feedback on incomplete code. |
| Guarding incremental reuse | [`src/Lean/Elab/Term.lean`](https://github.com/leanprover/lean4/blob/c155094f54eab345cca3da867dbd888a34fbf0d2/src/Lean/Elab/Term.lean): `incrementalAttr`, `isIncrementalElab` | Marks supported elaborators for incremental reuse. The source explains that unmarked elaborators do not receive the snapshot bundle, preventing accidental incorrect reuse. Useful warning against assuming every extension is automatically safe to cache. This file imports `Lean.Elab.Term.TermElabM`; it is not the entire term elaborator. |
| Responsive, version-aware editor service | [`src/Lean/Server/FileWorker.lean`, lines 1–110](https://github.com/leanprover/lean4/blob/c155094f54eab345cca3da867dbd888a34fbf0d2/src/Lean/Server/FileWorker.lean#L1-L110): architecture comment and `WorkerContext` | Describes per-file workers, command-level elaboration tasks, cancellation after edits, and rejecting notifications from outdated document versions. Relevant to keeping editor feedback responsive and correctly associated with the current buffer. |

## Existing Idriç comparison point

[`Protocol/IDE.idr`](https://github.com/isomorphisms/Idric/blob/d2463ec8a3a0dd4ac167029927452f3e83805dc3/Protocol/IDE.idr#L1-L104) already defines highlighting payloads, source-highlighting replies, and protocol serialization. The comparison is therefore not “Lean has metadata, Idriç has nothing.” It is whether the present Idriç pipeline retains and exposes the right context, positions, and partial results for Vim.

The existing source definitions have been inspected; end-to-end behavior of the current executable and Vim has not been tested here. Likewise, observing Lean's worker architecture does not establish that Edriç needs multiple processes, the same caching model, or the same editor extensions.

## Open questions, not selected next steps

- Would extending the current reply records supply the necessary type and source context, or is a richer retained information structure justified?
- How should partial results, diagnostics, and highlighting be associated with a particular document version so stale feedback cannot overwrite current feedback?
- What is the smallest useful Vim interaction that fits present Edriç without importing Lean's full server machinery?
- Which future syntax or elaborator extensions can safely reuse checked state, while preserving Idriç's own QTT rules?

The strategic comparison is useful, but the current-to-next implementation path is still unresolved. No redesign or implementation sequence is claimed by these notes.

## Scope and provenance

Created independently from default branch `Idriç` at [`d2463ec8a3a0dd4ac167029927452f3e83805dc3`](https://github.com/isomorphisms/Idric/commit/d2463ec8a3a0dd4ac167029927452f3e83805dc3). Inspected the linked source excerpts; did not build Lean, benchmark editor responsiveness, implement a protocol adapter, or run Idriç acceptance tests. No upstream code was copied.

Other reference branches: [Agda](https://github.com/isomorphisms/Idric/blob/agda/agda.md), [Coq](https://github.com/isomorphisms/Idric/blob/coq/coq.md), [Rocq](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md).
