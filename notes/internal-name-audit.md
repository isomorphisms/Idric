# Names for information carried through the compiler

STAR IDRIC-INTERNAL-NAMES-01, November 23, 2026. Source inspected at `b2f4c2488d0aa55cd947535eb9b61ff0e6bba963` on the Idriç branch, repository ID 1335092603. Both historical repository coordinates resolved to this identity.

## Source audit

The motivating module implements indexed *positional* compatibility. Replacing two corresponding names with different names preserves the relation. The decision procedure rejects an unmatched slot on either side. Building or carrying a value of this relation does not perform a name-equality check.

There are two distinct public modules. `Core/Name/CompatibleVars.idr` works from the right of snoc lists. `Core/Name/Scoped.idr` works from the left of ordinary lists. Both occur in `_/idris2api.ipkg`. Internal compiler imports go through the list version, including the public re-export by `Core/TT.idr`. I found no direct source import of the snoc module in this tree. A test that exercises only the usual compiler consumer misses the module that originally motivated the audit.

A case-insensitive, whole-word Git search for proof, prf, nprf, witness, lemma, theorem and proposition across Core, Compiler, Idris and TTImp found 231 matching lines in 54 files. Includes comments, user syntax and compatibility code. These counts scope the search. The rows below are the traced migration units. Nearby compound names can have entirely different meanings.

| Location and spelling | Value or operation, from producer to consumer | Proposed edit and boundary |
|---|---|---|
| Both scope modules, `extendCompats`, local `prf` | Existing correspondence between the original scopes. Its local recursion adds one `Ext` for each appended/prepended slot. The separate `Pre` clause retains identity. | `scope_alignment` in the equations and their local helper. Keep function, constructors, exported type, binder names in public signatures and pattern ordering. Job 02. |
| Both modules, `decCompatibleVars`, local `prf` / `nprf` | Recursive `Yes` supplies the smaller correspondence that `Ext` extends. Recursive `No` supplies a function from the smaller correspondence to `Void`. Composing it with `invertExt` refutes a proposed larger correspondence. | `remaining_alignment` / `refute_remaining_alignment`. Contrast with `areCompatibleVars`, whose unequal-length case drops the refutation and returns `Nothing`. Keep both result types. Job 02. |
| Both modules, `invertExt (Ext p)`, `areCompatibleVars` local `compat` | The first returns a stored inner correspondence. The latter binds the recursive successful correspondence in `Maybe`. | `remaining_alignment` at each binder and its uses. Job 02. |
| `Core/Env.idr`, `uniqifyEnv.uenv` local `compat`; `Core/TT/Var.idr`, `compatVar prf (MkVar p)` | The list API serves binder renaming. The environment recursion returns a name-adjusted environment with matching slots. `compatNs` transports the binder, and `compatIsVar` maps the input variable to the same index in the target scope. | `scope_alignment` at those clause-local binders, `variable_position` for the latter `p`. Keep dependent tuple, calls, public signatures and transport implementation intact. Job 02. |
| `Idris/Parser.idr` at `MkPWithProblem`, local `prf`; `TTImp/ProcessDef.idr`, `checkClause` local `mprf` | The parser returns an optional multiplicity and chosen binder name. It cannot have established the equality at parse time. Elaboration uses this request when calling `bindWithArgs` and constructing the corresponding application of `Refl`. | `with_equality_binding` at the parser, transport clauses and elaborator, including the serializer's local pattern variable. Preserve its optionality, both fields and argument positions. Job 03. |
| `Compiler/LambdaLift.idr`, private `markUsed` and `finIdx`, `prf` | A local occurrence carries an erased `IsVar x idx vars`. `finIdx` represents its index in range, and `replaceAt` sets the actual used-slot flag. | `variable_position`, including the named implicit in the private declaration, patterns and call. Separate future slice, after qualifying code generation for this pass. No rename of public constructor parameters. |
| `Compiler/Opts/ConstantFold.idr`, private `WkCExp.prf` | Erased equality decomposes a scope into weakening prefix and expression support. `weakenNs` supplies append associativity and lookup matches `Refl` to reuse the expression. | Candidate `scope_decomposition`. Defer generated field/projection and debug-name comparison to a later optimizer slice. |
| `Core/TTC.idr`, private `mkPrf` | Decoder receives an index and uses `believe_me` to reconstruct indexed local membership. Four read paths reconstruct a local term, case, or compiled expression. This function does not validate the index against an actual scope. | Candidate `restore_variable_position`. Keep as-is for this tranche. An attempt to validate input or change an old artifact would be a functional change. |
| `TTImp/Elab/Rewrite.idr`, private `Lemma` | `elabRewrite` returns a rewrite-rule name, the predicate to pass to it and the predicate type. The elaborator constructs the actual application. | Candidate `RewriteApplicationParts` if later paired with checked rewrite cases. Preserve mathematical uses of “lemma” and named user rules. |
| `Protocol/IDE/Result.idr`, public `MetaVarLemma.lemma` | IDE’s make-lemma command produces the printed definition type. A different field contains the replacement application. S-expression encoding exposes `definition-type` and `replace-metavariable`. | Retain the public projection and serialized keys, command spelling and presentation. `Idris/Syntax.idr` also publicly exports `withRigProof : Maybe (RigCount, Name)`. Retain this spelling. |

