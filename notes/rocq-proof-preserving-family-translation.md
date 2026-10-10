# Rocq → Idris-family proof-preserving translation

Status: **DESIGN / ACCEPTANCE CONTRACT**, 2026-10-10. This document does **not** claim that an emitter, MetaRocq quotation plugin, target compiler acceptance, or mathematical preservation theorem has been implemented or run.

## Objective and size

Build a Rocq-facing emitter into the *evolving Idris-family language space*, not an Idris 2 pretty-printer and not an extension of Rocq's ordinary proof-erasing Haskell extraction. The intended output is useful both when a program needs an implementation and when a mathematical construction should be translated, inspected, compared, or learned from. These are distinct translation purposes.

Do **not** choose the representational ceiling by asking only what the current Idris 2 compiler accepts. In particular, do not discard universes, propositions, inductive indices, proof bodies, termination arguments, or source dependencies merely to make the initial target compile. Keep the original meaning available, then express exactly what each current target can justify.

Design the durable interfaces for the intended family. Implementation can advance in checked steps, but a short prototype is not the definition of the system.

## Actual local target lines

Observed in `isomorphisms/Idric` on 2026-10-10:

| Target | Observed anchor | Translation relationship |
| --- | --- | --- |
| Idris 2 | Upstream compiler and inherited compatibility surface | Concrete `.idr` compatibility destination, with its own QTT and type-theoretic limitations |
| **Idriç** | Current default `Idriç` at `2734ac5a86610eddfab73b1644d72b4ac85a65ee` | Canonical evolving target language; `.idric`, domain vocabulary, explicit mathematical distinctions, no mandatory RefC fallback |
| **Oodriç** | Experimental branch `17c76eed11522f9dfa9d232d17bea31e17068950`, `OODRIC.md` | Declaration dependency/order experiments. Its existing scheduling supports only specific forward-reference cases and has normalization/structural barriers |
| **Adriç** | Research branch `0ab65f7a09ef89ecfdd04a02c6d5e920951a8965` | Adverbs, constraints, purpose-level actions, and interface interpretation. Do not confuse a natural-language request with an already formalized proposition |
| **Odriç** | Unsettled branch `0476044583fc8aef897cefeaeb1d0f2e976f3230`, `ODRIC.md` | A deliberately open independent future calculus, compiler, effects, representation, runtime, and native interface. Not bound by inherited Idris ANF or ABI |

Branches represent different research directions, **not five presently working proof-checking backends**. The `rocq` branch at `f63a9406aa26d052d9d62984b9b56f20d5b4a5f6` is historical research reference; it is 140 commits behind the canonical compiler and must not serve as the implementation base. See `rocq.md` on that branch and the separate `coq` branch for earlier kernel comparisons.

Existing Idriç source conventions are binding for maintained `.idric` output: `Number` rather than `Nat`, `Text` rather than `String`, domain-specific sized collections rather than uncritically emitting `Vect`, `→` for dependent function arrows, `=` for propositional equality and `≟` for a runtime equality question. These are output-vocabulary choices, **not** proof that arbitrary Rocq objects have identical semantics to the corresponding Idriç objects.

## Proposed architecture

```text
Rocq checked global environment and selected declarations
    │  source version, transitive dependencies, axiom audit
    ▼
MetaRocq quotation / PCUIC or another explicitly pinned pre-erasure input
    │  no silent opacity opening, no proof erasure
    ▼
Source-faithful, versioned Rocq semantic package
    │  binder scopes and de Bruijn indices
    │  Prop / SProp / Set / Type universes and constraints
    │  declarations, kinds, inductives, eliminators, fix/cofix
    │  opaque body status, assumptions, primitive dependencies
    │  source locations, source & environment identities
    ▼
Semantic translation and explicit preservation obligations
    │  map constructs and dependency graph, never flatten proof obligations
    ├──► Idris 2 adapter: inherited syntax/core, QTT compatibility
    ├──► Idriç adapter: maintained notation and mathematical vocabulary
    ├──► Oodriç adapter: graph scheduling and normalization barriers
    ├──► Adriç adapter: typed intent/constraint relationships when formal
    └──► Odriç adapter: independently selected future calculus/runtime
                │
                ▼
    independent target checking and separately classified evidence
```

The **source-faithful package** is neither Rocq's already-erased ML extraction IR nor the target runtime IR. It is an interchange boundary for mathematical information. A future verified translation may replace or refine parts of it. Do not decree that all target languages share one calculus, syntax, prelude, or execution representation.

