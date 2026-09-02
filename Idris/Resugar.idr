module Idris.Resugar

import Core.Env

import Idris.Syntax
import Idris.Syntax.Traversals

import TTImp.TTImp
import TTImp.TTImp.Functor
import TTImp.Unelab
import TTImp.Utils

import Data.String
import Libraries.Data.ANameMap

%default covering

-- Convert checked terms back to source syntax. Note that this is entirely
-- for readability therefore there is NO GUARANTEE that the result will
-- type check (in fact it probably won't due to tidying up names for
-- readability).

unbracketApp : PTerm' nm -> PTerm' nm
unbracketApp (PBracketed _ tm@(PApp {})) = tm
unbracketApp tm = tm

-- TODO: Deal with precedences
mkOp : {auto s : Ref Syn SyntaxInfo} ->
       IPTerm -> Core IPTerm
mkOp tm@(PApp fc (PApp _ (PRef opFC kn) x) y)
  = do syn <- get Syn
       let raw = rawName kn
       let pop = if isOpName raw then OpSymbols else Backticked
       -- to check if the name is an operator we use the root name as a basic
       -- user name. This is because if the name is qualified with the namespace
       -- looking the fixity context will fail. A qualified operator would look
       -- like this: `M1.M2.(++)` which would not match its fixity namesapce
       -- that looks like this: `M1.M2.infixl.(++)`. However, since we only want
       -- to know if the name is an operator or not, it's enough to check
       -- that the fixity context contains the name `(++)`
       let rootName = UN (Basic (nameRoot raw))
       let asOp = POp fc (MkFCVal opFC
                $ NoBinder (unbracketApp x)) (MkFCVal opFC (pop kn)) (unbracketApp y)
       if not (null (lookupName rootName (infixes syn)))
         then pure asOp
         else case dropNS raw of
           DN str _ => pure $ ifThenElse (isOpUserName (Basic str)) asOp tm
           _ => pure tm
mkOp tm@(PApp fc (PRef opFC kn) x)
  = do syn <- get Syn
       let n = rawName kn
       let asOp = PSectionR fc (unbracketApp x) (MkFCVal opFC $ OpSymbols kn)
       if not (null $ lookupName (UN $ Basic (nameRoot n)) (infixes syn))
         then pure asOp
         else case dropNS n of
           DN str _ => pure $ ifThenElse (isOpUserName (Basic str)) asOp tm
           _ => pure tm
mkOp tm = pure tm

mkSectionL : {auto c : Ref Ctxt Defs} ->
             {auto s : Ref Syn SyntaxInfo} ->
             IPTerm -> Core IPTerm
mkSectionL tm@(PLam fc rig info (PRef _ bd) ty
                 (PApp _ (PApp _ (PRef opFC kn) (PRef _ (MkKindedName (Just Bound) nm _))) x))
  = do log "resugar.sectionL" 30 $ "SectionL candidate: \{show tm}"
       let True = bd.fullName == nm
         | _ => pure tm
       syn <- get Syn
       let n = rawName kn
       let asOp = PSectionL fc (MkFCVal opFC $ OpSymbols kn) (unbracketApp x)
       if not (null $ lookupName (UN $ Basic (nameRoot n)) (fixities syn))
         then pure asOp
         else case dropNS n of
           DN str _ => pure $ ifThenElse (isOpUserName (Basic str)) asOp tm
           _ => pure tm
mkSectionL tm = pure tm

export
addBracket : FC -> PTerm' nm -> PTerm' nm
addBracket fc tm = if needed tm then PBracketed fc tm else tm
  where
    needed : PTerm' nm -> Bool
    needed (PBracketed {}) = False
    needed (PRef {}) = False
    needed (PPair {}) = False
    needed (PDPair {}) = False
    needed (PUnit {}) = False
    needed (PComprehension {}) = False
    needed (PList {}) = False
    needed (PSnocList {}) = False
    needed (PRange {}) = False
    needed (PRangeStream {}) = False
    needed (PPrimVal {}) = False
    needed (PIdiom {}) = False
    needed (PBang {}) = False
    needed tm = True

