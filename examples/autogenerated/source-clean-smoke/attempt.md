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
