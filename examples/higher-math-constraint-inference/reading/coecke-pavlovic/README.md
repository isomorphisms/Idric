# Bob Coecke and Duško Pavlović

The abbreviated name in the originating note, `Dustin Pa___`, is interpreted here as **Duško Pavlović**.

## Primary sources for this reading thread

### Quantum measurements without sums

Bob Coecke and Duško Pavlović, “Quantum measurements without sums,” 2006.

- arXiv: https://arxiv.org/abs/quant-ph/0608035
- Oxford technical report RR-06-02: https://www.cs.ox.ac.uk/techreports/oucl/rr-06-02.html

The paper asks how much of quantum measurement can be expressed using tensor/compositional structure rather than direct sums. The key operational move is to characterize classical data by explicit copying and deleting operations satisfying algebraic laws, yielding a graphical calculus.

### A new description of orthogonal bases

Bob Coecke, Duško Pavlović, and **Jamie Vicary**, “A new description of orthogonal bases,” *Mathematical Structures in Computer Science* 23(3), 2013; preprint 2008.

- arXiv: https://arxiv.org/abs/0810.0812

The result identifies orthogonal bases in finite-dimensional Hilbert spaces with commutative dagger-Frobenius monoids; normalization corresponds to specialness. The basis vectors are recovered as the copyable points of the comultiplication.

## Redistribution status

**Link to the arXiv/Oxford copies; do not mirror them here unless the exact file's redistribution license is verified.**

The papers are publicly available, but public availability alone is not a sufficient redistribution grant. This directory contains independent summaries and citations only.

## Why these papers belong here

The important lesson for Idriç is that graphical rewrite power should come from *typed algebraic structure*, not from a compiler recognizing a pretty picture and guessing a law.

A source-level operation such as copying, deleting, fusing, or contracting can generate a structure obligation. Once that obligation is solved, the corresponding equations become legitimate rewrite rules. This is the higher-math analogue of Hindley–Milner constraints: use generates requirements; satisfying the requirements authorizes additional conclusions.

These papers also sharpen the distinction between ordinary tensor-product composition and special structure attached to a chosen classical interface/basis. That distinction matters if Einstein-index notation is to remain mathematically honest.

## Credit and thanks

Deep thanks to **Bob Coecke** and **Duško Pavlović** for making the copy/delete structure of classical data explicit, and to **Jamie Vicary** for the orthogonal-basis characterization paper.

The surrounding categorical-quantum-mechanics program also depends heavily on work by **Samson Abramsky**, **Peter Selinger**, and many others recorded in `CREDIT-AND-CITATION-NETWORK.md`.
