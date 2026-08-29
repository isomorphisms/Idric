# Pass 3 — Frobenius structures as typed rewrite interfaces

Coecke/Pavlović supply a model for how mathematical structure can control optimization.

## Do not hard-code the picture

Suppose the compiler sees a network that visually resembles a spider. It should not fuse it merely because a ZX tutorial would.

Instead, the relevant object should carry or resolve a structure with named operations and laws. Schematically:

```text
structure ClassicalLike A where
  copy   : A -> A ⊗ A
  delete : A -> I
  ... laws ...
```

A stronger structure may add multiplication, dagger compatibility, Frobenius, commutativity, specialness, etc.

Once the solver has established the required structure, the rewrite engine may use the laws attached to it.

## Compiler architecture

Keep four things distinct:

```text
1. carrier/object type       A
2. chosen structure          S on A
3. law/certificate           L(S)
4. rewrite instance          matched subgraph -> replacement
```

Two values can have the same storage representation and even the same carrier type while supporting different mathematical structures. The rewrite entitlement comes from `S` and its laws, not from byte layout.

## Explanation trace

A useful compiler trace would look like:

```text
subgraph matched connected copy/multiply network
-> resolved structure S : CommutativeSpecialDaggerFrobenius A
-> applied Frobenius/spider law from S
-> replaced network by fused node
```

This is the diagrammatic counterpart of explaining an inferred type by the constraints that forced it.

## Theorem corpus boundary

The theorem index proposed in Idriç #42 can store general implications such as “this combination of operations/laws yields that structure” or “this structure admits this normal form.” The active compiler pass should still use a finite, versioned rewrite set so compilation remains predictable.

The knowledge corpus can be encyclopedic; the optimizer should not be an unbounded search engine.
