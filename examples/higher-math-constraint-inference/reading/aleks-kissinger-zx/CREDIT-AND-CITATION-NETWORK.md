# Credit and citation network — Kissinger / ZX

## Direct authorship

- **Aleks Kissinger** — *Pictures of Processes*; coauthor of *Picturing Quantum Processes* and *Picturing Quantum Software*.
- **Bob Coecke** — coauthor of *Picturing Quantum Processes* and a central originator of categorical quantum mechanics / ZX-style diagrammatic reasoning.
- **John van de Wetering** — coauthor of *Picturing Quantum Software* and a major contributor to modern ZX-based compilation and PyZX.

## Important nearby contributors and lines of work

The books, thesis, and ZX literature build on a broad network. Names that recur centrally in the mathematical and computational lineage include:

- **Samson Abramsky** — categorical semantics of quantum protocols;
- **Peter Selinger** — dagger compact categories, CPM, and graphical coherence;
- **Ross Duncan** — interacting observables, ZX calculus, and graphical reasoning;
- **Miriam Backens** — completeness and stabilizer ZX-calculus results;
- **Emmanuel Jeandel**, **Simon Perdrix**, and **Renaud Vilmart** — completeness results and rewrite theory for richer ZX fragments;
- **Niel de Beaudrap** — ZX-calculus and graph-state/measurement-based techniques;
- **Jamie Vicary** — categorical structures for classical/quantum systems;
- **Roger Penrose** — tensor-diagram tradition;
- **André Joyal** and **Ross Street** — string-diagram / monoidal graphical foundations;
- **G. M. Kelly** and **M. L. Laplaza** — compact-closed coherence;
- **André Joyal**, **Ross Street**, and **Dominic Verity** — traced monoidal categories.

The computational lineage includes **Quantomatic** and **PyZX**. When a concrete algorithm from those systems is imported, cite its paper/repository directly rather than treating “ZX” as a single undifferentiated source.

## Upstream attribution for the open book

*Picturing Quantum Software* is:

> Aleks Kissinger and John van de Wetering, *Picturing Quantum Software: An Introduction to the ZX-Calculus and Quantum Compilation*, preprint.

Canonical repository: https://github.com/zxcalc/book

The upstream README specifies CC BY-NC 4.0. Any redistributed excerpt, adaptation, or future mirror in this project must retain attribution to Kissinger and van de Wetering and the license.

## Citation discipline here

A compiler rewrite should cite the most specific source available. Examples:

- a compact-closed yanking rule should cite the compact-category/coherence source used;
- a Frobenius/spider rule should cite the relevant Frobenius/ZX source;
- a completeness-based normalization should cite the completeness result;
- a PyZX-derived optimization should cite PyZX rather than only the textbook.

This keeps “the diagram told us so” from becoming an untraceable oracle.