A target adapter may emit source, provide a checked-core import, or construct an explicit proof obligation for missing target features. A diagnostic is an acceptable translation result. Substituting a postulate, unverified intrinsic, uncontrolled primitive, placeholder, `believe_me`, `assert_total`, or an erased proof where a relevant proof is needed is **not** a successful proof translation.

### Source package fidelity

Required fields/relations (representation format not chosen yet):

- source Rocq and MetaRocq versions and immutable revisions; kernel check receipt and environment identity;
- fully qualified declaration identity, names, types, proof/definition bodies *where accessible*, opacity state, declaration kind, transitive dependency graph;
- local telescope and binding depths; Π binders, λ, let, applications and conversions; implicitness should not become a semantic ambiguity;
- sort information including `SProp`, `Prop`, `Set` and universe levels, polymorphic constraints and cumulativity;
- inductive families, parameters, indices, constructors, eliminator motives and elimination restrictions; mutual declarations;
- fixpoints, cofixpoints, guardedness/termination information, reduction/transparency behavior;
- source axioms, `Admitted`, unsafe assumptions, admitted primitive behavior, and an explicit classification of opaque inaccessible proofs;
- proof terms versus computational programs, with any erasure performed **only after** the proof-bearing representation has been preserved;
- source of each semantic mapping and whether it is definitionally equal, propositionally equivalent with a proof, requires an additional assumption, or currently unknown.

Quotation by itself does not supply a theorem that the target translation is correct. The original Rocq kernel judgment and the target judgment must be retained as distinct facts.

### Target capability profile

Each named adapter must report capabilities **for an exact compiler revision**, not claim capabilities from a branch name:

1. Sort/universe structure and available cumulativity or predicativity.
2. Inductive definitions, large elimination, equality eliminators, and proof irrelevance.
3. Definitionally equal reductions, opacity, rewrite behavior, and reflection.
4. Termination, coinduction, positivity, mutual recursion.
5. Quantity/erasure discipline and any preservation proof for translating `Prop` to QTT `0`.
6. Declaration dependency scheduling, cycles, namespaces, and normalization barriers.
7. Names, semantic vocabulary, interfaces, effects, imports, and executable representation.
8. Checked-output entry point: source check, compiler-internal elaboration, or independent kernel.
9. Whether the proposed mapping is **meaning-preserving**, **program-only**, **requires obligations**, or **unsupported**.

This is a machine-checkable contract to implement later, not permission to mark unresolved fields true by default.

## Nontrivial semantic boundaries

**Universe hierarchy.** Rocq's constrained universe hierarchy and impredicative logical sorts cannot be copied into current Idris 2 by printing `Type`. The current Idris 2 FAQ states `Type : Type` and no implemented cumulativity. A successful Idris 2 type check therefore cannot *by itself* certify Rocq-equivalent logical soundness. Idriç or another future line may acquire a richer logical kernel without requiring Idris 2 to be the permanent ceiling.

**Propositions and erasure.** `Prop` / `SProp` and their elimination rules are not equivalent to Idris 2 quantity `0`. Keep proof relevance, admissible elimination, and program extraction as independent dimensions. Preserve proof terms when the goal is proof translation; an explicitly chosen executable extraction mode may erase only after preservation and classification.

**Inductive families.** A Rocq indexed `Vector`/`Fin`-like definition is mathematical data with induction/elimination rules. Printing an existing `Vect` or `SizedList` spelling is valid only when the required relationship and computation/induction behavior have been established. No representation silently defines the mathematical object.

**Recursion and coreduction.** Rocq guarded fixpoints/cofixpoints do not automatically satisfy the totality/coverage rules of an Idris-family target. Emit transparent obligations or a formally supported translation; do not bypass a checker.

**Axioms and opaque constants.** Kernel acceptance of a context *with axioms* is not an axiom-free theorem. Preserve the entire trusted-assumption closure and opaque body access requirements. A missing body or unresolved existential variable blocks a claim of complete proof transport.

**Purpose and order.** Oodriç suggests organizing output from a declaration dependency graph rather than in Rocq source order or naive topological order. Reducibility of type-level definitions and structural/foreign boundaries still matter. Adriç intent phrases and constraints should remain interpretable, and should not be fabricated from Rocq syntax as if they were already proved semantics.

**Runtime choices.** Odriç's language/runtime may change independently. The proof-bearing source package must not depend on `execve`, machine ABIs, ANF, RefC, or an inherited Idris 2 representation. Executable lowering remains separate from theorem transport.

**Mathematical laws.** Investigate explicit translation-preservation laws for binding and substitution, weakening, β/ι/δ/ζ conversion where supported, and composition of declaration dependencies. A hoped-for functorial description is a research problem: it requires specifying source and target categories and showing preservation/coherence, not merely naming the translation a functor.

