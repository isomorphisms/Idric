# Linear geometry type core

This is the bounded second pass after the exact units/time/interval slice.  It is intentionally centered on finite-dimensional linear algebra rather than a broad inheritance hierarchy.

## SETTLED and encoded here

- dimension-indexed mathematical vectors: incompatible dimensions cannot be passed to subtraction, dot product, distance, or semantic-residual operations;
- explicit approximation thresholds: the compiler checks ambient compatibility but does not invent an application-specific semantic epsilon;
- orientation as a type index for orthogonal transformations;
- composition rules for orientation, including reflection × reflection landing in `SO(n)`;
- an exact first-axis reflection and a first-coordinate-plane quarter turn (a Givens rotation with `c = 0`, `s = 1`);
- `S^n` represented with ambient dimension `n + 1`, plus the standard `O(n+1)` action preserving sphere membership;
- integral cohomology ranks of spheres, with the `S^0` case handled separately;
- `chi(S^n) = 1 + (-1)^n`, so odd spheres have Euler characteristic 0 and even spheres 2;
- Hamilton quaternion multiplication on exact integer-coordinate samples, norm-one certificates, and the typed unit-quaternion-to-`SO(3)` boundary;
- `CP^n` real dimension `2n`, the Hopf presentation `S^(2n+1) / S^1`, and additive integral cohomology ranks;
- named theorem-library facts for Jordan separation on `S^2` and `(R^n)^+ ~= S^n` one-point compactification.

The additive cohomology ranks of positive-dimensional odd and even spheres are deliberately **not** distinguished: both have rank one in degrees 0 and n and zero elsewhere.  Parity appears here through Euler characteristic.

## Executable-coordinate boundary

`ExactRealVector n` uses integer coordinates only so these tests stay exact and avoid choosing a floating-point policy.  Such points are ordinary points of `R^n`; this is an executable sample subdomain, not a claim that real coordinates are integers.  The eventual scalar layer can widen this while keeping the dimension indices and structural constraints.

Likewise, the quaternion executable fixture uses integer coefficients.  It checks Hamilton multiplication and exact norm-one samples without pretending to enumerate the full `S^3` of unit quaternions.

## OPEN / later passes

- the general real scalar abstraction and precision policy;
- arbitrary-axis Householder reflections and general-angle Givens rotations;
- concrete matrix realization and determinant/orthogonality checking for imported matrices;
- subspaces, orthogonal projection, and projection-law certificates;
- normalized arbitrary semantic embeddings and cosine similarity;
- a genuine quotient representation for `CP^n` rather than only typed standard facts;
- the cohomology ring `Z[x]/(x^(n+1))`, `|x| = 2`, rather than only additive ranks;
- full theorem provenance/explanation traces in the elaborator.

The theorem-shaped entries in this slice are not presented as compiler-generated proofs.  They model the intended #42 boundary: a checked/versioned mathematical knowledge layer may contribute a named fact when its hypotheses match, and inference should be able to say exactly which fact it used.
