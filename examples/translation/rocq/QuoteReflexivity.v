(* Source proof is quoted before erasure. Its candidate Idriç proof text is
   generated with the equality interpretation recorded as an open obligation.
   UNRUN until pinned Rocq 9.1 / MetaRocq 9.1 qualification. *)

From MetaRocq.Utils Require Import utils.
From MetaRocq.Template Require Import Loader TemplateMonad.

Require Import ProofTerms IdricEmitter.
Import MRMonadNotation.

MetaRocq Run (
  quoted_program <- tmQuoteRec reflexive_for_every_type ;;
  match render_quoted_definition 512 "quoted_reflexivity" quoted_program with
  | IdricRejected reason =>
      tmFail ("Rocq → Idriç reflexivity translation blocked: " ^ reason)
  | IdricCandidate source obligations =>
      tmMsg "IDRIC_SOURCE_BEGIN" ;;
      tmMsg source ;;
      tmMsg "IDRIC_SOURCE_END" ;;
      tmMsg "IDRIC_UNRESOLVED_OBLIGATIONS_BEGIN" ;;
      tmMsg (display_obligations obligations) ;;
      tmMsg "IDRIC_UNRESOLVED_OBLIGATIONS_END"
  end).
