# Signed ordinary division

This executable model explores [Idriç #149](https://github.com/isomorphisms/Idric/issues/149).
Two exact signed integers enter a pure operation with one static result type.
Its alternatives denote a zero divisor, a rational quotient, or that quotient
embedded in the complex field with imaginary part zero. The choice depends
on the original operands. Integer numerator/denominator arithmetic preserves
exactness. Representatives have a positive denominator and may have common
factors. Equality uses cross multiplication. No machine division or floating
conversion is necessary for this experiment.

The main action runs the examples or reads two command-line integer arguments
and prints the selected result. The type, sign test and zero handling are being
tested as a proposal. This program defines a named operation. It does not
install a new implementation of the source operator.

## Reproduce on a qualified Idriç host

With this directory as the source root, compile `Main.idric` using the owned
Idriç executable with arguments `--cg chez -o signed-division Main.idric`.
Run the generated `build/exec/signed-division` without arguments for the
twelve assertions. Two further arguments exercise runtime input. For example,
`7 -3` prints `complex -7/3 + 0i`, and `-7 -3` prints
`complex 7/3 + 0i`. Display keeps the input fraction representation. Comparisons
in the tests use fraction equality.

## Evidence

Executed on Linux x86-64 using the owned compiler checkout
`2bce7677f513d711875e978bd6f5ad28b9e54d58`, Chez 10.4.1, compiler image
SHA-256 `ddd950bb6a66b61b4ea3d252c531ca0d02817dbdaa9ef07f6c99f59fc7af9d71`.
The source branch inspected for the proposal is
`b2f4c2488d0aa55cd947535eb9b61ff0e6bba963`. The lexer, numeric prelude and
Chez support source cited in the design were byte-identical at both checkouts.

All twelve cases passed, including the value beyond unsigned 64-bit range,
two negative operands, and a negative operand with zero divisor. Separate
process runs read pairs from the command line and confirmed both signed
positions, two negative operands, zero numerator, zero divisor and large
magnitude. A separately compiled mutant that tests only the dividend's sign
exited 1 on the same assertion suite.

On the same compiler, ordinary division with explicit integer inputs and
integer result failed elaboration with `Can't find an implementation for
Fractional Integer`. With an explicit Double result, −7.0 ÷ 3.0 printed
−2.3333333333333335. Explicit integer quotient/remainder were (−3, 2) for
(−7, 3), (−2, 1) for (7, −3), and (3, 2) for (−7, −3).

The first language change would expose the wider result of exact ordinary
division in the shared numeric layer. See the [design and downstream acceptance
cases](../../../notes/ordinary-division-of-signed-integers.md). This run covers
only the named model on the Chez host. Source-operator integration and direct
backend execution remain open.

## Composing two divisions

The second experiment makes the result type abstract across a compiler module
boundary. Given a prior quotient and another signed integer, divide by that
integer while preserving an already selected complex domain. Two independent
runtime sign choices can now occur in one process. A zero divisor at either
step propagates. Both operations return the same static type. The existing
positive-denominator invariant makes the exact second quotient
numerator / (positive_denominator × next_divisor) before sign normalization.
A client asking for an Integer directly from either operation must be rejected.

The edric011 runner checks SignedDivision first, moves its staged source out of
the import path, then compiles Main against the checked interface. The caller's
implicit Integer return is a required type error. The eight new runtime cases
cover a real and an already-complex quotient with identical coordinates, later
promotion, preserved complex zero, either zero-divisor position, and a
denominator product of 2^64. The complete golden output matched with the
compiler identified above. A mutant that discards the prior complex domain
passed all 12 original cases but printed real 7/15 on arguments −7, −3, 5.
The new expected output is complex 7/15 + 0i. All executions here use the
named experimental operations on Chez.
