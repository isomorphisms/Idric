# Batch compiler errors must remain failures

The Venn consumer at Flexible Pipes commit
64e0c38e19606468812a47b5de9a5e705c1c17c6 exposed a source-less compiler error:
missing Prelude printed an error but returned zero from both compilation and
checking. Workflow 38344724204 then mislabeled the first negative fixture as an
accepted invalid program. The fixture had never reached its intended check.

The compiler result, rather than the availability of a diagnostic line number,
must determine batch success. A source-load failure must stop before code
generation or execution. A failed code generator must return failure. Ordinary
interactive recovery remains available when no batch action was requested.

The small Idriç program below has type `main : IO ()` and writes one fixed
line. Its `.idr` companion checks the inherited surface. The missing-module
program differs only by a nonexistent import. Neither program uses unsafe
proof escapes or a foreign function. The test runs the actual compiler with
and without the installed library prefix, and separately checks generated Node
output. It exercises the host evaluator, not any native or device backend.
The separate module without `main` exercises failure after a successful load.

The Ithon driver is an explicit subprocess/evidence adapter. Its process results
are observations, not proofs about dependent types. Missing dependencies must
produce nonzero exit status and must never emit a fresh executable.

Observed on Ubuntu 24.04 x86-64 with the checked-Ithon frontend at
`d6e83969f82512e920fb17b44326cb54f31d015c`: the baseline compiler at
`2734ac5a86610eddfab73b1644d72b4ac85a65ee` passed the six positive cases but
returned zero for a missing import. A compiler rebuilt from that base with this
patch passed all 13 process cases: six successful checks/compiles/executions and
seven failures for missing entrypoint, imports, files, and Prelude. The test
driver retains stdout, stderr and process
statuses for each actual invocation. This working-tree build does not establish
standalone-package relocation or hosted CI acceptance.

Tested bytes (SHA-256):

- `Idris/Driver.idr`: `e059fd4dd60c27147389a1105905269de08b507dcee5475c244cb067c334c16a`
- `Idris/SetOptions.idr`: `a6af492444f1546eccb100ed2baad90d68418a066cecb60dc8f92e45db5c8d86`
- generated Chez compiler `idris2.so`: `c57fc180e3365a83993f9e9ccb3baa6566bc41cc430ef0d36ddd9124afed92b7`
- `check.pi`: `b713f87b585197f2915868191f669dcb29e69eeff2d6c42d9082f47d300b8b2b`

Source owner: `isomorphisms/Idric`; consuming pipeline:
`isomorphisms/flexible-pipes` PR #104, “Add reproducible animated college/job Venn pipeline”.
