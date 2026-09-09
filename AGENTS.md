# Agent instructions

## Cross-repository anti-patterns

These rules apply in addition to stricter repository-specific rules below.

- Claim only the boundary actually exercised. Source presence, fixtures, generation, compilation, packaging, installation, launch, smoke checks, semantic execution, backend execution, and physical-device execution are different evidence levels. If a stronger boundary was not exercised, report it as unverified.
- The named mechanism is part of acceptance. Do not substitute a fallback, oracle, mock, alternate backend, alternate executable, lookalike renderer, or conventional nearby toolchain and keep the original label.
- Do not weaken acceptance to obtain green. Repair the implementation. Change the contract only when the requirement itself is shown to be wrong or obsolete, and keep that semantic decision explicit. Targeted negative tests must fail for the intended reason when the distinction matters.
- Keep semantics independent of convenient representations. Mathematical, domain, and language objects are not defined by tuples, matrices, compiler nodes, ABI records, transport bytes, storage shapes, or UI payloads unless the semantics explicitly say so.
- Current explicit human corrections and current architecture outrank stale source, generated code, upstream conventions, older branches, bootstrap precedent, and familiar practice. Do not restore a rejected abstraction under its old name or a near-synonym.
- Acceptance belongs to an exact head and its material pins. An ancestor's, sibling branch's, or previous pin's green result is historical evidence only.
- Mocks, fixtures, harnesses, and today's platform adapter must cross replaceable interfaces; they do not get to define the permanent architecture merely because they are currently convenient.
- Preserve the repository's chosen implementation path and layout before introducing familiar infrastructure. Where `_` is an established machinery boundary, keep build/package/generated/test/compiler material there and preserve canonical source and intended soft links.

## Do not substitute weaker evidence

A design, source file, generated text, fixture, successful compile, or green workflow proves only what it actually exercised. Do not describe a compiler feature or backend as implemented merely because related code exists.

When a task names a compiler/backend path, acceptance must exercise the exact current source through that path and identify the produced artifact. If execution is part of the claim, execute that artifact. A fallback, oracle, bootstrap implementation, handwritten equivalent, or different backend is not evidence for the named path.

Report unverified boundaries as unverified. Do not promote an old receipt, another branch's result, or a nearby smoke test into current acceptance.

## Do not weaken acceptance to get green

When an intended property fails, repair the implementation. Do not obtain green by deleting a refusal case, accepting a broader class of malformed input, replacing semantic assertions with existence/smoke checks, dropping ordering/identity/serialization cases, or testing a substitute implementation.

Change a test only when the intended property itself is shown to be wrong or obsolete. Keep the reason for that semantic change separate from the fact that the implementation failed.

Negative/refusal tests are part of the contract. A rejection test should distinguish the intended rejection from an unrelated crash or generic failure when the distinction matters.

## Keep semantics above representations

Do not define a mathematical or language-level object by whichever representation is currently convenient for one backend. Tuples, components, matrices, ABI records, primitive widths, compiler IR nodes, and storage layouts are representations unless the language semantics explicitly make them part of the object.

Expose purpose-level operations and invariants before representation plumbing. Keep backend-specific encoding behind the semantic boundary so a representation can change without redefining the object.

## Current design outranks stale precedent

Before preserving, restoring, renaming, or generalizing an abstraction, inspect the current branch and nearby current design work. An explicit later human correction outranks stale source, generated code, bootstrap compatibility, an old branch, upstream Idris conventions, or an earlier agent's terminology.

Do not reintroduce a rejected ontology under the old name or a near-synonym merely because older code used it. If current terminology is unsettled, preserve the established semantic distinction without inventing a new generic replacement.

Do not "clean up" deliberate Idriç design into conventional textbook or upstream structures until the repository's actual intent is understood.

## Exact head and exact pin

Tie every acceptance claim to the exact commit under review and to every compiler/backend revision that materially produced the artifact. A successful run for an ancestor, sibling branch, mutable dependency, or previous compiler pin is historical evidence, not acceptance of the present head.

When repairing a failing exact-head job, isolate the first real failure before changing semantics or acceptance. Preserve the purpose of the branch and its required pins while doing the repair.