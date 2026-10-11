# Rocq → Idriç: proof-preserving emitter

Status: **DESIGN / ACCEPTANCE CONTRACT**, updated 2026-10-10. No Rocq emitter, MetaRocq quotation acceptance, Idriç output, or proof-preservation theorem has yet been implemented and qualified by this change.

## Governing destination

**Idriç is the only destination.** The Rocq emitter produces maintained Idriç `.idric` source, or eventually an explicitly specified checked-core Idriç import with equivalent visibility and validation. It must not be designed as a family of output adapters. Idris 2, Haskell, Agda, OCaml, Scheme, Oodriç, Adriç, and Odriç are **not additional destinations** for this project.

Rocq and MetaRocq remain the source-side tooling; the source-faithful intermediate is an internal representation/transport boundary, **not an alternative target language**. Idris 2 remains Idriç's inherited *implementation and compatibility substrate*, not the semantics or syntax that the emitter is allowed to stop at.

The emitter should explore meaningful mathematical translation and executable implementation separately. Preserve mathematical types, theorems, proof terms, and their source contexts before considering program erasure. Do not use today's implemented features of the Idris 2 bootstrap compiler as a permanent limit on what Idriç may represent.

This is an appropriately broad language/compiler effort, not an agreement to translate only identity functions or another permanently narrow subset.

## Existing language work: relevant research, not multiple targets

At the time of this design the canonical repository is `isomorphisms/Idric`, default branch `Idriç` at `2734ac5a86610eddfab73b1644d72b4ac85a65ee`. Maintained Idriç source is `.idric`; inherited Idris 2 compiler implementation is `.idr`. `STYLE.md` and the existing canonical intent examples govern Idriç source spelling and structure.

Other language lines can inform improvements **inside Idriç**, only after explicit semantic decisions:

- **Idris 2:** bootstrap compiler, QTT implementation and compatibility reference; output must not silently degrade into ordinary `.idr` source.
- **Oodriç:** declaration dependency scheduling and normalization barriers, especially purpose-first presentation versus type-level reducibility. It is a separate experiment, not the required build or an emitter endpoint.
- **Adriç:** adverbs, constraints, role-sensitive and intent-oriented naming; a proof translator must not manufacture proven propositions from an informal English-language request.
- **Odriç:** experiments with the compiler, effects, resource lifetimes, runtime and machine interfaces. Its unsettled ANF/ABI are not the proof translation's semantic contract.
- **Historical `rocq` and `coq` branches:** kernel/quotation/extraction research references, not implementation bases. The historical `rocq` note's source snapshot should remain distinguishable from any newly pinned quotation input.

One Idriç destination does not require importing those research branches, adopting their uncertain semantics, or guaranteeing compiler compatibility with them.

## Proposed architecture

```text
Rocq's checked global environment and selected declarations
    │  source and kernel revision, complete dependency closure, assumptions
    ▼
Pinned pre-erasure quotation (MetaRocq / PCUIC candidate)
    │  no proof-erasing extraction as the input
    ▼
Source-faithful Rocq semantic package
    │  terms, contexts, indices, universes, inductives, proof bodies
    │  fix/cofix, opacity, assumptions, source/environment identity
    ▼
Rocq → Idriç semantic translation
    │  explicit mapping, context transport, unfulfilled obligations
    │  no silently invented axioms, erasure, or definitional equalities
    ▼
Idriç emitter and language-facing integration
    │  maintained .idric surface and its compiler elaboration,
    │  or later a separately justified checked-core import
    ▼
Idriç compiler/type checker at an exact commit
    │
    ├── source/target judgment comparison and independent
    │   proof-preservation evidence
    │
    └── optional executable lowering by a specifically named
        Idriç backend, with independent run receipts
```

The source package preserves Rocq's information for the translator. It is **not** a new universal language shared by many output compilers. Its structure must be sufficient to preserve source semantic facts even if the current Idriç checker cannot yet admit a translated declaration. A translation diagnostic with a concrete missing Idriç capability is preferable to a falsely successful theorem.

No Haskell or Agda intermediate is required. Rocq's ordinary extraction output, including its JSON debug form, is not a substitute for pre-erasure quotation when proof terms are needed.

## Source-faithful package requirements

A quoted package should retain, or explicitly report inability to retain:

