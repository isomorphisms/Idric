# Idriç agent instructions

Before writing or reviewing Idriç-facing source, read:

1. [`STYLE.md`](STYLE.md)
2. [`examples/intent/railway/`](examples/intent/railway/README.md)
3. [`examples/intent/http_server/`](examples/intent/http_server/README.md)
4. [`_/AGENTS.md`](_/AGENTS.md) for repository and branch rules

`STYLE.md` is the canonical source-style guide. The two intent examples are the
canonical structural references. This file is operational guidance; do not copy
the full style guide into `AGENTS.md`.

The repository contains a large inherited Idris codebase. Its existence is not
permission to reproduce Idris/Haskell style in new Idriç work.

Inspect the relevant surrounding Idriç work before inventing a new pattern, but
do not promote arbitrary existing files into style authorities. Human
corrections and the canonical guide/examples take precedence.

Work on a branch, keep changes narrow, and run the checks relevant to the code
you changed before proposing it for merge.
