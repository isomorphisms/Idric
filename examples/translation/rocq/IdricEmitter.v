(* Rocq-side candidate emitter for the sole target language, Idriç.
   The quotations are checked by the Rocq kernel; an emitted candidate is NOT
   a proof of correspondence between Rocq and Idriç type theories.

   This module deliberately lives at the Rocq boundary and depends on pinned
   MetaRocq. No Haskell extraction, Idris 2 code generation, postulates, or
   erased proof input is involved. *)

From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import Kernames Universes BasicAst.
From MetaRocq.Template Require Import Ast TemplateMonad.
From Stdlib Require Import Lists.List.

Import ListNotations.

(* The obligations are deliberately part of every candidate, not an optional
   diagnostic emitted only when someone remembers to request it. *)
Inductive idric_emission : Type :=
| IdricRejected : string -> idric_emission
| IdricCandidate : string -> list string -> idric_emission.

Definition join_candidates
    (combine : string -> string -> string)
    (left right : idric_emission) : idric_emission :=
  match left with
  | IdricRejected reason => IdricRejected reason
  | IdricCandidate left_text left_obligations =>
      match right with
      | IdricRejected reason => IdricRejected reason
      | IdricCandidate right_text right_obligations =>
          IdricCandidate (combine left_text right_text)
                         (left_obligations ++ right_obligations)
      end
  end.

Definition add_obligations (extra : list string)
    (result : idric_emission) : idric_emission :=
  match result with
  | IdricRejected reason => IdricRejected reason
  | IdricCandidate text obligations =>
      IdricCandidate text (obligations ++ extra)
  end.

Definition binder_relevance_obligations (binder : aname) : list string :=
  match binder_relevance binder with
  | Relevant => []
  | Irrelevant =>
      ["Rocq binder is irrelevant; prove corresponding Idriç quantity rules"]
  end.

(* Depth-derived source identifiers avoid capture and shadowing even for
   anonymous or repeated Rocq binder names. tRel 0 denotes the most recently
   introduced binder. The names in the source never determine semantics. *)
Definition generated_binder_name (context : list string) : string :=
  "bound_" ^ string_of_nat (List.length context).

Definition is_rocq_equality (source_inductive : inductive) : bool :=
  Nat.eqb (inductive_ind source_inductive) 0 &&
  (string_of_kername (inductive_mind source_inductive)
   == "Corelib.Init.Logic.eq").

Definition equality_obligations : list string :=
  ["Rocq Corelib.Init.Logic.eq / eq_refl to Idriç (=) / Refl: " ^
   "prove the constructor, elimination and reduction correspondence"].

Definition emission_for_equality
    (left right : idric_emission) : idric_emission :=
  add_obligations equality_obligations
    (join_candidates
      (fun left_text right_text =>
        "(" ^ left_text ^ " = " ^ right_text ^ ")")
      left right).

(* This is an explicit pre-erasure syntax transformation, not a trusted
   checker. Every unhandled constructor rejects; in particular no evar or
   opaque/unknown global silently turns into an Idriç theorem. *)
