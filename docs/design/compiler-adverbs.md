# Compiler implementation adverbs

Date: 2026-08-26

## Design claim

Idriç should distinguish, where possible, between:

1. **what a program means**;
2. **how a backend realizes it**;
3. **which observations the programmer requires to remain invariant**.

The third item is what makes implementation choice principled rather than merely heuristic.

A useful working metaphor is **adverbs**. An operation is the verb; an implementation policy modifies how it is carried out.

```text
emit bytes          -- verb
emit immediately    -- verb + adverb
emit buffered       -- verb + adverb
emit in bounded chunks
emit adaptively
```

The concrete motivating case is a tiny Arm Thumb program that emits `X\b` 100,000 times. The loop itself stays tiny, but a direct implementation can make 100,000 kernel writes, while a buffered implementation can trade memory and visibility latency for drastically fewer writes.

## Do not make one hidden policy universal

The compiler should not silently assert that one of these is always better:

- minimum latency;
- maximum throughput;
- minimum executable size;
- minimum runtime dependency closure;
- bounded memory;
- minimum power;
- easiest debugging;
- strongest failure visibility.

Different programs, call sites, deployment profiles, and targets can legitimately choose differently.

## A compiler can ask a useful question

When the source leaves an implementation choice open and the consequences are large, the compiler may present the programmer with the relevant tradeoff instead of issuing a style warning or silently choosing.

The question should be about consequences, for example:

```text
This expression may produce 200,000 output bytes.

Choose an output policy:

immediate
  earliest externally visible effects
  approximately one write per iteration for this backend
  minimal buffering

bounded-buffer
  at most N bytes working buffer
  fewer writes
  visibility may be delayed until flush

adaptive
  compile more than one implementation
  select from runtime/target facts
```

A choice should be recordable in source or a named build/deployment profile so the compiler does not repeatedly ask the same settled question.

## Observational boundaries first

`write A; write B` is not automatically equivalent to `buffer AB; write AB` under every semantics.

They can differ if the program/environment observes:

- flush timing;
- a crash between effects;
- interactive terminal updates;
- hardware-device timing;
- network interaction;
- externally visible progress;
- errors returned by individual writes.

Therefore an implementation adverb should either:

- preserve all observations specified by the operation's contract; or
- require the programmer to explicitly relax some observations.

This is a natural place for Idriç's type/effect machinery eventually to help, but the design note does not assume a particular type encoding yet.

## Multiple implementations are allowed

Do not force the compiler to collapse a policy family to one implementation at compile time.

A valid compilation product can be:

```text
P semantics
  ├─ P/immediate
  ├─ P/buffered
  └─ P/select
```

where `P/select` is a small ordinary program that chooses an implementation based on facts such as:

- TTY versus pipe/file;
- expected output size;
- available RAM;
- target device class;
- latency mode;
- power mode;
- hardware capability.

This preserves the programmer's idea that case A and case B may both be correct and that case C decides which one to use.

## Policy as data

A future representation should make policies inspectable rather than burying them in backend flags.

Illustrative, not proposed syntax:

```text
OutputPolicy =
    Immediate
  | Buffered bytes
  | Adaptive criteria

SizePolicy =
    SmallestStandalone
  | SharedRuntime
  | SmallestInstallation programCount

PrecisionPolicy =
    Exact
  | F32
  | F16
  | Approximate tolerance
```

The important point is that the policy becomes a value/configuration with a name and provenance.

## Deployment profiles

A profile can answer many compiler questions at once:

```text
interactive-phone
bare-metal-smallest
batch-throughput
low-power
exact-debug
```

Profiles should express constraints and preferences, not just conventional `-O0`/`-O2`/`-Os` buckets.

For example `bare-metal-smallest` might prefer:

- runtime-free lowering where supported;
- no dynamic loader;
- no heap;
- bounded stack;
- smallest standalone artifact;
- explicit rejection when the requested semantics require unsupported runtime machinery.

`interactive-phone` might prefer immediate or explicitly flushed output where latency is part of the user-visible behavior.

## Backend protocol implication

Backends should eventually be able to report candidate realizations and costs/capabilities, not merely accept a finished IR and emit code.

Conceptually:

```text
semantic IR
    ↓
required observations
    ↓
policy/profile
    ↓
backend candidate(s)
    ↓
reported properties
    ↓
selection
    ↓
codegen
```

Candidate properties can include:

- code bytes;
- runtime dependencies;
- required runtime features;
- temporary memory;
- expected syscall/dispatch count;
- precision/rounding behavior;
- target capability requirements;
- measured or estimated latency/throughput.

`unknown` is preferable to invented precision.

## Relationship to optimization

This should not eliminate ordinary compiler optimization. Local transformations that are proved semantics-preserving can remain automatic.

The conversation/adverb layer is for materially different realizations whose preference depends on information outside pure semantics or where the allowed observational equivalence itself needs to be stated.

A useful distinction is:

```text
compiler knows transformations are equivalent under the current contract
    → optimize automatically

compiler sees multiple valid policies with different observable/cost behavior
    → expose the choice or use a recorded profile
```

## Test direction

The `X\b` × 100,000 fixture should eventually test three policies on the Arm backend:

1. immediate tiny writes;
2. bounded buffered writes;
3. an adaptive selector.

Tests should assert both byte-sequence semantics and the policy-specific structural facts, such as syscall count bounds and maximum buffer size.

The same policy layer should be reusable by non-Arm backends instead of baking these decisions into one target.