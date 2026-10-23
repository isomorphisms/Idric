# Program attempt: Unicode subtraction in ChordReader

Status: PASS — both generated host executables compiled and executed.

Purpose: the real ChordReader written-interval implementation uses canonical
Unicode subtraction in its octave and accidental calculations.

Type sketch: `subtract_interval : Integer → Integer → Integer`; all arguments
and results are exact signed integers. No IO occurs except the acceptance
program printing its results. Subtraction must keep ordinary precedence,
support negative results and work without spaces around the symbol.

The maintained compiler at `0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35`,
executed from its genuinely generated Scheme compiler source after its optimized
executable build exceeded the 8 GiB host memory limit, rejected:

`octave = (absolute_letter − wrap 7 absolute_letter) div 7`

with `Undefined name −`. This was a source-checker diagnostic, not a backend
failure. The style guide already requires Unicode minus, but the filename-scoped
lexer alias list implemented × and ÷ without −.

Implementation: add − to that same Idriç-only lexer boundary and lower it to
the inherited subtraction token. The independent `.idr` fixture keeps − inside
an ordinary identifier and must continue to print 19; literals retain their original text.
The existing test harness requires its small `run` interface; no new shell
language implementation or launcher is introduced.

Source: `_/tests/idris2/basic/edric012/Main.idric` and `Compatibility.idr`.

Fallback: none. ChordReader keeps its Unicode source.

Executed qualification: the rebuilt maintained compiler produced and ran both
fixtures. Main printed `-1`, `5`, `8`, and `Keep − in text`; Compatibility printed
`19` and `Keep − in Idris text`. The application core subsequently passed 366
checks. The compiler base was 0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35 with this
patch (tree 06a6befebdf573d2fe7d4fedd99880bccca5e42c). The API-published commit is
28c5755d37fb868f1b9c2f5d8fab1ce2b2ada663; its source tree matches the locally
built commit 7accb208e94269e3d66873fcd61b0d63dfeaa51b. These are host syntax tests,
not DEX/ARM/Android acceptance.
