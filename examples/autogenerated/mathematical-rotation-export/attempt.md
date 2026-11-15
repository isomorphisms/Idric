# Checked mathematical rotation export

Status: PASS for the restricted mathematical producer; NIR-0 remains incomplete

Recover the NIR-S1 boundary on current Idriç. The October 8 report names an
unpublished commit, 7126cb70e6da10332a387b3c8da149872dbcbc08, which neither the
current remote nor its original scratch workspace supplies. This is a fresh
implementation, not recovery or verification of that commit.

## Type-system sketch

FiniteSpace retains nominal identity and rank. A rotation is indexed by that
space, its explicit standard Euclidean structure, and its oriented frame name.
Identity, exact rational plane rotation, inverse and ordered composition are
distinct closed constructors. A plane carries bounded distinct axes, a positive
common denominator and checked integer evidence that cosine² + sine² = 1.
Rank has no fixed upper mathematical limit. Dimension zero and one allow identity.

The pure evaluator maps exact rational coordinate samples to exact samples;
it makes no floating precision choice. Runtime constructors validate the same
conditions. Compiler export inspects the checked, normalized Core term before
erasure, independently rechecks the restricted constructors and retains source
name/span/type/term. Provenance is not a proof certificate. Unknown constructors,
holes, forged coefficients, incompatible frames and ranks cannot be lowered.

Output is an internal versioned graph with source provenance. It is neither a
user-facing grammar nor a numerical plan. Numerical and machine lowering,
general-real angles and universal preservation theorems remain separate work.

## Runtime and backend

Use the owned Chez compiler on the build host. Integer arithmetic is exact;
no Double, RefC, generated-C or Android compilation path participates.
The compiler pass is inherited `.idr` bootstrap code; the mathematical API and
acceptance fixtures are `.idric`.

## Verification

The mathematical API typechecked and its Chez executable passed 15 runtime
groups: R128 quarter/rational turns, inactive coordinates, exact sample norms
250/199 and dot 190, composition/reversed inverse, four quarter turns,
preserved dot, rank-zero/one identity, invalid bounds/coefficients/sample
denominators, and runtime space/rank/frame matching. Compile-time failing
blocks verify invalid static construction.

The independently implemented importer compiled and executed 16 groups,
including handwritten Unicode input and targeted corruptions. The rebuilt
incremental Chez compiler then produced an actual R128 mathematical export.
The independent importer checked its graph and retained/reproduced its bytes
exactly. The acceptance entrypoint also rejects forged source coefficients,
axes, frames, wrong root types, holes and missing root selection, and checks
nonzero status for valid-but-wrong identity/sign results. These mathematical
receipts do not establish completion of NIR-0.

The existing edric009 geometry runner also executed all twelve output groups
successfully with the added nominal-space constructor, through the existing
owned bootstrap compiler. This does not test the new exporter.

The new compiler modules typechecked with the owned Chez compiler reporting
0.8.0-2bce7677f (its worktree is 2bce7677f513d711875e978bd6f5ad28b9e54d58).
The 1b5176dc9 tag in that launcher's generated comment identifies the compiler
that produced it, not the executable's own reported version.
The whole modified compiler generated Chez source. Its normal optimize-level-3
Chez object build was killed with status 137 in this disposable host. A
level-zero object build failed with an invalid FASL procedure diagnostic. The
existing incremental Chez build succeeded and executed the actual exporter.
The cause of status 137 has not been established. The compiler workflow's
ordinary whole-program build has not run on this branch.
No RefC/generated-C/stock-compiler replacement is used.

All source is based on isomorphisms/Idric at
2bce7677f513d711875e978bd6f5ad28b9e54d58. Acceptance.idric is the durable
reproduction entrypoint, wired through make -C _ test-mathematical-ir and the
exact-head compiler workflow. Fallback: none.

## Language work exposed

The negative gates require location-free backend errors, source-load errors and
CompilationFailed to return nonzero at the command line. The accompanying CLI
changes cover those paths. The API's implicit space parameters must be resolved
before checking a closed plane's evidence; fixtures keep them explicit and
disable unbound implicit variables. This is internal constructor notation, not
an approved mathematical source surface.

## Evidence boundary

The make -C _ test-mathematical-ir entrypoint is exercised with the incremental
compiler and the existing owned prelude/base/network libraries. It includes
actual rank-zero/one named identity exports and a rank-five Unicode space/frame
export, as well as the R128 rotation and rejection controls. The compiler's
version metadata is regenerated from the source commit before the final replay;
the supplied receipt records the complete commit and material hashes.

No numerical plan, native ICK lowering, Fourier integration, Android execution
or physical acceptance is established by these tests. Universal norm, dot and
inverse laws are not proved; this slice independently validates a restricted
constructor calculus and checks its selected exact samples.

The current pinned shared style gate fails on `Nat` in the two new bootstrap
`.idr` compiler modules. `STYLE.md` explicitly distinguishes that inherited
compiler stratum from `.idric` source. `Number` is a filename-scoped parser
alias, not an available inherited bootstrap type, as Parser.Source records.
No spelling dodge or acceptance exclusion has been introduced. Reconciliation
of that source-role conflict remains a separate required gate; the branch is
not claimed merge-ready.

Public branch publication was rejected by automatic approval review because
the short NIR-0 request did not explicitly authorize public disclosure of the
new local code. No push, PR, hosted CI, merge or release is claimed.
