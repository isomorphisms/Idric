# Pass 3 — variance, duals, and no silent metric

This is the main safety boundary exposed by comparing Einstein notation with birdtracks and ZX diagrams.

## Conservative default

Treat an upper index as a port in a space `V` and a lower index as a port in the corresponding dual `V*` (or the project's eventual precise convention). The canonical contraction is evaluation:

```text
V* ⊗ V -> F
```

Therefore:

```text
Aᵢ Bⁱ
```

can contract after the `i` spaces unify appropriately.

But:

```text
Aᵢ Bᵢ
```

has two covariant/lower occurrences. It should **not** silently contract.

## What would make same-variance contraction legal?

Extra typed structure could.

Examples include:

- a nondegenerate bilinear form / metric `g : V ⊗ V -> F`;
- an explicit isomorphism `V -> V*`;
- compact-category cup/cap structure;
- a representation-specific invariant tensor.

If such structure is present, the elaborator can insert or expose the corresponding map and the explanation trace can say exactly what happened.

That is different from globally pretending `V = V*`.

## Why ZX can look looser

ZX-calculus diagrams are normally interpreted in a compact/self-dual setting where wire bending is meaningful. Under those assumptions, orientation and index raising/lowering can often be suppressed graphically.

That convenience is a theorem/convention of the structure. It is not a universal fact of modules, infinite-dimensional spaces, manifolds, arbitrary tensor categories, or every future object Idriç may type.

## Compiler rule

Never make the parser's desire for a simple graph stronger than the mathematics.

A graph edge should be created only when one of the following is visible:

1. canonical upper/lower evaluation after type unification;
2. an explicit source operation;
3. a resolved structure instance that supplies the needed map;
4. a named theorem/rewrite whose hypotheses are satisfied.

The graph should record which case authorized the edge/rewrite.

## Diagnostic benefit

Then a rejected expression can say something useful:

```text
cannot contract lower i with lower i
both occurrences are in V*
no metric / bilinear form / V ≅ V* witness is in scope
```

That is much better than either rejecting all graphical shorthand or silently doing the wrong mathematics.