- immutable source Rocq/MetaRocq versions, original kernel check, source file/declaration identity, original qualified names, and exact environment/dependency identity;
- complete transitively needed definitions, type signatures, bodies when accessible, opacity/transparency and explicit assumptions, including `Axiom`, `Admitted` and missing proofs;
- local telescope, binder identity and indices, Π, λ, let and application structures, and capture-free substitution/renaming semantics;
- `SProp`, `Prop`, `Set`, `Type` levels, universe polymorphism, cumulative constraints and permitted eliminations;
- inductive and coinductive definitions, indices, parameters, constructor signatures, motives, positivity and elimination restrictions, including mutually recursive blocks;
- guarded fixpoint/cofixpoint structure and reduction equations, including the original termination evidence;
- equivalence classification (source definitional equality, separately proved propositional equivalence, assumes an axiom, or unresolved);
- source-derived provenance for every mapping or semantic obligation, not only textual pretty-printing.

Quoted input must pass source-side integrity checks. Complete source certification and successful quotation are separate observations. Quotation cannot by itself certify an Idriç interpretation.

## The Idriç target contract

The project must specify **the target language's meaning**, not merely output resembling familiar Idris code. Required Idriç features and obligations include:

| Rocq construct | Idriç destination question |
| --- | --- |
| Universe-sorted `SProp` / `Prop` / `Set` / `Type` | Which source sorts and universe constraints can Idriç represent and independently check? Which require actual language/kernel work? |
| Dependent Π and λ | How do quantification, named binders, implicit arguments, application, substitution, and scopes correspond to Idriç's checked terms? |
| Inductive families and dependent eliminators | Are constructor, motive, pattern-match, positivity, elimination, and computation principles preserved? |
| Equality and proof terms | Does proposition-level `=` mean the required relation? Are `Refl`, transport and dependent rewriting valid under the checked Idriç rules? |
| Natural-number data and indexed sequences | Where `Number`, `SizedList`, `ListOfLength` or a domain-specific family is appropriate, which induction and reduction facts establish correspondence? Never blindly substitute `Nat` or `Vect`. |
| Fixpoints, cofixpoints, guardedness | Can Idriç establish the same recursion, productivity, and definitional reduction facts without `assert_total`? |
| `Prop` erasure and quantitative binders | What evidence maps source proof relevance and elimination rules to Idriç quantities? Rocq proof erasure is not the same as QTT usage `0`. |
| Axioms, opaque definitions, imported modules | How are assumptions and bodies represented? A theorem depending on an assumption is never relabeled axiom-free. |
| Declaration order and definitions | How can Idriç emit understandable source while still satisfying elaboration, normalization and dependency barriers? |
| Idriç executable behavior | Which compiled artifacts preserve computational meaning, and which are proof-only? Runtime backends do not determine mathematical meaning. |

Current Idriç vocabulary is not negotiable merely because the source is from Rocq: use `Number` for the maintained nonnegative whole-number surface, `Text` for decoded text, `→` for arrows, `=` for propositional equality, and `≟` only for runtime decidable equality. Inherited `Nat`, `String` and `Vect` are available only where compatibility or a separately proved semantic translation calls for them. Preserve the intended mathematical object rather than choosing a convenient representation first.

**Universe blocker:** Rocq's universe hierarchy and impredicative logical sorts cannot be validated by simple Idris 2 `Type` printing. Idris 2's inherited `Type : Type` and its missing general cumulativity mean that acceptance by the inherited type checker is not, on its own, certification of Rocq-level consistency or logical preservation. The emitter must be allowed to surface *required Idriç kernel extensions* as explicit blocked obligations rather than throw away source information. Which such extensions to adopt is a separate Idriç language design decision.

**No axioms by translation trick:** Never turn unsupported cases into unchecked axioms, postulates, opaque primitives, guessed equality proofs, placeholders, `believe_me`, `assert_total`, or automatically erased proof bodies and then claim proof preservation.

The translator's checked obligation is a relation between judgments, schematically:

```text
Rocq Γ ⊢ term : type
   ── source quotation and explicit correspondence obligations ──►
Idriç translate(Γ) ⊢ translate(term) : translate(type)
```

This diagram is a *desired theorem schema*, not an already established translation theorem. It must explicitly account for source/target conversion, universes, assumptions, binding, inductive computation, and quantities. Successful Idriç typechecking is a necessary gate for an accepted target declaration, not sufficient proof of semantic correspondence.

## Acceptance evidence at exact revisions

Acceptance should be recorded through the established Flexible Pipes job envelope and ai-ci checks, binding source, target and artifact revisions. No pass or merge may be manufactured from unrun stages.

