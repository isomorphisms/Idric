# Keep smoke fixtures out of the pinned source tree

The real VIN consumer built owned Idriç and ran its complete smoke suite, then
the independent maintained FP source-pin gate refused the compiler checkout.
At e8b9173ab2d840ef0cf212698ea2fee97bd9e807, edric007 copies two compatibility
sources beside its run script and leaves them untracked. Run39356116445 at
CLI head e09f199c23444de0a07f5fa50680989ffc095aa8 records both source paths,
then enforced-source-pins FAIL. Artifact12236465328 retains the refusal; its
ZIP SHA256 is2614589b985a0f61d7914b9b28f9c00e912e75d3ebc46f812ecabb626a627810.

The same original fixture writer remains at current canonical Idriç source
3f7f707968a5aa3ac7e62d9c29cbc5051db92001. Move those exact byte copies under
the test's existing ignored build directory and run the same compiler and
executable there. Preserve the compatibility .idr names, expected output and
complete smoke selection; this does not restyle the inherited test harness or
claim a new language/backend. The existing POSIX testutils/run interface is an
explicit inherited harness boundary, not a newly introduced shell layer.

Type/effect sketch: canonical units examples are immutable inputs; the fixture
directory owns two derived source copies plus compiler output. The unchanged
compiled test supplies the same expected stdout. Only the build directory is
mutable, and the source-pin gate remains unchanged. No generated file is
deleted or ignored to conceal a dirty source tree.

The existing type-system workflow now builds native compiler support through
the qualified pinned ICK profile, executes all smoke tests, checks byte-identical
fixture copies and requires the source test directory to remain clean. The
previous real-source writer is the retained known-bad specimen; restoring it
makes the new source-location gate fail after the same numerical test passes.
Current-head hosted evidence and the downstream installed/provider rerun remain
required before claiming either acceptance. Physical A1/C67 remains NOT_RUN.

The initial Git-data publication31e359f2 inadvertently used mode100644 for
this existing executable test runner. Its original100755 mode is now preserved;
no script entrypoint or harness invocation is changed. Preliminary runs at the
initial head remain historical and are not current acceptance. The unfiltered
exact-head workflow also keeps compiler-source dependencies eligible.

## Keep the source guards at the fixed smoke-harness boundary

Post-integration review found that the new multi-command CI assertion block
was owned shell orchestration, while the standing contract selects Grease.
The inherited smoke runner fixes the run/testutils interface to POSIX shell;
keep the exact absence, byte-equality and clean-source assertions at that
existing boundary instead. CI again only delegates to the maintained edric
entrypoint; no new shell program or alternate runtime is introduced.

The compiled numerical test's nonzero result must stop the harness before
later successful source guards could mask it. Each guard and Git-status read
also propagates failure explicitly. Expected stdout, canonical source bytes,
compatibility filenames, compiler selection, executable mode100755 and the
independent downstream source-pin gate stay unchanged. Actual initial
source-clean failure and all earlier attempts above remain historical facts.
Current-head hosted full/type smoke checks must pass before this follow-up
lands on Idriç; no new provider or physical-device acceptance is inferred.

The actual Golden.runTest implementation (libs/test/Test/Golden.idr) fixes
the interface to `sh ./run`, pipes only stdout into its golden comparison,
and ignores process status. A guard returning nonzero after the expected
numerical stdout is therefore insufficient. The first follow-up candidate
a135c322 is retained as a failed design attempt, not accepted evidence.
Every failed child/guard now emits an explicit stdout diagnostic and exits1;
compiler failure also stops before any previously created child can execute.

Three Grease process fixtures exercise this exact fixed interface locally in
new disposable Git repositories. They deliberately do not compile source:
their tiny compiler/child subprocesses supply controlled bytes and statuses.
The clean case preserves exact expected stdout and exit0. Five bad cases
(compiler exit23, matching-output child exit57, original-style stray source,
changed derived copy, unavailable Git identity) all exit1 and cannot equal the
golden stdout. The recorded host compatibility Grease is used explicitly;
this is not C++-free FP2 acceptance or an alternate product/compiler path.

Type/effect sketch: the guard driver takes exact absolute runtime/source/new
output paths and creates only disposable fixture trees and retained outputs.
The synthetic compiler reads one finite variant and writes its child under
the fixture build directory; variants mutate only that fixture. The child
supplies known golden bytes and an optional bad status. Actual compiler
acceptance remains the separate exact-head hosted full/type smoke runs.
Local fixed-interface execution passed all6cases; syntax/diff checks pass.

The local guard source SHA256 is221940d307a9f9c8a889c964cb4c7e889361960af94a9e5c18fc840cb68e1b2e.
The recorded Grease launcher SHA256 is37088097c36a2f82cf45aaea9392e4a4cf16155fecb9da87d08a9c7fb4d92e4a;
its declared host compatibility engine is7e31cd05b7a9d8fb2a4a9e003a7f3fcb0159138506d17f0fb28da8cbe22aa85c.
The synthetic compiler fixture is an executable entrypoint100755; the child
source is read and copied with explicit chmod by that fixture. The real smoke
runner remains100755. These identities and local6case results do not replace
the next exact-head full/type smoke runs.