Public syntax `proof`, REPL help and diagnostic wording, declared commands, external modules and upstream library names remain compatibility surfaces. The historical TTImp/ANF vocabulary branches change constructor and expression names. Those changes are already reflected in the default source and its vocabulary notes. The scope alignment and optional binder migrations require no changes to those constructors. Exclude frozen bootstrap trees, generated Scheme/C and RefC, along with mathematical terminology in examples.

## Baseline

The build and type-smoke workflows on the audited source succeeded on the hosted runner. The type workflow selects ICK from `isomorphisms/ai-ci/ick-host@903b2cb27ea572c9c6cb2ffa9f39e0fbf06ec9f8`. The bootstrap installer specifies threaded Chez 10.4.1, archive SHA-256 `2e74952db7bc177f0c3602e2217a341ba677d733eec4cd7726418c3a4e1ef308`. Each workflow checks out its declared head. Job 01 adds narrow tests for the two scope APIs and reuses the existing with-clause regressions. [Build](https://github.com/isomorphisms/Idric/actions/runs/44582797447) · [Type smoke](https://github.com/isomorphisms/Idric/actions/runs/44582797451)

### Executed host fixture

The following unchanged client imported both current source modules into a fresh build directory. Linux x86-64, Idriç built from `2bce7677f513d711875e978bd6f5ad28b9e54d58`, Chez code generator. Compiler Scheme object SHA-256 `ddd950bb6a66b61b4ea3d252c531ca0d02817dbdaa9ef07f6c99f59fc7af9d71`. Compilation used `--cg chez -o scope-check ScopeCheck.idr`. The executable emitted the eight lines `yes, some, no, none, yes, some, no, none` (one token per line, stdout SHA-256 `a8d77b6682e52e81b5d61a53eccb7c7e67bcabde2916652ce58a132a5190508d`). Both the correct compiler and source import matter: checkout Core, Libraries and Idris sources together, and do not accept a driver exit without a newly generated executable.

```idris
module ScopeCheck

import Core.Name.CompatibleVars as Snoc
import Core.Name.Scoped as Cons

tagDecision : Dec a -> String
tagDecision (Yes _) = "yes"
tagDecision (No _) = "no"

tagOption : Maybe a -> String
tagOption (Just _) = "some"
tagOption Nothing = "none"

main : IO ()
main = do
  putStrLn $ tagDecision (Cons.decCompatibleVars (the (List Nat) [1,2]) [5,6])
  putStrLn $ tagOption (Cons.areCompatibleVars (the (List Nat) [1,2]) [5,6])
  putStrLn $ tagDecision (Cons.decCompatibleVars (the (List Nat) [1]) [2,3])
  putStrLn $ tagOption (Cons.areCompatibleVars (the (List Nat) [1,2]) [3])
  putStrLn $ tagDecision (Snoc.decCompatibleVars (the (SnocList Nat) [<1,2]) [<5,6])
  putStrLn $ tagOption (Snoc.areCompatibleVars (the (SnocList Nat) [<1,2]) [<5,6])
  putStrLn $ tagDecision (Snoc.decCompatibleVars (the (SnocList Nat) [<1]) [<2,3])
  putStrLn $ tagOption (Snoc.areCompatibleVars (the (SnocList Nat) [<1,2]) [<3])
```

In a disposable copy of the snoc implementation replace only the empty/empty clause of `areCompatibleVars` with `Nothing`. Recompiling produced an executable; only row six changed from `some` to `none`. Comparing complete stdout rejected the mutation (diff exit 1). Restored the original source. The fixture below separately failed `--check BadScope.idr` at `Snoc.Pre` on line 6 with exit 1, because the scope indices cannot unify.

```idris
module BadScope

import Core.Name.CompatibleVars as Snoc

cannot_align : Snoc.CompatibleVars (the (SnocList Nat) [<1]) [<2,3]
cannot_align = Snoc.Pre
```

These are host fixtures against the selected source and an earlier compiler binary. They do not constitute a fresh self-build of that source or independent ai-ci acceptance of a rename. The exact-head hosted build is identified above.

## Complete Sun assignments

### SUN IDRIC-NAMES-01 — Pin and exercise both existing contracts

Start on isomorphisms/Idric branch Idriç at b2f4c2488d0aa55cd947535eb9b61ff0e6bba963, or reconcile intervening changes by comparing the exact paths in this audit. Own the regression fixtures and runner invocation only. Read AGENTS.md, STYLE.md, _/AGENTS.md and the build workflow. Work in a separate checkout and descriptive branch. Resolve an absolute checkout and run its root edric all through the maintained Kitchen build path. Record source, compiler executable digest, material package revisions and raw exits. Use the existing Flexible Pipes handoff and ai-ci independent gate when submitting these results.

Compile separate or qualified client imports of Core.Name.CompatibleVars and Core.Name.Scoped against the actual package. Use empty scopes, equal-depth scopes with unequal names, unequal-depth scopes in both directions, and a mismatch below matched outer slots. Check both decCompatibleVars and areCompatibleVars. Exercise extendCompats with Pre and Ext inputs and multiple added slots, then pattern-match the result with invertExt; inspect shape as well as decision tags. Compile a client trying to supply Pre for unequal depths and require a type error at that expression. In a disposable copy, make the nonempty Maybe branch drop a valid match; require the unchanged positive fixture to fail at the correct row. Discard the mutant. Ensure proper diagnostics and raw nonzero child status are captured even if the compiler driver returns zero without producing an executable.

Execute the root edric test --only selectors idris2/with/with005, idris2/with/with012, ideMode/ideMode014 and idris2/basic/edric001 using the absolute entrypoint. Preserve both passing source files and the expected failing blocks in with012 (erased name inaccessible, linear name unused). Save normalized user-facing output only under an explicit path/line-ending allowance. Keep originals and exit statuses. Mark the exact baseline with independent source/host coverage. Stop if an import is accidentally satisfied only by a previously installed TTC, a mutant survives, or a baseline case fails for unrelated reasons. Fix the fixture or report the first prerequisite. Revert this fixture-only commit to roll back.

### SUN IDRIC-NAMES-02 — Give both scope relations and their transport meaningful local names

Start from the exact isomorphisms/Idric revision accepted by IDRIC-NAMES-01; its audit source was b2f4c2488d0aa55cd947535eb9b61ff0e6bba963 on Idriç. Take the scope and transport rows of this audit. Update the equations of invertExt, extendCompats, decCompatibleVars and areCompatibleVars in both named modules, plus the two uniqifyEnv.uenv branches in Core/Env.idr and compatVar in Core/TT/Var.idr. Use scope_alignment for the existing mapping, remaining_alignment for a recursive success and refute_remaining_alignment for the callable negative result. Add one short explanation beside each relation that corresponding names may differ. Keep public declarations byte-for-byte where possible. Add a short example of naming an action separately from its carried value to STYLE.md. No aliases, type or algorithm changes. If surrounding source has changed, re-trace before applying the mapping.

Build in an isolated checkout using the absolute edric all entrypoint. Rerun both decision and transport clients from 01 against fresh objects. Compare the same source inputs, raw outcomes, generated client code and erasure-sensitive results on both revisions without deleting source-level identifiers from diagnostics indiscriminately. Require both directions of the unequal-depth test, the same-name and different-name controls, and the deliberate mutant detection. Record the compiler pins, artifacts, exact diff and independent ai-ci verdict through the existing Kitchen/Flexible Pipes route. Split out anything that changes an externally visible name or an exported implicit binder. Revert the source/style commit as a unit if any unaccounted output changes. Finish with this bounded batch checked.

### SUN IDRIC-NAMES-03 — Name the optional with-equality binding through its existing route

Start from the exact isomorphisms/Idric baseline accepted by 01. This job is independent of 02 after baseline qualification. Source anchor b2f4c2488d0aa55cd947535eb9b61ff0e6bba963. Follow MkPWithProblem from Idris/Parser.idr through Idris/Desugar.idr, Idris/Elab/{Interface,Implementation}.idr, Idris/Resugar.idr, Idris/REPL.idr and the matching WithClause routes under TTImp, including TTImp/{Parser,ProcessDef,TTImp}.idr and TTImp/TTImp/{TTC,Functor,Traversals}.idr. Use the current constructor signature to identify each actual occurrence; do not rename unrelated equality terms, user-supplied names or parser keywords. Change clause-local names that carry the optional (RigCount, Name) to with_equality_binding at their producers and consumers. Include directly related local helpers in TTImp/Utils and TTImp/Elab where they forward this same field. Preserve source positions, public withRigProof accessor, constructors, exported named arguments, clause rebuilding and existing serialization. Add a short comment explaining the data at the parser-to-elaborator boundary.

Run the 01 with-clause suite on clean baseline and candidate builds, using the root edric test --only path, including source with no binding, named binding, erased binding, linear binding and nested with. Exercise the ordinary .idr caller and .idric compatibility fixture. Capture REPL output for a named binding. In TTImp/TTImp/TTC.idr ImpClause tag 2, the existing order is fc, lhs, rig, wval, optional binding, clauses; flags currently read back as []. Compare emitted field observations and re-read a baseline-generated with-clause fixture with the candidate and the reverse using the same supported TTC version. Temporarily drop the optional field in the producer and demand a failure of the named-binding case; revert the mutant. Record independent behavior, file provenance, binary/IR differences and logs. Do not revise flags or format version here. Revert the complete local-variable change if serialization, name resolution, diagnostics or behavior drift. Report unsupported cross-version combinations separately.

### SUN IDRIC-NAMES-04 — Qualify callers and finish the terminology record

Start from the exact tested commits of 02 and 03, based on the 01 baseline in isomorphisms/Idric. Historical source b2f4c2488d0aa55cd947535eb9b61ff0e6bba963. Check both parent patches for path and semantic collisions in a fresh integration checkout. Build once cleanly and run both preceding suites together. Resolve the current Flexible Pipes, Kitchen and ai-ci dependency heads; the Star observed 543b18ae60d7da1c4cef5538e50b1f44a6842691, ba2f3cb00b2c15facfa7ca535363c390002fdb2d and 07f84bd3f368efe393fcef6b740633078b2b22dc respectively. Preserve the independently accepted compiler option and artifact pins. Exercise old downstream source importing each scope module and projecting withRigProof without editing the callers. Check wire-form keys and :makelemma behavior only where the comparison actually touches those paths. Check generated output, map names/debug metadata, fresh and already-supported saved artifacts and target-neutral handoff bytes for the focused clients. If an artifact differs, isolate the exact field and demonstrate why the difference is observable or harmless. Do not normalize all names. Run the repository build, type, layout and style checks, carrying both compatibility strata and focused negative controls into the final receipt.

Update the owning documentation with the exact retained public names and why they remain, checked combinations, material revisions and any first untested boundary. Source layout and a grep total cannot qualify program behavior. Do not expand to optimizer internals, public projections, the TTC restoration algorithm, deprecated bootstrap surfaces, or backend-wide or physical qualification. Resolve a collision by isolating the responsible batch and reverting it in the integration checkout. Finish at an independently reviewed integration candidate. This assignment grants no merge, release or dispatch authority.

## Separate engineering question

The TTC reader constructs an IsVar from a decoded index using the existing private mkPrf, while the term consumer needs a position in a particular scope. Whether the surrounding format already enforces a sufficient range contract is a separate investigation. A future experiment could trace a valid small fixture's encoded index through its decoding boundary and compare the index with the available scope length before proposing a semantics or format change. This observation adds no prerequisite to the naming work.

## Delivery state

These four assignments are authored. The repository's Flexible Pipes contract distinguishes saved bytes and a display-only handoff from an admitted worker execution and trusted client acknowledgement. The design audit is complete. Independent acceptance of the proposed source edits, dispatch of children, and release are separate events.
