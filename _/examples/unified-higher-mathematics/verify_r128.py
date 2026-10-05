#!/usr/bin/env python3
"""Independent exact check for the sparse R^128 fixture; no dependencies."""

DIMENSION = 128


def signed_permutation_determinant(transform):
    permutation = [source for source, _ in transform]
    inversions = sum(
        permutation[left] > permutation[right]
        for left in range(DIMENSION)
        for right in range(left + 1, DIMENSION)
    )
    permutation_sign = -1 if inversions % 2 else 1
    coordinate_sign = 1
    for _, sign in transform:
        coordinate_sign *= sign
    return permutation_sign * coordinate_sign


def apply(transform, vector):
    return [sign * vector[source] for source, sign in transform]


def dot(left, right):
    return sum(x * y for x, y in zip(left, right, strict=True))


def iterate(transform, count, vector):
    result = vector
    for _ in range(count):
        result = apply(transform, result)
    return result


def report(name, condition):
    if not condition:
        raise AssertionError(name)
    print(f"{name}: PASS")


x = [0] * DIMENSION
x[0], x[1], x[2], x[127] = 3, 4, 12, 9

y = [0] * DIMENSION
y[0], y[1], y[2], y[127] = 5, -2, 7, 11

reflection = [(index, -1 if index == 0 else 1) for index in range(DIMENSION)]
quarter_turn = [(1, -1), (0, 1)] + [
    (index, 1) for index in range(2, DIMENSION)
]

hx = apply(reflection, x)
hy = apply(reflection, y)
gx = apply(quarter_turn, x)
gy = apply(quarter_turn, y)

report("rank", len(x) == DIMENSION == len(y))
report("Hx", hx[:3] == [-3, 4, 12])
report("Gx", gx[:3] == [-4, 3, 12])
report("norm_H", dot(hx, hx) == dot(x, x) == 250)
report("norm_G", dot(gx, gx) == dot(x, x) == 250)
report("dot_H", dot(hx, hy) == dot(x, y) == 190)
report("dot_G", dot(gx, gy) == dot(x, y) == 190)
report("H2", iterate(reflection, 2, x) == x)
report("G4", iterate(quarter_turn, 4, x) == x)
report("det_H", signed_permutation_determinant(reflection) == -1)
report("det_G", signed_permutation_determinant(quarter_turn) == 1)
report("far_H", hx[127] == 9)
report("far_G", gx[127] == 9)
