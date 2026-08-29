# Summary — Kissinger, string graphs and ZX

This folder combines three levels of the same idea: a mathematical graphical language, a computer representation of that language, and a compiler-like use of rewriting.

## 1. *Pictures of Processes*: diagrams need a data structure

The thesis begins from string diagrams: processes are boxes with typed input and output wires; composition plugs compatible wires together; monoidal product places processes side by side.

The key computer-science step is to discretize these diagrams as **string graphs**. Once the picture is represented as a graph rather than as geometry on a page, it can be matched and rewritten with graph-rewriting machinery. The thesis develops double-pushout rewriting for this purpose and uses it to represent free traced/compact-closed categorical structure.

For Idriç, this is almost a direct IR proposal. An indexed expression can elaborate into an open typed graph where:

- operator/tensor occurrences are nodes;
- index occurrences are ports/wire endpoints;
- a contraction is an internal connection;
- a free index is a boundary connection;
- object/index-space types live on wires or ports;
- source spans remain metadata for diagnostics.

The exact graph formalism does not have to be Kissinger's string-graph implementation. The important precedent is that diagrammatic equality can be made computational without falling back to textual index substitution.

## 2. Rewriting is not arbitrary simplification

A graphical theory consists of generators plus equations. A rewrite engine applies oriented instances of those equations to matching subgraphs.

This gives a clean boundary for Idriç's theorem/law index:

```text
checked structure + named law
-> graph rewrite rule
-> typed match
-> replacement
-> explanation/provenance record
```

The compiler can be aggressive while remaining inspectable. “Why did this disappear?” can be answered by a local rewrite trace rather than “the optimizer knew a theorem somehow.”

## 3. *Picturing Quantum Processes*: take diagrams seriously

The book develops quantum theory with processes and diagrams as primary notation rather than as pictures pasted on top of matrices. Hilbert-space calculations remain a semantics/check, but much reasoning is performed diagrammatically using composition, tensor, duality, dagger structure, classical structures, phases, and complementarity.

For our purposes, the important methodological point is that a high-level representation can be both mathematically precise and computationally useful. Coordinate matrices are one realization, not necessarily the privileged semantic form.

## 4. ZX spiders compress index equations

In the ZX calculus, Z- and X-spiders are generators with compact graphical rewrite laws. Connected same-colour spiders can fuse under the spider law. Algebraically, a spider represents a highly structured tensor; graphically, many summations/equalities among indices become one connected component.

The tensor-network reading is especially relevant: wires correspond to finite-dimensional index spaces and connecting wires denotes contraction. A spider imposes a structured equality/phase relation on the incident indices.

This is strong evidence for treating Einstein notation as a *front end for connectivity*. The surface source may say:

```text
Tⁱⱼ vʲ
```

but the internal object need only know that the `j` output/input ports are connected and `i` remains on the boundary.

## 5. Critical caveat: ZX can forget variance because it has extra structure

ZX practice often treats wire orientation and index raising/lowering much more freely than ordinary tensor calculus. In a dagger compact category, cups/caps and duality make wire bending meaningful; in the qubit ZX setting, additional self-duality conventions simplify it further.

That must not leak into the general Idriç Einstein rule.

`Aᵢ Bᵢ` is still invalid under the current strict sketch unless the context supplies an explicit metric/bilinear form/duality map that makes the operation meaningful. A graphical IR may *represent* such a cup/cap or metric edge, but it may not invent one.

## 6. *Picturing Quantum Software*: diagram rewrite as compilation

The newer book makes the compiler analogy explicit in practice. It moves from circuits into ZX diagrams, performs diagrammatic transformations, and extracts/compiles useful circuit forms. Later chapters apply the representation to Clifford/stabilizer structure, universal circuits, measurement-based computation, controlled operations, Clifford+T reasoning, error correction, routing, and fault-tolerant compilation.

For Idriç, the architectural lesson is:

> do not lower away the mathematical representation before it has had a chance to simplify the computation.

An open contraction graph can be normalized, factorized, fused, or recognized structurally before it becomes scalar loads/adds/multiplies or backend-specific instructions.

## 7. Normal forms and strategies matter

A set of sound rewrite equations does not automatically provide a terminating, confluent, or efficient optimizer. Practical graphical software therefore needs strategies: which rules are oriented, which patterns are preferred, when to stop, and how to extract a target form.

The same will be true for Idriç. The theorem corpus can be larger than the optimizer's active rewrite set. A deterministic compilation pass should use a bounded/versioned strategy rather than an unbounded theorem search.

## Takeaway for the current branch

The likely useful pipeline is:

```text
Unicode Einstein syntax
-> typed index occurrences
-> typed open graph
-> law-governed graph normalization
-> cost/target planning
-> scalar loop / SIMD / GPU / other realization
```

Kissinger's work is evidence that the middle two stages can be first-class computational objects, not merely explanatory diagrams.
