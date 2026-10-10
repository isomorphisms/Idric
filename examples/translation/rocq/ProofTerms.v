(* Rocq input, NOT Idris 2 or Idriç source.
   Qualification status: UNRUN. Pin Rocq before accepting results.
   Every declaration below is intended to exercise an independent part of
   proof-preserving quotation. Nothing here is an extraction pass. *)

From Corelib Require Import Init.Nat.

Polymorphic Definition polymorphic_identity (A : Type) (value : A) : A :=
  value.

Inductive indexed_list (A : Type) : nat -> Type :=
| indexed_empty : indexed_list A O
| indexed_cons :
    forall length : nat,
      A -> indexed_list A length -> indexed_list A (S length).

Arguments indexed_empty {A}.
Arguments indexed_cons {A length} _ _.

Definition indexed_one (A : Type) (value : A) : indexed_list A (S O) :=
  indexed_cons value indexed_empty.

Definition successor_injective
  (left right : nat)
  (equal_successors : S left = S right) : left = right :=
  f_equal Nat.pred equal_successors.

Fixpoint add_zero_right (value : nat) :
    Nat.add value O = value :=
  match value as current return Nat.add current O = current with
  | O => eq_refl
  | S previous => f_equal S (add_zero_right previous)
  end.
