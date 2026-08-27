# Projective spaces and several complex variables

This note records a direction for Idriç's mathematical type system. It is deliberately not a proposal for a new machine-level infinity value.

## Principle

A projective point should be represented by ordinary scalar data plus type-level structure and invariants. The ISA does not need a distinguished projective `Inf` value.

The compiler should keep three questions separate:

1. **What mathematical space does the value inhabit?**
2. **What representation realizes that space?**
3. **How does that representation lower to the target?**

For projective geometry, the first question belongs in the type system. Homogeneous coordinates are a natural answer to the second. Ordinary scalar registers, vectors, memory, and control flow can answer the third.

## Projective infinity is not a scalar sentinel

For one complex dimension,

\[
\mathbf{CP}^1 \cong \mathbf C \cup \{\infty\}.
\]

This special case makes it tempting to think of projective compactification as attaching one distinguished infinity. In general the standard affine chart gives

\[
\mathbf C^n \hookrightarrow \mathbf{CP}^n,
\qquad
(z_1,\ldots,z_n) \mapsto [1:z_1:\cdots:z_n],
\]

and the complement is

\[
H_0 = \{[0:z_1:\cdots:z_n]\} \cong \mathbf{CP}^{n-1}.
\]

Thus the "points at infinity" form an entire projective hyperplane. Relative to the standard coordinate flag this iterates as

\[
\mathbf{CP}^n
= \mathbf C^n \sqcup \mathbf C^{n-1} \sqcup \cdots \sqcup \mathbf C^0
\]

as a cell/stratum decomposition. This notation must not be mistaken for saying that the topology of \(\mathbf{CP}^n\) is an ordinary coproduct: the strata are glued and finite points can converge to the boundary.

This also differs from the one-point compactification

\[
(\mathbf C^n)^+ \cong S^{2n}.
\]

A compactification does not mean "add one infinity" in general.

## Infinity is chart-relative

Abstract \(\mathbf{CP}^n\) does not come with one intrinsically distinguished hyperplane called infinity. Choosing the affine chart

\[
U_i = \{[z_0:\cdots:z_n] : z_i \ne 0\}
\]

makes the complementary hyperplane \(z_i=0\) the boundary of that chart. Another chart makes another coordinate hyperplane play that role.

Therefore an Idriç API should prefer explicit chart/hyperplane information to a universal constructor named `Infinity`.

## Homogeneous representation

Over a field \(K\),

\[
\mathbf P^n(K) = (K^{n+1} \setminus \{0\}) / K^\times.
\]

A concrete representation can therefore start from a nonzero array of \(n+1\) scalars. Two representatives describe the same projective point when one is obtained from the other by multiplication by a nonzero scalar.

The implementation must keep these facts explicit:

- the all-zero coordinate tuple is invalid;
- coordinate equality is not projective equality;
- scaling every coordinate by the same nonzero scalar does not change the point;
- choosing a chart requires a proof or checked fact that its denominator coordinate is nonzero;
- changing charts is ordinary mathematics, not overflow recovery;
- `z_i = 0` is an ordinary coordinate condition, not an ISA exception.

The first code in this branch intentionally models **representatives** rather than pretending Idris already supplies quotient types. A future opaque `ProjectivePoint` abstraction should hide representative choice behind an API that respects the scaling relation.

## Type direction

The shape we eventually want is roughly:

```text
ProjectivePoint : Nat -> Type -> Type
CoordinateChart : Nat -> Type
AffinePoint     : Nat -> Type -> Type
InChart         : CoordinateChart n -> ProjectivePoint n k -> Type
```

For several complex variables, specialize the scalar parameter to a genuine complex type:

```text
ProjectivePoint n Complex
AffinePoint n Complex
```

The dimension belongs in the type. Chart membership and other mathematical conditions can be represented by dependent/refinement types when useful, with proofs erased when they have no runtime role.

`Vector` should continue to mean an actual mathematical/numeric vector in new Idriç APIs. A sized list used to store coordinates is a representation choice, not the mathematical definition of projective space.

## Operations that should exist

Natural projective operations include:

- affine embedding and chart extraction;
- chart transitions;
- projective linear transformations and eventually `PGL` actions;
- hyperplanes and incidence;
- rational maps on the domain where their homogeneous coordinates do not vanish simultaneously;
- projective varieties and their affine charts.

For several complex variables this can later support:

- domains in \(\mathbf C^n\);
- holomorphic maps \(\mathbf C^n \to \mathbf C^m\);
- complex derivatives/Jacobians;
- meromorphic and rational maps;
- projective compactifications where they are mathematically appropriate.

## Operations that should not be invented

A tuple of complex coordinates has componentwise addition and multiplication. A projective point does not inherit those operations merely because its representative is stored as such a tuple.

In particular, do not provide a generic numeric instance for `ProjectivePoint n k` unless the mathematical object genuinely carries the claimed structure. The type system should prevent representation-level arithmetic from masquerading as projective arithmetic.

This is one of the reasons to make the projective type opaque rather than expose `Vect (S n) k` as if the two were synonymous.

## Lowering

Nothing here requires projective infinity to appear as a special register value.

A backend may lower a homogeneous representative to ordinary scalar coordinates. A chart test is an ordinary comparison against zero. A chart transition is ordinary arithmetic. A proof that a denominator is nonzero may disappear entirely after elaboration. SIMD/GPU/vector lowering is a separate optimization question.

This preserves the mathematical meaning above the backend while giving the backend freedom to choose a representation appropriate to ARM, GPU, or another target.

## First implementation boundary

The first executable sketch should stay small:

1. a dimension-indexed homogeneous representative with \(n+1\) coordinates;
2. evidence that at least one coordinate is nonzero;
3. a dimension-indexed coordinate chart;
4. the standard affine embedding `[1:z1:...:zn]`;
5. chart-membership evidence based on the chosen denominator coordinate.

It should **not** yet claim:

- quotient-type support;
- a completed complex-number implementation;
- a general algebra hierarchy for fields;
- projective equality;
- normalization or canonical representatives;
- projective arithmetic that does not actually exist.

## Tests to earn later claims

Before a public projective API is called complete, tests should cover at least:

- rejection of the all-zero homogeneous tuple;
- invariance under nonzero common scaling;
- affine embedding followed by extraction in the same chart;
- transitions between overlapping charts;
- points outside one affine chart but inside another;
- the \(\mathbf{CP}^{n-1}\) hyperplane at infinity of a chosen \(\mathbf C^n\) chart;
- parallel affine lines meeting the same appropriate point at infinity after projective completion;
- prevention of accidental coordinatewise `+` or `*` on projective points.

The goal is not exotic syntax. The goal is for Idriç to know what object a program is manipulating, preserve the mathematical invariants through elaboration, and lower that knowledge without replacing the object by an unrelated machine convention.