# Summary — Coecke and Pavlović

## The main conceptual shift

The papers replace some coordinate/basis-specific descriptions by algebraic operations with equations. Instead of saying “choose this basis, write a matrix, and use the basis labels,” they ask what operations distinguish the structure operationally.

For classical data inside the categorical quantum setting, the distinguishing operations are copying and deleting. Those operations are not available naturally for arbitrary quantum states, but they are available on the states singled out by a classical structure.

That is a compiler-relevant pattern:

```text
operation used
-> generate structure constraint
-> solve structure constraint
-> expose associated laws
-> permit typed rewrites
```

## 1. Tensor/composition first

“Quantum measurements without sums” deliberately asks how much can be done with monoidal composition and tensor alone, rather than taking direct sums as primitive infrastructure. In the graphical language, sequential composition is plugging outputs into inputs and tensor product is placing processes side by side.

This is very close to the semantic distinction needed for Einstein syntax:

- juxtaposition / tensor product creates a larger interface;
- connection / contraction consumes a matching pair of ports;
- untouched ports remain in the result interface.

No machine loop is implied by any of these operations.

## 2. Copying and deleting are structure, not generic operations

A classical object carries a comultiplication (copying) and counit (deleting), subject to compatibility laws. In finite-dimensional Hilbert spaces, a suitable structure picks out a basis. The no-cloning phenomenon is exactly why this cannot be treated as an operation available uniformly on every state.

For a programming language, this is a useful anti-handwaving rule: `copy` should not become a universal algebraic rewrite merely because the runtime can duplicate bytes. Mathematical copying and memory copying are different operations with different laws.

## 3. Frobenius laws make local graphical rewriting possible

Frobenius compatibility relates multiplication/comultiplication in a way that admits compact diagrammatic equations. When the additional commutativity, dagger, and specialness conditions hold, connected networks of the same structure can often be simplified aggressively.

The relevant compiler architecture is therefore not “hard-code spider fusion.” It is closer to:

```text
?S : structure on A
require CommutativeDaggerFrobenius ?S
...
solver resolves ?S
...
rewrite engine may now use the laws attached to ?S
```

The explanation trace should name the structure and law.

## 4. Orthogonal bases become intrinsic

“A new description of orthogonal bases” shows that an orthogonal basis of a finite-dimensional Hilbert space can be characterized by a commutative dagger-Frobenius monoid, while orthonormality corresponds to the special case. The basis vectors are precisely the elements that the comultiplication copies.

This matters because it replaces external enumeration by an internal universal property/behavior. The programmer need not necessarily carry explicit integer labels for basis elements when the operations already determine the relevant structure.

That is analogous to the goal in Idriç #42: infer mathematical context from operations and laws rather than requiring the programmer to restate a name for a structure the computer can derive.

## 5. Classical interfaces are typed boundaries

The copy/delete structure also marks a boundary between quantum and classical information. A process that respects copying and deleting is not merely any process with the right dimension; it preserves the classical structure.

This suggests richer constraints than shape equality:

```text
same carrier dimension                insufficient
same underlying object                still insufficient for some rewrites
same resolved algebraic structure     enough for structure-specific law
```

So an Einstein edge should carry at least the object/index-space type, while higher rewrites may require additional resolved structure on that object.

## 6. Relation to the HM analogy

Hindley–Milner itself does not infer Frobenius algebras. The useful analogy is architectural:

1. introduce unknowns;
2. generate constraints from use;
3. solve the constraints;
4. propagate the consequences;
5. keep the reasoning inspectable.

Here, the unknown might be a basis/classical structure rather than a simple type variable. The consequence of solving it might be a family of legal diagram equations rather than merely a substituted type.

## Takeaway for Idriç

Treat algebraic laws as capabilities attached to resolved mathematical structures. The graphical representation can make those laws easy to apply, but the type/structure solver must establish that they are available. This gives us aggressive mathematical simplification without turning the compiler into an unprincipled bag of diagram tricks.
