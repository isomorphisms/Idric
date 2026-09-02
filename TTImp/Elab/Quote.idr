module TTImp.Elab.Quote

import Core.Env
import Core.Metadata
import Core.Reflect
import Core.UnifyState

import Idris.REPL.Opts
import Idris.Syntax

import TTImp.Elab.Check
import TTImp.Reflect
import TTImp.TTImp

%default covering

-- Collecting names and terms to let bind for unquoting
data Unq : Type where

-- Collect the escaped subterms in a term we're about to quote, and let bind
-- them first
mutual
  getUnquote : {auto c : Ref Ctxt Defs} ->
               {auto q : Ref Unq (List (Name, FC, RawImp))} ->
               {auto u : Ref UST UState} ->
               RawImp ->
               Core RawImp
  getUnquote (Elaborable_Dependent_Function_Type fc c p n arg ret)
      = pure $ Elaborable_Dependent_Function_Type fc c p n !(getUnquote arg) !(getUnquote ret)
  getUnquote (Elaborable_Lambda fc c p n arg sc)
      = pure $ Elaborable_Lambda fc c p n !(getUnquote arg) !(getUnquote sc)
  getUnquote (Elaborable_Binding fc lhsFC c n ty val sc)
      = pure $ Elaborable_Binding fc lhsFC c n !(getUnquote ty) !(getUnquote val) !(getUnquote sc)
  getUnquote (Elaborable_Case fc opts sc ty cs)
      = pure $ Elaborable_Case fc opts
                !(getUnquote sc) !(getUnquote ty)
                !(traverse getUnquoteClause cs)
  getUnquote (Elaborable_Local_Definitions fc ds sc)
      = pure $ Elaborable_Local_Definitions fc !(traverse getUnquoteDecl ds) !(getUnquote sc)
  getUnquote (Elaborable_Record_Update fc ds sc)
      = pure $ Elaborable_Record_Update fc !(traverse getUnquoteUpdate ds) !(getUnquote sc)
  getUnquote (Elaborable_Apply fc f a)
      = pure $ Elaborable_Apply fc !(getUnquote f) !(getUnquote a)
  getUnquote (Elaborable_Automatic_Apply fc f a)
      = pure $ Elaborable_Automatic_Apply fc !(getUnquote f) !(getUnquote a)
  getUnquote (Elaborable_Named_Apply fc f n a)
      = pure $ Elaborable_Named_Apply fc !(getUnquote f) n !(getUnquote a)
  getUnquote (Elaborable_With_Apply fc f a)
      = pure $ Elaborable_With_Apply fc !(getUnquote f) !(getUnquote a)
  getUnquote (Elaborable_Alternative fc at as)
      = pure $ Elaborable_Alternative fc at !(traverse getUnquote as)
  getUnquote (Elaborable_Rewrite fc f a)
      = pure $ Elaborable_Rewrite fc !(getUnquote f) !(getUnquote a)
  getUnquote (Elaborable_Coerced fc t)
      = pure $ Elaborable_Coerced fc !(getUnquote t)
  getUnquote (Elaborable_Bind_Here fc m t)
      = pure $ Elaborable_Bind_Here fc m !(getUnquote t)
  getUnquote (Elaborable_As_Pattern fc nameFC u nm t)
      = pure $ Elaborable_As_Pattern fc nameFC u nm !(getUnquote t)
  getUnquote (Elaborable_Must_Unify fc r t)
      = pure $ Elaborable_Must_Unify fc r !(getUnquote t)
  getUnquote (Elaborable_Delayed_Type fc r t)
      = pure $ Elaborable_Delayed_Type fc r !(getUnquote t)
  getUnquote (Elaborable_Delay fc t)
      = pure $ Elaborable_Delay fc !(getUnquote t)
  getUnquote (Elaborable_Force fc t)
      = pure $ Elaborable_Force fc !(getUnquote t)
  getUnquote (Elaborable_Quote fc t)
      = pure $ Elaborable_Quote fc !(getUnquote t)
  getUnquote (Elaborable_Unquote fc tm)
      = do qv <- genVarName "q"
           update Unq ((qv, fc, tm) ::)
           pure (Elaborable_Unquote fc (Elaborable_Name fc qv)) -- turned into just qv when reflecting
  getUnquote tm = pure tm

  getUnquoteClause : {auto c : Ref Ctxt Defs} ->
                     {auto q : Ref Unq (List (Name, FC, RawImp))} ->
                     {auto u : Ref UST UState} ->
                     ImpClause ->
                     Core ImpClause
  getUnquoteClause (PatClause fc l r)
      = pure $ PatClause fc !(getUnquote l) !(getUnquote r)
  getUnquoteClause (WithClause fc l rig w prf flags cs)
      = pure $ WithClause
                 fc
                 !(getUnquote l)
                 rig
                 !(getUnquote w)
                 prf
                 flags
                 !(traverse getUnquoteClause cs)
  getUnquoteClause (ImpossibleClause fc l)
      = pure $ ImpossibleClause fc !(getUnquote l)

  getUnquoteUpdate : {auto c : Ref Ctxt Defs} ->
                     {auto q : Ref Unq (List (Name, FC, RawImp))} ->
                     {auto u : Ref UST UState} ->
                     Elaborable_Field_Update ->
                     Core Elaborable_Field_Update
  getUnquoteUpdate (Elaborable_Set_Field p t) = pure $ Elaborable_Set_Field p !(getUnquote t)
  getUnquoteUpdate (Elaborable_Apply_To_Field p t) = pure $ Elaborable_Apply_To_Field p !(getUnquote t)

  getUnquoteRecord : {auto c : Ref Ctxt Defs} ->
                     {auto q : Ref Unq (List (Name, FC, RawImp))} ->
                     {auto u : Ref UST UState} ->
                     ImpRecordData Name ->
                     Core (ImpRecordData Name)
  getUnquoteRecord (MkImpRecord header body)
        -- unlike before, we are also unquoting the default value, maybe this is important?
      = pure $ MkImpRecord !(traverse (traverse (traverse (traverse getUnquote))) header)
                           !(traverse (traverse (traverse (traverse getUnquote))) body)

  getUnquoteData : {auto c : Ref Ctxt Defs} ->
                   {auto q : Ref Unq (List (Name, FC, RawImp))} ->
                   {auto u : Ref UST UState} ->
                   ImpData ->
                   Core ImpData
  getUnquoteData (MkImpData fc n tc opts cs)
      = pure $ MkImpData fc n !(traverseOpt getUnquote tc) opts
                         !(traverse (traverse getUnquote) cs)
  getUnquoteData (MkImpLater fc n tc)
      = pure $ MkImpLater fc n !(getUnquote tc)

  getUnquoteDecl : {auto c : Ref Ctxt Defs} ->
                   {auto q : Ref Unq (List (Name, FC, RawImp))} ->
                   {auto u : Ref UST UState} ->
                   ImpDecl ->
                   Core ImpDecl
  getUnquoteDecl (Elaborable_Claim (MkWithData fc (Make_Elaborable_Claim_Data c v opts ty)))
      = pure $ Elaborable_Claim (MkWithData fc (Make_Elaborable_Claim_Data c v opts !(traverse getUnquote ty)))
  getUnquoteDecl (Elaborable_Data_Declaration fc v mbt d)
      = pure $ Elaborable_Data_Declaration fc v mbt !(getUnquoteData d)
  getUnquoteDecl (Elaborable_Definition fc v d)
      = pure $ Elaborable_Definition fc v !(traverse getUnquoteClause d)
  getUnquoteDecl (Elaborable_Parameter_Block fc ps ds)
      = pure $ Elaborable_Parameter_Block fc -- We also unquote default arguments here too
                           !(traverseList1 (traverse (traverse getUnquote)) ps)
                           !(traverse getUnquoteDecl ds)
  getUnquoteDecl (Elaborable_Record_Declaration fc ns v mbt d)
      = pure $ Elaborable_Record_Declaration fc ns v mbt !(traverse getUnquoteRecord d)
  getUnquoteDecl (Elaborable_Namespace_Block fc ns ds)
      = pure $ Elaborable_Namespace_Block fc ns !(traverse getUnquoteDecl ds)
  getUnquoteDecl (Elaborable_Transformation fc n l r)
      = pure $ Elaborable_Transformation fc n !(getUnquote l) !(getUnquote r)
  getUnquoteDecl d = pure d

