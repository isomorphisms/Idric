module TTImp.WithClause

import Core.Context.Log
import Core.Metadata

import TTImp.BindImplicits
import TTImp.TTImp
import TTImp.Elab.Check

%default covering

matchFail : FC -> Core a
matchFail loc = throw (GenericMsg loc "With clause does not match parent")

--- To be used on the lhs of a nested with clause to figure out a tight location
--- information to give to the generated LHS
getHeadLoc : RawImp -> Core FC
getHeadLoc (Elaborable_Name fc _) = pure fc
getHeadLoc (Elaborable_Apply _ f _) = getHeadLoc f
getHeadLoc (Elaborable_With_Apply _ f _) = getHeadLoc f
getHeadLoc (Elaborable_Automatic_Apply _ f _) = getHeadLoc f
getHeadLoc (Elaborable_Named_Apply _ f _ _) = getHeadLoc f
getHeadLoc t = throw (InternalError $ "Could not find head of LHS: " ++ show t)

addAlias : {auto m : Ref MD Metadata} ->
           {auto c : Ref Ctxt Defs} ->
           FC -> FC -> Core ()
addAlias from to =
  whenJust (isConcreteFC from) $ \ from =>
    whenJust (isConcreteFC to) $ \ to => do
      log "ide-mode.highlight.alias" 25 $
        "Adding alias: " ++ show from ++ " -> " ++ show to
      addSemanticAlias from to

