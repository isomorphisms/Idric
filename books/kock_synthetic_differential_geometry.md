# Anders Kock — Synthetic Differential Geometry

**Book:** second edition, Cambridge University Press, 2006; first edition 1981.
**Scope:** selected opening passages and I §§1–2, not a full-book review.
**Source:** [author-hosted text](https://users-math.au.dk/kock/sdg99.pdf);
[publisher record](https://www.cambridge.org/core/books/synthetic-differential-geometry/4933FF5EDF69BD13E8D8FCA346BB1C06).
Page numbers below are printed pages.

## Source notes

Kock starts I §1, p. 2, by distinguishing the geometric line from the ring
structure obtained after choosing 0 and 1. The geometric line is not initially
identified with the arithmetically constructed real numbers.

His line object R has first-order infinitesimals

$$D = \{d \in R \mid d^2 = 0\}.$$

Axiom 1 requires every internal map g : D → R to have a unique slope b:

$$g(d) = g(0) + db \qquad (d \in D).$$

I §2, p. 7, obtains differentiation from this uniqueness:

$$f(x+d) = f(x) + d f'(x).$$

The preface, pp. x–xi, uses generalized elements X → R, not just global
points. I §1, pp. 4–5, explains the conflict with unrestricted excluded middle.
Do not interpret D as an ordinary set of tiny nonzero real numbers.

## Worked example — our calculation

For f(x) = x² and d² = 0,

$$f(x+d) = (x+d)^2 = x^2 + 2xd + d^2 = x^2 + d(2x).$$

Thus the uniquely determined coefficient is f′(x) = 2x. This is an exact
algebraic calculation, not a small-step floating-point approximation.

## Connection to Idriç — proposed, not attributed to Kock

Keep the geometric object, chosen coordinate data, admitted operations, and
logic visible before selecting storage or machine instructions. The name R
must not silently identify distinct scalar theories.

A differentiation implementation using dual-number pairs could realize a
bounded calculation without constituting an implementation of an entire SDG
model. Preserve that distinction in both documentation and acceptance claims.

The negative-divisor/complex-plane interpretation is our separate semantic
proposal; these notes do not claim that Kock adopts it. Its exact-real-axis
normalization needs evidence, not a fabricated universal Boolean zero test.

See [continuous quantity and preserved meaning](continuous_quantity_and_preserved_meaning.md).