bindUnqs : {vars : _} ->
           {auto c : Ref Ctxt Defs} ->
           {auto m : Ref MD Metadata} ->
           {auto u : Ref UST UState} ->
           {auto e : Ref EST (EState vars)} ->
           {auto s : Ref Syn SyntaxInfo} ->
           {auto o : Ref ROpts REPLOpts} ->
           List (Name, FC, RawImp) ->
           RigCount -> ElabInfo -> NestedNames vars -> Env Term vars ->
           Term vars ->
           Core (Term vars)
bindUnqs [] _ _ _ _ tm = pure tm
bindUnqs ((qvar, fc, esctm) :: qs) rig elabinfo nest env tm
    = do defs <- get Ctxt
         Just (idx, gdef) <- lookupCtxtExactI (reflectionttimp "TTImp") (gamma defs)
              | _ => throw (UndefinedName fc (reflectionttimp "TTImp"))
         (escv, escty) <- check rig elabinfo nest env esctm
                                (Just (gnf env (Ref fc (TyCon 0)
                                           (Resolved idx))))
         sc <- bindUnqs qs rig elabinfo nest env tm
         pure (Bind fc qvar (Let fc (rigMult top rig) escv !(getTerm escty))
                    (refToLocal qvar qvar sc))

onLHS : ElabMode -> Bool
onLHS (InLHS _) = True
onLHS _ = False