mutual
  export
  getMatch : {auto m : Ref MD Metadata} ->
             {auto c : Ref Ctxt Defs} ->
             (lhs : Bool) -> RawImp -> RawImp ->
             Core (List (Name, RawImp))
  getMatch lhs (Elaborable_Bind_Name to n) tm@(Elaborable_Bind_Name from _)
      = [(n, tm)] <$ addAlias from to
  getMatch lhs (Elaborable_Bind_Name _ n) tm = pure [(n, tm)]
  getMatch lhs (Implicit {}) tm = pure []
  getMatch lhs _ (Elaborable_Must_Unify _ UserDotted _) = pure []

  getMatch lhs (Elaborable_Name to (NS ns n)) (Elaborable_Name from (NS ns' n'))
      = if n == n' && isParentOf ns' ns
          then [] <$ addAlias from to -- <$ decorateName loc nm
          else matchFail from
  getMatch lhs (Elaborable_Name to (NS ns n)) (Elaborable_Name from n')
      = if n == n'
          then [] <$ addAlias from to -- <$ decorateName loc (NS ns n')
          else matchFail from
  getMatch lhs (Elaborable_Name to n) (Elaborable_Name from n')
      = if n == n'
          then [] <$ addAlias from to -- <$ decorateName loc n'
          else matchFail from
  getMatch lhs (Elaborable_Dependent_Function_Type _ c p n arg ret) (Elaborable_Dependent_Function_Type loc c' p' n' arg' ret')
      = if c == c' && eqPiInfoBy (\_, _ => True) p p' && n == n'
           then matchAll lhs [(arg, arg'), (ret, ret')]
           else matchFail loc
  -- TODO: Lam, Let, Case, Local, Update
  getMatch lhs (Elaborable_Apply _ f a) (Elaborable_Apply loc f' a')
      = matchAll lhs [(f, f'), (a, a')]
  getMatch lhs (Elaborable_Automatic_Apply _ f a) (Elaborable_Automatic_Apply loc f' a')
      = matchAll lhs [(f, f'), (a, a')]
  getMatch lhs (Elaborable_Named_Apply _ f n a) (Elaborable_Named_Apply loc f' n' a')
      = if n == n'
           then matchAll lhs [(f, f'), (a, a')]
           else matchFail loc
  getMatch lhs (Elaborable_With_Apply _ f a) (Elaborable_With_Apply loc f' a')
      = matchAll lhs [(f, f'), (a, a')]
  -- On LHS: If there's an implicit in the parent, but not the clause, add the
  -- implicit to the clause. This will propagate the implicit through to the
  -- body
  getMatch True (Elaborable_Named_Apply fc f n a) f'
      = matchAll True [(f, f'), (a, a)]
  getMatch True (Elaborable_Automatic_Apply fc f a) f'
      = matchAll True [(f, f'), (a, a)]
  -- On RHS: Rely on unification to fill in the implicit
  getMatch False (Elaborable_Named_Apply fc f n a) f'
      = getMatch False f f'
  getMatch False (Elaborable_Automatic_Apply fc f a) f'
      = getMatch False f f'
  -- Can't have an implicit in the clause if there wasn't a matching
  -- implicit in the parent
  getMatch lhs f (Elaborable_Named_Apply fc f' n a)
      = matchFail fc
  getMatch lhs f (Elaborable_Automatic_Apply fc f' a)
      = matchFail fc
  -- Alternatives are okay as long as the alternatives correspond, and
  -- one of them is okay
  getMatch lhs (Elaborable_Alternative _ _ as) (Elaborable_Alternative fc _ as')
      = matchAny fc lhs (zip as as')
  getMatch lhs (Elaborable_As_Pattern _ _ _ nm@(UN (Basic _)) p) (Elaborable_As_Pattern _ fc _ nm'@(UN (Basic _)) p')
      = do ms <- getMatch lhs p p'
           mergeMatches lhs ((nm, Elaborable_As_Pattern fc emptyFC UseLeft nm' (Implicit fc True)) :: ms)
  getMatch lhs (Elaborable_As_Pattern _ _ _ nm@(UN (Basic _)) p) p'
      = do ms <- getMatch lhs p p'
           mergeMatches lhs ((nm, p') :: ms)
  getMatch lhs (Elaborable_As_Pattern _ _ _ _ p) p' = getMatch lhs p p'
  getMatch lhs p (Elaborable_As_Pattern _ _ _ _ p') = getMatch lhs p p'
  getMatch lhs (Elaborable_Type_Universe _) (Elaborable_Type_Universe _) = pure []
  getMatch lhs (Elaborable_Primitive_Value fc c) (Elaborable_Primitive_Value fc' c') =
    if c == c'
    then pure []
    else matchFail fc'
  getMatch lhs pat spec = matchFail (getFC spec)

  matchAny : {auto m : Ref MD Metadata} ->
             {auto c : Ref Ctxt Defs} ->
             FC -> (lhs : Bool) -> List (RawImp, RawImp) ->
             Core (List (Name, RawImp))
  matchAny fc lhs [] = matchFail fc
  matchAny fc lhs ((x, y) :: ms)
      = catch (getMatch lhs x y)
              (\err => matchAny fc lhs ms)

  matchAll : {auto m : Ref MD Metadata} ->
             {auto c : Ref Ctxt Defs} ->
             (lhs : Bool) -> List (RawImp, RawImp) ->
             Core (List (Name, RawImp))
  matchAll lhs [] = pure []
  matchAll lhs ((x, y) :: ms)
      = do matches <- matchAll lhs ms
           mxy <- getMatch lhs x y
           mergeMatches lhs (mxy ++ matches)

  mergeMatches : {auto m : Ref MD Metadata} ->
                 {auto c : Ref Ctxt Defs} ->
                 (lhs : Bool) -> List (Name, RawImp) ->
                 Core (List (Name, RawImp))
  mergeMatches lhs [] = pure []
  mergeMatches lhs ((n, tm) :: rest)
      = do rest' <- mergeMatches lhs rest
           case lookup n rest' of
                Nothing => pure ((n, tm) :: rest')
                Just tm' =>
                   do ignore $ getMatch lhs tm tm'
                      -- ^ just need to know it succeeds
                      pure rest'

-- Get the arguments for the rewritten pattern clause of a with by looking
-- up how the argument names matched
getArgMatch : FC -> (side : ElabMode) -> (search : Bool) ->
              (warg : RawImp) -> (matches : List (Name, RawImp)) ->
              (arg : Maybe (PiInfo RawImp, Name)) -> RawImp
getArgMatch ploc mode search warg ms Nothing = warg
getArgMatch ploc mode True warg ms (Just (AutoImplicit, nm))
    = case lookup nm ms of
        Just tm => tm
        Nothing =>
          let arg = Elaborable_Search ploc 500 in
          if isJust (isLHS mode)
            then Elaborable_As_Pattern ploc ploc UseLeft nm arg
             else arg
getArgMatch ploc mode search warg ms (Just (_, nm))
    = case lookup nm ms of
        Just tm => tm
        Nothing =>
          let arg = Implicit ploc True in
           if isJust (isLHS mode)
             then Elaborable_As_Pattern ploc ploc UseLeft nm arg
             else arg

export
getNewLHS : {auto c : Ref Ctxt Defs} ->
            {auto m : Ref MD Metadata} ->
            FC -> (drop : Nat) -> NestedNames vars ->
            Name -> List (Maybe (PiInfo RawImp, Name)) ->
            RawImp -> RawImp -> Core RawImp
getNewLHS iploc drop nest wname wargnames lhs_raw patlhs
    = do let vploc = virtualiseFC iploc
         (mlhs_raw, wrest) <- dropWithArgs drop patlhs

         log "declare.def.clause.with" 20 $ "Parent LHS: " ++ show lhs_raw
         log "declare.def.clause.with" 20 $ "Modified LHS: " ++ show mlhs_raw

         autoimp <- isUnboundImplicits
         setUnboundImplicits True
         (_, lhs) <- bindNames False lhs_raw
         (_, mlhs) <- bindNames False mlhs_raw
         setUnboundImplicits autoimp

         log "declare.def.clause.with" 20 $ "Parent LHS (with implicits): " ++ show lhs
         log "declare.def.clause.with" 20 $ "Modified LHS (with implicits): " ++ show mlhs

         let (warg :: rest) = reverse wrest
             | _ => throw (GenericMsg iploc "Badly formed 'with' clause")
         log "declare.def.clause.with" 5 $ show lhs ++ " against " ++ show mlhs ++
                 " dropping " ++ show (warg :: rest)
         ms <- getMatch True lhs mlhs
         log "declare.def.clause.with" 5 $ "Matches: " ++ show ms
         let params = map (getArgMatch vploc (InLHS top) False warg ms) wargnames
         log "declare.def.clause.with" 5 $ "Parameters: " ++ show params

         hdloc <- getHeadLoc patlhs
         let newlhs = apply (Elaborable_Name hdloc wname) (params ++ rest)
         log "declare.def.clause.with" 5 $ "New LHS: " ++ show newlhs
         pure newlhs
  where
    dropWithArgs : Nat -> RawImp ->
                   Core (RawImp, List RawImp)
    dropWithArgs Z tm = pure (tm, [])
    dropWithArgs (S k) (Elaborable_Apply _ f arg)
        = do (tm, rest) <- dropWithArgs k f
             pure (tm, arg :: rest)
    dropWithArgs (S k) (Elaborable_With_Apply _ f arg)
        = do (tm, rest) <- dropWithArgs k f
             pure (tm, arg :: rest)
    -- Shouldn't happen if parsed correctly, but there's no guarantee that
    -- inputs come from parsed source so throw an error.
    dropWithArgs _ _ = throw (GenericMsg iploc "Badly formed 'with' clause")

-- Find a 'with' application on the RHS and update it
export
withRHS : {auto c : Ref Ctxt Defs} ->
          {auto m : Ref MD Metadata} ->
          FC -> (drop : Nat) -> Name -> List (Maybe (PiInfo RawImp, Name)) ->
          RawImp -> RawImp ->
          Core RawImp
withRHS fc drop wname wargnames tm toplhs
    = wrhs tm
  where
    withApply : FC -> RawImp -> List RawImp -> RawImp
    withApply fc f [] = f
    withApply fc f (a :: as) = withApply fc (Elaborable_With_Apply fc f a) as

    updateWith : FC -> RawImp -> List RawImp -> Core RawImp
    updateWith fc (Elaborable_With_Apply _ f a) ws = updateWith fc f (a :: ws)
    updateWith fc tm []
        = throw (GenericMsg fc "Badly formed 'with' application")
    updateWith fc tm (arg :: args)
        = do log "declare.def.clause.with" 10 $ "With-app: Matching " ++ show toplhs ++ " against " ++ show tm
             ms <- getMatch False toplhs tm
             hdloc <- getHeadLoc tm
             log "declare.def.clause.with" 10 $ "Result: " ++ show ms
             let newrhs = apply (Elaborable_Name hdloc wname)
                                (map (getArgMatch fc InExpr True arg ms) wargnames)
             log "declare.def.clause.with" 10 $ "With args for RHS: " ++ show wargnames
             log "declare.def.clause.with" 10 $ "New RHS: " ++ show newrhs
             pure (withApply fc newrhs args)

    mutual
      wrhs : RawImp -> Core RawImp
      wrhs (Elaborable_Dependent_Function_Type fc c p n ty sc)
          = pure $ Elaborable_Dependent_Function_Type fc c p n !(wrhs ty) !(wrhs sc)
      wrhs (Elaborable_Lambda fc c p n ty sc)
          = pure $ Elaborable_Lambda fc c p n !(wrhs ty) !(wrhs sc)
      wrhs (Elaborable_Binding fc lhsFC c n ty val sc)
          = pure $ Elaborable_Binding fc lhsFC c n !(wrhs ty) !(wrhs val) !(wrhs sc)
      wrhs (Elaborable_Case fc opts sc ty clauses)
          = pure $ Elaborable_Case fc opts !(wrhs sc) !(wrhs ty) !(traverse wrhsC clauses)
      wrhs (Elaborable_Local_Definitions fc decls sc)
          = pure $ Elaborable_Local_Definitions fc decls !(wrhs sc) -- TODO!
      wrhs (Elaborable_Record_Update fc upds tm)
          = pure $ Elaborable_Record_Update fc upds !(wrhs tm) -- TODO!
      wrhs (Elaborable_Apply fc f a)
          = pure $ Elaborable_Apply fc !(wrhs f) !(wrhs a)
      wrhs (Elaborable_Automatic_Apply fc f a)
          = pure $ Elaborable_Automatic_Apply fc !(wrhs f) !(wrhs a)
      wrhs (Elaborable_Named_Apply fc f n a)
          = pure $ Elaborable_Named_Apply fc !(wrhs f) n !(wrhs a)
      wrhs (Elaborable_With_Apply fc f a) = updateWith fc f [a]
      wrhs (Elaborable_Rewrite fc rule tm) = pure $ Elaborable_Rewrite fc !(wrhs rule) !(wrhs tm)
      wrhs (Elaborable_Delayed_Type fc r tm) = pure $ Elaborable_Delayed_Type fc r !(wrhs tm)
      wrhs (Elaborable_Delay fc tm) = pure $ Elaborable_Delay fc !(wrhs tm)
      wrhs (Elaborable_Force fc tm) = pure $ Elaborable_Force fc !(wrhs tm)
      wrhs tm = pure tm

      wrhsC : ImpClause -> Core ImpClause
      wrhsC (PatClause fc lhs rhs) = pure $ PatClause fc lhs !(wrhs rhs)
      wrhsC c = pure c
