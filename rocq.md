# Rocq reference notes for Idriç

Status: **RESEARCH_REFERENCE**. Recorded 2026-09-06. Notes only; no implementation changes.

## Identity and position

Rocq is the renamed Coq project, not an additional independent language foundation; see the [official Rocq 9.0 announcement](https://rocq-prover.org/releases/9.0.0). This branch covers a current upstream source snapshot. The separate [`coq` branch](https://github.com/isomorphisms/Idric/blob/coq/coq.md) retains historical Coq-era kernel, goal-state, and extraction references.

Upstream: [rocq-prover/rocq](https://github.com/rocq-prover/rocq). Source links below are pinned to the observed `master` commit [`0c884e3eba9dbdc2147d5a3ca03aa268aa1b7012`](https://github.com/rocq-prover/rocq/commit/0c884e3eba9dbdc2147d5a3ca03aa268aa1b7012), not a claim about the latest release.

For Idriç, study the boundaries between elaboration, core checking, and admitting declarations into an environment. Idris 2 remains the implementation reference. Borrowing a boundary or invariant does not mean importing Rocq's calculus or implementing its entire environment machinery.

## Specific code worth reading

| Layer | Source and entry points | Relevance to Idriç |
| --- | --- | --- |
| Elaboration with incomplete information | [`pretyping/pretyping.mli`, lines 1–110](https://github.com/rocq-prover/rocq/blob/0c884e3eba9dbdc2147d5a3ca03aa268aa1b7012/pretyping/pretyping.mli#L1-L110): `typing_constraint`, `inference_flags`, `understand_tcc` | Documents translation from located surface terms to internal terms, including implicit arguments, coercions, and pattern matching. Its default behavior can leave unresolved existential variables. A successful elaboration call must not automatically be labeled a closed, checked result. |
| Core type operations | [`kernel/typeops.ml`, lines 1–85](https://github.com/rocq-prover/rocq/blob/0c884e3eba9dbdc2147d5a3ca03aa268aa1b7012/kernel/typeops.ml#L1-L85): `conv_leq`, `check_poly_constraints`, `check_type`, `infer_assumption` | Concrete places to inspect conversion and constraint checks separately from elaboration heuristics. This excerpt is an entry point, not a complete account of the trusted kernel. |
| Checked environment updates | [`kernel/safe_typing.mli`, lines 1–125](https://github.com/rocq-prover/rocq/blob/0c884e3eba9dbdc2147d5a3ca03aa268aa1b7012/kernel/safe_typing.mli#L1-L125): `safe_environment`, `add_constant`, `check_opaque`, `fill_opaque` | Defines an abstract environment interface and separates checking a delayed result from installing it. The `fill_opaque` documentation notes that changed universe constraints can make installation fail even after checking produced a certificate. |

## Interpretation for Idriç

The useful distinction is between **constructing a candidate**, **checking it under an environment**, and **accepting it into the continuing state**. These are not interchangeable success conditions. This is a design observation from the interfaces, not a claim that copying their OCaml implementation would create a suitable Idriç kernel.

An independent Idriç checker, if pursued, would need to preserve Idriç's own term rules, quantities, conversion behavior, primitives, and environment assumptions. The existing [`Core/LinearCheck.idr`](https://github.com/isomorphisms/Idric/blob/d2463ec8a3a0dd4ac167029927452f3e83805dc3/Core/LinearCheck.idr#L1-L90) is a concrete local reference for usage counting and hole-related usage information. Its presence alone does not establish that all required checking has been isolated behind an independent boundary.

## Open questions, not a migration plan

- What exactly counts as a complete checked term or declaration in present Edriç, including unresolved holes and quantity constraints?
- Which checks happen during elaboration, and which can be rerun without trusting the elaborator's internal state?
- What environment information must accompany a checked result so that it cannot be reused under incompatible assumptions?

No new checker, tactic layer, or rewrite is selected here. The current-to-next implementation path remains unresolved; these notes only identify useful source-level comparisons.

## Scope and provenance

Created independently from default branch `Idriç` at [`d2463ec8a3a0dd4ac167029927452f3e83805dc3`](https://github.com/isomorphisms/Idric/commit/d2463ec8a3a0dd4ac167029927452f3e83805dc3). Inspected the linked source excerpts; no Rocq build, dependency audit, independent-checker prototype, or Idriç acceptance run was performed. No upstream code was copied.

Other reference branches: [Agda](https://github.com/isomorphisms/Idric/blob/agda/agda.md), [Coq](https://github.com/isomorphisms/Idric/blob/coq/coq.md), [Lean](https://github.com/isomorphisms/Idric/blob/lean/lean.md).
