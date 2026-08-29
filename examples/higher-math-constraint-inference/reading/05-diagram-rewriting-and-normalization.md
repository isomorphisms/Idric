# Pass 3 — diagram rewriting and normalization

Kissinger's string-graph work makes a typed open graph a plausible compiler IR rather than just a whiteboard metaphor.

## Proposed role

The graph sits after parsing/type elaboration and before backend planning:

```text
AST
-> typed AST
-> typed open diagram
-> normalization / algebraic planning
-> backend-neutral operation plan
-> target lowering
```

This should be a semantic layer, not a drawing API.

## Rewrite rule shape

A rule needs:

```text
name
required structures/laws
typed left-hand graph
typed right-hand graph
side conditions
provenance
orientation/strategy metadata
```

Matching must respect wire/object types and any variance/duality annotations.

## Why graph rewriting helps

Textual tensor expressions contain accidental syntax:

- bound index names;
- multiplication association;
- order choices that may be semantically symmetric;
- temporary names introduced only to spell an intermediate result.

A graph can quotient out some of that noise before optimization. Local algebraic identities then become local graph replacements.

## But sound rules are not enough

A library of valid equalities can still loop forever:

```text
A -> B
B -> A
```

or explode the search space. Compilation therefore needs a strategy layer:

- preferred normal forms;
- measures expected to decrease;
- bounded saturation where appropriate;
- cost-guided choices when several normal forms are possible;
- a deterministic fallback.

Confluence should be established where claimed; otherwise the compiler should admit that the strategy chooses one representative rather than pretending a unique normal form exists.

## Validation

Good tests should separate:

1. graph construction from Einstein syntax;
2. type preservation of each rewrite;
3. semantic equivalence of the rule;
4. termination/strategy behavior;
5. target lowering after normalization.

This avoids a test passing merely because the final numeric answer happened to agree.
