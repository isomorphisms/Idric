# Edric project checkpoint

This file is the durable handoff for the project called **Idriç**, **Idric**, or **Edric**. A new work thread should be able to start here without reconstructing the project from chat history.

## Canonical repository

`https://github.com/isomorphisms/Idric`

The repository's ASCII name is `Idric`. The intended project name is `Idriç`; `Edric` is also used in speech/transcription. All three names deliberately appear here so repository search can find the project.

## Foundation

Edric is an experimental Idris-derived compiler line built on the current Idris 2 compiler. The modern baseline for this checkpoint is Idris 2 commit:

`9b2116d98b5789afe3a003b234fd173c6b9aa379`

The older `isomorphisms/Idri-` / `Idris2-boot` work is historical reference only. Do **not** use that obsolete bootstrap tree as the foundation and do not replay its broad mechanical rewrite wholesale. Extract intentional language ideas from it individually and add each one to this modern tree with focused tests.

## Implementation rule

Use ordinary, current Idris 2 to implement Edric until an Edric change is itself stable enough to be deliberately dogfooded. Do not make the compiler depend on an unbuilt dialect of itself.

At this checkpoint **no Edric-specific syntax change is being claimed**. The project first establishes a modern, reproducible base and a testable handoff.

## Working copy

Preferred checkout:

```sh
git clone https://github.com/isomorphisms/Idric.git /opt/Idric
cd /opt/Idric
```

If `/opt` is not writable, use `~/opt/Idric`.

## Repo-local Scheme toolchain

A system-wide Chez Scheme installation is not required. The root `edric` command installs the pinned threaded Chez Scheme toolchain under the ignored directory `.tools`:

```sh
./edric scheme
```

The stable executable path is:

```text
.tools/bin/scheme
```

The installer fetches the official Chez Scheme 10.4.1 source archive, verifies its SHA-256 digest, builds without X11 or curses, installs it under `.tools/chez-10.4.1`, and verifies that `(threaded?)` returns `#t`.

For a machine without outbound network access, provide the same verified archive explicitly:

```sh
CHEZ_ARCHIVE=/path/to/csv10.4.1.tar.gz ./edric scheme
```

The host still needs a C compiler, `make`, `tar`, and either `sha256sum` or `shasum`. `curl` or `wget` is needed only when `CHEZ_ARCHIVE` is not supplied.

## Build and test

From a clean checkout, the complete checkpoint build is:

```sh
./edric
```

That is equivalent to:

```sh
./edric scheme
./edric bootstrap
./edric test
```

The individual underlying commands remain available:

```sh
make bootstrap SCHEME="$PWD/.tools/bin/scheme"
make test only=idris2/basic/edric001
make test only=idris2/basic/edric002
```

## Change discipline

For each language change:

1. Make the smallest parser, elaborator, or compiler change that expresses the idea.
2. Add a focused regression test under the existing Idris 2 test harness.
3. Keep ordinary Idris 2 behavior working unless the change explicitly replaces it.
4. Record user-visible syntax and semantic decisions here when they become part of Edric rather than leaving them only in a conversation.
5. Keep `main` buildable; use a branch when an experiment is not yet coherent.

## New-thread handoff

A new thread working on Edric should:

1. Open this file and the root `README.md`.
2. Inspect the latest commits and current branch before changing code.
3. Use `./edric` to establish the repo-local Scheme toolchain, bootstrap the compiler, and run the focused handoff test.
4. Treat this repository as authoritative for implemented state. Conversation notes may explain intent but do not override the checked-in source and tests.
5. Update this checkpoint when a new architectural decision would otherwise be lost between threads.

## Current state

- Modern Idris 2 foundation: established.
- Durable repository handoff: established.
- Ordinary Idris 2 implementation language: established.
- Pinned repo-local threaded Chez Scheme bootstrap: established.
- Focused Edric handoff test: checked in.
- Idriç source extension: `.idric`; `.idr` remains accepted for Idris compatibility.
- Edric-specific syntax or semantic changes on this modern base: not yet claimed by this checkpoint.
- Historical broad mechanical Unicode rewrite: reference only, not the base.
