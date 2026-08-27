# Odriç

Odriç is the deliberately unsettled compiler line on the `Odriç` branch of
Idriç. It exists so that `ish` and the language used to implement `ish` can be
born together. `ish` does not have to pretend that Idriç already supplies a
stable ANF, prelude, primitive set, runtime, or native ABI.

## Starting facts, not inherited laws

This branch begins at Idriç commit
`081b9cde0591154839fb5d80d76e5570e0436300`.

At that point, the checked-in Idriç-specific implementation consists mainly
of the `.idric` source boundary, `choice ... one_of`, filename-scoped Unicode
syntax aliases, bootstrap support, vocabulary decisions, and compiler-checked
koans. The inherited Idris 2 compiler and its backends can still bootstrap and
run programs, but Idriç does not yet have a general direct-native binary path
of its own.

These are all open to deliberate replacement in Odriç:

- ANF and the boundaries around it;
- the prelude and what is primitive rather than library-defined;
- text, bytes, arrays, argument vectors, and their representations;
- effects, errors, ownership, and resource lifetimes;
- calling conventions, runtime seams, and target code generation;
- source notation that was inherited from Idris rather than chosen for Odriç.

The current Idris 2 tree is bootstrap material and accumulated knowledge. It is
not Odriç's specification.

## Co-design with ish

`ish` is Odriç's first deliberately co-evolving client. Pressure is allowed to
travel in both directions:

```text
ish program
    -> ish parser and evaluator written in Odriç
    -> Odriç types, primitives, and lowering
    -> operating-system process boundary
```

A concrete `ish` need should expose the next missing Odriç facility. Odriç
should then implement the smallest coherent facility, rather than predicting a
complete shell runtime or preserving an Idris mechanism merely because it is
already present.

The first pressure is intentionally narrow: source spans, a distinction
between source text and argument bytes, an exact one-to-many argument
representation, process-entry values, and the Linux `execve` boundary.

## Native-work rule

No Odriç or `ish` native acceptance gate may pass by routing through RefC. A
program-specific assembly scaffold may be useful while bringing up a syscall,
but it must be named as a scaffold; it does not count as implementing an Odriç
or `ish` language form.

The first joint acceptance target is specified in the `ish` repository. It is
one parsed simple command becoming one process with exact arguments and status.