bracket : {auto c : Ref Ctxt Defs} ->
          {auto s : Ref Syn SyntaxInfo} ->
          (outer : Nat) -> (inner : Nat) ->
          IPTerm -> Core IPTerm
bracket outer inner tm
    = do tm <- mkOp tm
         tm <- mkSectionL tm
         if outer > inner
            then pure (addBracket emptyFC tm)
            else pure tm

startPrec : Nat
startPrec = 0

tyPrec : Nat
tyPrec = 1

appPrec : Nat
appPrec = 999

argPrec : Nat
argPrec = 1000

showImplicits : {auto c : Ref Ctxt Defs} ->
                Core Bool
showImplicits = showImplicits <$> getPPrint

showFullEnv : {auto c : Ref Ctxt Defs} ->
              Core Bool
showFullEnv = showFullEnv <$> getPPrint

unbracket : PTerm' nm -> PTerm' nm
unbracket (PBracketed _ tm) = tm
unbracket tm = tm

||| Attempt to extract a constant natural number
extractNat : Nat -> IPTerm -> Maybe Nat
extractNat acc tm = case tm of
  PRef _ (MkKindedName _ (NS ns (UN (Basic n))) rn) =>
    do guard (n == "Z")
       guard (ns == typesNS || ns == preludeNS)
       pure acc
  PApp _ (PRef _ (MkKindedName _ (NS ns (UN (Basic n))) rn)) k => case n of
    "S" => do guard (ns == typesNS || ns == preludeNS)
              extractNat (1 + acc) k
    "fromInteger" => extractNat acc k
    _ => Nothing
  PPrimVal _ (BI n) => do guard (0 <= n)
                          pure (acc + integerToNat n)
  PBracketed _ k    => extractNat acc k
  _                 => Nothing

||| Attempt to extract a constant integer
extractInteger : IPTerm -> Maybe Integer
extractInteger tm = case tm of
  PApp _ (PRef _ (MkKindedName _ (NS ns (UN (Basic n))) rn)) k => case n of
    "fromInteger" => extractInteger k
    "negate"      => negate <$> extractInteger k
    _ => Nothing
  PPrimVal _ (BI i) => pure i
  PBracketed _ t    => extractInteger t
  _                 => Nothing

||| Attempt to extract a constant double
extractDouble : IPTerm -> Maybe Double
extractDouble tm = case tm of
  PApp _ (PRef _ (MkKindedName _ (NS ns (UN (Basic n))) rn)) k => case n of
    "fromDouble" => extractDouble k
    "negate"     => negate <$> extractDouble k
    _ => Nothing
  PPrimVal _ (Db d) => pure d
  PBracketed _ t    => extractDouble t
  _                 => Nothing

||| Put the special names of primitive operations (+, *, ++, etc.) back as syntax.
||| Returns `Nothing` in case there was nothing to resugar.
sugarPrimAppM : {auto c : Ref Ctxt Defs} ->
                IPTerm -> Core (Maybe IPTerm)
