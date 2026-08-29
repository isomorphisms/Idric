# High-dimensional orthogonal verification

This note records independent oracles for the exact `R^128` rotation/reflection tests.
It is verification provenance, not another implementation of the Idriç type layer.

## Exact fixtures

Let

```text
x = (3, 4, 12, 0, ..., 0) in R^128
y = (5, -2, 7, 0, ..., 0) in R^128
```

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
Hx = (-3, 4, 12, 0, ..., 0)
Gx = (-4, 3, 12, 0, ..., 0).
```

The deliberately redundant invariants are

```text
H^T H = I,  det(H) = -1,  H^2 = I
G^T G = I,  det(G) =  1,  G^4 = I
x dot x = 169
x dot y = 91
(Hx) dot (Hx) = (Gx) dot (Gx) = 169
(Hx) dot (Hy) = (Gx) dot (Gy) = 91
```

## Independent computational checks

Two separate local library paths were used before the Idriç implementation was committed.

### SymPy exact arithmetic

A literal 128 by 128 `sympy.Matrix` construction returned:

```text
G det 1
H det -1
G orth True
H orth True
Gx [-4, 3, 12, 0, 0]
Hx [-3, 4, 12, 0, 0]
norm x 169; norm Gx 169; norm Hx 169
dot xy 91; dot G 91; dot H 91
HHx equals x True
GGGGx equals x True
```

This path is exact integer/symbolic arithmetic.

### NumPy / SciPy numerical construction

A separately constructed `scipy.linalg.block_diag` / NumPy matrix path returned:

```text
G det 1; orth_err 0.0
H det -1; orth_err 0.0
Gx [-4.0, 3.0, 12.0, 0.0, 0.0]
Hx [-3.0, 4.0, 12.0, 0.0, 0.0]
norm2 169.0
dot 91.0
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

The user's uploaded copy of *Making matrices better* was also checked independently; its arbitrary-size SVD/polar sections describe the orthogonal factors as rigid motions and cite Golub--Van Loan and Horn--Johnson.

## Scope boundary

Macaulay2 and homology/cohomology software are useful independent oracles for algebraic/topological assertions, but they do not add an independent check to these elementary coordinate-level O(128) identities. They should be used when the test target is an algebraic variety, quotient, homology group, cohomology ring, or related theorem-level object rather than invoked ceremonially here.
