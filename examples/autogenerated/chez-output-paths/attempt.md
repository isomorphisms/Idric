# Chez output paths and failed code generation

Owner: Idriç issue 138, exposed by IB-X64-01. This is a separate path-literal
correction stacked on the existing batch-failure repair in PR 136. The latter
continues to own CLI failure propagation; this branch does not duplicate it.

## Requirements before implementation

The compiler receives a source file and an output directory as filesystem paths.
The generated `compileChez` file must describe that same path as a Chez string,
without interpreting decimal character escapes as octal escapes. Compilation
must work in directories containing ASCII, whitespace, apostrophes, backslashes,
BMP and non-BMP characters. The resulting real program must print the unchanged
source text. A forced Chez failure must return nonzero and leave no accepted
executable. Correct-looking diagnostics or a leftover output cannot establish
success.

The small Idriç program has `main : IO ()` and emits `chez-path-ready 東京🙂`.
Its `.idr` companion exercises the unchanged inherited language surface. Neither
uses FFI or creates filesystem state. The process test owns temporary output
directories and checks the actual compiler, generated executable and process
statuses. The compiler implementation remains ordinary `.idr` bootstrap source.

## Proposed correction

Use the existing `chezString` literal generator for `compile-program`'s path,
as the separate Chez backend already does. Do not repair generated Scheme after
compilation or replace the compiler. The existing batch-failure owner must
propagate a thrown code-generation error through its established failure path.

The regression belongs to the existing compiler smoke harness, whose external
interface invokes `sh ./run`. That narrow fixed interface is not a new consumer
shell implementation. Every test failure must print a visible refusal because
the inherited Golden harness compares stdout independently of subprocess status.

## Evidence

The independently delivered compiler/runtime at source
`5b55b4444fd66ab940cb8f9b74ee2f79043f148a` passes ASCII, spaces and apostrophe
controls. The strengthened existing `chez037` test observes the real failed
`CHEZ=false` invocation returning zero. That is a failure of the baseline.

A literal backslash output component is a separate observed limitation:
`Libraries.Utils.Path` deliberately parses both slash spellings as separators,
including on Linux. `with\backslash` therefore produces `with/backslash` before
Chez code generation. This one-line Chez literal repair does not change that
global path contract. The original all-path requirement remains incomplete for
literal Linux backslashes; the focused `chez039` positive suite covers ASCII,
spaces, apostrophes, BMP, non-BMP and `.idr` compatibility without claiming that
unresolved case. The failed backslash observation remains in the local process
logs and is not a PASS.

The actual patched compiler was rebuilt through the independently admitted
delivered Idriç/Chez compiler/runtime. Its generated executable passed all six
`chez039` compile-and-run controls, including BMP/non-BMP output directories and
the `.idr` compatibility program. The strengthened failure test initially
looked for the old diagnostic on stdout; the reused PR 136 error path correctly
writes it to stderr and exits unsuccessfully. The test checks that actual
channel and emits its matching line on stdout for Golden's comparison.

Compiled compiler SHA-256:
`6f4916138f8c9f209f3fd466c7ed494194cf465a22433ce8bdb8100e8edc7703`.
The path emitter source SHA-256 is
`e912854eed05e833e56d2a33452784453c3f9a1a5ea90326309eb6f70a457cd0`;
the unchanged PR 136 driver and batch-option implementation hashes are
`e059fd4dd60c27147389a1105905269de08b507dcee5475c244cb067c334c16a`
and `a6af492444f1546eccb100ed2baad90d68418a066cecb60dc8f92e45db5c8d86`.
These are local exact-source build observations; hosted exact-head acceptance
remains pending. No RefC, alternate code generator or physical-device result is
claimed.

Both focused regressions completed with exit zero through that compiled
compiler: `chez039` printed all six expected PASS lines, and `chez037` refused
the forced failure, found no executable and matched its stderr diagnostic.
The unfiltered existing compiler workflow now executes both regressions and
retains their raw compilation/execution files alongside its existing evidence.
