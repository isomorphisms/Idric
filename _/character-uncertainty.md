# Character uncertainty

Status: language-design note, 2026-10-06. The idea predates the current compiler work and is being revived as a typed uncertainty object rather than as fuzzy parser behavior.

## Companion notes

- [Econometrician in a Box](https://github.com/bl4ckb4ll/econometrician/blob/main/notes/character-uncertainty.md)
- [Idriç](https://github.com/isomorphisms/Idric/blob/Idriç/_/character-uncertainty.md)
- [ARM Thumb / direct backend work](https://github.com/fuego-ironworks/idric-arm-thumb/blob/main/_/character-uncertainty.md)
- [ICK](https://github.com/dilapidated-shed/ick/blob/main/docs/character-uncertainty.md)

## Semantic requirement

A character can be uncertain for different reasons. Idriç should preserve those reasons in the type-level/data-level model instead of representing "maybe this character" as one anonymous scalar confidence.

Initial evidence channels:

- **visual shape** — e.g. lowercase `b p q d` can be near each other as rendered shapes;
- **input geometry** — e.g. a broad QWERTY neighborhood centered at `D` is

  ```text
  W E R
  S D F
  Z X C
  ```

  which expresses motor/touch proximity rather than glyph similarity;
- **empirical confusion** — a learned or measured relation with explicit provenance.

More channels can be added later, but these must not be conflated.

## Sketch, not yet surface syntax

The semantic structure should be approximately:

```text
uncertain character
  observed character
  candidate hypotheses
    intended character
    one or more evidence records
      channel
      distance / cost / rank / calibrated probability
      context
      provenance
```

The important point is not the spelling of constructors. The important point is that the program can distinguish:

- structural neighborhood from probability;
- visual evidence from physical-input evidence;
- one observation from a distribution over intended characters;
- calibrated probabilities from uncalibrated costs;
- character identity from the representation used to store it.

A later design can decide whether the core container is a `choice`, a record plus `List`, a nonempty weighted structure, or another form. Do not freeze storage into the source semantics.

## Combination

Combination belongs above the individual evidence records. If two channels contribute to the same candidate, retain both contributions. A statistical layer may later produce a posterior or normalized ranking, but only with an explicit model.

This follows the broader Idriç rule that semantic operations must stay named as semantic operations rather than disappearing into machine tricks.

## Parser boundary

This is a program data type, not permission for the Idriç lexer/parser to silently repair source code. Source text remains exact unless a future feature explicitly introduces uncertain-source input with its own acceptance rules.

## First implementation questions

1. What is the canonical semantic name: `UncertainCharacter`, `CharacterEvidence`, or a composition of smaller types?
2. What minimal interface works without choosing a probability model?
3. How are Unicode characters represented without assuming one byte per character?
4. Which operations are total: add evidence, union candidates, restrict candidates, best candidate under an explicit ordering, normalize calibrated weights?
5. Which invariants should the type checker enforce, such as nonempty candidate sets or provenance attached to calibrated probabilities?

The ARM Thumb and ICK notes deliberately leave compact storage and lowering downstream of these semantics.
