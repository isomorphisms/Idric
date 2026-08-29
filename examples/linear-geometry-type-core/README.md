# Linear geometry type core

This executable slice keeps a small set of settled finite-dimensional linear/elementary geometry facts explicit in the Idriç type layer without choosing a general floating-point representation yet.

The coordinate samples use exact integers embedded in real vector spaces.  That is only a test representation: it lets the compiler execute dimension/orientation/topology constraints exactly and does **not** claim that real coordinates are integers.

## Dimension-indexed linear algebra

`ExactRealVector n` carries ambient dimension in its type.  Addition, subtraction, dot product, norm, distance, and semantic residual require equal dimensions by construction.  Approximation thresholds remain explicit; the compiler does not invent an epsilon.

## O(n), SO(n), rotations, reflections

`OrthogonalTransform n orientation` tracks ambient dimension and orientation.  There is no constructor that simply asserts an arbitrary matrix is orthogonal.  The first exact generators are:

- a first-coordinate-axis reflection in every positive dimension;
- a first-plane quarter-turn Givens rotation in every dimension at least two;
- composition, whose orientation index is computed;
- the unit-quaternion boundary into `SO(3)`.

The exact first-plane convention is the 2 by 2 block `[[0,-1],[1,0]]` embedded with an identity block on all remaining coordinates.

The `R^128` extension on the stacked high-dimensional branch executes those two generators on sparse exact coordinate samples and checks exact images, norm/dot preservation, orientation, reflection involution, and four-quarter-turn identity.  See `HIGH_DIMENSIONAL_VERIFICATION.md` for independent SymPy and NumPy/SciPy oracle receipts.

General real angles, arbitrary coordinate planes, arbitrary Householder normals, imported-matrix orthogonality certification, and complete coordinate evaluation for every `OrthogonalTransform` remain deliberately open.

## Spheres

`UnitSpherePoint n` means `S^n` in ambient `R^(n+1)`.  A checked coordinate point carries its norm-one equality.  An orthogonal action preserves sphere membership at the type boundary.

The ordinary integral cohomology ranks of spheres are included, with the special `S^0` case explicit.  Odd and even positive-dimensional spheres have the same additive rank pattern; parity enters here through the Euler characteristic `chi(S^n) = 1 + (-1)^n`.

## Quaternions / SO(3)

The executable quaternion samples use exact integer coefficients and Hamilton multiplication.  `UnitQuaternion` carries a norm-one equality rather than a detachable Boolean tag.  A unit quaternion has a typed boundary into `SO(3)`; this slice does not yet implement the full coordinate action of that rotation.

## CP^n and named topology facts

The slice records:

- `CP^n` real dimension `2n`;
- Hopf presentation sphere dimension `2n+1` for `CP^n = S^(2n+1)/S^1`;
- additive integral cohomology ranks of `CP^n`;
- named standard facts for Jordan separation on `S^2` and one-point compactification `(R^n)^+ ~= S^n`.

These last facts model the intended theorem-index boundary from #42: a named checked theorem/library fact may contribute a typed consequence.  Ordinary unification is not being credited with rediscovering topology.

## Deliberate boundaries

This is not yet a general real-scalar or numerical-linear-algebra library.  Arbitrary-angle rotations, arbitrary Householder/Givens parameters, imported matrices, subspaces/projections, full `CP^n` quotient equality, the cohomology ring, and theorem-provenance machinery remain later work.
