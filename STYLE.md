# Idriç source style

This repository contains two languages at once. Files ending in `.idric` show
the Idriç language being designed. Files ending in `.idr` implement the
bootstrap compiler and preserve the Idris 2 compatibility surface. Do not make
the first look like renamed Idris, and do not mechanically restyle the second
as though its external and bootstrap names were Idriç names.

## Read from purpose into mechanism

Application and example entry points explain what the program means before
showing parsing, monadic plumbing, foreign calls, or backend machinery. Order
operations by human purpose. Put concrete algorithms and target-specific
implementations in descriptively named files below that layer; keep small
aggregation files limited to the operations their caller needs.

Compiler directives are mechanism. `.idric` source is total by default, so it
does not begin with `%default total`. Use an explicit function-level or file
directive only when the source deliberately chooses another totality contract,
and explain why. `public export` is for an API that downstream modules must be
able to re-export; it is not a ceremonial prefix for every definition.

## Idriç vocabulary and syntax

- Use `snake_case` for names under our control and prefer complete domain words
  to conventional Haskell abbreviations.
- Use `Number`, not `Nat` or the older migration spelling `ℕ`, in new `.idric`
  source. Use `Text`, not `String`, for decoded character text. Both lower to
  inherited representations inside the bootstrap compiler.
- Use a semantic type instead of `Number`, `Text`, a raw integer, `Bits8`, or a
  flag when the value has narrower operations or invariants.
- Use `List` for an ordinary sequence, `SizedList` or `ListOfLength` when length
  belongs in the type, and `Array` for contiguous indexed storage. Reserve
  `Vector` for a mathematical vector-space value. `Vect` survives only at an
  explicit Idris compatibility boundary.
- Use the canonical Unicode spellings `→`, `←`, and `⇒` in fresh `.idric`
  source. Use `$` when it removes unhelpful nested parentheses, not as a reason
  to remove readable grouping.
- Avoid gratuitous currying, bare-application chains, constructor-led program
  descriptions, and implementation types in domain vocabulary.

The general name for a number that may be positive or negative is still
unresolved. Prefer a domain name where there is one and do not introduce a new
unrestricted wrapper merely to avoid inherited spelling.

## Semantic boundaries

Receive and validate raw data once, retain its source identity and semantic
meaning, and lower it explicitly at the next raw boundary. Distinguish text
from bytes, paths from arbitrary text, units and widths, protocol states, and
structured results from Boolean or integer projections. Prefer a named record
when tuple positions have different meanings.

Keep target-neutral checked forms above target-specific lowering. C/RefC is not
a universal backend escape hatch. A direct DEX, Wasm, machine-code, GPU, or
other backend must generate that target in its production path and fail closed
for unsupported semantics. DEX and ARM/Thumb work are sibling backend lines;
do not give one the other's Git ancestry, modules, fixtures, or acceptance
claims.

Preserve an explicitly chosen numeric width through checking, IR, and lowering.
Float16 is the ordinary source default; Float32 remains deliberate, and neither
is silently carried as or narrowed from an unrelated host `Double`.

## Repository layout and provenance

The maintained compiler source is exposed at the repository root. Build
machinery, the pinned bootstrap tree, upstream libraries, inherited tests, and
generated output live under `_`. Do not style those imported strata as newly
written Idriç. New language examples use `.idric`; Idris bootstrap and external
compatibility source remains `.idr`.

Keep `.gitattributes` accurate so `.idric` is recognized and generated,
vendored, bootstrap, and foreign material does not distort repository language
statistics. Retain source/specification provenance for unusual inherited or
foreign mechanisms without copying their architecture into new code.

## Comments and acceptance

Name semantic constants and explain non-obvious numeric values, opcodes, bit
patterns, representation conversions, and backend restrictions. Comments say
why a mechanism exists and what a boundary guarantees.

Every language change needs a focused `.idric` acceptance case and a matching
`.idr` compatibility case when tokenization or parsing could affect Idris.
Acceptance must identify the exact compiler revision, prove the intended source
or artifact structure, and run behavior at the claimed boundary. Use `PASS`,
`FAIL`, `SKIP`, and `BLOCKED` accurately; an emulator or stale branch is not a
device or current-head receipt.
