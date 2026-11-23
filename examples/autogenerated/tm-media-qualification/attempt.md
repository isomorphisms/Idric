# Program attempt: TM media compiler qualification

Status: PARTIAL — local archive qualification passed; hosted exact-head checks pending.

## Purpose

Continue STAR TM-1 at its first dependency, SUN TM-S1: qualify a usable
pinned Idriç compiler/runtime against the original Nightingale media contracts.
The original experiment ran a host media oracle but did not compile Idriç.

## Type-system sketch

Values are artifact identities, observation channels, source sample extents,
exact rational clock rates, frame positions, decode times, and presentation
times. A checked observation proves a predicate of a reported value; it does
not prove that a decoder or mutable file reported truthfully.

The recovered `MediaEvidence.idric` supplies the intended domain types:
`Observation identity channel value`, `CheckedObservation`, `SourceWindow`,
`DurationAgreement`, `RegularCoverage`, `FrameAtTime`, `DecodeTime`, and
`PresentationTime`. Pure checked constructors return `Maybe` witnesses.
The executable actions obtain runtime arguments, apply these constructors,
report named checks, and return a nonzero status on a failed required claim.

`RuntimeMedia.idric` discovers a frame sequence's size from runtime arguments
and retains it in a domain-indexed collection. `Qualify.idric` compiles and
executes the fixtures, records command/stdout/stderr/status files, checks exact
runtime output, and admits negative controls only for status 1 and intended
type-mismatch diagnostics. Its process boundary uses the inherited escaping
API and fixed stream redirections. It is an Idriç program, not a replacement
shell, compiler, decoder, or package verifier.

Negative compilation must distinguish artifact identity, evidence channel,
clock role, and image storage order from temporal scanning. Each negative
must be preceded by an accepted positive sibling under identical pins.
Exact integer cross-products avoid rounding timestamps or durations.

The immediate target is Linux x86_64 with the owned compiler's Chez backend.
This neither selects nor qualifies Android, DEX, GPU, or physical execution.
Compiler/runtime acquisition and execution must retain source and material
identities. Archive relocation, tamper refusal, and Cat Food delivery remain
separate requirements until actually exercised.

The distribution stage installs the existing compiler libraries/support through
the owned Make targets, copies the compiled compiler and pinned Chez runtime,
and retains both heap files and explicit system-libc/libm provider boundaries.
An archive consumer invokes the delivered compiler application through the
delivered runtime, with its own prefix and heap paths. It must not repair
absolute launchers or rebuild a missing executable.

The unchanged ai-ci material admission program owns file/mode/path inventory
validation. Its exact pinned `inspect_material` operation generates the producer
inventory. Caller-owned required rows are hashed from the original payloads;
the approved inventory digest remains outside the archive. A separate admission
stage must accept an extracted package and reject changed payload bytes and a
stale producer manifest for their intended diagnostics. Media qualification then
runs using that admitted compiler/runtime on a host without the producer tree.

## Recovered inputs

Source: `nightingale-typed-media-first-pass.zip`, created October 7, 2026.
Archive SHA-256:
`bcb19ea8f15f28f86390e6b263ab25cb436059d34245d7d5f6edcde207089fac`.
All 317 entries in its `MANIFEST.sha256` verified on November 15, 2026.
The original six `.idric` files are retained under `original/` without edits.
Maintained repairs, if needed, live outside that historical directory.

## Idriç attempt

Compiler source: `isomorphisms/Idric`, branch `Idriç`,
`2bce7677f513d711875e978bd6f5ad28b9e54d58`.
The repository's older `dilapidated-shed/Idric` coordinate redirects to that
same GitHub repository (numeric identity 1335092603).
Acquire the compiler using its canonical `edric bootstrap` entrypoint.
Chez 10.4.1 source archive SHA-256:
`2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308`.
Its prescribed bootstrap C toolchain is a compiler-bootstrap boundary,
not an alternate consumer backend.

First compile the unchanged candidates. Preserve diagnostics and separately
record repairs, source compatibility, runtime behavior, and intended negative
rejection. No compiler defect is inferred from an unavailable compiler.

