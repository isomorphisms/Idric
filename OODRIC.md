# Oodriç

Oodriç is the experimental branch for removing accidental source-order requirements from Idriç elaboration.

The language question is simple:

> A module should be readable in the order that best explains the program. A function body should not fail merely because a declaration it uses appears later in the same module.

This branch is allowed to break inherited Idris behavior while that question is explored. Compatibility and compilation speed are not design constraints here. The experiment should prefer clear source semantics and clear compiler explanations.

## First executable slice

The first slice separates adjacent ordinary function claims from their definition bodies. Claims are established immediately while term-level bodies wait until the next structural declaration, or the end of the declaration sequence. Definitions whose claims return `Type` remain immediate because later elaboration may need to reduce them. Namespace blocks schedule their own sequences. Consequently, a purpose-level definition can use a later helper when that helper has an explicit claim and no intervening data, record, interface/implementation, parameter, or other structural declaration forms a scheduling boundary.

Those structural boundaries are significant. Type-synonym bodies can be required by later data, record, interface, or implementation declarations, so delaying every definition body until after every non-definition declaration breaks otherwise valid Idriç. The `oodric004` regression test keeps that boundary honest.

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

Oodriç does not require explicit types for every top-level value merely to make the implementation convenient. In this first slice, however, a declaration used before its definition needs an explicit claim; unclaimed later definitions remain source-ordered. Whether inference should cross that boundary is a separate language-design question.

Oodriç is also separate from the Adriç adverb/progressive-control experiment. The two ideas were exposed by the same readability problem, but either may survive without the other.
