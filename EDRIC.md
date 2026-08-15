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

At this checkpoint **no Edric-specific syntax change is being claimed**. The point of this commit is to establish the modern, reproducible base and a testable handoff before language changes begin.

## Working copy

Preferred checkout:

```sh
git clone https://github.com/isomorphisms/Idric.git /opt/Idric
cd /opt/Idric
```

If `/opt` is not writable, use `~/opt/Idric`.

## Build

Follow `INSTALL.md`. On a normal Unix system with Chez Scheme available, the bootstrap path is:

```sh
make bootstrap SCHEME=chez
```

The executable name may be `scheme`, `chez`, or `chezscheme` depending on the system; pass the installed name as `SCHEME=...`.

Then run the suite:

```sh
make test
```

The Edric handoff smoke test can be run alone with:

```sh
make test only=idris2/basic/edric001
```

## Change discipline

For each language change:

1. Make the smallest parser/elaborator/compiler change that expresses the idea.
2. Add a focused regression test under the existing Idris 2 test harness.
3. Keep ordinary Idris 2 behavior working unless the change explicitly replaces it.
4. Record user-visible syntax/semantic decisions here when they become part of Edric rather than leaving them only in a conversation.
5. Keep `main` buildable; use a branch when an experiment is not yet coherent.

## New-thread handoff

A new thread working on Edric should:

1. Open this file and the root `README.md`.
2. Inspect the latest commits and current branch before changing code.
3. Run `make test only=idris2/basic/edric001` as a quick baseline when a built compiler is available.
4. Treat this repository as authoritative for implemented state. Conversation notes may explain intent but do not override the checked-in source and tests.
5. Update this checkpoint when a new architectural decision would otherwise be lost between threads.

## Current state

- Modern Idris 2 foundation: established.
- Durable repository handoff: established.
- Ordinary Idris 2 implementation language: established.
- Edric-specific syntax or semantic changes on this modern base: not yet claimed by this checkpoint.
- Historical broad mechanical Unicode rewrite: reference only, not the base.
