# Checked mathematical rotation export

Status: PARTIAL

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
including handwritten Unicode input and targeted corruptions. Neither of these
results is yet an actual export receipt or completion of NIR-0.

The new compiler modules typechecked with the owned Chez compiler reporting
0.8.0-1b5176dc9 (its worktree is currently 2bce7677f513d711875e978bd6f5ad28b9e54d58).
The whole modified compiler generated Chez source. Its normal optimize-level-3
Chez object build was killed with status 137 in this disposable host. A
level-zero build and actual exporter acceptance are being checked separately.
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

No numerical plan, native ICK lowering, Fourier integration, Android execution
or physical acceptance is established by these tests. Universal norm, dot and
inverse laws are not proved; this slice independently validates a restricted
constructor calculus and checks its selected exact samples.
