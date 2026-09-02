module TTImp.BindImplicits

import Core.Context.Log
import TTImp.TTImp
import TTImp.Utils

import Control.Monad.State

import Data.List

%default covering

-- Rename the IBindVars in a term. Anything which appears in the list 'renames'
-- should be renamed, to something which is *not* in the list 'used'
export
renameIBinds : (renames : List String) ->
               (used : List String) ->
               RawImp -> State (List (String, String)) RawImp
renameIBinds rs us (Elaboratable_Dependent_Function_Type fc c p (Just un@(UN (Basic n))) ty sc)
    = if n `elem` rs
         then let n' = genUniqueStr (rs ++ us) n
                  un' = UN (Basic n')
                  sc' = substNames (map (UN . Basic) (filter (/= n) us))
                                   [(un, Elaboratable_Name fc un')] sc in
             do scr <- renameIBinds rs (n' :: us) sc'
                ty' <- renameIBinds rs us ty
                upds <- get
                put ((n, n') :: upds)
                pure $ Elaboratable_Dependent_Function_Type fc c p (Just un') ty' scr
         else do scr <- renameIBinds rs us sc
                 ty' <- renameIBinds rs us ty
                 pure $ Elaboratable_Dependent_Function_Type fc c p (Just un) ty' scr
renameIBinds rs us (Elaboratable_Dependent_Function_Type fc c p n ty sc)
    = pure $ Elaboratable_Dependent_Function_Type fc c p n !(renameIBinds rs us ty) !(renameIBinds rs us sc)
renameIBinds rs us (Elaboratable_Lambda fc c p n ty sc)
    = pure $ Elaboratable_Lambda fc c p n !(renameIBinds rs us ty) !(renameIBinds rs us sc)
renameIBinds rs us (Elaboratable_Apply fc fn arg)
    = pure $ Elaboratable_Apply fc !(renameIBinds rs us fn) !(renameIBinds rs us arg)
renameIBinds rs us (Elaboratable_Automatic_Apply fc fn arg)
    = pure $ Elaboratable_Automatic_Apply fc !(renameIBinds rs us fn) !(renameIBinds rs us arg)
renameIBinds rs us (Elaboratable_Named_Apply fc fn n arg)
    = pure $ Elaboratable_Named_Apply fc !(renameIBinds rs us fn) n !(renameIBinds rs us arg)
renameIBinds rs us (Elaboratable_With_Apply fc fn arg)
    = pure $ Elaboratable_With_Apply fc !(renameIBinds rs us fn) !(renameIBinds rs us arg)
renameIBinds rs us (Elaboratable_As_Pattern fc nameFC s n pat)
    = pure $ Elaboratable_As_Pattern fc nameFC s n !(renameIBinds rs us pat)
renameIBinds rs us (Elaboratable_Must_Unify fc r pat)
    = pure $ Elaboratable_Must_Unify fc r !(renameIBinds rs us pat)
renameIBinds rs us (Elaboratable_Delayed_Type fc r t)
    = pure $ Elaboratable_Delayed_Type fc r !(renameIBinds rs us t)
renameIBinds rs us (Elaboratable_Delay fc t)
    = pure $ Elaboratable_Delay fc !(renameIBinds rs us t)
renameIBinds rs us (Elaboratable_Force fc t)
    = pure $ Elaboratable_Force fc !(renameIBinds rs us t)
renameIBinds rs us (Elaboratable_Record_Update fc updates tm)
    = pure $ Elaboratable_Record_Update fc !(traverse f updates) !(renameIBinds rs us tm)
  where
      f : Elaboratable_Field_Update -> State (List (String, String)) Elaboratable_Field_Update
      f (Elaboratable_Set_Field path x)    = Elaboratable_Set_Field path <$> renameIBinds rs us x
      f (Elaboratable_Apply_To_Field path x) = Elaboratable_Apply_To_Field path <$> renameIBinds rs us x
renameIBinds rs us (Elaboratable_Alternative fc u alts)
    = pure $ Elaboratable_Alternative fc !(renameAlt u)
                             !(traverse (renameIBinds rs us) alts)
  where
    renameAlt : AltType -> State (List (String, String)) AltType
    renameAlt (UniqueDefault t) = pure $ UniqueDefault !(renameIBinds rs us t)
    renameAlt u = pure u
renameIBinds rs us (Elaboratable_Bind_Name fc nm@(UN (Basic n)))
    = if n `elem` rs
         then do let n' = genUniqueStr (rs ++ us) n
                 upds <- get
                 put ((n, n') :: upds)
                 pure $ Elaboratable_Bind_Name fc (UN (Basic n'))
         else pure $ Elaboratable_Bind_Name fc nm
renameIBinds rs us tm = pure $ tm

export
doBind : List (Name, Name) -> RawImp -> RawImp
doBind [] tm = tm
doBind ns (Elaboratable_Name fc nm)
    = maybe (Elaboratable_Name fc nm) (Elaboratable_Bind_Name fc) (lookup nm ns)
doBind ns (Elaboratable_Dependent_Function_Type fc rig p mn aty retty)
    = let ns' = case mn of
                     Just nm => filter (\x => fst x /= nm) ns
                     _ => ns in
          Elaboratable_Dependent_Function_Type fc rig p mn (doBind ns' aty) (doBind ns' retty)
doBind ns (Elaboratable_Lambda fc rig p mn aty sc)
    = let ns' = case mn of
                     Just nm => filter (\x => fst x /= nm) ns
                     _ => ns in
          Elaboratable_Lambda fc rig p mn (doBind ns' aty) (doBind ns' sc)
doBind ns (Elaboratable_Apply fc fn av)
    = Elaboratable_Apply fc (doBind ns fn) (doBind ns av)
doBind ns (Elaboratable_Automatic_Apply fc fn av)
    = Elaboratable_Automatic_Apply fc (doBind ns fn) (doBind ns av)
doBind ns (Elaboratable_Named_Apply fc fn n av)
    = Elaboratable_Named_Apply fc (doBind ns fn) n (doBind ns av)
doBind ns (Elaboratable_With_Apply fc fn av)
    = Elaboratable_With_Apply fc (doBind ns fn) (doBind ns av)
doBind ns (Elaboratable_As_Pattern fc nameFC s n pat)
    = Elaboratable_As_Pattern fc nameFC s n (doBind ns pat)
doBind ns (Elaboratable_Must_Unify fc r pat)
    = Elaboratable_Must_Unify fc r (doBind ns pat)
doBind ns (Elaboratable_Delayed_Type fc r ty)
    = Elaboratable_Delayed_Type fc r (doBind ns ty)
doBind ns (Elaboratable_Delay fc tm)
    = Elaboratable_Delay fc (doBind ns tm)
doBind ns (Elaboratable_Force fc tm)
    = Elaboratable_Force fc (doBind ns tm)
doBind ns (Elaboratable_Quote fc tm)
    = Elaboratable_Quote fc (doBind ns tm)
doBind ns (Elaboratable_Unquote fc tm)
    = Elaboratable_Unquote fc (doBind ns tm)
doBind ns (Elaboratable_Alternative fc u alts)
    = Elaboratable_Alternative fc (mapAltType (doBind ns) u) (map (doBind ns) alts)
doBind ns (Elaboratable_Record_Update fc updates tm)
    = Elaboratable_Record_Update fc (map (mapFieldUpdateTerm $ doBind ns) updates) (doBind ns tm)
doBind ns tm = tm

export
bindNames : {auto c : Ref Ctxt Defs} ->
            (arg : Bool) -> RawImp -> Core (List Name, RawImp)
bindNames arg tm
    = if !isUnboundImplicits
         then do ns <- excludeKnownTyOrDataCons
                         (nub (findBindableNames arg [] [] tm))
                 log "elab.bindnames" 10 $ "Found names :" ++ show ns
                 pure (map snd ns, doBind ns tm)
         else pure ([], tm)

-- if the name is part of the using decls, add the relevant binder for it:
-- either an implicit pi binding, if there's a name, or an autoimplicit type
-- binding if the name just appears as part of the type
getUsing : Name -> List (Int, Maybe Name, RawImp) ->
           List (Int, (RigCount, PiInfo RawImp, Maybe Name, RawImp))
getUsing n [] = []
getUsing n ((t, Just n', ty) :: us) -- implicit binder
    = if n == n'
         then (t, (erased, Implicit, Just n, ty)) :: getUsing n us
         else getUsing n us
getUsing n ((t, Nothing, ty) :: us) -- autoimplicit binder
    = let ns = nub (findIBindVars ty) in
          if n `elem` ns
             then (t, (top, AutoImplicit, Nothing, ty)) ::
                      getUsing n us
             else getUsing n us

getUsings : List Name -> List (Int, Maybe Name, RawImp) ->
            List (Int, (RigCount, PiInfo RawImp, Maybe Name, RawImp))
getUsings ns u = concatMap (flip getUsing u) ns

bindUsings : List (RigCount, PiInfo RawImp, Maybe Name, RawImp) -> RawImp -> RawImp
bindUsings [] tm = tm
bindUsings ((rig, p, mn, ty) :: us) tm
    = Elaboratable_Dependent_Function_Type (getFC ty) rig p mn ty (bindUsings us tm)

addUsing : List (Maybe Name, RawImp) ->
           RawImp -> RawImp
addUsing uimpls tm
    = let ns = nub (findIBindVars tm)
          bs = nubBy (\x, y => fst x == fst y)
                     (getUsings ns (tag 0 uimpls)) in
          bindUsings (map snd bs) tm
  where
    tag : Int -> List a -> List (Int, a) -- to check uniqueness of resulting uimps
    tag t xs = zip (map (+t) [0..cast (length xs)]) xs

export
bindTypeNames : {auto c : Ref Ctxt Defs} ->
                FC -> List (Maybe Name, RawImp) ->
                List Name -> RawImp-> Core RawImp
bindTypeNames fc uimpls env tm
    = if !isUnboundImplicits
             then do ns <- findUniqueBindableNames fc True env [] tm
                     let btm = doBind ns tm
                     pure (addUsing uimpls btm)
             else pure tm

export
bindTypeNamesUsed : {auto c : Ref Ctxt Defs} ->
                    FC -> List String -> List Name -> RawImp -> Core RawImp
bindTypeNamesUsed fc used env tm
    = if !isUnboundImplicits
         then do ns <- findUniqueBindableNames fc True env used tm
                 pure (doBind ns tm)
         else pure tm

export
piBindNames : {auto c : Ref Ctxt Defs} ->
              FC -> List Name -> RawImp -> Core RawImp
piBindNames loc env tm
    = do ns <- findUniqueBindableNames loc True env [] tm
         pure $ piBind (map fst ns) tm
  where
    piBind : List Name -> RawImp -> RawImp
    piBind [] ty = ty
    piBind (n :: ns) ty
       = Elaboratable_Dependent_Function_Type loc erased Implicit (Just n) (Implicit loc False)
       $ piBind ns ty