sugarPrimAppM (PApp fc (PApp fc' (PRef opFC (MkKindedName nt (UN $ Basic n) rn)) l) r) = do
  defs <- get Ctxt
  case definition <$> !(lookupCtxtExact rn defs.gamma) of
      Just (Builtin {arity=2} f) =>
         let nm' = (UN $ Basic $ show @{Sugared} f)
             l'  = (MkFCVal fc' $ NoBinder l)
             op' = (MkFCVal opFC (OpSymbols $ (MkKindedName nt nm' nm')))
             in  do log "resugar.var" 80
                          "Resugaring primitive op \{show n} to \{show nm'}"
                    pure . Just $ POp fc l' op' r
      _ => pure Nothing
sugarPrimAppM _ = pure Nothing

sugarPrimApp : {auto c : Ref Ctxt Defs} ->
               IPTerm -> Core IPTerm
sugarPrimApp tm = pure $ fromMaybe tm !(sugarPrimAppM tm)

mutual
  ||| Put the special names (Nil, ::, Pair, Z, S, etc) back as syntax
  ||| Returns `Nothing` in case there was nothing to resugar.
  sugarAppM : IPTerm -> Maybe IPTerm
  sugarAppM (PApp fc (PApp _ (PApp _ (PRef opFC (MkKindedName nt (NS ns nm) rn)) l) m) r) =
    case nameRoot nm of
      "rangeFromThenTo" => pure $ PRange fc (unbracket l) (Just $ unbracket m) (unbracket r)
      _ => Nothing
  sugarAppM (PApp fc (PApp _ (PRef opFC (MkKindedName nt (NS ns nm) rn)) l) r) =
    if builtinNS == ns then
      case nameRoot nm of
        "Pair"   => pure $ PPair fc (unbracket l) (unbracket r)
        "MkPair" => pure $ PPair fc (unbracket l) (unbracket r)
        "Equal"  => pure $ PEq fc (unbracket l) (unbracket r)
        "==="    => pure $ PEq fc (unbracket l) (unbracket r)
        "~=~"    => pure $ PEq fc (unbracket l) (unbracket r)
        _        => Nothing
    else if dpairNS == ns then
      case nameRoot nm of
        "DPair"  => case unbracket r of
          PLam _ _ _ n _ r' => pure $ PDPair fc opFC n (unbracket l) (unbracket r')
          _                 => Nothing
        "MkDPair" => pure $ PDPair fc opFC (unbracket l) (PImplicit opFC) (unbracket r)
        _                 => Nothing
    else
      case nameRoot nm of
        "::" => case sugarApp (unbracket r) of
          PList fc nilFC xs => pure $ PList fc nilFC ((opFC, unbracketApp l) :: xs)
          _ => Nothing
        ":<" => case sugarApp (unbracket l) of
          PSnocList fc nilFC xs => pure $ PSnocList fc nilFC
                                            (xs :< (opFC, unbracketApp r))
          _ => Nothing
        "rangeFromTo" => pure $ PRange fc (unbracket l) Nothing (unbracket r)
        "rangeFromThen" => pure $ PRangeStream fc (unbracket l) (Just $ unbracket r)
        _    => Nothing
  sugarAppM tm =
  -- refolding natural numbers if the expression is a constant
    let Nothing = extractNat 0 tm
          | Just k => pure $ PPrimVal (getPTermLoc tm) (BI (cast k))
        Nothing = extractInteger tm
          | Just k => pure $ PPrimVal (getPTermLoc tm) (BI k)
        Nothing = extractDouble tm
          | Just d => pure $ PPrimVal (getPTermLoc tm) (Db d)
    in case tm of
        PRef fc (MkKindedName nt (NS ns nm) rn) =>
          if builtinNS == ns
             then case nameRoot nm of
               "Unit"   => pure $ PUnit fc
               "MkUnit" => pure $ PUnit fc
               _           => Nothing
             else case nameRoot nm of
               "Nil" => pure $ PList fc fc []
               "Lin" => pure $ PSnocList fc fc [<]
               _     => Nothing
        PApp fc (PRef _ (MkKindedName nt (NS ns nm) rn)) arg =>
          case nameRoot nm of
            "rangeFrom" => pure $ PRangeStream fc (unbracket arg) Nothing
            _           => Nothing
        _ => Nothing

  ||| Put the special names (Nil, ::, Pair, Z, S, etc.) back as syntax
  sugarApp : IPTerm -> IPTerm
  sugarApp tm = fromMaybe tm (sugarAppM tm)

export
sugarName : Name -> String
sugarName (MN n _) = "(implicit) " ++ n
sugarName (PV n _) = sugarName n
sugarName (DN n _) = n
sugarName x = show x