| Stage | PASS requires |
| --- | --- |
| Source | The chosen Rocq declarations check in the pinned Rocq kernel; the complete assumption closure is recorded. |
| Quote | Pinned MetaRocq or equivalent pre-erasure quotation runs and produces a faithful, checkable package with universes, required bodies and provenance, or explicitly identifies missing source information. |
| Map | Every supported quoted construct is accounted for in the Rocq→Idriç translation, with explicit obligations/rejections for all unsupported constructs. |
| Emit | Actual maintained `.idric` source is generated, or a specified Idriç checked-core import is provided; source structure and provenance are retained. |
| Idriç check | The *actual Idriç compiler*, pinned to its source revision, accepts output without unresolved holes, unapproved axioms or bypasses. |
| Mathematical preservation | Independent proof/certificate or specifically justified bounded semantic equivalence establishes the precise claimed translation relationship; merely passing Idriç's checker is not enough. |
| Execution (if claimed) | A named Idriç backend runs the generated program on its claimed platform, without a substitute backend. |

Use separate `UNRUN`, `BLOCKED`, `FAILED` and `PASS` statuses and never interpret `GENERATED` as `TARGET_CHECKED` or `PROOF_PRESERVED`. An axiom-dependent result can be reported as conditionally checked only under a recorded context, not as an axiom-free theorem.

## Working corpus and expansion

The checked input corpus should develop into a meaningful mathematical testbed, not define the ultimate size of the emitter:

- polymorphic identity with universe constraints and explicit context transport;
- dependent families, constructor arguments, motives, induction and equality transport;
- recursive proofs, guarded/coinductive declarations and mutually defined types;
- negative cases for assumptions, opacity, incompatible universe constraints and proof-irrelevant elimination;
- checked Idriç output demonstrating import, module/dependency mapping, semantic conventions, and (when appropriate) runtime behavior;
- larger theorems, leading eventually to Dirichlet characters, arithmetic identities and Euler-product formalization.

The initial proposed Rocq quotation corpus lives under `examples/translation/rocq`; its source and driver are currently **UNRUN**. No `.idric` artifact or real quotation package has yet been produced. Expand the tests as implementation establishes real capabilities; do not redefine success to mean source generation alone.

## Implementation and ownership

1. Pin Rocq/MetaRocq versions and qualify full quotation without proof erasure.
2. Implement the source-faithful package and validate source identity, assumptions and universe constraints.
3. Make one explicitly owned **Idriç** translation/emit boundary; choose `.idric` and/or a truly checked Idriç core import, not an inherited Idris 2-only endpoint.
4. When the target cannot express a Rocq construct, identify the precise missing Idriç semantic feature and the required kernel/elaboration change. Do not promise that all source terms already admit interpretation.
5. Qualify generated Idriç source with the real compiler and separate preservation checks. Direct native, shader, mobile or other Idriç runtime codegen belongs to separate execution gates.
6. Preserve Oodriç/Adriç/Odriç findings only as inputs to an explicit Idriç design decision, not output adapters or extra deliverables.
7. Record every stage with pinned receipts in Flexible Pipes and ai-ci; keep this PR in draft until actual acceptance evidence exists.

## Source references

- Rocq [extraction reference](https://rocq-prover.org/doc/master/refman/addendum/extraction.html): ordinary extraction is proof erasing, and is not the desired source representation.
- [MetaRocq](https://github.com/MetaRocq/metarocq): candidate quotation / PCUIC metatheory; must be pinned and checked before relying on its specific APIs.
- [Idris 2 FAQ](https://idris2.readthedocs.io/en/stable/faq/faq.html): inherited universe limitations; [QTT multiplicities](https://idris2.readthedocs.io/en/latest/tutorial/multiplicities.html).
- Local: `STYLE.md`, `AGENTS.md`, [historical Rocq note](https://github.com/isomorphisms/Idric/blob/rocq/rocq.md), [Oodriç charter](https://github.com/isomorphisms/Idric/blob/Oodri%C3%A7/OODRIC.md), [Odriç charter](https://github.com/isomorphisms/Idric/blob/Odri%C3%A7/ODRIC.md), [Adriç interface research](https://github.com/isomorphisms/Idric/blob/Adri%C3%A7/_/docs/design/adric/tls-api-language/api-structure.md).

This specification documents intent and acceptance requirements; it is **not** a checked or working Rocq→Idriç proof translation.
