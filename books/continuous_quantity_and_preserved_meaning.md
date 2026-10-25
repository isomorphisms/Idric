# Continuous quantity and preserved meaning

**Status:** Idriç design discussion, recorded 2026-10-24. This file preserves
conceptual intent; it does not claim that the compiler implements these rules.
The linked books and paper motivate questions. They do not endorse the specific
negative-divisor rule below.

## Quantity is not its coordinate representation

Keep these questions separate: what varies continuously; what counts as an
origin; what fixes a unit; what supplies polarity or orientation; what operations
are meaningful; and what logic supports the reasoning.

As an elementary example, let A be an affine line with translation space V.
For points p and q, the displacement q − p belongs to V, but A has no chosen
origin. Choosing o in A lets us associate p with p − o. Choosing a nonzero unit
direction u then permits a scalar coordinate x through p = o + xu.

The zero displacement in V is not a distinguished point of A. An additive
identity and a chosen coordinate origin must not be conflated. Continuity alone
also does not choose an affine structure; this example separates some choices,
not all possible continuum theories.

[Kock's opening discussion](kock_synthetic_differential_geometry.md) is a direct
reading connection. [Hellman and Shapiro's paper](hellman_shapiro_classical_continuum_without_points.md)
and [their book](hellman_shapiro_varieties_of_continua.md) broaden the question
beyond point-based objects. The [historical collection](shapiro_hellman_history_of_continua.md)
provides further routes.

## Preserve the intended negative-divisor interpretation

The proposed Idriç semantics do not treat division by a negative real as a
primitive operation staying inside ℝ. For r > 0, interpret division by −r
through ℂ as positive scaling followed by a half-turn:

$$a \div (-r) \;\rightsquigarrow\; (a/r)e^{-i\pi}.$$

For example:

$$6 \div (-2) \;\rightsquigarrow\; 3e^{-i\pi}
= -3 + 0i \;\rightsquigarrow\; -3 \in \mathbb{R}.$$

The last step uses a general rule for every complex result known to lie exactly
on the real axis, not a division-specific exception:

$$z \in \mathbb{C},\quad \operatorname{Im}(z)=0
\quad\Longrightarrow\quad \operatorname{Re}(z) \in \mathbb{R}.$$

Examples include (2 + 3i) + (4 − 3i) → 6 and i² → −1. The rule needs exact
equality evidence. A small imaginary component, a numerical tolerance, and
proof of zero are different things. In particular, floating evaluation of
sin(π) must not replace the exact half-turn identity.

Conventional real-field arithmetic defines negative-divisor division directly.
The rule here deliberately specifies a different conceptual route, while
preserving those arithmetic values. No claim that real-field arithmetic is
inconsistent is needed.

## Normalization must not erase meaning

The result −3 and the derivation of −3 are distinct information. Normalization
may select a real-valued result without deleting the complex-plane derivation.

Keep the expression, its intermediate semantic types, positive scaling,
half-turn, and evidence of return to the real axis inspectable by people and
LLMs. Machine lowering may omit intermediate complex storage and calculations;
it must not retroactively rewrite the language's explanation as though those
concepts were absent.

A retained derivation is part of the intended semantic account, not optional
presentation decoration. Its concrete storage format remains an implementation
question. No runtime allocation or particular instruction sequence is prescribed.

## Boundaries still to resolve

Sign and zero evidence need not be decidable for every exact value. Preserve
unresolved obligations rather than silently substituting a floating test.
Clarify how normalized values inhabit declared interfaces and how derivations
remain accessible across compilation and serialization.

Do not apply ordinary complex polar coordinates automatically to every possible
smooth or region-based scalar theory. Each interpretation needs its own
operations and hypotheses. The requested separation of quantity, origin, and
polarity is broader than any single complex-number model.

Wegert motivates making the geometry visible. A visual explanation and an
optimized numerical implementation should remain views of the same declared
meaning, not competing definitions of it.
