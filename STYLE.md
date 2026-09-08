# Idriç source style

This file records Idriç rules that have actually been decided. It is deliberately
incomplete. The language and its programming style are still being worked out
with a human in the loop.

Valid Idris is not automatically good Idriç. Do not fill gaps in this document
by reverting to conventional Idris, Haskell, or generic functional-programming
style.

## Established mechanical rules

### `Nat` is prohibited in new Idriç-facing source

Use `Number` when the program means an ordinary number or count.

If nonnegativity, sign, bounds, units, or another restriction are part of the
meaning, do not reach for `Nat` as an implementation-shaped substitute. Give
that meaning a semantic restricted type.

Do not mechanically replace every historical `Nat` in inherited Idris code.
This rule prevents new Idriç source from adding more of it.

### `Vect` is prohibited in new Idriç-facing source

Use `List` when the length is not part of what the program means.

If a length or shape really is semantically important, preserve that fact with
a domain-specific collection or restriction. Do not use generic `Vect` merely
because Idris makes it available, and do not blindly replace `Vect` with `List`
when doing so would erase meaning.

### Use `snake_case`, not lower camel case

A newly introduced lowerCamelCase identifier is a style canary. It often means
the surrounding code was written from Idris/Haskell habit rather than from the
Idriç design.

The mechanical check warns rather than rewrites it. When the warning appears,
inspect the whole declaration and its vocabulary before deciding the correct
`snake_case` name.

### Use real arrows in Idriç-facing notation

Use `→` and `←`, not ASCII `->` and `<-`, when writing Idriç-facing source.

An ASCII arrow is also a style canary. Do not treat the warning as a request for
blind character substitution; re-check the declaration for other inherited
Idris/Haskell defaults at the same time.

## Human corrections are part of the specification

There is not yet a blessed directory of canonical "good Idriç" examples.
Current work in Idriç, ICU, ish, Idric-Net, and related repositories is still
being corrected and refined.

When the user corrects generated code, treat the correction as evidence about
the language style. Repeated corrections should become explicit rules or
mechanical checks when the rule is clear enough.

Do not declare an example canonical without explicit human approval.