## Result or failure

The canonical bootstrap completed on Linux x86_64, Debian 13.6. The nine
canonical smoke fixtures and one-step emitter passed through `edric test`.

The unchanged historical source first failed at `MediaEvidence.idric:87`:
`Expected '=>' or 'impossible'` because `proof` is reserved. After renaming
that binder, checking reached an undeclared capitalized `Value` in the
`check_observation` signature. The maintained signature now explicitly binds
`value_type`. Four negative modules also needed a capitalized `Negative`
namespace matching their file paths. The original six sources remain unchanged.

The repaired ten-case media executable, four intended type-mismatch rejections,
positive siblings, inherited `.idr` compatibility, runtime-sized frame sequence,
and malformed/failed runtime controls passed using the real compiled compiler
and freshly rebuilt libraries. Local fixtures are an overlay on compiler
revision `2bce7677f513d711875e978bd6f5ad28b9e54d58`; the receipt hashes identify
their actual bytes rather than pretending they were already in that commit.

A clean-environment pilot replay also passed through the packaged compiler,
runtime, support and libraries. The first independent material-admission run
caught an incorrect consumer expectation: Chez installs its executable as mode
555, not 755. Its pinned `makefiles/install.zuo` establishes 555 for the executable
and 444 for heap files. The producer expectation was corrected from that source;
no delivered executable was chmodded or repaired to satisfy the check.

The final archive then passed with both producer checkouts renamed away and
the consumer environment cleared. All ten original media checks, four semantic
type rejections and their positive siblings, ordinary `.idr` compatibility,
runtime counts of 180 and 4, a missing-frame count of 179, wrong duration,
malformed integer and zero-denominator controls passed. The unchanged shared
observer admitted 914 inventoried payload files, rejected changed payload bytes
with `MATERIAL-APPROVED-INVENTORY`, rejected a stale producer record with
`MATERIAL-RECORD`, and admitted the same inventory again after compilation and
execution. Both negative material processes exited 1 for their intended reason.

Historical local archive SHA-256:
`f627f6148a4fad33497999558084952c405f19dbfe73c6ef4b7126c09fce1b29`.
Approved material-inventory SHA-256:
`a22e8adc39457bf91ab7720ff17d60e6db38e034278f2eb954f881f2e4f67d1a`.
These identify the local compiler-2bce7677f fixture-overlay experiment, not a
published release or a future hosted archive. The workflow records its own
current-head identities, packages the runtime, and replays it on a separate
runner with no producer checkout. Its result is not inferred from the local run.

## Fallback

None. No Python, JavaScript, RefC, generated-C, or Java replacement.

## Idriç language work exposed

No compiler-language defect is required to repair this fixture. Its initial
failures were source and module-layout errors. The next semantic boundary is
admitting real immutable observation bytes, not manufacturing media truth from
an indexed report. That remains TM-S3 work.

## Evidence boundary

Archive recovery, the original manifest, compiler bootstrap, source repair,
runtime behavior, semantic negative controls, corrupted-material controls,
replay without producer checkouts and post-execution inventory verification passed.
Hosted exact-head evidence remains pending until the corresponding workflow runs.
This example does not authenticate observations of actual media bytes.

## Preserved downstream work

The recovered October 8 dependency order was TM-S1 → TM-S3 → TM-S4/TM-S5 →
TM-S6, with TM-S2 independently runnable. The remaining jobs concern replay
and counterexample validation; checked admission of actual observations;
temporal/mathematical correspondence; raster, colour, encoded timing and audio;
and integration with the real CPU/GPU application. This compiler slice does
not complete those jobs.

The first experiment used a 1024-sample window at a 1600-sample hop and observed
only 64% of source positions. The later correction also showed that continuous
1024/512 analysis plus a 30fps latest-state display can omit an impulse at
sample 1800. Analysis coverage does not establish visible event preservation.
TM-S4 must preserve that distinction and compare the strongest completed state
since the preceding picture rather than silently choosing latest-state display.
The six-second recovered derivative is a historical compiler fixture, not a
new selection of the original archival clip or a permanent sampling policy.
