module TTImp.Reflect

import Core.Context
import Core.Env
import Core.Normalise
import Core.Reflect
import Core.Value

import TTImp.TTImp
import Libraries.Data.WithDefault

%default covering

export
Reify BindMode where
  reify defs val@(NDCon _ n _ _ args)
      = case (dropAllNS !(full (gamma defs) n), args) of
             (UN (Basic "PI"), [(_, c)])
                 => do c' <- reify defs !(evalClosure defs c)
                       pure (PI c')
             (UN (Basic "PATTERN"), _) => pure PATTERN
             (UN (Basic "COVERAGE"), _) => pure COVERAGE
             (UN (Basic "NONE"), _) => pure NONE
             _ => cantReify val "BindMode"
  reify deva val = cantReify val "BindMode"

export
Reflect BindMode where
  reflect fc defs lhs env (PI c)
      = do c' <- reflect fc defs lhs env c
           appCon fc defs (reflectionttimp "PI") [c']
  reflect fc defs lhs env PATTERN
      = getCon fc defs (reflectionttimp "PATTERN")
  reflect fc defs lhs env COVERAGE
      = getCon fc defs (reflectionttimp "COVERAGE")
  reflect fc defs lhs env NONE
      = getCon fc defs (reflectionttimp "NONE")

export
Reify UseSide where
  reify defs val@(NDCon _ n _ _ args)
      = case (dropAllNS !(full (gamma defs) n), args) of
             (UN (Basic "UseLeft"), _) => pure UseLeft
             (UN (Basic "UseRight"), _) => pure UseRight
             _ => cantReify val "UseSide"
  reify defs val = cantReify val "UseSide"

export
Reflect UseSide where
  reflect fc defs lhs env UseLeft
      = getCon fc defs (reflectionttimp "UseLeft")
  reflect fc defs lhs env UseRight
      = getCon fc defs (reflectionttimp "UseRight")

export
Reify DotReason where
  reify defs val@(NDCon _ n _ _ args)
      = case (dropAllNS !(full (gamma defs) n), args) of
             (UN (Basic "NonLinearVar"), _) => pure NonLinearVar
             (UN (Basic "VarApplied"), _) => pure VarApplied
             (UN (Basic "NotConstructor"), _) => pure NotConstructor
             (UN (Basic "ErasedArg"), _) => pure ErasedArg
             (UN (Basic "UserDotted"), _) => pure UserDotted
             (UN (Basic "UnknownDot"), _) => pure UnknownDot
             (UN (Basic "UnderAppliedCon"), _) => pure UnderAppliedCon
             _ => cantReify val "DotReason"
  reify defs val = cantReify val "DotReason"

export
Reflect DotReason where
  reflect fc defs lhs env NonLinearVar
      = getCon fc defs (reflectionttimp "NonLinearVar")
  reflect fc defs lhs env VarApplied
      = getCon fc defs (reflectionttimp "VarApplied")
  reflect fc defs lhs env NotConstructor
      = getCon fc defs (reflectionttimp "NotConstructor")
  reflect fc defs lhs env ErasedArg
      = getCon fc defs (reflectionttimp "ErasedArg")
  reflect fc defs lhs env UserDotted
      = getCon fc defs (reflectionttimp "UserDotted")
  reflect fc defs lhs env UnknownDot
      = getCon fc defs (reflectionttimp "UnknownDot")
  reflect fc defs lhs env UnderAppliedCon
      = getCon fc defs (reflectionttimp "UnderAppliedCon")


mutual
  export
  Reify RawImp where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "IVar"), [fc, n])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          n' <- reify defs !(evalClosure defs n)
                          pure (Elaboratable_Name fc' n')
               (UN (Basic "IPi"), [fc, c, p, mn, aty, rty])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          c' <- reify defs !(evalClosure defs c)
                          p' <- reify defs !(evalClosure defs p)
                          mn' <- reify defs !(evalClosure defs mn)
                          aty' <- reify defs !(evalClosure defs aty)
                          rty' <- reify defs !(evalClosure defs rty)
                          pure (Elaboratable_Dependent_Function_Type fc' c' p' mn' aty' rty')
               (UN (Basic "ILam"), [fc, c, p, mn, aty, lty])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          c' <- reify defs !(evalClosure defs c)
                          p' <- reify defs !(evalClosure defs p)
                          mn' <- reify defs !(evalClosure defs mn)
                          aty' <- reify defs !(evalClosure defs aty)
                          lty' <- reify defs !(evalClosure defs lty)
                          pure (Elaboratable_Lambda fc' c' p' mn' aty' lty')
               (UN (Basic "ILet"), [fc, lhsFC, c, n, ty, val, sc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          lhsFC' <- reify defs !(evalClosure defs lhsFC)
                          c' <- reify defs !(evalClosure defs c)
                          n' <- reify defs !(evalClosure defs n)
                          ty' <- reify defs !(evalClosure defs ty)
                          val' <- reify defs !(evalClosure defs val)
                          sc' <- reify defs !(evalClosure defs sc)
                          pure (Elaboratable_Binding fc' lhsFC' c' n' ty' val' sc')
               (UN (Basic "ICase"), [fc, opts, sc, ty, cs])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          opts' <- reify defs !(evalClosure defs opts)
                          sc' <- reify defs !(evalClosure defs sc)
                          ty' <- reify defs !(evalClosure defs ty)
                          cs' <- reify defs !(evalClosure defs cs)
                          pure (Elaboratable_Case fc' opts' sc' ty' cs')
               (UN (Basic "ILocal"), [fc, ds, sc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          ds' <- reify defs !(evalClosure defs ds)
                          sc' <- reify defs !(evalClosure defs sc)
                          pure (Elaboratable_Local_Definitions fc' ds' sc')
               (UN (Basic "IUpdate"), [fc, ds, sc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          ds' <- reify defs !(evalClosure defs ds)
                          sc' <- reify defs !(evalClosure defs sc)
                          pure (Elaboratable_Record_Update fc' ds' sc')
               (UN (Basic "IApp"), [fc, f, a])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          f' <- reify defs !(evalClosure defs f)
                          a' <- reify defs !(evalClosure defs a)
                          pure (Elaboratable_Apply fc' f' a')
               (UN (Basic "INamedApp"), [fc, f, m, a])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          f' <- reify defs !(evalClosure defs f)
                          m' <- reify defs !(evalClosure defs m)
                          a' <- reify defs !(evalClosure defs a)
                          pure (Elaboratable_Named_Apply fc' f' m' a')
               (UN (Basic "IAutoApp"), [fc, f, a])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          f' <- reify defs !(evalClosure defs f)
                          a' <- reify defs !(evalClosure defs a)
                          pure (Elaboratable_Automatic_Apply fc' f' a')
               (UN (Basic "IWithApp"), [fc, f, a])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          f' <- reify defs !(evalClosure defs f)
                          a' <- reify defs !(evalClosure defs a)
                          pure (Elaboratable_With_Apply fc' f' a')
               (UN (Basic "ISearch"), [fc, d])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          d' <- reify defs !(evalClosure defs d)
                          pure (Elaboratable_Search fc' d')
               (UN (Basic "IAlternative"), [fc, t, as])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          as' <- reify defs !(evalClosure defs as)
                          pure (Elaboratable_Alternative fc' t' as')
               (UN (Basic "IRewrite"), [fc, t, sc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          sc' <- reify defs !(evalClosure defs sc)
                          pure (Elaboratable_Rewrite fc' t' sc')
               (UN (Basic "IBindHere"), [fc, t, sc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          sc' <- reify defs !(evalClosure defs sc)
                          pure (Elaboratable_Bind_Here fc' t' sc')
               (UN (Basic "IBindVar"), [fc, n])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          n' <- reify defs !(evalClosure defs n)
                          pure (Elaboratable_Bind_Name fc' n')
               (UN (Basic "IAs"), [fc, nameFC, s, n, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          nameFC' <- reify defs !(evalClosure defs nameFC)
                          s' <- reify defs !(evalClosure defs s)
                          n' <- reify defs !(evalClosure defs n)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_As_Pattern fc' nameFC' s' n' t')
               (UN (Basic "IMustUnify"), [fc, r, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          r' <- reify defs !(evalClosure defs r)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Must_Unify fc' r' t')
               (UN (Basic "IDelayed"), [fc, r, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          r' <- reify defs !(evalClosure defs r)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Delayed_Type fc' r' t')
               (UN (Basic "IDelay"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Delay fc' t')
               (UN (Basic "IForce"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Force fc' t')
               (UN (Basic "IQuote"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Quote fc' t')
               (UN (Basic "IQuoteName"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Quote_Name fc' t')
               (UN (Basic "IQuoteDecl"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Quote_Declarations fc' t')
               (UN (Basic "IUnquote"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Unquote fc' t')
               (UN (Basic "IPrimVal"), [fc, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_Primitive_Value fc' t')
               (UN (Basic "IType"), [fc])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          pure (Elaboratable_Type_Universe fc')
               (UN (Basic "IHole"), [fc, n])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          n' <- reify defs !(evalClosure defs n)
                          pure (Elaboratable_Hole fc' n')
               (UN (Basic "Implicit"), [fc, n])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          n' <- reify defs !(evalClosure defs n)
                          pure (Implicit fc' n')
               (UN (Basic "IWithUnambigNames"), [fc, ns, t])
                    => do fc' <- reify defs !(evalClosure defs fc)
                          ns' <- reify defs !(evalClosure defs ns)
                          t' <- reify defs !(evalClosure defs t)
                          pure (Elaboratable_With_Unambiguous_Names fc' ns' t')
               _ => cantReify val "TTImp"
    reify defs val = cantReify val "TTImp"

  export
  Reify Elaboratable_Field_Update where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), args) of
               (UN (Basic "ISetField"), [(_, x), (_, y)])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          pure (Elaboratable_Set_Field x' y')
               (UN (Basic "ISetFieldApp"), [(_, x), (_, y)])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          pure (Elaboratable_Apply_To_Field x' y')
               _ => cantReify val "IFieldUpdate"
    reify defs val = cantReify val "IFieldUpdate"

  export
  Reify AltType where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), args) of
               (UN (Basic "FirstSuccess"), _)
                    => pure FirstSuccess
               (UN (Basic "Unique"), _)
                    => pure Unique
               (UN (Basic "UniqueDefault"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (UniqueDefault x')
               _ => cantReify val "AltType"
    reify defs val = cantReify val "AltType"

  export
  Reify FnOpt where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), args) of
               (UN (Basic "Inline"), _) => pure Inline
               (UN (Basic "Unsafe"), _) => pure Unsafe
               (UN (Basic "NoInline"), _) => pure NoInline
               (UN (Basic "Deprecate"), _) => pure Deprecate
               (UN (Basic "TCInline"), _) => pure TCInline
               (UN (Basic "Hint"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (Hint x')
               (UN (Basic "GlobalHint"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (GlobalHint x')
               (UN (Basic "ExternFn"), _) => pure ExternFn
               (UN (Basic "ForeignFn"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (ForeignFn x')
               (UN (Basic "ForeignExport"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (ForeignExport x')
               (UN (Basic "Invertible"), _) => pure Invertible
               (UN (Basic "Totality"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (Totality x')
               (UN (Basic "Macro"), _) => pure Macro
               (UN (Basic "SpecArgs"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (SpecArgs x')
               _ => cantReify val "FnOpt"
    reify defs val = cantReify val "FnOpt"

  export
  Reify ImpTy where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "MkTy"), [w, y, z])
                    => do fc' <- reify defs !(evalClosure defs w)
                          name' <- the (Core (WithFC Name)) (reify defs !(evalClosure defs y))
                          term' <- reify defs !(evalClosure defs z)
                          pure (Mk [fc', name'] term')
               _ => cantReify val "ITy"
    reify defs val = cantReify val "ITy"

  export
  Reify DataOpt where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), args) of
               (UN (Basic "SearchBy"), [(_, x)])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (SearchBy x')
               (UN (Basic "NoHints"), _) => pure NoHints
               (UN (Basic "UniqueSearch"), _) => pure UniqueSearch
               (UN (Basic "External"), _) => pure External
               (UN (Basic "NoNewtype"), _) => pure NoNewtype
               _ => cantReify val "DataOpt"
    reify defs val = cantReify val "DataOpt"

  export
  Reify ImpData where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "MkData"), [v,w,x,y,z])
                    => do v' <- reify defs !(evalClosure defs v)
                          w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (MkImpData v' w' x' y' z')
               (UN (Basic "MkLater"), [x,y,z])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (MkImpLater x' y' z')
               _ => cantReify val "Data"
    reify defs val = cantReify val "Data"

  export
  Reify Elaboratable_Field where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "MkIField"), [v,w,x,y,z])
                    => do fc <- reify defs !(evalClosure defs v)
                          rig <- reify defs !(evalClosure defs w)
                          info <- reify defs !(evalClosure defs x)
                          name <- reify defs !(evalClosure defs y)
                          type <- reify defs !(evalClosure defs z)
                          pure (Mk [fc, rig, NoFC name] (MkPiBindData info type))
               _ => cantReify val "IField"
    reify defs val = cantReify val "IField"

  export
  Reify ImpRecord where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "MkRecord"), [v,w,x,y,z,a])
                    => do fc <- reify defs !(evalClosure defs v)
                          tyName <- reify defs !(evalClosure defs w)
                          params <- reify defs !(evalClosure defs x)
                          opts <- reify defs !(evalClosure defs y)
                          conName <- reify defs !(evalClosure defs z)
                          fields <- reify defs !(evalClosure defs a)
                          pure (Mk [fc] $ MkImpRecord (Mk [NoFC tyName] (map fromOldParams params))
                                                      (Mk [NoFC conName, opts] fields))
               _ => cantReify val "Record"
    reify defs val = cantReify val "Record"

  export
  Reify WithFlag where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "Syntactic"), [])
                    => pure Syntactic
               _ => cantReify val "WithFlag"
    reify defs val = cantReify val "WithFlag"

  export
  Reify ImpClause where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "PatClause"), [x,y,z])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (PatClause x' y' z')
               (UN (Basic "WithClause"), [u,v,w,x,y,z,a])
                    => do u' <- reify defs !(evalClosure defs u)
                          v' <- reify defs !(evalClosure defs v)
                          w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          a' <- reify defs !(evalClosure defs a)
                          pure (WithClause u' v' w' x' y' z' a')
               (UN (Basic "ImpossibleClause"), [x,y])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          pure (ImpossibleClause x' y')
               _ => cantReify val "Clause"
    reify defs val = cantReify val "Clause"

  export
  Reify (Elaboratable_Claim_Data Name) where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "MkIClaimData"), [w, x, y, z])
                    => do w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (Make_Elaboratable_Claim_Data w' x' y' z')
               _ => cantReify val "IClaimData"
    reify defs val = cantReify val "IClaimData"

  export
  Reify ImpDecl where
    reify defs val@(NDCon _ n _ _ args)
        = case (dropAllNS !(full (gamma defs) n), map snd args) of
               (UN (Basic "IClaim"), [v])
                    => do v' <- reify defs !(evalClosure defs v)
                          pure (Elaboratable_Claim v')
               (UN (Basic "IData"), [x,y,z,w])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          w' <- reify defs !(evalClosure defs w)
                          pure (Elaboratable_Data_Declaration x' y' z' w')
               (UN (Basic "IDef"), [x,y,z])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (Elaboratable_Definition x' y' z')
               (UN (Basic "IParameters"), [x,y,z])
                    => do x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (Elaboratable_Parameter_Block x' (map fromOldParams y') z')
               (UN (Basic "IRecord"), [w,x,y,z,u])
                    => do w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          u' <- reify defs !(evalClosure defs u)
                          pure (Elaboratable_Record_Declaration w' x' y' z' u')
               (UN (Basic "IFail"), [w,x,y])
                    => do w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          pure (Elaboratable_Expected_Failure w' x' y')
               (UN (Basic "INamespace"), [w,x,y])
                    => do w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          pure (Elaboratable_Namespace_Block w' x' y')
               (UN (Basic "ITransform"), [w,x,y,z])
                    => do w' <- reify defs !(evalClosure defs w)
                          x' <- reify defs !(evalClosure defs x)
                          y' <- reify defs !(evalClosure defs y)
                          z' <- reify defs !(evalClosure defs z)
                          pure (Elaboratable_Transformation w' x' y' z')
               (UN (Basic "ILog"), [x])
                    => do x' <- reify defs !(evalClosure defs x)
                          pure (Elaboratable_Logging x')
               _ => cantReify val "Decl"
    reify defs val = cantReify val "Decl"

mutual
  export
  Reflect RawImp where
    reflect fc defs lhs env (Elaboratable_Name tfc n)
        = do fc' <- reflect fc defs lhs env tfc
             n' <- reflect fc defs lhs env n
             appCon fc defs (reflectionttimp "IVar") [fc', n']
    reflect fc defs lhs env (Elaboratable_Dependent_Function_Type tfc c p mn aty rty)
        = do fc' <- reflect fc defs lhs env tfc
             c' <- reflect fc defs lhs env c
             p' <- reflect fc defs lhs env p
             mn' <- reflect fc defs lhs env mn
             aty' <- reflect fc defs lhs env aty
             rty' <- reflect fc defs lhs env rty
             appCon fc defs (reflectionttimp "IPi") [fc', c', p', mn', aty', rty']
    reflect fc defs lhs env (Elaboratable_Lambda tfc c p mn aty rty)
        = do fc' <- reflect fc defs lhs env tfc
             c' <- reflect fc defs lhs env c
             p' <- reflect fc defs lhs env p
             mn' <- reflect fc defs lhs env mn
             aty' <- reflect fc defs lhs env aty
             rty' <- reflect fc defs lhs env rty
             appCon fc defs (reflectionttimp "ILam") [fc', c', p', mn', aty', rty']
    reflect fc defs lhs env (Elaboratable_Binding tfc lhsFC c n aty aval sc)
        = do fc' <- reflect fc defs lhs env tfc
             lhsFC' <- reflect fc defs lhs env lhsFC
             c' <- reflect fc defs lhs env c
             n' <- reflect fc defs lhs env n
             aty' <- reflect fc defs lhs env aty
             aval' <- reflect fc defs lhs env aval
             sc' <- reflect fc defs lhs env sc
             appCon fc defs (reflectionttimp "ILet") [fc', lhsFC', c', n', aty', aval', sc']
    reflect fc defs lhs env (Elaboratable_Case tfc opts sc ty cs)
        = do fc' <- reflect fc defs lhs env tfc
             opts' <- reflect fc defs lhs env opts
             sc' <- reflect fc defs lhs env sc
             ty' <- reflect fc defs lhs env ty
             cs' <- reflect fc defs lhs env cs
             appCon fc defs (reflectionttimp "ICase") [fc', opts', sc', ty', cs']
    reflect fc defs lhs env (Elaboratable_Local_Definitions tfc ds sc)
        = do fc' <- reflect fc defs lhs env tfc
             ds' <- reflect fc defs lhs env ds
             sc' <- reflect fc defs lhs env sc
             appCon fc defs (reflectionttimp "ILocal") [fc', ds', sc']
    reflect fc defs lhs env (Elaboratable_Case_Local_Definition tfc u i args t)
        = reflect fc defs lhs env t -- shouldn't see this anyway...
    reflect fc defs lhs env (Elaboratable_Record_Update tfc ds sc)
        = do fc' <- reflect fc defs lhs env tfc
             ds' <- reflect fc defs lhs env ds
             sc' <- reflect fc defs lhs env sc
             appCon fc defs (reflectionttimp "IUpdate") [fc', ds', sc']
    reflect fc defs lhs env (Elaboratable_Apply tfc f a)
        = do fc' <- reflect fc defs lhs env tfc
             f' <- reflect fc defs lhs env f
             a' <- reflect fc defs lhs env a
             appCon fc defs (reflectionttimp "IApp") [fc', f', a']
    reflect fc defs lhs env (Elaboratable_Automatic_Apply tfc f a)
        = do fc' <- reflect fc defs lhs env tfc
             f' <- reflect fc defs lhs env f
             a' <- reflect fc defs lhs env a
             appCon fc defs (reflectionttimp "IAutoApp") [fc', f', a']
    reflect fc defs lhs env (Elaboratable_Named_Apply tfc f m a)
        = do fc' <- reflect fc defs lhs env tfc
             f' <- reflect fc defs lhs env f
             m' <- reflect fc defs lhs env m
             a' <- reflect fc defs lhs env a
             appCon fc defs (reflectionttimp "INamedApp") [fc', f', m', a']
    reflect fc defs lhs env (Elaboratable_With_Apply tfc f a)
        = do fc' <- reflect fc defs lhs env tfc
             f' <- reflect fc defs lhs env f
             a' <- reflect fc defs lhs env a
             appCon fc defs (reflectionttimp "IWithApp") [fc', f', a']
    reflect fc defs lhs env (Elaboratable_Search tfc d)
        = do fc' <- reflect fc defs lhs env tfc
             d' <- reflect fc defs lhs env d
             appCon fc defs (reflectionttimp "ISearch") [fc', d']
    reflect fc defs lhs env (Elaboratable_Alternative tfc t as)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             as' <- reflect fc defs lhs env as
             appCon fc defs (reflectionttimp "IAlternative") [fc', t', as']
    reflect fc defs lhs env (Elaboratable_Rewrite tfc t sc)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             sc' <- reflect fc defs lhs env sc
             appCon fc defs (reflectionttimp "IRewrite") [fc', t', sc']
    reflect fc defs lhs env (Elaboratable_Coerced tfc d) = reflect fc defs lhs env d
    reflect fc defs lhs env (Elaboratable_Bind_Here tfc n sc)
        = do fc' <- reflect fc defs lhs env tfc
             n' <- reflect fc defs lhs env n
             sc' <- reflect fc defs lhs env sc
             appCon fc defs (reflectionttimp "IBindHere") [fc', n', sc']
    reflect fc defs lhs env (Elaboratable_Bind_Name tfc n)
        = do fc' <- reflect fc defs lhs env tfc
             n' <- reflect fc defs lhs env n
             appCon fc defs (reflectionttimp "IBindVar") [fc', n']
    reflect fc defs lhs env (Elaboratable_As_Pattern tfc nameFC s n t)
        = do fc' <- reflect fc defs lhs env tfc
             nameFC' <- reflect fc defs lhs env nameFC
             s' <- reflect fc defs lhs env s
             n' <- reflect fc defs lhs env n
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IAs") [fc', nameFC', s', n', t']
    reflect fc defs lhs env (Elaboratable_Must_Unify tfc r t)
        = do fc' <- reflect fc defs lhs env tfc
             r' <- reflect fc defs lhs env r
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IMustUnify") [fc', r', t']
    reflect fc defs lhs env (Elaboratable_Delayed_Type tfc r t)
        = do fc' <- reflect fc defs lhs env tfc
             r' <- reflect fc defs lhs env r
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IDelayed") [fc', r', t']
    reflect fc defs lhs env (Elaboratable_Delay tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IDelay") [fc', t']
    reflect fc defs lhs env (Elaboratable_Force tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IForce") [fc', t']
    reflect fc defs lhs env (Elaboratable_Quote tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IQuote") [fc', t']
    reflect fc defs lhs env (Elaboratable_Quote_Name tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IQuoteName") [fc', t']
    reflect fc defs lhs env (Elaboratable_Quote_Declarations tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IQuoteDecl") [fc', t']
    reflect fc defs lhs env (Elaboratable_Unquote tfc (Elaboratable_Name _ t))
        = pure (Ref tfc Bound t)
    reflect fc defs lhs env (Elaboratable_Unquote tfc t)
        = throw (InternalError "Can't reflect an unquote: escapes should be lifted out")
    reflect fc defs lhs env (Elaboratable_Run_Elaborator tfc _ t)
        = throw (InternalError "Can't reflect a %runElab")
    reflect fc defs lhs env (Elaboratable_Primitive_Value tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IPrimVal") [fc', t']
    reflect fc defs lhs env (Elaboratable_Type_Universe tfc)
        = do fc' <- reflect fc defs lhs env tfc
             appCon fc defs (reflectionttimp "IType") [fc']
    reflect fc defs lhs env (Elaboratable_Hole tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IHole") [fc', t']
    reflect fc defs lhs env (Elaboratable_Unification_Log tfc _ t)
        = reflect fc defs lhs env t
    reflect fc defs True env (Implicit tfc t)
        = pure (Erased fc Placeholder)
    reflect fc defs lhs env (Implicit tfc t)
        = do fc' <- reflect fc defs lhs env tfc
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "Implicit") [fc', t']
    reflect fc defs lhs env (Elaboratable_With_Unambiguous_Names tfc ns t)
        = do fc' <- reflect fc defs lhs env tfc
             ns' <- reflect fc defs lhs env ns
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "IWithUnambigNames") [fc', ns', t']

  export
  Reflect Elaboratable_Field_Update where
    reflect fc defs lhs env (Elaboratable_Set_Field p t)
        = do p' <- reflect fc defs lhs env p
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "ISetField") [p', t']
    reflect fc defs lhs env (Elaboratable_Apply_To_Field p t)
        = do p' <- reflect fc defs lhs env p
             t' <- reflect fc defs lhs env t
             appCon fc defs (reflectionttimp "ISetFieldApp") [p', t']

  export
  Reflect AltType where
    reflect fc defs lhs env FirstSuccess = getCon fc defs (reflectionttimp "FirstSuccess")
    reflect fc defs lhs env Unique = getCon fc defs (reflectionttimp "Unique")
    reflect fc defs lhs env (UniqueDefault x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "UniqueDefault") [x']

  export
  Reflect FnOpt where
    reflect fc defs lhs env Unsafe = getCon fc defs (reflectionttimp "Unsafe")
    reflect fc defs lhs env Inline = getCon fc defs (reflectionttimp "Inline")
    reflect fc defs lhs env NoInline = getCon fc defs (reflectionttimp "NoInline")
    reflect fc defs lhs env Deprecate = getCon fc defs (reflectionttimp "Deprecate")
    reflect fc defs lhs env TCInline = getCon fc defs (reflectionttimp "TCInline")
    reflect fc defs lhs env (Hint x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "Hint") [x']
    reflect fc defs lhs env (GlobalHint x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "GlobalHint") [x']
    reflect fc defs lhs env ExternFn = getCon fc defs (reflectionttimp "ExternFn")
    reflect fc defs lhs env (ForeignFn x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "ForeignFn") [x']
    reflect fc defs lhs env (ForeignExport x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "ForeignExport") [x']
    reflect fc defs lhs env Invertible = getCon fc defs (reflectionttimp "Invertible")
    reflect fc defs lhs env (Totality r)
        = do r' <- reflect fc defs lhs env r
             appCon fc defs (reflectionttimp "Totality") [r']
    reflect fc defs lhs env Macro = getCon fc defs (reflectionttimp "Macro")
    reflect fc defs lhs env (SpecArgs r)
        = do r' <- reflect fc defs lhs env r
             appCon fc defs (reflectionttimp "SpecArgs") [r']

  export
  Reflect ImpTy where
    reflect fc defs lhs env ty
        = do w' <- reflect fc defs lhs env ty.fc
             x' <- reflect fc defs lhs env ty.tyName
             z' <- reflect fc defs lhs env ty.val
             appCon fc defs (reflectionttimp "MkTy") [w', x', z']

  export
  Reflect DataOpt where
    reflect fc defs lhs env (SearchBy x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "SearchBy") [x']
    reflect fc defs lhs env NoHints = getCon fc defs (reflectionttimp "NoHints")
    reflect fc defs lhs env UniqueSearch = getCon fc defs (reflectionttimp "UniqueSearch")
    reflect fc defs lhs env External = getCon fc defs (reflectionttimp "External")
    reflect fc defs lhs env NoNewtype = getCon fc defs (reflectionttimp "NoNewtype")

  export
  Reflect ImpData where
    reflect fc defs lhs env (MkImpData v w x y z)
        = do v' <- reflect fc defs lhs env v
             w' <- reflect fc defs lhs env w
             x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "MkData") [v', w', x', y', z']
    reflect fc defs lhs env (MkImpLater x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "MkLater") [x', y', z']

  export
  Reflect Elaboratable_Field where
    reflect fc defs lhs env field -- Order matters to maintain compatibility with elab reflection
        = do v' <- reflect fc defs lhs env field.fc
             w' <- reflect fc defs lhs env field.rig
             x' <- reflect fc defs lhs env field.val.info
             y' <- reflect fc defs lhs env field.name.val
             z' <- reflect fc defs lhs env field.val.boundType
             appCon fc defs (reflectionttimp "MkIField") [v', w', x', y', z']
  export
  Reflect ImpRecord where
    reflect fc defs lhs env r@(MkWithData _ $ MkImpRecord header body)
        = do v' <- reflect fc defs lhs env r.fc
             w' <- reflect fc defs lhs env header.name.val
             x' <- reflect fc defs lhs env (map toOldParams header.val)
             y' <- reflect fc defs lhs env body.opts
             z' <- reflect fc defs lhs env body.name.val
             a' <- reflect fc defs lhs env body.val
             appCon fc defs (reflectionttimp "MkRecord") [v', w', x', y', z', a']

  export
  Reflect WithFlag where
    reflect fc defs lhs env Syntactic
        = getCon fc defs (reflectionttimp "Syntactic")

  export
  Reflect ImpClause where
    reflect fc defs lhs env (PatClause x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "PatClause") [x', y', z']
    reflect fc defs lhs env (WithClause u v w x y z a)
        = do u' <- reflect fc defs lhs env u
             v' <- reflect fc defs lhs env v
             w' <- reflect fc defs lhs env w
             x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             a' <- reflect fc defs lhs env a
             appCon fc defs (reflectionttimp "WithClause") [u', v', w', x', y', z', a']
    reflect fc defs lhs env (ImpossibleClause x y)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             appCon fc defs (reflectionttimp "ImpossibleClause") [x', y']

  export
  Reflect (Elaboratable_Claim_Data Name) where
    reflect fc defs lhs env (Make_Elaboratable_Claim_Data w x y z)
        = do w' <- reflect fc defs lhs env w
             x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "MkIClaimData") [w', x', y', z']

  export
  Reflect ImpDecl where
    reflect fc defs lhs env (Elaboratable_Claim v)
        = do v' <- reflect fc defs lhs env v
             appCon fc defs (reflectionttimp "IClaim") [v']
    reflect fc defs lhs env (Elaboratable_Data_Declaration x y z w)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             w' <- reflect fc defs lhs env w
             appCon fc defs (reflectionttimp "IData") [x', y', z', w']
    reflect fc defs lhs env (Elaboratable_Definition x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "IDef") [x', y', z']
    reflect fc defs lhs env (Elaboratable_Parameter_Block x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env (map toOldParams y)
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "IParameters") [x', y', z']
    reflect fc defs lhs env (Elaboratable_Record_Declaration w x y z u)
        = do w' <- reflect fc defs lhs env w
             x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             u' <- reflect fc defs lhs env u
             appCon fc defs (reflectionttimp "IRecord") [w', x', y', z', u']
    reflect fc defs lhs env (Elaboratable_Expected_Failure x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "IFail") [x', y', z']
    reflect fc defs lhs env (Elaboratable_Namespace_Block x y z)
        = do x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "INamespace") [x', y', z']
    reflect fc defs lhs env (Elaboratable_Transformation w x y z)
        = do w' <- reflect fc defs lhs env w
             x' <- reflect fc defs lhs env x
             y' <- reflect fc defs lhs env y
             z' <- reflect fc defs lhs env z
             appCon fc defs (reflectionttimp "ITransform") [w', x', y', z']
    reflect fc defs lhs env (Elaboratable_Run_Elaborator_Declaration w x)
        = throw (GenericMsg fc "Can't reflect a %runElab")
    reflect fc defs lhs env (Elaboratable_Pragma _ _ x)
        = throw (GenericMsg fc "Can't reflect a pragma")
    reflect fc defs lhs env (Elaboratable_Logging x)
        = do x' <- reflect fc defs lhs env x
             appCon fc defs (reflectionttimp "ILog") [x']
    reflect fc defs lhs env (Elaboratable_Builtin_Declaration {})
        = throw (GenericMsg fc "Can't reflect a %builtin")
