# Oodriç

Oodriç is the experimental branch for removing accidental source-order requirements from Idriç elaboration.

The language question is simple:

> A module should be readable in the order that best explains the program. A function body should not fail merely because a declaration it uses appears later in the same module.

This branch is allowed to break inherited Idris behavior while that question is explored. Compatibility and compilation speed are not design constraints here. The experiment should prefer clear source semantics and clear compiler explanations.

## First executable slice

The first slice separates ordinary function definitions from the declarations that establish their names and types. The compiler first walks the module to establish non-definition declarations, then checks ordinary function bodies. Namespace blocks participate in both walks.

This is intentionally narrower than the final question. Parameter blocks, records, data dependencies, transformations, run-elaborator declarations, and genuinely circular dependencies still need deliberate treatment. A green forward-reference example is evidence for one step, not a claim that declaration order is fully irrelevant.

The regression example is purpose-first source:

```idris
run_morning_routine : IO ()
run_morning_routine = do
  open_chicken_coop

open_chicken_coop : IO ()
open_chicken_coop = pure ()
```

The body comes first because that is the useful reading order. The later declaration should be available when the body is checked.

## Non-goals for this experiment

Oodriç does not currently require explicit types for every top-level value merely to make the implementation convenient. That remains a language-design question and has to justify itself independently.

Oodriç is also separate from the Adriç adverb/progressive-control experiment. The two ideas were exposed by the same readability problem, but either may survive without the other.
