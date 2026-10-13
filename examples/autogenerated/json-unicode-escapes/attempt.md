# Correct JSON Unicode escapes for the Indeed client

The real Indeed local-HTTP test exposed `\u002d` decoding as `M`, allowing an
escaped credential echo to avoid redaction. Lowercase hexadecimal digits were
handled as uppercase offsets. Inspection also found that UTF-16 code units
were immediately converted to host characters before surrogate validation.

Type sketch: a JSON Unicode escape first yields a code unit (0–65535); one
non-surrogate unit or a checked high/low pair yields a Unicode scalar. Invalid
or isolated surrogates yield parse failure. The application receives decoded
Text and must see raw and escaped equivalent strings identically.

The inherited library implementation remains `.idr` compatibility source.
The new acceptance program is `.idric` and compiles with the existing core
compiler. No alternate client parser, escape-rewriting shim or language fallback
is used. Tests cover lowercase/uppercase hexadecimal, BMP characters, both
surrogate-pair cases, isolated units, wrong-order pairs and malformed hex.
