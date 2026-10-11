(* Candidate MetaRocq 9.1 quotation driver.
   Qualification status: UNRUN. Import path, plugin API, recursive quotation,
   opaque dependencies and universe identities require real Rocq qualification.
   DO NOT describe successful command execution or complete proof transport
   without a pinned source/environment receipt and downstream checks. *)

From MetaRocq.Template Require Import Loader.
Require Import ProofTerms.

MetaRocq Quote Recursively Definition quoted_identity :=
  (polymorphic_identity).

MetaRocq Quote Recursively Definition quoted_indexed_family :=
  (indexed_list).

MetaRocq Quote Recursively Definition quoted_reflexive_for_every_type :=
  (reflexive_for_every_type).

MetaRocq Quote Recursively Definition quoted_successor_injective :=
  (successor_injective).

MetaRocq Quote Recursively Definition quoted_add_zero_right :=
  (add_zero_right).
