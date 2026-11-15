# Checked mathematical rotation handoff

`MathematicalRotations` extends the existing named finite-space and Euclidean
examples with exact rational plane rotations, identity, inverse and ordered
composition. Spaces, ranks and oriented frames remain in the checked term.
The runtime constructor validates axes and rational coefficients; existential
composition requires equality witnesses for rank, nominal identity and frame.

The owned compiler's `idric-mathematical` code generator reads one closed
definition selected by `--directive root=NAME`. It runs before `prepareExp` and
erasure. It recognizes only the restricted constructors, checks their nominal
space/metric/frame against the checked root type, independently validates the
axes and rational unit pair, and writes schema 1. The existing erased
`idric-one-step` path retains its purpose.

`Compiler.MathematicalIR.parseArtifact` is the independent importer. It retains
the original bytes and rejects unknown schemas, operators, evidence categories,
metrics, orientations, invalid coefficients, missing nodes, bad references and
trailing fields. Labels and provenance are nonempty single-line Unicode text.
Its deterministic tree IDs are local to an export; they are not persistent
spatial-editor identities. The unsimplified inverse/composition graph survives.

`definition`, `span`, `checked_type`, `normalized_term` and `checker` record
provenance. They do not certify arbitrary propositions. The accepted evidence
kind is independent validation of the restricted closed constructors; no
universal preservation proof is claimed. A different valid rotation must still
be checked against the consumer's expected result.

Run the acceptance target from a bootstrapped checkout using `make -C _
test-mathematical-ir`. `Acceptance.idric` stages the sources and executes the
exact compiler, runtime oracle, importer and negative controls. It checks real
R128 exports, rational/quarter turns, inverse/composition, sample norms/dot,
rank-zero/one identity, static/runtime rejection, forged evidence and frames,
incomplete source, wrong root type, wrong backend, missing root selection, and
valid-but-wrong-result mutants. A rejection requires nonzero status and no
accepted output. The compiler workflow runs the same target at its exact head.

This is the mathematical producer for NIR-S4/S2/S9. It does not implement a
numerical precision plan, native ICK lowering, Fourier integration, an approved
source grammar, Android execution or physical-device acceptance.
