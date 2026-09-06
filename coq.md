# Coq reference notes for Idriç

Status: **RESEARCH_REFERENCE**. Recorded 2026-09-06. Notes only; no implementation changes.

## Identity and scope

Coq and Rocq are the same project under successive names, not two competing compiler foundations. The [official Rocq 9.0 release announcement](https://rocq-prover.org/releases/9.0.0) identifies the completion of the rename. Keep both requested Idriç branches: this `coq` branch records historical Coq-era references; the [`rocq` branch](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md) records a current upstream source snapshot.

Canonical repository: [rocq-prover/rocq](https://github.com/rocq-prover/rocq). Historical source baseline here: verified tag [`V8.20.1`](https://github.com/rocq-prover/rocq/tree/V8.20.1). It is deliberately not presented as the current release.

Use these references for kernel discipline, goal-state manipulation, and extraction. Keep Idris 2 as the primary implementation reference for Idriç, including QTT and executable backends. No port or replacement architecture is selected.

## Specific code worth reading

| Subject | Historical source and entry points | Relevance to Idriç |
| --- | --- | --- |
| Core type checking | [`kernel/typeops.ml`, lines 1–105](https://github.com/rocq-prover/rocq/blob/V8.20.1/kernel/typeops.ml#L1-L105): `conv_leq`, `check_constraints`, `check_type`, `infer_assumption` | Distinguishes conversion, universe constraints, and checking that something is a type. Read the dependencies as part of the boundary: this is not a self-contained checker that can simply be copied into Idriç. |
| Goal-state interface | [`engine/proofview.mli`, lines 1–120](https://github.com/rocq-prover/rocq/blob/V8.20.1/engine/proofview.mli#L1-L120): `proofview`, `init`, `dependent_init`, `finished`, `partial_proof`, `focus` | Exposes a state containing existential variables and goals, with an abstract interface for tactics. Especially useful for separating editing or search operations from the status of the resulting term. |
| Extraction and erasure | [`plugins/extraction/extraction.ml`, lines 1–100](https://github.com/rocq-prover/rocq/blob/V8.20.1/plugins/extraction/extraction.ml#L1-L100): `info_of_family`, `flag_of_type`, `check_default` | Shows explicit classification of logical material, computational information, and type schemes. Compare the classification boundary with Idriç's erasure decisions; do not equate them. |

## Two distinctions to preserve

**No focused goals is not necessarily completion.** The `finished` documentation in `proofview.mli` explicitly allows unsolved goals outside the current focus. An editor or acceptance check must not mistake an empty visible goal list for a fully checked result.

**Extraction erasure is not QTT usage checking.** The extraction excerpt classifies sorts and types. Locally, [`Core/LinearCheck.idr`](https://github.com/isomorphisms/Idric/blob/d2463ec8a3a0dd4ac167029927452f3e83805dc3/Core/LinearCheck.idr#L1-L90) counts variable uses and adjusts usage information around holes. These are different responsibilities. A comparison must preserve the intended erased, linear, and unrestricted usage rules rather than assuming a Coq-style erasure pass supplies them.

## Open questions, not a work schedule

- What is the explicit checked-result boundary in current Idriç, and which operations may still leave unresolved information?
- Could a future search/tactic layer construct ordinary core terms without enlarging what the checker must trust?
- Which parts of extraction are informative for Idriç's erasure and backend interface, and which depend on different type-theoretic rules?

Those questions require a separate examination of present Edriç. These notes do not establish a clear migration path or commit the project to adding tactics.

## Scope and provenance

Created independently from default branch `Idriç` at [`d2463ec8a3a0dd4ac167029927452f3e83805dc3`](https://github.com/isomorphisms/Idric/commit/d2463ec8a3a0dd4ac167029927452f3e83805dc3). Inspected the linked source excerpts; no Coq build, extraction experiment, kernel audit, or Idriç acceptance run was performed. No upstream code was copied.

Other reference branches: [Agda](https://github.com/isomorphisms/Idric/blob/agda/agda.md), [Rocq](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md), [Lean](https://github.com/isomorphisms/Idric/blob/lean/lean.md).
