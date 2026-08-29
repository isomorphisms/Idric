# Summary — Cvitanović, *Group Theory: Birdtracks, Lie's, and Exceptional Groups*

## Central move

The book replaces a large amount of coordinate-heavy invariant tensor algebra with a graphical calculus. Tensor legs become lines. Invariant tensors become junctions or other primitive diagrammatic pieces. Contracting indices becomes connecting compatible legs. Closed components evaluate to scalars; unconnected legs describe the remaining tensorial interface.

That sounds cosmetic until one notices what disappears: arbitrary index names, parenthesization noise, and many basis choices. What remains is connectivity plus the algebraic identities satisfied by the invariant tensors.

The book is therefore useful here less as “group theory background” than as a worked example of a representation in which *the operations themselves expose the constraints*.

## 1. Invariants before coordinates

Cvitanović contrasts a canonical/basis-driven approach with a tensorial invariant approach. The tensorial approach keeps statements invariant under changes of basis and works directly with invariant building blocks.

For the compiler experiment, the analogous design question is whether the elaborated form of an indexed expression should preserve the coordinate spelling or preserve the invariant interface:

```text
surface:     Aⁱⱼ vʲ
semantic:    one typed contraction on j, one free upper i boundary
```

The latter survives renaming `j`, changes in storage layout, and changes in backend realization.

## 2. Diagrammatic notation as a real calculation language

Chapter 4 is the decisive precedent. Agglomerations of invariant tensors are represented by birdtracks and manipulated diagrammatically. The point is not to draw a picture of an already-finished calculation; the picture is the working expression.

This suggests an Idriç phase boundary:

```text
parsed indexed syntax
-> typed indexed occurrences
-> open diagram / contraction graph
-> algebraic normalization
-> implementation plan
```

The index letters can disappear once the graph has been constructed, except where source mapping or diagnostics need them.

## 3. Projection and decomposition are structural

Projection operators, Young projections, symmetrization, antisymmetrization, and recoupling are all naturally represented by compositions of graphical pieces. This is important because it shows that a diagram IR need not be limited to “multiply these arrays and sum an index.” It can carry higher mathematical structure such as idempotents, symmetry classes, and decomposition maps.

A type checker or elaborator could therefore know more than a dimension tuple. It might know, for example, that an output lies in a symmetric subspace or that a map is an invariant projection, and preserve that fact until it is either used or intentionally forgotten.

## 4. Loops are mathematics, not necessarily program loops

A closed graphical loop often means a trace, dimension factor, or another contracted scalar. This is a useful warning for compiler vocabulary. A *diagram loop* is not a `for` loop. The same mathematical contraction might later be realized as:

- a scalar loop;
- SIMD instructions;
- a GPU reduction;
- a tensor kernel;
- a closed-form simplification that eliminates iteration entirely.

The graphical form keeps the semantic loop/contraction separate from the implementation choice.

## 5. Recoupling and rewrite

Many calculations proceed by replacing a local diagram with an equivalent local diagram. That is already close to a rewrite system over a typed graph. The important feature is locality: one can recognize a subdiagram, verify that a known identity applies, and replace it while leaving the rest untouched.

For Idriç, that argues for named, provenance-bearing rewrites rather than opaque global “smart math”:

```text
subgraph matches symmetry projector law
-> apply named law
-> record reason in explanation trace
```

## 6. Algorithms fall out of identities

Cvitanović repeatedly turns invariant identities into evaluation procedures. Complicated group-theoretic graphs can be recursively reduced to simpler ones. The high-level expression is not first flattened into scalar arithmetic and then optimized back upward; the algebraic structure is exploited before low-level evaluation.

That is exactly the direction wanted for Idriç: ask what the mathematics lets us simplify before asking which registers or lanes will hold intermediate values.

## 7. What not to import blindly

Birdtracks live in settings with specific invariant tensors and duality conventions. A graphical line can carry more structure than an untyped edge. Idriç must keep enough typing information to distinguish `V`, `V*`, representations of different groups, different index spaces, and any metric/invariant form that authorizes raising, lowering, or same-variance contraction.

So the compiler lesson is not “indices are irrelevant.” It is:

> index *names* are often irrelevant after elaboration; typed incidence, variance, symmetry, and invariant structure are not.

## Takeaway for the current branch

Use the Einstein glyphs as a compact surface notation for constructing a typed open graph. Let free indices become boundary ports, contractions become internal edges, and named mathematical structures authorize graph rewrites. Only after that semantic graph is stable should the compiler choose scalar iteration, SIMD, GPU work, or another realization.
