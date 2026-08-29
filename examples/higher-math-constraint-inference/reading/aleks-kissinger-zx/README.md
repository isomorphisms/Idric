# Aleks Kissinger — string graphs, spiders, and the ZX calculus

The “Oxford person” in the originating note is taken to mean **Aleks Kissinger**, Professor of Quantum Computing in Oxford's Department of Computer Science and coauthor of the two *Picturing...* textbooks.

Oxford profile: https://www.cs.ox.ac.uk/people/aleks.kissinger/

## Primary sources

### Pictures of Processes

Aleks Kissinger, *Pictures of Processes: Automated Graph Rewriting for Monoidal Categories and Applications to Quantum Computing*, DPhil thesis, University of Oxford, 2012.

- arXiv: https://arxiv.org/abs/1203.0202
- Oxford repository: https://ora.ox.ac.uk/objects/uuid:61fb3161-a353-48fc-8da2-6ce220cce6a2

This is the graph-rewriting source most directly relevant to compiler representation: typed input/output wires, string diagrams, a discretized string-graph representation, and double-pushout rewriting.

**Redistribution:** link only here. No permissive redistribution grant for the exact thesis file was verified in this pass.

### Picturing Quantum Processes

Bob Coecke and Aleks Kissinger, *Picturing Quantum Processes: A First Course in Quantum Theory and Diagrammatic Reasoning*, Cambridge University Press, 2017. DOI 10.1017/9781316219317.

- Cambridge contents: https://www.cambridge.org/core/books/picturing-quantum-processes/7A1A65B9E6B3F4A9F1A47D5A73B2FBA0
- author description: https://www.cs.ox.ac.uk/people/aleks.kissinger/

The book develops quantum theory diagram-first: processes, string diagrams, Hilbert-space semantics, measurement, classical/quantum interaction, phases/complementarity, computation, resources, and Quantomatic.

**Redistribution:** link only. This is a Cambridge University Press book; no permissive redistribution license was found.

### Picturing Quantum Software

Aleks Kissinger and John van de Wetering, *Picturing Quantum Software: An Introduction to the ZX-Calculus and Quantum Compilation*.

- canonical repository: https://github.com/zxcalc/book
- HTML: https://zxcalc.github.io/book/html/main_html.html
- release used for these notes: **v1.3.0**, 2026-01-16
- v1.3.0 commit: `5ed5a29a5d03d7d00284dab7957de67f80032d07`
- PDF SHA-256 recorded by the release: `97a2013cc33f267506d257d1bb1d4e94c75d972006cc522d4e0086892d82e89c`

The upstream README explicitly licenses the book under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**.

That license permits redistribution and adaptation with attribution for non-commercial purposes. The source is already maintained as a public Git repository and v1.3.0 includes a ~4.8 MB generated PDF. Rather than copy a large generated binary into the Idriç compiler repository and immediately create a stale second copy, this dossier pins the exact upstream release/commit and records its digest and license. This is a repository-size/versioning decision, not a rights restriction. A deliberate future vendor/mirror can use this pin as provenance.

## Why this source belongs here

Kissinger provides the missing computer-science middle layer between Einstein syntax and backend code:

```text
index expression
-> typed open diagram
-> graph representation
-> local typed rewrites / normalization
-> extraction into a target representation
```

The ZX-calculus is especially suggestive because it is used not just for exposition but for real circuit optimization and compilation. The critical lesson is that a rewrite system can preserve semantics while changing the shape of the computation before low-level realization.

The equally critical caveat is that ZX diagrams live in a compact setting where wire bending and spider structure justify identifications that ordinary tensor notation does **not** justify universally. See `03-variance-duals-and-no-silent-metric.md` in the parent directory.

## Credit and thanks

Deep thanks to **Aleks Kissinger**; to **Bob Coecke** for *Picturing Quantum Processes*; and to **John van de Wetering** for *Picturing Quantum Software* and the current public book repository/release. The wider ZX and categorical-quantum community is credited in `CREDIT-AND-CITATION-NETWORK.md`.
