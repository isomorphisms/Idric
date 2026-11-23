(* Attempt a real recursive MetaRocq quotation of the source definition and
   pass the retained type/body to the Idriç candidate emitter.
   The marked region is a candidate, not a proof-preservation certificate.
   This file is intentionally not run in an environment lacking Rocq/MetaRocq. *)

From MetaRocq.Utils Require Import utils.
From MetaRocq.Template Require Import Loader TemplateMonad.

Require Import ProofTerms IdricEmitter.
Import MRMonadNotation.

MetaRocq Run (
  quoted_program <- tmQuoteRec polymorphic_identity ;;
  match render_quoted_definition 512 "quoted_identity" quoted_program with
  | IdricRejected reason =>
      tmFail ("Rocq → Idriç translation blocked: " ^ reason)
  | IdricCandidate source obligations =>
      tmMsg "IDRIC_SOURCE_BEGIN" ;;
      tmMsg source ;;
      tmMsg "IDRIC_SOURCE_END" ;;
      tmMsg "IDRIC_UNRESOLVED_OBLIGATIONS_BEGIN" ;;
      tmMsg (display_obligations obligations) ;;
      tmMsg "IDRIC_UNRESOLVED_OBLIGATIONS_END"
  end).
