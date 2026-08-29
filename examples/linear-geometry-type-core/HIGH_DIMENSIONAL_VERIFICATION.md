# High-dimensional orthogonal verification

This note records independent oracles for the exact `R^128` rotation/reflection tests.
It is verification provenance, not another implementation of the Idriç type layer.

## Exact fixtures

Let

```text
x = (3, 4, 12, 0, ..., 0, 9) in R^128
y = (5, -2, 7, 0, ..., 0, 11) in R^128
```

The last entries are intentionally nonzero: the oracle therefore checks that the first-plane operations preserve data all the way out at coordinate 128 rather than only carrying a type-level dimension label.

The reflection is the coordinate-axis Householder reflection

```text
H = diag(-1, 1, ..., 1).
```

The rotation is the first-plane Givens quarter turn

```text
G = [[0, -1],
     [1,  0]] direct-sum I_126.
```

Therefore the expected exact images are

```text
Hx = (-3, 4, 12, 0, ..., 0, 9)
Gx = (-4, 3, 12, 0, ..., 0, 9).
```

The deliberately redundant invariants are

```text
H^T H = I,  det(H) = -1,  H^2 = I
G^T G = I,  det(G) =  1,  G^4 = I
x dot x = 250
x dot y = 190
(Hx) dot (Hx) = (Gx) dot (Gx) = 250
(Hx) dot (Hy) = (Gx) dot (Gy) = 190
```

## Independent computational checks

Two separate library paths were used as computational oracles, in addition to the direct block-matrix calculation.

### SymPy exact arithmetic

A literal 128 by 128 `sympy.Matrix` construction returned:

```text
G det 1
H det -1
G orth True
H orth True
Gx first coordinates [-4, 3, 12, 0]
Gx coordinate 128 9
Hx first coordinates [-3, 4, 12, 0]
Hx coordinate 128 9
norm x 250; norm Gx 250; norm Hx 250
dot xy 190; dot G 190; dot H 190
HHx equals x True
GGGGx equals x True
```

This path is exact integer/symbolic arithmetic.

### NumPy / SciPy numerical construction

A separately constructed `scipy.linalg.block_diag` / NumPy matrix path returned:

```text
G det 1; orth_err 0.0
H det -1; orth_err 0.0
Gx coordinate 128 9.0
Hx coordinate 128 9.0
norm2 250.0
dot 190.0
G4 error 0.0
H2 error 0.0
```

Because every entry in these particular matrices and samples is an exactly representable small integer, this numerical oracle introduces no rounding disagreement in the checked values.

## Literature cross-checks

The construction follows the standard numerical-linear-algebra definitions:

- Golub and Van Loan, *Matrix Computations*, section 5.1: Householder reflections and Givens rotations are orthogonal transformations; a Givens block is a two-coordinate rotation embedded in the ambient space.
- DeTurck, Elsaify, Gluck, Grossmann, Hoisington, Krishnan, Zhang, *Making matrices better: Geometry and topology of polar and singular value decomposition*, arXiv:1702.02131: orthogonal transformations act rigidly, and the paper explicitly moves between low-dimensional pictures and arbitrary-size orthogonal matrix decompositions.

Useful public references:

- https://arxiv.org/abs/1702.02131
- https://www.cs.cornell.edu/courses/cs4220/2026sp/lec/2026-02-23.html

The uploaded copy of *Making matrices better* was also checked independently; its arbitrary-size SVD/polar sections describe the orthogonal factors as rigid motions and cite Golub--Van Loan and Horn--Johnson. Another uploaded numerical-linear-algebra discussion points readers to Golub--Van Loan, Trefethen--Bau, Horn--Johnson, and Strang for the same orthogonal/SVD background.

## Scope boundary

Macaulay2 and homology/cohomology software are useful independent oracles for algebraic/topological assertions, but they do not add an independent check to these elementary coordinate-level `O(128)` identities. They should be used when the test target is an algebraic variety, quotient, homology group, cohomology ring, or related theorem-level object rather than invoked ceremonially here.
