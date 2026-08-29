# Diagrammatic constraint reading

This directory is the three-pass reading layer for the higher-math constraint-inference experiment.

The immediate question is whether the Einstein-index surface syntax in this branch can elaborate into a typed representation of *wiring* before any decision is made about scalar loops, SIMD, GPU work, or another backend realization.

The three source families are:

1. [`predrag-cvitanovic-birdtracks/`](predrag-cvitanovic-birdtracks/) — Predrag Cvitanović, especially *Group Theory: Birdtracks, Lie's, and Exceptional Groups*.
2. [`coecke-pavlovic/`](coecke-pavlovic/) — Bob Coecke and Duško Pavlović, especially the papers that turn copying/deleting, bases, and measurement into algebraic and graphical structure.
3. [`aleks-kissinger-zx/`](aleks-kissinger-zx/) — Aleks Kissinger, especially *Pictures of Processes*, *Picturing Quantum Processes*, and *Picturing Quantum Software* / the ZX calculus.

The names in the original note were abbreviated. `Dustin Pa___` is taken here to mean **Duško Pavlović**; the Oxford author associated with spiders and the ZX calculus is taken to mean **Aleks Kissinger**. These identifications are recorded rather than silently normalized.

## Passes

Each source directory contains:

- `README.md` — provenance, canonical links, redistribution boundary, and credit trail;
- `SUMMARY.md` — a source-faithful mathematical summary focused on what matters to this experiment;
- `CREDIT-AND-CITATION-NETWORK.md` — people and prior work that should remain visible when these ideas are reused.

The higher-level files in this directory are pass 3: synthesis written *after* the source summaries, rather than pretending one source already says what Idriç should do.

## Pass 3 index

- [`01-index-syntax-to-wiring.md`](01-index-syntax-to-wiring.md)
- [`02-free-bound-indices-and-hm.md`](02-free-bound-indices-and-hm.md)
- [`03-variance-duals-and-no-silent-metric.md`](03-variance-duals-and-no-silent-metric.md)
- [`04-frobenius-structures-as-typed-rewrite-interfaces.md`](04-frobenius-structures-as-typed-rewrite-interfaces.md)
- [`05-diagram-rewriting-and-normalization.md`](05-diagram-rewriting-and-normalization.md)
- [`06-compiler-boundary.md`](06-compiler-boundary.md)
- [`SYNTHESIS.md`](SYNTHESIS.md)

## One boundary to keep explicit

The graphical calculi are powerful partly because particular mathematical settings supply duals, cups/caps, invariant forms, Frobenius structures, or other equations that make diagrams deformable. That must **not** become a compiler-wide license to identify `V` with `V*` or to contract two lower indices merely because a picture could bend a wire.

The current strict Einstein experiment remains the conservative default:

```text
one lower occurrence             -> free lower index
one upper occurrence             -> free upper index
one lower + one upper occurrence -> contraction
other repetition                 -> reject unless extra typed structure justifies it
```

Diagrammatic structure should make the typed constraints clearer, not erase them.
