# Pass 3 — semantic contraction versus machine realization

The reading makes the existing compiler-stage distinction sharper.

## Semantic fact

From source such as:

```text
ωᵢ vⁱ
```

the elaborator can establish:

- there is one compatible upper/lower `i` pair;
- the pair is contracted;
- no `i` boundary remains;
- the contraction has a particular scalar/object/index-space type.

That is true before the compiler knows how many machine instructions will execute.

## Planning fact

After graph normalization, the compiler can choose a realization. Possibilities include:

- a scalar indexed loop;
- SIMD instructions;
- GPU fragment/compute work;
- a library/kernel call;
- a closed-form algebraic reduction;
- another target-specific implementation.

The same source expression may choose differently at different sizes or targets.

## Do not encode loops into mathematical op names

An opcode such as `contract` or an IR edge should not mean `for`. Likewise a graph-theoretic loop/trace should not mean a machine branch-back loop.

The semantic IR should say what mathematical work exists. The backend plan should say how it will be carried out.

## Preserve enough structure for optimization

Lowering too early to scalar loads/multiplies/adds destroys information that could support:

- reassociation of contractions;
- fusion;
- symmetry-based elimination;
- recognition of traces/projections;
- SIMD/GPU mapping;
- avoiding work through a closed-form identity.

So keep the contraction graph until the target planner has consumed the useful mathematics.

## AICI observation

The companion AICI work should be able to report both layers independently:

```text
semantic: typed indexed contraction preserved
realization: SIMD | GPU | scalar loop | other
```

A scalar loop can be semantically correct even when a later performance gate prefers SIMD. Mixing those questions would make compiler diagnostics less informative.