toPRef : FC -> KindedName -> Core IPTerm
toPRef fc (MkKindedName nt fn nm) = case dropNS nm of
  MN n i     => pure (sugarApp (PRef fc (MkKindedName nt fn $ MN n i)))
  PV n _     => pure (sugarApp (PRef fc (MkKindedName nt fn $ n)))
  DN n _     => pure (sugarApp (PRef fc (MkKindedName nt fn $ UN $ Basic n)))
  Nested _ n => toPRef fc (MkKindedName nt fn n)
  n          => pure (sugarApp (PRef fc (MkKindedName nt fn n)))

mutual
  toPTerm : {auto c : Ref Ctxt Defs} ->
            {auto s : Ref Syn SyntaxInfo} ->
            (prec : Nat) -> Kinded_Elaborable_Term -> Core IPTerm
  toPTerm p (Elaborable_Name fc nm) = do
    t <- if fullNamespace !(getPPrint)
      then pure $ PRef fc nm
      else toPRef fc nm
    log "resugar.var" 70 $
      unwords [ "Resugaring", show @{Raw} nm.rawName, "to", show t]
    pure t
  toPTerm p (Elaborable_Dependent_Function_Type fc rig Implicit n arg ret)
      = do imp <- showImplicits
           if imp
              then do arg' <- toPTerm tyPrec arg
                      ret' <- toPTerm tyPrec ret
                      bracket p tyPrec (PPi fc rig Implicit n arg' ret')
              else if needsBind n
                      then do arg' <- toPTerm tyPrec arg
                              ret' <- toPTerm tyPrec ret
                              bracket p tyPrec (PPi fc rig Implicit n arg' ret')
                      else toPTerm p ret
    where
      needsBind : Maybe Name -> Bool
      needsBind (Just nm@(UN (Basic _)))
          = let ret = map rawName ret
                ns = findBindableNames False [] [] ret
                allNs = findAllNames [] ret in
                (nm `elem` allNs) && not (nm `elem` (map Builtin.fst ns))
      needsBind _ = False
  toPTerm p (Elaborable_Dependent_Function_Type fc rig pt n arg ret)
      = do arg' <- toPTerm appPrec arg
           ret' <- toPTerm tyPrec ret
           pt' <- traverse (toPTerm argPrec) pt
           bracket p tyPrec (PPi fc rig pt' n arg' ret')
  toPTerm p (Elaborable_Lambda fc rig pt mn arg sc)
      = do let n = case mn of
                        Nothing => UN Underscore
                        Just n' => n'
           imp <- showImplicits
           arg' <- if imp then toPTerm tyPrec arg
                          else pure (PImplicit fc)
           sc' <- toPTerm startPrec sc
           pt' <- traverse (toPTerm argPrec) pt
           let var = PRef fc (MkKindedName (Just Bound) n n)
           bracket p startPrec (PLam fc rig pt' var arg' sc')
  toPTerm p (Elaborable_Binding fc lhsFC rig n ty val sc)
      = do imp <- showImplicits
           ty' <- if imp then toPTerm startPrec ty
                         else pure (PImplicit fc)
           val' <- toPTerm startPrec val
           sc' <- toPTerm startPrec sc
           let var = PRef lhsFC (MkKindedName (Just Bound) n n)
           bracket p startPrec (PLet fc rig var ty' val' sc' [])
  toPTerm p (Elaborable_Case fc _ sc scty [PatClause _ lhs rhs])
      = do sc' <- toPTerm startPrec sc
           lhs' <- toPTerm startPrec lhs
           rhs' <- toPTerm startPrec rhs
           bracket p startPrec
                   (PLet fc top lhs' (PImplicit fc) sc' rhs' [])
  toPTerm p (Elaborable_Case fc opts sc scty alts)
      = do opts' <- traverse toPFnOpt opts
           sc' <- toPTerm startPrec sc
           alts' <- traverse toPClause alts
           bracket p startPrec (mkIf (PCase fc opts' sc' alts'))
    where
      mkIf : IPTerm -> IPTerm
      mkIf tm@(PCase loc opts sc
                 [ MkPatClause _ (PRef _ tval) t []
                 , MkPatClause _ (PRef _ fval) f []])
         = if dropNS (rawName tval) == UN (Basic "True")
           && dropNS (rawName fval) == UN (Basic "False")
              then PIfThenElse loc sc t f
              else tm
      mkIf tm = tm
  toPTerm p (Elaborable_Local_Definitions fc ds sc)
      = do ds' <- traverse toPDecl ds
           sc' <- toPTerm startPrec sc
           bracket p startPrec (PLocal fc (catMaybes ds') sc')
  toPTerm p (Elaborable_Case_Local_Definition fc _ _ _ sc) = toPTerm p sc
  toPTerm p (Elaborable_Record_Update fc ds f)
      = do ds' <- traverse toPFieldUpdate ds
           f' <- toPTerm argPrec f
           bracket p startPrec (PApp fc (PUpdate fc ds') f')
  toPTerm p (Elaborable_Apply fc fn arg)
      = do arg' <- toPTerm argPrec arg
           app <- toPTermApp fn [(fc, Nothing, arg')]
           bracket p appPrec app
  toPTerm p (Elaborable_Automatic_Apply fc fn arg)
      = do arg' <- toPTerm argPrec arg
           app <- toPTermApp fn [(fc, Just Nothing, arg')]
           bracket p appPrec app
  toPTerm p (Elaborable_With_Apply fc fn arg)
      = do arg' <- toPTerm startPrec arg
           fn' <- toPTerm startPrec fn
           bracket p appPrec (PWithApp fc fn' arg')
  toPTerm p (Elaborable_Named_Apply fc fn n arg)
      = do arg' <- toPTerm startPrec arg
           app <- toPTermApp fn [(fc, Just (Just n), arg')]
           imp <- showImplicits
           if imp
              then bracket p startPrec app
              else mkOp app
  toPTerm p (Elaborable_Search fc d) = pure (PSearch fc d)
  toPTerm p (Elaborable_Alternative fc _ _) = pure (PImplicit fc)
  toPTerm p (Elaborable_Rewrite fc rule tm)
      = pure (PRewrite fc !(toPTerm startPrec rule)
                               !(toPTerm startPrec tm))
  toPTerm p (Elaborable_Coerced fc tm) = toPTerm p tm
  toPTerm p (Elaborable_Primitive_Value fc c) = pure (PPrimVal fc c)
  toPTerm p (Elaborable_Hole fc str) = pure (PHole fc False str)
  toPTerm p (Elaborable_Type_Universe fc) = pure (PType fc)
  toPTerm p (Elaborable_Bind_Name fc nm)
    = pure (PRef fc (MkKindedName (Just Bound) nm nm))
  toPTerm p (Elaborable_Bind_Here fc _ tm) = toPTerm p tm
  toPTerm p (Elaborable_As_Pattern fc nameFC _ n pat) = pure (PAs fc nameFC n !(toPTerm argPrec pat))
  toPTerm p (Elaborable_Must_Unify fc r pat) = pure (PDotted fc !(toPTerm argPrec pat))

  toPTerm p (Elaborable_Delayed_Type fc r ty) = pure (PDelayed fc r !(toPTerm argPrec ty))
  toPTerm p (Elaborable_Delay fc tm) = pure (PDelay fc !(toPTerm argPrec tm))
  toPTerm p (Elaborable_Force fc tm) = pure (PForce fc !(toPTerm argPrec tm))
  toPTerm p (Elaborable_Quote fc tm) = pure (PQuote fc !(toPTerm argPrec tm))
  toPTerm p (Elaborable_Quote_Name fc n) = pure (PQuoteName fc n)
  toPTerm p (Elaborable_Quote_Declarations fc ds)
      = do ds' <- traverse toPDecl ds
           pure $ PQuoteDecl fc (catMaybes ds')
  toPTerm p (Elaborable_Unquote fc tm) = pure (PUnquote fc !(toPTerm argPrec tm))
  toPTerm p (Elaborable_Run_Elaborator fc _ tm) = pure (PRunElab fc !(toPTerm argPrec tm))

  toPTerm p (Elaborable_Unification_Log fc _ tm) = toPTerm p tm
  toPTerm p (Implicit fc True) = pure (PImplicit fc)
  toPTerm p (Implicit fc False) = pure (PInfer fc)

  toPTerm p (Elaborable_With_Unambiguous_Names fc ns rhs) =
    PWithUnambigNames fc ns <$> toPTerm startPrec rhs

  mkApp : {auto c : Ref Ctxt Defs} ->
          {auto s : Ref Syn SyntaxInfo} ->
          IPTerm ->
          List (FC, Maybe (Maybe Name), IPTerm) ->
          Core IPTerm
  mkApp fn [] = pure fn
  mkApp fn ((fc, Nothing, arg) :: rest)
      = do ap <- sugarPrimApp $ sugarApp (PApp fc fn arg)
           mkApp ap rest
  mkApp fn ((fc, Just Nothing, arg) :: rest)
      = do ap <- sugarPrimApp $ sugarApp (PAutoApp fc fn arg)
           mkApp ap rest
  mkApp fn ((fc, Just (Just n), arg) :: rest)
      = do imp <- showImplicits
           if imp
              then do let ap = PNamedApp fc fn n arg
                      mkApp ap rest
              else mkApp fn rest

  toPTermApp : {auto c : Ref Ctxt Defs} ->
               {auto s : Ref Syn SyntaxInfo} ->
               Kinded_Elaborable_Term -> List (FC, Maybe (Maybe Name), IPTerm) ->
               Core IPTerm
  toPTermApp (Elaborable_Apply fc f a) args
      = do a' <- toPTerm argPrec a
           toPTermApp f ((fc, Nothing, a') :: args)
  toPTermApp (Elaborable_Named_Apply fc f n a) args
      = do a' <- toPTerm startPrec a
           toPTermApp f ((fc, Just (Just n), a') :: args)
  toPTermApp fn@(Elaborable_Name fc n) args
      = do defs <- get Ctxt
           case !(lookupCtxtExact (rawName n) (gamma defs)) of
                Nothing => do fn' <- toPTerm appPrec fn
                              mkApp fn' args
                Just def => do fn' <- toPTerm appPrec fn
                               fenv <- showFullEnv
                               let args'
                                     = if fenv
                                          then args
                                          else drop (length (localVars def)) args
                               mkApp fn' args'
  toPTermApp fn args
      = do fn' <- toPTerm appPrec fn
           mkApp fn' args

  toPFieldUpdate : {auto c : Ref Ctxt Defs} ->
                   {auto s : Ref Syn SyntaxInfo} ->
                   Elaborable_Field_Update' KindedName -> Core (PFieldUpdate' KindedName)
  toPFieldUpdate (Elaborable_Set_Field p v)
      = do v' <- toPTerm startPrec v
           pure (PSetField p v')
  toPFieldUpdate (Elaborable_Apply_To_Field p v)
      = do v' <- toPTerm startPrec v
           pure (PSetFieldApp p v')

  toPClause : {auto c : Ref Ctxt Defs} ->
              {auto s : Ref Syn SyntaxInfo} ->
              ImpClause' KindedName -> Core (PClause' KindedName)
  toPClause (PatClause fc lhs rhs)
      = pure (MkPatClause fc !(toPTerm startPrec lhs)
                             !(toPTerm startPrec rhs)
                             [])
  toPClause (WithClause fc lhs rig wval prf flags cs)
      = pure $ MkWithClause fc
                 !(toPTerm startPrec lhs)
                 (MkPWithProblem rig !(toPTerm startPrec wval) prf ::: [])
                 flags
                 !(traverse toPClause cs)
  toPClause (ImpossibleClause fc lhs)
      = pure (MkImpossible fc !(toPTerm startPrec lhs))

  toPTypeDecl : {auto c : Ref Ctxt Defs} ->
                {auto s : Ref Syn SyntaxInfo} ->
                ImpTy' KindedName -> Core (PTypeDecl' KindedName)
  toPTypeDecl impTy
      = pure (MkFCVal impTy.fc $ MkPTy (pure ("", impTy.tyName)) "" !(toPTerm startPrec impTy.val))

  toPData : {auto c : Ref Ctxt Defs} ->
            {auto s : Ref Syn SyntaxInfo} ->
            ImpData' KindedName -> Core (PDataDecl' KindedName)
  toPData (MkImpData fc n ty opts cs)
      = pure (MkPData fc n !(traverseOpt (toPTerm startPrec) ty) opts
                   !(traverse toPTypeDecl cs))
  toPData (MkImpLater fc n ty)
      = pure (MkPLater fc n !(toPTerm startPrec ty))

  toPField : {auto c : Ref Ctxt Defs} ->
             {auto s : Ref Syn SyntaxInfo} ->
             Elaborable_Field' KindedName -> Core (PField' KindedName)
  toPField field
      = do bind' <- traverse (toPTerm startPrec) field.val
           pure (Mk [field.fc , "", field.rig, [field.name]] bind')

  toPFnOpt : {auto c : Ref Ctxt Defs} ->
             {auto s : Ref Syn SyntaxInfo} ->
             FnOpt' KindedName -> Core (PFnOpt' KindedName)
  toPFnOpt (ForeignFn cs)
      = do cs' <- traverse (toPTerm startPrec) cs
           pure (PForeign cs')
  toPFnOpt o = pure $ IFnOpt o

  toPDecl : {auto c : Ref Ctxt Defs} ->
            {auto s : Ref Syn SyntaxInfo} ->
            ImpDecl' KindedName -> Core (Maybe (PDecl' KindedName))
  toPDecl (Elaborable_Claim (MkWithData fc $ Make_Elaborable_Claim_Data rig vis opts ty))
      = do opts' <- traverse toPFnOpt opts
           pure (Just (MkWithData fc $ PClaim (MkPClaim rig vis opts' !(toPTypeDecl ty))))
  toPDecl (Elaborable_Data_Declaration fc vis mbtot d)
      = pure (Just (MkFCVal fc $ PData "" vis mbtot !(toPData d)))
  toPDecl (Elaborable_Definition fc n cs)
      = pure (Just (MkFCVal fc $ PDef !(traverse toPClause cs)))
  toPDecl (Elaborable_Parameter_Block fc ps ds)
      = do ds' <- traverse toPDecl ds
           args <-
             traverseList1 (\binder =>
                 do info' <- traverse (toPTerm startPrec) binder.val.info
                    type' <- toPTerm startPrec binder.val.boundType
                    pure (MkFullBinder info' binder.rig binder.name type')) ps
           pure (Just (MkFCVal fc (PParameters (Right args) (catMaybes ds'))))
  toPDecl (Elaborable_Record_Declaration fc _ vis mbtot (MkWithData _ $ MkImpRecord header body))
      = do ps' <- traverse (traverse (traverse (toPTerm startPrec))) header.val
           fs' <- traverse toPField body.val
           pure (Just (MkFCVal fc $ PRecord "" vis mbtot
                          (MkPRecord header.name.val (map toBinder ps') body.opts (Just (AddDef body.name)) fs')))
           where
             toBinder : ImpParameter' (PTerm' KindedName) -> PBinder' KindedName
             toBinder binder
               = MkFullBinder binder.val.info binder.rig binder.name binder.val.boundType

  toPDecl (Elaborable_Expected_Failure fc msg ds)
      = do ds' <- traverse toPDecl ds
           pure (Just (MkFCVal fc $ PFail msg (catMaybes ds')))
  toPDecl (Elaborable_Namespace_Block fc ns ds)
      = do ds' <- traverse toPDecl ds
           pure (Just (MkFCVal fc $ PNamespace ns (catMaybes ds')))
  toPDecl (Elaborable_Transformation fc n lhs rhs)
      = pure (Just (MkFCVal fc $ PTransform (show n)
                                  !(toPTerm startPrec lhs)
                                  !(toPTerm startPrec rhs)))
  toPDecl (Elaborable_Run_Elaborator_Declaration fc tm)
      = pure (Just (MkFCVal fc $ PRunElabDecl !(toPTerm startPrec tm)))
  toPDecl (Elaborable_Pragma {}) = pure Nothing
  toPDecl (Elaborable_Logging _) = pure Nothing
  toPDecl (Elaborable_Builtin_Declaration fc type name) = pure $ Just $ MkFCVal fc $ PBuiltin type name

export
cleanPTerm : {auto c : Ref Ctxt Defs} ->
             IPTerm -> Core IPTerm
cleanPTerm ptm
   = do pp <- getPPrint
        if showMachineNames pp then pure ptm else mapPTermM cleanNode ptm

  where

    cleanName : Name -> Core Name
    cleanName nm = case nm of
      PV n _     => pure n
      -- Some of these may be "_" so we use `mkUserName`
      MN n _     => pure (UN $ mkUserName n)
      DN n _     => pure (UN $ mkUserName n)
      -- namespaces have already been stripped in toPTerm if necessary
      NS ns n    => NS ns <$> cleanName n
      Nested _ n => cleanName n
      UN n       => pure (UN n)
      _          => UN . mkUserName <$> prettyName nm

    cleanKindedName : KindedName -> Core KindedName
    cleanKindedName (MkKindedName nt fn nm) = MkKindedName nt fn <$> cleanName nm

    cleanBinderName : PiInfo IPTerm -> Name -> Core (Maybe Name)
    cleanBinderName AutoImplicit (UN (Basic "__con")) = pure Nothing
    cleanBinderName _ nm = Just <$> cleanName nm

    cleanNode : IPTerm -> Core IPTerm
    cleanNode (PRef fc nm)    =
      PRef fc <$> cleanKindedName nm
    cleanNode (POp fc abi op y) =
      (\ op => POp fc abi op y) <$> traverse (traverseOp @{Functor.CORE} cleanKindedName) op
    cleanNode (PPrefixOp fc op x) =
      (\ op => PPrefixOp fc op x) <$> traverse (traverseOp @{Functor.CORE} cleanKindedName) op
    cleanNode (PSectionL fc op x) =
      (\ op => PSectionL fc op x) <$> traverse (traverseOp @{Functor.CORE} cleanKindedName) op
    cleanNode (PSectionR fc x op) =
      PSectionR fc x <$> traverse (traverseOp @{Functor.CORE} cleanKindedName) op
    cleanNode (PPi fc rig vis (Just n) arg ret) =
      (\ n => PPi fc rig vis n arg ret) <$> (cleanBinderName vis n)
    cleanNode tm = pure tm

toCleanPTerm : {auto c : Ref Ctxt Defs} ->
               {auto s : Ref Syn SyntaxInfo} ->
               (prec : Nat) -> Kinded_Elaborable_Term -> Core IPTerm
toCleanPTerm prec tti = do
  ptm <- toPTerm prec tti
  cleanPTerm ptm

export
resugar : {vars : _} ->
          {auto c : Ref Ctxt Defs} ->
          {auto s : Ref Syn SyntaxInfo} ->
          Env Term vars -> Term vars -> Core IPTerm
resugar env tm
    = do tti <- unelab env tm
         toCleanPTerm startPrec tti

export
resugarNoPatvars : {vars : _} ->
                   {auto c : Ref Ctxt Defs} ->
                   {auto s : Ref Syn SyntaxInfo} ->
                   Env Term vars -> Term vars -> Core IPTerm
resugarNoPatvars env tm
    = do tti <- unelabNoPatvars env tm
         toCleanPTerm startPrec tti

export
pterm : {auto c : Ref Ctxt Defs} ->
        {auto s : Ref Syn SyntaxInfo} ->
        Kinded_Elaborable_Term -> Core IPTerm
pterm raw = toCleanPTerm startPrec raw
