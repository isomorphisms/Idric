# Finding the point where a lowering choice is made

Status: research/navigation note, 2026-10-24. **No new compiler pass, choice mechanism or acceptance test is implemented by this note.**

The important developer question is: **Which file and function make this choice, what alternatives were possible, how can I change it, and what artifact proves the change survived subsequent lowering?** This is prior to automatic optimization or target benchmarking.

See the [ComputerScience decision atlas](https://github.com/walnut-burgundy/computer-science/pull/82) for the full cross-repository trace and the [Android-NDK direct-DEX inspection pointers](https://github.com/isomorphisms/android-NDK/pull/31) for backend-owned decisions.

## What Idriç owns

- Language meaning and checking remain in [Idriç](../README.md); a machine storage representation cannot retroactively define a semantic object.
- [`Compiler/ANF.idr`](../Compiler/ANF.idr) is a concrete one-step-at-a-time intermediate form. A named intermediate is **not** a required memory store or physical register.
- [`Compiler/CaseOpts.idr`](../Compiler/CaseOpts.idr), [`Compiler/Inline.idr`](../Compiler/Inline.idr), and [`Compiler/CompileExpr.idr`](../Compiler/CompileExpr.idr) are candidate starting points to trace actual compiler transformations; identify exact functions and revisions before attributing a transformation to one of them.
- [Control flow, predication, selection and speculation](control-flow-predication.md) supplies one semantic hazard: an apparently profitable lowering can execute a previously untaken computation. The compiler must prove that a specific transformation is legal before treating it as an optimization.
- The root [one-step vocabulary in ComputerScience](https://github.com/walnut-burgundy/computer-science/blob/how-long%2Bhow-wide/notes/one-step-at-a-time-compilation.md) explains why temporary names are not physical writes.

## What Idriç does not own

- The architecture planner's proposed choice of trie, DFA, scanner, buffer layout, or data placement belongs in [ComputerScience architecture-search](https://github.com/walnut-burgundy/computer-science/tree/how-long%2Bhow-wide/architecture-search), not implicitly in the language typechecker.
- For the direct Android backend, [`Backend/DEX/Codegen.idr`](https://github.com/isomorphisms/android-NDK/blob/main/dex/idric/src/Backend/DEX/Codegen.idr), [`Lower.idr`](https://github.com/isomorphisms/android-NDK/blob/main/dex/idric/src/Backend/DEX/Lower.idr), [`IR.idr`](https://github.com/isomorphisms/android-NDK/blob/main/dex/idric/src/Backend/DEX/IR.idr), and [`Encode.idr`](https://github.com/isomorphisms/android-NDK/blob/main/dex/idric/src/Backend/DEX/Encode.idr) own their target-specific choices. Do not conflate working code on an unmerged DEX PR with current `main`.
- Android ART's later JIT/AOT decisions and a processor's observed instructions are not Idriç decisions. [English Major C](https://github.com/isomorphisms/English-major-C) is useful for describing actual native instructions and the execution index, not for proving what ART emits without target-specific evidence.

## Minimal trace required before changing a choice

For an example program and one target: record exact Idriç revision and symbol; the checked source and one-step form; the precise pass where two representations cease to be alternatives; what source edit or option can change that choice; the emitted plan and bytes; the downstream runtime output or disassembly; and correctness evidence against an independent oracle.

If the choice happens in a backend or external runtime, say so instead of adding a parallel Idriç setting. If the mechanism is unknown, record it as **not yet located**, not as an optimizer requirement.