Fixpoint render_quoted_term
    (fuel : nat) (context : list string) (quoted : Ast.term)
    {struct fuel} : idric_emission :=
  match fuel with
  | O => IdricRejected "Rocq term exceeds configured traversal depth"
  | S remaining =>
      match quoted with
      | tRel index =>
          match nth_error context index with
          | Some name => IdricCandidate name []
          | None => IdricRejected
                       ("Out-of-scope Rocq de Bruijn index " ^ string_of_nat index)
          end

      | tSort (sType universe) =>
          IdricCandidate "Type"
            ["Transport and validate Rocq universe sort " ^
             string_of_sort (sType universe) ^ " in the Idriç checker"]
      | tSort sProp =>
          IdricRejected
            "Rocq Prop cannot be silently identified with Idriç Type"
      | tSort sSProp =>
          IdricRejected
            "Rocq SProp needs an explicit Idriç logical/irrelevance interpretation"

      | tProd binder domain codomain =>
          let name := generated_binder_name context in
          add_obligations (binder_relevance_obligations binder)
            (join_candidates
              (fun domain_text codomain_text =>
                "(" ^ name ^ " : " ^ domain_text ^ ") → " ^ codomain_text)
              (render_quoted_term remaining context domain)
              (render_quoted_term remaining (name :: context) codomain))

      | tLambda binder domain body =>
          let name := generated_binder_name context in
          add_obligations (binder_relevance_obligations binder)
            (join_candidates
              (fun domain_text body_text =>
                "(\" ^ name ^ " ⇒ " ^ body_text ^ ")")
              (render_quoted_term remaining context domain)
              (render_quoted_term remaining (name :: context) body))

      | tLetIn binder value value_type body =>
          let name := generated_binder_name context in
          add_obligations (binder_relevance_obligations binder)
            (join_candidates
              (fun type_text value_and_body =>
                "(let " ^ name ^ " : " ^ type_text ^ " = " ^ value_and_body ^ ")")
              (render_quoted_term remaining context value_type)
              (join_candidates
                (fun value_text body_text =>
                  value_text ^ " in " ^ body_text)
                (render_quoted_term remaining context value)
                (render_quoted_term remaining (name :: context) body)))

      (* The source equality family has the explicit parameter A, whereas the
         maintained Idriç spelling is proposition-level x = y. The missing
         proof of this mapping is attached as a required obligation. *)
      | tApp (tInd source_inductive instance) [source_type; left; right] =>
          if is_rocq_equality source_inductive then
            add_obligations
              ["Rocq equality instance: " ^ print_universe_instance instance]
              (join_candidates
                (fun _ rendered_equality => rendered_equality)
                (render_quoted_term remaining context source_type)
                (emission_for_equality
                  (render_quoted_term remaining context left)
                  (render_quoted_term remaining context right)))
          else
            IdricRejected
              ("Unmapped Rocq inductive application: " ^
               string_of_inductive source_inductive)

      (* A Rocq eq_refl has explicit kernel parameters A and x; in Idriç
         Refl infers these parameters from the separately generated type.
         This never discharges the required equality-interpretation proof. *)
      | tApp (tConstruct source_inductive 0 instance)
             [source_type; value] =>
          if is_rocq_equality source_inductive then
            add_obligations
              (equality_obligations ++
                ["Rocq eq_refl instance: " ^ print_universe_instance instance])
              (join_candidates
                (fun _ _ => "Refl")
                (render_quoted_term remaining context source_type)
                (render_quoted_term remaining context value))
          else
            IdricRejected
              ("Unmapped Rocq constructor application: " ^
               string_of_inductive source_inductive)

      | tApp function arguments =>
          match arguments with
          | [] => IdricRejected "Malformed zero-argument Rocq application"
          | _ =>
              let fix render_arguments (arguments : list Ast.term)
                  {struct arguments} : idric_emission :=
                match arguments with
                | [] => IdricCandidate "" []
                | argument :: rest =>
                    join_candidates
                      (fun text tail => " (" ^ text ^ ")" ^ tail)
                      (render_quoted_term remaining context argument)
                      (render_arguments rest)
                end in
              join_candidates
                (fun function_text argument_text =>
                  "(" ^ function_text ^ argument_text ^ ")")
                (render_quoted_term remaining context function)
                (render_arguments arguments)
          end

      | tEvar _ _ =>
          IdricRejected "Unresolved Rocq existential variable (proof hole)"
      | tVar name =>
          IdricRejected ("Unbound/free Rocq variable " ^ name)
      | tCast _ _ _ =>
          IdricRejected "Rocq cast requires checked conversion interpretation"
      | tConst source_name _ =>
          IdricRejected
            ("Unmapped Rocq global constant " ^ string_of_kername source_name)
      | tInd source_inductive _ =>
          IdricRejected
            ("Unmapped Rocq inductive " ^ string_of_inductive source_inductive)
      | tConstruct source_inductive _ _ =>
          IdricRejected
            ("Unmapped Rocq constructor " ^ string_of_inductive source_inductive)
      | tCase _ _ _ _ =>
          IdricRejected "Dependent case motive/elimination not yet implemented"
      | tProj _ _ =>
          IdricRejected "Record projection with unproved semantics"
      | tFix _ _ =>
          IdricRejected "Rocq structural recursion needs Idriç totality proof"
      | tCoFix _ _ =>
          IdricRejected "Rocq cofixpoint needs Idriç productivity proof"
      | tInt _ =>
          IdricRejected "Rocq primitive integer needs width/representation mapping"
      | tFloat _ =>
          IdricRejected "Rocq primitive float needs exact numerical mapping"
      | tString _ =>
          IdricRejected "Rocq primitive string needs text/byte semantics"
      | tArray _ _ _ _ =>
          IdricRejected "Rocq array needs checked Idriç array semantics"
      end
  end.

(* The quoted program is (global environment, root term). It matters that
   we fetch a named definition's actual type and body from that environment.
   Quoting only the reference and then printing its name is NOT translation. *)
Definition render_quoted_definition
    (fuel : nat) (target_name : string) (quoted_program : Ast.Env.program)
    : idric_emission :=
  let '(environment, root_term) := quoted_program in
  match root_term with
  | tConst source_name universe_instance =>
      match lookup_env environment source_name with
      | Some (ConstantDecl constant) =>
          match cst_body constant with
          | None =>
              IdricRejected
                ("Rocq constant lacks an accessible body (axiom or opaque): " ^
                 string_of_kername source_name)
          | Some body =>
              add_obligations
                ["Rocq named declaration: " ^ string_of_kername source_name;
                 "Rocq universe instance: " ^
                   print_universe_instance universe_instance;
                 "Rocq global and local universe constraints, opacity, " ^
                   "and dependency closure require independent validation";
                 "Generated Idriç source must pass its own checker; " ^
                   "translation does not certify logical preservation"]
                (join_candidates
                  (fun type_text body_text =>
                    "module RocqBridge" ^ nl ^ nl ^
                    target_name ^ " : " ^ type_text ^ nl ^
                    target_name ^ " = " ^ body_text ^ nl)
                  (render_quoted_term fuel [] (cst_type constant))
                  (render_quoted_term fuel [] body))
          end
      | Some (InductiveDecl _) =>
          IdricRejected "Quoted reference resolves to an inductive, not a definition"
      | None =>
          IdricRejected
            ("Quoted root missing from the provided environment: " ^
             string_of_kername source_name)
      end
  | _ => IdricRejected "Expected a recursively quoted named Rocq definition"
  end.

Fixpoint display_obligations (obligations : list string) : string :=
  match obligations with
  | [] => "none"
  | [one] => one
  | one :: rest => one ^ nl ^ display_obligations rest
  end.
