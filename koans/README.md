# Idriç koans

These are Idriç exercises, not an Idris 1 suite with a few characters changed.
They live beside the compiler so language changes and teaching examples cannot
silently drift apart.

Bootstrap this checkout and run the koans:

```sh
./edric bootstrap
./koans/run
```

`run` checks the exercises in order and stops at the first compiler objection.
Edit that exercise's `exercise/Main.idric`, use the reported hole type or error
as the next instruction, and run it again. A name beginning with `?` is a named
hole. The compiler reports its required type and the values available where it
appears.

The sequence is:

1. values, types, and named holes
2. functions using `→` and `⇒`
3. lists and length-indexed vectors
4. equality proofs and `Refl`
5. totality and coverage
6. implicit arguments and dependent results
7. erased arguments with multiplicity `0`
8. linear arguments with multiplicity `1`
9. `choice ... one_of`
10. exhaustive lower-snake-case patterns
11. `.idr` and `.idric` compatibility boundaries
12. a small Wegert model combining choices, vectors, and proofs

Reference answers are deliberately separate from the exercises:

```sh
./koans/run --solutions
```

The repository test harness uses `./koans/run --validate`. It proves that every
untouched exercise fails for its intended reason, every solution compiles and
runs, and every result matches its checked-in expectation.
