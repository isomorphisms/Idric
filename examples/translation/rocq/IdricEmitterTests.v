(* Pure source-side acceptance/negative tests for the candidate emitter.
   A proof here concerns the Gallina emitter function, NOT the logical
   correspondence between Rocq and Idriç. *)

From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import Universes BasicAst.
From MetaRocq.Template Require Import Ast.
Require Import IdricEmitter.

Definition example_quoted_identity : Ast.term :=
  tLambda (mkBindAnn nAnon Relevant) (tSort Sort.type0)
    (tLambda (mkBindAnn nAnon Relevant) (tRel 0) (tRel 0)).

Example binder_names_track_de_bruijn_indices :
  match render_quoted_term 20 [] example_quoted_identity with
  | IdricCandidate text _ =>
      text = "(\bound_0 ⇒ (\bound_1 ⇒ bound_1))"
  | IdricRejected _ => False
  end.
Proof. reflexivity. Qed.

Example bound_variables_do_not_capture_outer_names :
  render_quoted_term 4 ["inner"; "outer"] (tRel 1) =
    IdricCandidate "outer" [].
Proof. reflexivity. Qed.

Example unknown_de_bruijn_index_rejects :
  match render_quoted_term 4 ["inner"] (tRel 2) with
  | IdricRejected _ => True
  | IdricCandidate _ _ => False
  end.
Proof. exact I. Qed.

Example existential_holes_reject :
  match render_quoted_term 4 [] (tEvar 1 []) with
  | IdricRejected _ => True
  | IdricCandidate _ _ => False
  end.
Proof. exact I. Qed.

Example prop_is_not_implicitly_a_type :
  match render_quoted_term 4 [] (tSort sProp) with
  | IdricRejected _ => True
  | IdricCandidate _ _ => False
  end.
Proof. exact I. Qed.

Example sprop_is_not_implicitly_a_type :
  match render_quoted_term 4 [] (tSort sSProp) with
  | IdricRejected _ => True
  | IdricCandidate _ _ => False
  end.
Proof. exact I. Qed.

Example type_carries_a_universe_obligation :
  match render_quoted_term 4 [] (tSort Sort.type0) with
  | IdricCandidate _ (_ :: _) => True
  | _ => False
  end.
Proof. exact I. Qed.

Example unresolved_global_does_not_become_axiom :
  match render_quoted_term 4 [] (tConst (MPfile ["Test"], "unknown") []) with
  | IdricRejected _ => True
  | _ => False
  end.
Proof. exact I. Qed.

(* The specific Rocq equality kernel name is part of the explicit boundary.
   These examples test candidate output, not equality-elimination semantics. *)
Definition quoted_rocq_equality : inductive :=
  mkInd (MPfile ["Logic"; "Init"; "Corelib"], "eq") 0.

Example known_rocq_equality_is_selected :
  is_rocq_equality quoted_rocq_equality = true.
Proof. reflexivity. Qed.

Example reflexivity_emits_a_candidate_with_obligations :
  match render_quoted_term 20 ["value"; "value_type"]
    (tApp (tConstruct quoted_rocq_equality 0 [])
          [tRel 1; tRel 0]) with
  | IdricCandidate source (_ :: _) => source = "Refl"
  | _ => False
  end.
Proof. reflexivity. Qed.

Example equality_type_emits_a_candidate_with_obligations :
  match render_quoted_term 20 ["value"; "value_type"]
    (tApp (tInd quoted_rocq_equality [])
          [tRel 1; tRel 0; tRel 0]) with
  | IdricCandidate source (_ :: _) => source = "(value = value)"
  | _ => False
  end.
Proof. reflexivity. Qed.