## Acceptance: evidence must not collapse stages

Every example produces independent observations, each tied to immutable source/target compiler identities:

| Stage | Evidence | A PASS means |
| --- | --- | --- |
| Source | Rocq kernel check + closed-dependency/axiom audit | The original artifact was accepted under the **declared** Rocq environment |
| Quote | Pre-erasure structural roundtrip or equivalence check | The quoted package retains the selected term/declaration information, dependencies, universes, and provenance |
| Translate | Mapping and all generated obligations | Every construct has a documented mapping or an explicit failure; none silently disappears |
| Target | Exact target compiler checks source/core with no holes or unapproved axioms | The target accepted the translated artifact under its own rules |
| Mathematical preservation | An independently established translation theorem/certificate or explicitly bounded semantic comparison | The specific claimed source/target relationship is supported; **target typechecking alone is insufficient** |
| Execution (optional) | Named backend execution and behavior at exact revision | The executable ran at the claimed target, not via an unrelated fallback |

A source file printed successfully is **GENERATED**, not **CHECKED**. A target check is **TARGET_CHECKED**, not **PROOF_PRESERVED**. Unsupported features yield `BLOCKED` with a named reason rather than invented proofs. Axiomatic correspondence is classified separately from axiom-free proof transport.

Suggested initial semantic corpus, growing toward a broad benchmark rather than defining an arbitrary permanent subset:

- polymorphic identity with explicit universe constraints;
- equality `refl`, substitution and an inductive proof with real case analysis;
- a length-indexed family with dependent elimination and a lemma relating construction to an index;
- nested/mutual inductives and guarded recursive functions;
- proof-irrelevant `SProp` and restricted elimination adversarial cases;
- opaque `Qed` theorem with a dependency, an explicit `Axiom`, an `Admitted` proof and an unresolved-hole negative control;
- forward-reference modules with Oodriç scheduling barriers;
- mathematical library stress cases leading eventually to Dirichlet character identities and Euler-product reasoning.

These are **test requirements**, not claims that Rocq or any target has already passed them.

## Engineering ownership and sequence

- Retain Rocq-specific quotation/loader code and pinned upstream compatibility at an explicit integration boundary. Use MetaRocq's quotation and PCUIC work as a *candidate*, not Rocq's ordinary proof-erasing Haskell/JSON extraction as proof input.
- Implement a versioned, lossless source package and source-side validator before choosing a target pretty-printer as the permanent architecture.
- Give each language line its own capability declaration and independent check path. Do not merge Oodriç's speculative elaboration schedule, Adriç's adverb model, and Odriç's intentionally unsettled runtime into the canonical compiler just because they are relevant destinations.
- Develop proof-preserving translation and optional executable extraction as distinct modes sharing a source-faithful capture. Distinguish translation for understanding from translation needed to ship an application.
- Integrate acceptance through the existing Flexible Pipes execution envelope and the shared ai-ci evidence rules; no direct publication or merge based on unverified generated source.
- Keep maintained Idriç syntax under `STYLE.md` and use `.idr` for inherited compiler implementation. Do not make the compiler bootstrap depend on an unfinished new dialect.

## References and source grounding

- Rocq [Extraction reference](https://rocq-prover.org/doc/master/refman/addendum/extraction.html): Haskell, OCaml, Scheme, and development/debugging JSON *post-erasure* output.
- [MetaRocq](https://github.com/MetaRocq/metarocq) and [9.1 Template-Rocq documentation](https://github.com/MetaRocq/metarocq/blob/9.1/README.md): pre-erasure quotation, PCUIC, environment representation, and metatheory; no checked Idriç emitter implied.
- [Idris 2 universe FAQ](https://idris2.readthedocs.io/en/stable/faq/faq.html), [multiplicities](https://idris2.readthedocs.io/en/latest/tutorial/multiplicities.html), and [implementation overview](https://idris2.readthedocs.io/en/latest/implementation/overview.html).
- Existing local [`rocq` reference branch](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md), [Oodriç charter](https://github.com/isomorphisms/Idric/blob/Oodri%C3%A7/OODRIC.md), [Odriç charter](https://github.com/isomorphisms/Idric/blob/Odri%C3%A7/ODRIC.md), and [Adriç interface research](https://github.com/isomorphisms/Idric/blob/Adri%C3%A7/_/docs/design/adric/tls-api-language/api-structure.md).

This design records mathematical and compiler requirements. It is not a compilation, checked proof, verified logical translation, independent acceptance result, or implementation claim.
