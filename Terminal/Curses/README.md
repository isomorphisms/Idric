# Curses terminal contract

Status: first design sketch, 2026-09-11. No callable Idriç bindings, compiler
changes, native execution, or device acceptance are claimed by these files.
The declarations are semantic notation, not a promise of accepted grammar.

## Purpose

Give Idriç programs typed access to a terminal without making them understand
curses pointers, attribute masks, sentinel integers, or Python objects.
VisiData motivates the requirements; the library must also serve other terminal
programs. Sheets, columns, selection, command registries, replay, and plots
belong to applications, not to this library.

```idric
terminal ← open terminal using terminal_settings
window ← open window on terminal within available_space
write heading to window at heading_position with heading_style
present window on terminal
event ← read event from terminal using input_wait
close window
close terminal
```

This is a purpose-ordered outline. Real execution must bracket acquisition and
cleanup on success, failure, and cancellation; the straight-line example is not
an exception-safe implementation.

Read [CONTRACT.md](CONTRACT.md) for types and state transitions,
[ncurses/API.md](ncurses/API.md) for the foreign boundary, and
[acceptance.tsv](acceptance.tsv) for proposed positive and negative cases.
Every acceptance entry is pending.

## Ownership and integration

The core Idriç repository owns this target-neutral contract and the future
generic curses adapter. Application repositories depend on it rather than
copying foreign declarations. Architecture repositories own native calling
conventions and lowering. This work does not introduce or restore RefC.
Calling a C library from native-generated code is distinct from using a compiler
backend that emits C; neither source declarations nor a C test driver prove the
native-generated call path.

Existing STYLE.md and the intent examples remain authoritative. No changes to
Number, Text, Data.Text, .idr compatibility, default totality, or core numeric
semantics are part of this proposal. Domain counts, coordinates, and durations
below state their bounds without assigning them a machine representation.

## Evidence and scope

Compiler base: `isomorphisms/Idric` at
`7e27052ca862853bfe976c287fe9d7fdb7535943` on `Idriç`.

Consumer source inspected: `saulpw/visidata` at
`1d8a6fcd7f031a140c5662943af868e9108343ed`. The hook inventory covers the named
files in ncurses/API.md, not every dynamically imported plugin or all ncurses
entry points. Newly required operations are identified separately from observed
Python calls. Unsupported and unimplemented capabilities must stay visible.

No VisiData fork location is established by this document. Its application type
sketch belongs in that fork, independently of this compiler-repository branch.

## Next implementation slice

Implement acquisition/cleanup, a bounded text window, wide-character input,
resize, and presentation first. Compile and execute a native Idriç caller of
that slice. Then exercise mouse, colors, suspend/resume, and failure paths.
Keep phone ARMv7/Termux, tablet AArch64/Termux, and each host target as separate
receipts. Pin the compiler, adapter, headers, library, terminal description,
locale, executable, and actual target; never transfer acceptance between them.
