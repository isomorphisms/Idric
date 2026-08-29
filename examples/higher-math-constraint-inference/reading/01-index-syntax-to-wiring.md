# Pass 3 — Einstein index syntax as typed wiring

The three reading threads converge on one representation idea:

> index notation is a compact textual way to describe an open network of typed connections.

For a single product term, the current strict rule already contains most of the graph construction:

```text
Aᵢ        -> one free lower i boundary
vⁱ        -> one free upper i boundary
Aᵢ Bⁱ     -> connect the two i ports; i disappears from the boundary
Tⁱⱼ vʲ    -> connect j; upper i remains on the boundary
```

## Elaboration sketch

Do not implement this as a global Unicode scan. After parsing, each indexed occurrence should carry at least:

```text
source_name      i / j / k / ...
variance         upper | lower
index_space      metavariable or resolved space
dimension        derived from index_space or an explicit dependent index
source_span      diagnostic provenance
owner            tensor/operator occurrence and port
```

Then build equivalence/binding groups by the source index name *within the syntactic scope where Einstein binding is defined*.

For each group:

- one occurrence -> free boundary port;
- exactly one upper + one lower -> contraction edge, after compatible-space unification;
- any other repetition -> error unless an explicit higher rule handles it.

After this, the source letter is no longer semantically important. Alpha-renaming `i` to `k` should not change the graph.

## Sums and equations

Products are only the easy case. Addition/subtraction should require the same free-index interface on every term, modulo alpha-renaming and whatever commutativity of boundary ordering the type says is allowed.

Example:

```text
Aⁱⱼ vʲ + bⁱ
```

is well-shaped if both summands have the same free upper `i` space.

But

```text
Aⁱⱼ vʲ + cⱼ
```

should fail without an explicit identification of the output spaces/variance.

The two sides of `=` similarly need compatible free boundaries.

## Tensor product versus contraction

Two free indices survive juxtaposition:

```text
vⁱ ωⱼ
```

has an upper `i` and lower `j` boundary. That is an outer/tensor product shape.

A repeated upper/lower label creates an internal edge:

```text
ωᵢ vⁱ
```

and therefore produces no `i` boundary.

This is a much cleaner semantic distinction than introducing opcodes called `tensor_product` and `contract` before the parser/elaborator has even represented the connectivity.

## Compiler consequence

Once the graph exists, renaming indices, reassociating products, and choosing a loop order are separate concerns. The backend can later decide how to realize the same contraction graph without changing its mathematical meaning.