export
checkQuote : {vars : _} ->
             {auto c : Ref Ctxt Defs} ->
             {auto m : Ref MD Metadata} ->
             {auto u : Ref UST UState} ->
             {auto e : Ref EST (EState vars)} ->
             {auto s : Ref Syn SyntaxInfo} ->
             {auto o : Ref ROpts REPLOpts} ->
             RigCount -> ElabInfo ->
             NestedNames vars -> Env Term vars ->
             FC -> RawImp -> Maybe (Glued vars) ->
             Core (Term vars, Glued vars)
checkQuote rig elabinfo nest env fc tm exp
    = do defs <- get Ctxt
         q <- newRef Unq []
         tm' <- getUnquote tm
         qtm <- reflect fc defs (onLHS (elabMode elabinfo)) env tm'
         unqs <- get Unq
         qty <- getCon fc defs (reflectionttimp "TTImp")
         qtm <- bindUnqs unqs rig elabinfo nest env qtm
         fullqtm <- normalise defs env qtm
         checkExp rig elabinfo env fc fullqtm (gnf env qty) exp

export
checkQuoteName : {vars : _} ->
                 {auto c : Ref Ctxt Defs} ->
                 {auto u : Ref UST UState} ->
                 RigCount -> ElabInfo ->
                 NestedNames vars -> Env Term vars ->
                 FC -> Name -> Maybe (Glued vars) ->
                 Core (Term vars, Glued vars)
checkQuoteName rig elabinfo nest env fc n exp
    = do defs <- get Ctxt
         qnm <- reflect fc defs (onLHS (elabMode elabinfo)) env n
         qty <- getCon fc defs (reflectiontt "Name")
         checkExp rig elabinfo env fc qnm (gnf env qty) exp

export
checkQuoteDecl : {vars : _} ->
                 {auto c : Ref Ctxt Defs} ->
                 {auto m : Ref MD Metadata} ->
                 {auto u : Ref UST UState} ->
                 {auto e : Ref EST (EState vars)} ->
                 {auto s : Ref Syn SyntaxInfo} ->
                 {auto o : Ref ROpts REPLOpts} ->
                 RigCount -> ElabInfo ->
                 NestedNames vars -> Env Term vars ->
                 FC -> List ImpDecl -> Maybe (Glued vars) ->
                 Core (Term vars, Glued vars)
checkQuoteDecl rig elabinfo nest env fc ds exp
    = do defs <- get Ctxt
         q <- newRef Unq []
         ds' <- traverse getUnquoteDecl ds
         qds <- reflect fc defs (onLHS (elabMode elabinfo)) env ds'
         unqs <- get Unq
         qd <- getCon fc defs (reflectionttimp "Decl")
         qty <- appCon fc defs (basics "List") [qd]
         checkExp rig elabinfo env fc
                  !(bindUnqs unqs rig elabinfo nest env qds)
                  (gnf env qty) exp
