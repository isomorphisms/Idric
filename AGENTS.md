# Idriç agent instructions

Read [STYLE.md](STYLE.md) before writing or reviewing Idriç-facing source.
Also read `_/AGENTS.md` for repository and branch rules.

The repository contains a large inherited Idris codebase. Its existence is not
permission to reproduce Idris/Haskell style in new Idriç work.

## Hard stops

Do not introduce `Nat` or `Vect` in new Idriç-facing source.

- For `Nat`, first ask what the value means. Use `Number` for an ordinary number
  or count. If a restriction such as nonnegativity, a range, units, or another
  domain property matters, represent that semantic restriction explicitly.
- For `Vect`, use `List` when length is not part of the meaning. If length or
  shape matters, represent that semantic fact explicitly instead of defaulting
  to generic `Vect`.

## Style canaries

Treat newly introduced lowerCamelCase identifiers or ASCII `->` / `<-` arrows
as evidence that you may have fallen back to Idris/Haskell defaults.

Do not merely make the mechanical substitution and continue. Re-read
`STYLE.md`, re-read the surrounding declarations, and reconsider names, types,
structure, and vocabulary as a whole. If conversation history containing human
corrections is available, review it. Inspect relevant recent Idriç-family work
when useful, but do not assume any existing file is canonical unless the user
has said so.

Use `snake_case` and real `→` / `←` arrows in Idriç-facing source.

## Human-in-the-loop style development

There is no finished corpus of approved "good Idriç" examples yet. The user's
corrections determine the style while it is being developed. When a correction
recurs and becomes unambiguous, prefer recording or enforcing it rather than
making the same default-style mistake again.
