# Odriç command-line dogfood targets

Odriç should be exercised against ordinary command-line programs, not only small
language examples.

## Repository-wide rule

Every command-line access tool that has been developed anywhere in the user's
GitHub repositories is a valid Odriç target.

This is intentionally broader than the current news/API work. It includes every
CLI that talks to an external API, feed, archive, search service, web service,
or other remote data source, whether the tool already exists today or is added
later.

The existing corpus includes, but is not limited to:

- Amazon and AbeBooks access in `az`;
- Reddit;
- job/search services such as Indeed, ZipRecruiter, Adzuna, Arbeitnow,
  Careerjet, Jobicy, Jooble, LinkedIn, Reed, Remotive, The Muse, and USAJobs;
- New York Times, Guardian, Economist, Financial Times, Reuters, and AP;
- Internet Archive / Wayback CDX access;
- OpenAI / ChatGPT command-line API access work;
- any other command-line API/access program in repositories that has been used
  as a development checkpoint.

The list above is illustrative, not exhaustive. The rule is the important part:
**all such command-line access tools across the repositories are Odriç dogfood
and regression targets.** Do not require a separate decision to "port" each one
before treating it as part of the Odriç application corpus.

## What the corpus is for

These programs are useful because they pressure mundane language/runtime
features that compiler toy programs often miss:

1. command-line arguments;
2. strings and Unicode;
3. percent/query encoding;
4. environment and configuration access;
5. file input and fixtures;
6. JSON and other structured data;
7. arrays/lists and records;
8. deterministic text/TSV output;
9. process execution and exit status;
10. HTTP through ICU;
11. request methods, bodies, and caller-supplied headers;
12. authentication without leaking credentials;
13. explicit error cases and stable PASS / FAIL / SKIP receipts.

When Odriç cannot yet express one of these boundaries, keep the missing feature
visible as a named watchpoint, hole, FAIL, or SKIP. Do not silently replace the
Odriç lane with Python, Node, curl, or another mature implementation merely to
make the application appear to work.

Where another language lane already exists (Idriç, Ithon, Fieldmouse, or a small
reference client), preserve the same command contract and fixtures when useful
so language/compiler changes can be compared against concrete application
behavior.

## Maintenance rule

New command-line access tools added anywhere in the GitHub corpus automatically
become valid Odriç targets. This document should not need an edit every time a
new API client appears; additions to the example list are optional.
