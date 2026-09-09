# Idriç source style

This is the canonical style guide for new Idriç-facing source. It records rules
that have actually been decided; it is not a license to fill gaps with ordinary
Idris, Haskell, or generic functional-programming habits.

The canonical intent examples are:

- [`examples/intent/railway/`](examples/intent/railway/README.md)
- [`examples/intent/http_server/`](examples/intent/http_server/README.md)

Read them as examples of structure and vocabulary, not as a frozen grammar.

## Say what the program is doing first

Top-level code should read like a short, purpose-ordered recipe. Put intent above
mechanism. A reader should be able to understand the job before descending into
parsing, buffers, FFI calls, syscalls, allocation, or another implementation
choice.

Prefer meaningful domain phrases and semantic roles. For example:

```idric
connection ← accept connection from listener
request ← read request from connection
response ← answer request
write response to connection
```

Prefer grammatical phrases with words such as `from`, `to`, `on`, `with`,
`using`, and `via` when they make roles clear. Avoid piles of positional
arguments whose meaning is recoverable only from a signature.

Do not force a semantic phrase to mirror the filesystem. `read request from
connection` can have one meaning even if its implementation eventually lives
under `read/`, `request/`, `connection/`, or another sensible deep-dive path.

## Names must carry meaning

Use ordinary or domain vocabulary instead of inherited implementation jargon.
A name should tell the reader what a value or action means in this program.

Use `snake_case`, not lowerCamelCase, for ordinary identifiers.

Avoid names such as `ExternalInvocation`, `InvokeExternal`, abbreviations that
save little space, and generic numbered/positional names when a domain name is
available.

Prefer semantic types at boundaries: port, duration, byte count, HTTP method,
destination, output pin, and similar roles are better than exposing a generic
machine representation.

## Types should describe the domain

Do not introduce `Nat` in new Idriç-facing source. Use `Number` for an ordinary
number or count. If nonnegativity, sign, bounds, units, or another restriction
matters, represent that semantic restriction explicitly.

Do not introduce generic `Vect` merely because Idris provides it. Use `List`
when length is not part of the meaning. If length or shape matters, preserve
that fact with a domain-specific collection or semantic restriction.

Do not leak raw representations such as `Bits8` into domain code when a named
alias or restricted semantic type would say what the bytes mean.

Strong typing should clarify real boundaries and relationships, not turn the
source into type-theory ceremony.

## Notation

Use real Unicode notation in Idriç-facing source and documentation where the
language accepts it.

- `→` for type/result direction
- `←` for effectful binding or receiving a result
- `⇒` for branch/result notation where applicable
- `=` for equality
- `≠` for inequality
- `≝` for “defined as” in intent notation and documentation
- `∘` for composition where it actually clarifies the expression
- Unicode `−` for mathematical minus rather than an ASCII hyphen when writing
  mathematical notation

Do not use ASCII `->` or `<-` as substitutes for Idriç-facing arrows.

Use `$` when it materially removes nested parentheses and makes the expression
read in its natural order. Do not add punctuation merely to imitate another
functional language.

## Expose mechanism by descent

Use the filesystem as a deep-dive structure. Descriptive top-level files and
directories should expose purpose; deeper files can expose concrete algorithms,
foreign calls, and machine details. One concrete implementation per file is
fine when it makes alternatives inspectable.

A directory may contain multiple implementations of the same high-level action.
Callers should import the implementation or small aggregation they actually
need rather than pulling in a broad library by default.

Hide FFI declarations, primitives, host-language glue, raw syscalls, and similar
machinery below high-level wrappers. Explain why a primitive or foreign boundary
exists and what guarantee or constraint it carries.

Keep build machinery under `_/` rather than mixing it with the domain hierarchy.
When implementation is split away from the high-level declaration, keep the
source relationship easy to follow from the top level.

## Explain non-obvious constants

Special numeric values, encoding boundaries, UTF-8 cutoffs, protocol numbers,
bit masks, and similar constants need semantic names or a short explanation.
The source should not require a reader to recognize an unexplained magic number.

## Meaning errors are not style errors

Do not hard-code readability preferences into the grammar merely to enforce a
house style.

A compiler error is appropriate when meaning cannot be resolved, is ambiguous,
or is contradictory. For example, if no visible definition can give meaning to
`read request from connection`, report that unresolved semantic phrase and the
roles that were understood.

Warnings are appropriate when the program has a meaning but naming, morphology,
metadata, or an expected relationship looks suspicious.

Formatting and style checks should handle readability conventions such as
English-like phrasing, unnecessary abbreviations, positional argument piles,
and similar choices that do not make the program meaningless.

## Human corrections remain authoritative

These rules and the canonical intent examples are deliberately small. They do
not make every existing Idriç-family file canonical. Inherited Idris code in
this repository is especially not a style template for new Idriç work.

When a human correction establishes or changes a convention, update this guide
or the canonical examples rather than repeatedly falling back to the old
habit. Do not silently broaden a local example into a language-wide rule.
