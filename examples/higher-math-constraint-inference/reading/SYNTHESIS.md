# Pass 3 synthesis — from Einstein glyphs to typed diagrams

The three source families line up surprisingly cleanly without saying the same thing.

Cvitanović shows that invariant tensor calculations can be *performed* in a diagrammatic representation where contraction is connectivity rather than repeated index spelling. Coecke and Pavlović show that powerful graphical equations should arise from explicit algebraic structure and laws. Kissinger shows how such diagrams can be represented as graphs, rewritten mechanically, and used as an intermediate form for compilation-like transformations.

Taken together, they suggest this Idriç boundary:

```text
source
  ωᵢ vⁱ

parse / elaborate
  upper i on v
  lower i on ω
  compatible index spaces

bind
  i becomes an internal typed edge

result interface
  no free i

normalize
  apply only laws justified by resolved structures

plan
  choose contraction order / fusion / algebraic simplification

lower
  scalar loop | SIMD | GPU | kernel | closed form | other
```

## The important conceptual split

There are four different things that are easy to conflate:

1. **surface index names** — convenient binding syntax;
2. **typed wiring** — the semantic incidence/contraction structure;
3. **algebraic rewrite rights** — supplied by metrics, duals, Frobenius structures, symmetries, theorems, etc.;
4. **machine realization** — loops, lanes, instructions, GPU work, and storage.

Idriç should preserve those boundaries.

## Why this helps Hindley–Milner-style inference

The HM lesson is not that tensor calculus is secretly Algorithm W. It is that the programmer can omit information which use constrains uniquely or generally enough for the compiler to recover.

An indexed operator can generate:

- unknown index spaces;
- equality/duality constraints from connections;
- free-index constraints on results;
- structure obligations from special operations;
- law obligations for rewrites.

Solving those constraints can produce a typed graph and an explanation trace. That is a much more concrete meaning of “infer the mathematics” than a heuristic that recognizes familiar notation.

## First implementation target

Before adding a general graph-rewrite engine, prove the representation on the existing Einstein fixtures:

1. parse scripted upper/lower indices after lexing;
2. construct typed ports;
3. bind exactly one compatible upper/lower pair into an edge;
4. preserve single occurrences as result boundaries;
5. reject same-variance or over-repeated indices without explicit structure;
6. verify that alpha-renaming a bound index leaves the semantic graph unchanged;
7. require equal free-index interfaces across sums;
8. expose the graph to the compilation-stage observer before backend lowering.

That small path would already connect the keyboard notation, higher-math constraint solver, and AICI realization check without committing to a giant tensor compiler.
