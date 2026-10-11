# Signed OCP FP8 in canonical Idriç

This is the first source-level step of the corrected numerical intent,
[Flexible Pipes #83](https://github.com/isomorphisms/flexible-pipes/issues/83).

The canonical source types \`Prelude.LowPrecision.E4M3\` and
\`Prelude.LowPrecision.E5M2\` are distinct typed 8-bit values. Each raw byte
is legal; NaNs, E5M2 infinities, signed zeros, exponent biases and exact
finite dyadic fractions are recognized without a host floating-point carrier.

* **E4M3**: sign/exponent/fraction widths 1/4/3; exponent bias 7;
  NaN magnitudes at code 0x7f; no infinity; maximum finite +448 at 0x7e.
* **E5M2**: widths 1/5/2; bias 15; infinity at magnitude code 0x7c;
  NaN magnitudes at 0x7d..0x7f; maximum finite +57344 at 0x7b.
* Both preserve the raw negative-zero bit; finite fractions expose signed
  numerator/positive denominator, with separate sign inspection for zero.
* Both reject implicit E5M2-to-E4M3 type interchange.

**No arithmetic API is claimed.** The historical compact-numeric branch
provided \`Float\` as a binary32 primitive, but that branch diverged from
current \`Idriç\` and cannot be merged wholesale. The source's
widen-one-operation-to-binary32-and-requantize semantics must be reconciled
with an owned Float32 compiler path; substituting Double is not allowed.
This slice must not be called binary32 arithmetic or backend ABI acceptance.

References: the OCP 8-bit Floating Point Specification revision 1.0 and
the initial historical
[Idriç compact types PR #120](https://github.com/isomorphisms/Idric/pull/120).
The checked numerical acceptance is \`_/tests/idris2/basic/edric012\`; the
independent ICK C interface is tracked in
[ICK FP8 PR #91](https://github.com/dilapidated-shed/ick/pull/91).
