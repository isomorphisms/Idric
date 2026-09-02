module TTImp.TTImp

import Core.Context.Log
import Core.Env
import Core.Normalise
import Core.Value

import public Data.List1
import Data.SortedSet

import Libraries.Data.List.SizeOf
import Libraries.Data.WithDefault

%default covering

-- Information about names in nested blocks
public export
record NestedNames (vars : Scope) where
  constructor MkNested
  -- A map from names to the decorated version of the name, and the new name
  -- applied to its enclosing environment
  -- Takes the location and name type, because we don't know them until we
  -- elaborate the name at the point of use
  names : List (Name, (Maybe Name,  -- new name if there is one
                       List (Var vars), -- names used from the environment
                       FC -> NameType -> Term vars))

export
Weaken NestedNames where
  weakenNs {ns = wkns} s (MkNested ns) = MkNested (map wknName ns)
    where
      wknName : (Name, (Maybe Name, List (Var vars), FC -> NameType -> Term vars)) ->
                (Name, (Maybe Name, List (Var (wkns ++ vars)), FC -> NameType -> Term (wkns ++ vars)))
      wknName (n, (mn, vars, rep))
          = (n, (mn, map (weakenNs s) vars, \fc, nt => weakenNs s (rep fc nt)))

-- replace nested name with full name
export
mapNestedName : NestedNames vars -> Name -> Name
mapNestedName nest n = case lookup n (names nest) of
                               (Just (Just n', _)) => n'
                               _ => n

-- Unchecked terms, with implicit arguments
-- This is the raw, elaborable form.
-- Higher level expressions (e.g. case, pattern matching let, where blocks,
-- do notation, etc, should elaborate via this, perhaps in some local
-- context).
public export
data BindMode = PI RigCount | PATTERN | COVERAGE | NONE

%name BindMode bm

mutual

  public export
  RawImp : Type
  RawImp = RawImp' Name

  public export
  Kinded_Elaborable_Term : Type
  Kinded_Elaborable_Term = RawImp' KindedName

  public export
  data RawImp' : Type -> Type where
       Elaborable_Name : FC -> nm -> RawImp' nm
       Elaborable_Dependent_Function_Type : FC -> RigCount -> PiInfo (RawImp' nm) -> Maybe Name ->
             (argTy : RawImp' nm) -> (retTy : RawImp' nm) -> RawImp' nm
       Elaborable_Lambda : FC -> RigCount -> PiInfo (RawImp' nm) -> Maybe Name ->
              (argTy : RawImp' nm) -> (lamTy : RawImp' nm) -> RawImp' nm
       Elaborable_Binding : FC -> (lhsFC : FC) -> RigCount -> Name ->
              (nTy : RawImp' nm) -> (nVal : RawImp' nm) ->
              (scope : RawImp' nm) -> RawImp' nm
       Elaborable_Case : FC -> List (FnOpt' nm) -> RawImp' nm -> (ty : RawImp' nm) ->
               List (ImpClause' nm) -> RawImp' nm
       Elaborable_Local_Definitions : FC -> List (ImpDecl' nm) -> RawImp' nm -> RawImp' nm
       -- Local definitions made elsewhere, but that we're pushing
       -- into a case branch as nested names.
       -- An appearance of 'uname' maps to an application of
       -- 'internalName' to 'args'.
       Elaborable_Case_Local_Definition : FC -> (uname : Name) ->
                    (internalName : Name) ->
                    (args : List Name) -> RawImp' nm -> RawImp' nm

       Elaborable_Record_Update : FC -> List (Elaborable_Field_Update' nm) -> RawImp' nm -> RawImp' nm

       Elaborable_Apply : FC -> RawImp' nm -> RawImp' nm -> RawImp' nm
       Elaborable_Automatic_Apply : FC -> RawImp' nm -> RawImp' nm -> RawImp' nm
       Elaborable_Named_Apply : FC -> RawImp' nm -> Name -> RawImp' nm -> RawImp' nm
       Elaborable_With_Apply : FC -> RawImp' nm -> RawImp' nm -> RawImp' nm

       Elaborable_Search : FC -> (depth : Nat) -> RawImp' nm
       Elaborable_Alternative : FC -> AltType' nm -> List (RawImp' nm) -> RawImp' nm
       Elaborable_Rewrite : FC -> RawImp' nm -> RawImp' nm -> RawImp' nm
       Elaborable_Coerced : FC -> RawImp' nm -> RawImp' nm

       -- Any implicit bindings in the scope should be bound here, using
       -- the given binder
       Elaborable_Bind_Here : FC -> BindMode -> RawImp' nm -> RawImp' nm
       -- A name which should be implicitly bound
       Elaborable_Bind_Name : FC -> Name -> RawImp' nm
       -- An 'as' pattern, valid on the LHS of a clause only
       Elaborable_As_Pattern : FC -> (nameFC : FC) -> UseSide -> Name -> RawImp' nm -> RawImp' nm
       -- A 'dot' pattern, i.e. one which must also have the given value
       -- by unification
       Elaborable_Must_Unify : FC -> DotReason -> RawImp' nm -> RawImp' nm

       -- Laziness annotations
       Elaborable_Delayed_Type : FC -> LazyReason -> RawImp' nm -> RawImp' nm -- the type
       Elaborable_Delay : FC -> RawImp' nm -> RawImp' nm -- delay constructor
       Elaborable_Force : FC -> RawImp' nm -> RawImp' nm

       -- Quasiquoting
       Elaborable_Quote : FC -> RawImp' nm -> RawImp' nm
       Elaborable_Quote_Name : FC -> Name -> RawImp' nm
       Elaborable_Quote_Declarations : FC -> List (ImpDecl' nm) -> RawImp' nm
       Elaborable_Unquote : FC -> RawImp' nm -> RawImp' nm
       Elaborable_Run_Elaborator : FC -> (requireExtension : Bool) -> RawImp' nm -> RawImp' nm

       Elaborable_Primitive_Value : FC -> (c : Constant) -> RawImp' nm
       Elaborable_Type_Universe : FC -> RawImp' nm
       Elaborable_Hole : FC -> String -> RawImp' nm

       Elaborable_Unification_Log : FC -> LogLevel -> RawImp' nm -> RawImp' nm
       -- An implicit value, solved by unification, but which will also be
       -- bound (either as a pattern variable or a type variable) if unsolved
       -- at the end of elaborator
       Implicit : FC -> (bindIfUnsolved : Bool) -> RawImp' nm

       -- with-disambiguation
       Elaborable_With_Unambiguous_Names : FC -> List (FC, Name) -> RawImp' nm -> RawImp' nm

  %name RawImp' t, u

  public export
  Elaborable_Field_Update : Type
  Elaborable_Field_Update = Elaborable_Field_Update' Name

  public export
  data Elaborable_Field_Update' : Type -> Type where
       Elaborable_Set_Field : (path : List String) -> RawImp' nm -> Elaborable_Field_Update' nm
       Elaborable_Apply_To_Field : (path : List String) -> RawImp' nm -> Elaborable_Field_Update' nm
  %name Elaborable_Field_Update' upd

  public export
  AltType : Type
  AltType = AltType' Name

  public export
  data AltType' : Type -> Type where
       FirstSuccess : AltType' nm
       Unique : AltType' nm
       UniqueDefault : RawImp' nm -> AltType' nm
  %name AltType' alt

  export
  covering
  Show nm => Show (RawImp' nm) where
      show (Elaborable_Name fc n) = show n
      show (Elaborable_Dependent_Function_Type fc c p n arg ret)
         = "(%pi " ++ show c ++ " " ++ show p ++ " " ++
           showPrec App n ++ " " ++ show arg ++ " " ++ show ret ++ ")"
      show (Elaborable_Lambda fc c p n arg sc)
         = "(%lam " ++ show c ++ " " ++ show p ++ " " ++
           showPrec App n ++ " " ++ show arg ++ " " ++ show sc ++ ")"
      show (Elaborable_Binding fc lhsFC c n ty val sc)
         = "(%let " ++ show c ++ " " ++ " " ++ show n ++ " " ++ show ty ++
           " " ++ show val ++ " " ++ show sc ++ ")"
      show (Elaborable_Case _ _ scr scrty alts)
         = "(%case (" ++ show scr ++ " : " ++ show scrty ++ ") " ++ show alts ++ ")"
      show (Elaborable_Local_Definitions _ def scope)
         = "(%local (" ++ show def ++ ") " ++ show scope ++ ")"
      show (Elaborable_Case_Local_Definition _ uname iname args sc)
         = "(%caselocal (" ++ show uname ++ " " ++ show iname
               ++ " " ++ show args ++ ") " ++ show sc ++ ")"
      show (Elaborable_Record_Update _ flds rec)
         = "(%record " ++ showSep ", " (map show flds) ++ " " ++ show rec ++ ")"
      show (Elaborable_Apply fc f a)
         = "(" ++ show f ++ " " ++ show a ++ ")"
      show (Elaborable_Named_Apply fc f n a)
         = "(" ++ show f ++ " [" ++ show n ++ " = " ++ show a ++ "])"
      show (Elaborable_Automatic_Apply fc f a)
         = "(" ++ show f ++ " [" ++ show a ++ "])"
      show (Elaborable_With_Apply fc f a)
         = "(" ++ show f ++ " | " ++ show a ++ ")"
      show (Elaborable_Search fc d)
         = "%search"
      show (Elaborable_Alternative fc ty alts)
         = "(|" ++ showSep "," (map show alts) ++ "|)"
      show (Elaborable_Rewrite _ rule tm)
         = "(%rewrite (" ++ show rule ++ ") (" ++ show tm ++ "))"
      show (Elaborable_Coerced _ tm) = "(%coerced " ++ show tm ++ ")"

      show (Elaborable_Bind_Here fc b sc)
         = "(%bindhere " ++ show sc ++ ")"
      show (Elaborable_Bind_Name fc n) = "$" ++ show n
      show (Elaborable_As_Pattern fc _ _ n tm) = show n ++ "@(" ++ show tm ++ ")"
      show (Elaborable_Must_Unify fc r tm) = ".(" ++ show tm ++ ")"
      show (Elaborable_Delayed_Type fc r tm) = "(%delayed " ++ show tm ++ ")"
      show (Elaborable_Delay fc tm) = "(%delay " ++ show tm ++ ")"
      show (Elaborable_Force fc tm) = "(%force " ++ show tm ++ ")"
      show (Elaborable_Quote fc tm) = "(%quote " ++ show tm ++ ")"
      show (Elaborable_Quote_Name fc tm) = "(%quotename " ++ show tm ++ ")"
      show (Elaborable_Quote_Declarations fc tm) = "(%quotedecl " ++ show tm ++ ")"
      show (Elaborable_Unquote fc tm) = "(%unquote " ++ show tm ++ ")"
      show (Elaborable_Run_Elaborator fc _ tm) = "(%runelab " ++ show tm ++ ")"
      show (Elaborable_Primitive_Value fc c) = show c
      show (Elaborable_Hole _ x) = "?" ++ x
      show (Elaborable_Unification_Log _ lvl x) = "(%logging " ++ show lvl ++ " " ++ show x ++ ")"
      show (Elaborable_Type_Universe fc) = "%type"
      show (Implicit fc True) = "_"
      show (Implicit fc False) = "?"
      show (Elaborable_With_Unambiguous_Names fc ns rhs) = "(%with " ++ show ns ++ " " ++ show rhs ++ ")"

  export
  covering
  Show nm => Show (Elaborable_Field_Update' nm) where
    show (Elaborable_Set_Field p val) = showSep "->" p ++ " = " ++ show val
    show (Elaborable_Apply_To_Field p val) = showSep "->" p ++ " $= " ++ show val

  public export
  FnOpt : Type
  FnOpt = FnOpt' Name

  public export
  data FnOpt' : Type -> Type where
       Unsafe : FnOpt' nm
       Inline : FnOpt' nm
       NoInline : FnOpt' nm
       ||| Mark a function as deprecated.
       Deprecate : FnOpt' nm
       TCInline : FnOpt' nm
       -- Flag means the hint is a direct hint, not a function which might
       -- find the result (e.g. chasing parent interface dictionaries)
       Hint : Bool -> FnOpt' nm
       -- Flag means to use as a default if all else fails
       GlobalHint : Bool -> FnOpt' nm
       ExternFn : FnOpt' nm
       -- Defined externally, list calling conventions
       ForeignFn : List (RawImp' nm) -> FnOpt' nm
       -- Mark for export to a foreign language, list calling conventions
       ForeignExport : List (RawImp' nm) -> FnOpt' nm
       -- assume safe to cancel arguments in unification
       Invertible : FnOpt' nm
       Totality : TotalReq -> FnOpt' nm
       Macro : FnOpt' nm
       SpecArgs : List Name -> FnOpt' nm
  %name FnOpt' fopt

  public export
  isTotalityReq : FnOpt' nm -> Bool
  isTotalityReq (Totality _) = True
  isTotalityReq _ = False

  export
  extractTotality : FnOpt' nm -> Maybe TotalReq
  extractTotality (Totality t) = Just t
  extractTotality _ = Nothing

  export
  findTotality : List (FnOpt' nm) -> Maybe TotalReq
  findTotality = foldr (\elem, acc => extractTotality elem <|> acc) empty

  export
  covering
  Show nm => Show (FnOpt' nm) where
    show Unsafe = "%unsafe"
    show Inline = "%inline"
    show NoInline = "%noinline"
    show Deprecate = "%deprecate"
    show TCInline = "%tcinline"
    show (Hint t) = "%hint " ++ show t
    show (GlobalHint t) = "%globalhint " ++ show t
    show ExternFn = "%extern"
    show (ForeignFn cs) = "%foreign " ++ showSep " " (map show cs)
    show (ForeignExport cs) = "%export " ++ showSep " " (map show cs)
    show Invertible = "%invertible"
    show (Totality Total) = "total"
    show (Totality CoveringOnly) = "covering"
    show (Totality PartialOK) = "partial"
    show Macro = "%macro"
    show (SpecArgs ns) = "%spec " ++ showSep " " (map show ns)

  export
  Eq FnOpt where
    Inline == Inline = True
    NoInline == NoInline = True
    Deprecate == Deprecate = True
    TCInline == TCInline = True
    (Hint x) == (Hint y) = x == y
    (GlobalHint x) == (GlobalHint y) = x == y
    ExternFn == ExternFn = True
    (ForeignFn xs) == (ForeignFn ys) = True -- xs == ys
    (ForeignExport xs) == (ForeignExport ys) = True -- xs == ys
    Invertible == Invertible = True
    (Totality tot_lhs) == (Totality tot_rhs) = tot_lhs == tot_rhs
    Macro == Macro = True
    (SpecArgs ns) == (SpecArgs ns') = ns == ns'
    _ == _ = False

  public export
  ImpTy : Type
  ImpTy = ImpTy' Name

  public export
  ImpTy' : Type -> Type
  ImpTy' = AddMetadata FC' . AddMetadata TyName' . RawImp'

  export
  covering
  Show nm => Show (ImpTy' nm) where
    show ty = "(%claim " ++ show ty.tyName.val ++ " " ++ show ty.val ++ ")"

  public export
  ImpData : Type
  ImpData = ImpData' Name

  public export
  data ImpData' : Type -> Type where
       MkImpData : FC -> (n : Name) ->
                   -- if we have already declared the type using `MkImpLater`,
                   -- we are allowed to leave the telescope out here.
                   (tycon : Maybe (RawImp' nm)) ->
                   (opts : List DataOpt) ->
                   (datacons : List (ImpTy' nm)) -> ImpData' nm
       MkImpLater : FC -> (n : Name) -> (tycon : RawImp' nm) -> ImpData' nm

  %name ImpData' dat

  export
  covering
  Show nm => Show (ImpData' nm) where
    show (MkImpData fc n (Just tycon) _ cons)
        = "(%data " ++ show n ++ " " ++ show tycon ++ " " ++ show cons ++ ")"
    show (MkImpData fc n Nothing _ cons)
        = "(%data " ++ show n ++ " " ++ show cons ++ ")"
    show (MkImpLater fc n tycon)
        = "(%datadecl " ++ show n ++ " " ++ show tycon ++ ")"

  public export
  Elaborable_Field : Type
  Elaborable_Field = Elaborable_Field' Name

  public export
  Elaborable_Field' : Type -> Type
  Elaborable_Field' nm = AddFC $ ImpParameter' (RawImp' nm)

  public export
  ImpParameter : Type
  ImpParameter = ImpParameter' (RawImp' Name)

  public export
  ImpParameter' : Type -> Type
  ImpParameter' nm = WithRig $ WithName $ PiBindData nm

  -- old datatype for ImpParameter, used for elabreflection compatibility
  public export
  OldParameters' : Type -> Type
  OldParameters' nm = (Name, RigCount, PiInfo (RawImp' nm), RawImp' nm)

  public export
  toOldParams : ImpParameter' (RawImp' nm) -> OldParameters' nm
  toOldParams bind = (bind.name.val, bind.rig, bind.val.info, bind.val.boundType)

  public export
  fromOldParams : OldParameters' nm -> ImpParameter' (RawImp' nm)
  fromOldParams (nm, rig, info,type) = Mk [rig, NoFC nm] (MkPiBindData info type)

  export
  Show nm => Show (ImpParameter' nm) where
    show x = "\{show x.rig}\{show x.name.val} \{show x.val.boundType}"

  public export 0
  ImpRecord : Type
  ImpRecord = AddFC $ ImpRecordData Name

  public export 0
  DataHeader : Type -> Type -- the name is the type constructor's name
  DataHeader nm = WithName $ List (ImpParameter' (RawImp' nm))

  public export 0
  RecordBody : Type -> Type -- The name is the data constructor's name
  RecordBody nm = WithName $ WithOpts $ List (Elaborable_Field' nm)

  ||| A record is defined by its header containing the name and parameters, and its body
  ||| containing the constructor name, options, and a list of fields
  public export
  record ImpRecordData (nm : Type) where
    constructor MkImpRecord
    header : DataHeader nm
    body : RecordBody nm

  export
  covering
  Show nm => Show (Elaborable_Field' nm) where
    show f@(MkWithData _ (MkPiBindData Explicit ty)) = show f.name.val ++ " : " ++ show ty
    show f@(MkWithData _ ty) = "{" ++ show f.name.val ++ " : " ++ show ty.boundType ++ "}"

  export
  covering
  Show nm => Show (ImpRecordData nm) where
    show (MkImpRecord header body)
        = "record " ++ show header.name.val ++ " " ++ show header.val ++
          " " ++ show body.name.val ++ "\n\t" ++
          showSep "\n\t" (map show body.val) ++ "\n"

  public export
  data WithFlag
         = Syntactic -- abstract syntactically, rather than by value

  export
  Eq WithFlag where
      Syntactic == Syntactic = True

  public export
  ImpClause : Type
  ImpClause = ImpClause' Name

  public export
  Kinded_Elaborable_Clause : Type
  Kinded_Elaborable_Clause = ImpClause' KindedName

  public export
  data ImpClause' : Type -> Type where
       PatClause : FC -> (lhs : RawImp' nm) -> (rhs : RawImp' nm) -> ImpClause' nm
       WithClause : FC -> (lhs : RawImp' nm) ->
                    (rig : RigCount) -> (wval : RawImp' nm) -> -- with'd expression (& quantity)
                    (prf : Maybe (RigCount, Name)) -> -- optional name for the proof
                    (flags : List WithFlag) ->
                    List (ImpClause' nm) -> ImpClause' nm
       ImpossibleClause : FC -> (lhs : RawImp' nm) -> ImpClause' nm

  %name ImpClause' cl

  export
  covering
  Show nm => Show (ImpClause' nm) where
    show (PatClause fc lhs rhs)
       = show lhs ++ " = " ++ show rhs
    show (WithClause fc lhs rig wval prf flags block)
       = show lhs
       ++ " with " ++ showCount rig ++ "(" ++ show wval ++ ")"
          -- TODO: remove `the` after fix idris-lang/Idris2#3418
       ++ maybe "" (the (_ -> _) $ \(rg, nm) => " proof " ++ showCount rg ++ show nm) prf
       ++ "\n\t" ++ show block
    show (ImpossibleClause fc lhs)
       = show lhs ++ " impossible"

  public export
  ImpDecl : Type
  ImpDecl = ImpDecl' Name

  public export
  record Elaborable_Claim_Data (nm : Type) where
    constructor Make_Elaborable_Claim_Data
    rig : RigCount
    vis : Visibility
    opts : List (FnOpt' nm)
    type : ImpTy' nm

  public export
  data ImpDecl' : Type -> Type where
       Elaborable_Claim : WithFC (Elaborable_Claim_Data nm) -> ImpDecl' nm
       Elaborable_Data_Declaration : FC -> WithDefault Visibility Private ->
               Maybe TotalReq -> ImpData' nm -> ImpDecl' nm
       Elaborable_Definition : FC -> Name -> List (ImpClause' nm) -> ImpDecl' nm
       Elaborable_Parameter_Block : FC ->
                     List1 (ImpParameter' (RawImp' nm)) ->
                     List (ImpDecl' nm) -> ImpDecl' nm
       Elaborable_Record_Declaration : FC ->
                 Maybe String -> -- nested namespace
                 WithDefault Visibility Private ->
                 Maybe TotalReq ->
                 AddFC (ImpRecordData nm) -> ImpDecl' nm
       Elaborable_Expected_Failure : FC -> Maybe String -> List (ImpDecl' nm) -> ImpDecl' nm
       Elaborable_Namespace_Block : FC -> Namespace -> List (ImpDecl' nm) -> ImpDecl' nm
       Elaborable_Transformation : FC -> Name -> RawImp' nm -> RawImp' nm -> ImpDecl' nm
       Elaborable_Run_Elaborator_Declaration : FC -> RawImp' nm -> ImpDecl' nm
       Elaborable_Pragma : FC -> List Name -> -- pragmas might define names that wouldn't
                                    -- otherwise be spotted in 'definedInBlock' so they
                                    -- can be flagged here.
                 ({vars : _} ->
                  NestedNames vars -> Env Term vars -> Core ()) ->
                 ImpDecl' nm
       Elaborable_Logging : Maybe (List String, Nat) -> ImpDecl' nm
       Elaborable_Builtin_Declaration : FC -> BuiltinType -> Name -> ImpDecl' nm

  %name ImpDecl' decl

  export
  covering
  Show nm => Show (ImpDecl' nm) where
    show (Elaborable_Claim (MkWithData _ $ Make_Elaborable_Claim_Data c _ opts ty))
        = show opts ++ " " ++ show c ++ " " ++ show ty
    show (Elaborable_Data_Declaration _ _ _ d) = show d
    show (Elaborable_Definition _ n cs) = "(%def " ++ show n ++ " " ++ show cs ++ ")"
    show (Elaborable_Parameter_Block _ ps ds)
        = "parameters " ++ show ps ++ "\n\t" ++
          showSep "\n\t" (assert_total $ map show ds)
    show (Elaborable_Record_Declaration _ _ _ _ d) = show d.val
    show (Elaborable_Expected_Failure _ msg decls)
        = "fail" ++ maybe "" ((" " ++) . show) msg ++ "\n" ++
          showSep "\n" (assert_total $ map (("  " ++) . show) decls)
    show (Elaborable_Namespace_Block _ ns decls)
        = "namespace " ++ show ns ++
          showSep "\n" (assert_total $ map show decls)
    show (Elaborable_Transformation _ n lhs rhs)
        = "%transform " ++ show n ++ " " ++ show lhs ++ " ==> " ++ show rhs
    show (Elaborable_Run_Elaborator_Declaration _ tm)
        = "%runElab " ++ show tm
    show (Elaborable_Pragma {}) = "[externally defined pragma]"
    show (Elaborable_Logging Nothing) = "%logging off"
    show (Elaborable_Logging (Just (topic, lvl))) = "%logging " ++ case topic of
      [] => show lvl
      _  => concat (intersperse "." topic) ++ " " ++ show lvl
    show (Elaborable_Builtin_Declaration _ type name) = "%builtin " ++ show type ++ " " ++ show name


export
mkWithClause : FC -> RawImp' nm -> List1 (RigCount, RawImp' nm, Maybe (RigCount, Name)) ->
               List WithFlag -> List (ImpClause' nm) -> ImpClause' nm
mkWithClause fc lhs ((rig, wval, prf) ::: []) flags cls
  = WithClause fc lhs rig wval prf flags cls
mkWithClause fc lhs ((rig, wval, prf) ::: wp :: wps) flags cls
  = let vfc = virtualiseFC fc
        arg = UN $ Basic "arg"
     in WithClause fc lhs rig wval prf flags
          [mkWithClause fc (Elaborable_Apply vfc lhs $ Elaborable_Bind_Name vfc arg) (wp ::: wps) flags cls]

-- Extract the RawImp term from a FieldUpdate.
export
getFieldUpdateTerm : Elaborable_Field_Update' nm -> RawImp' nm
getFieldUpdateTerm (Elaborable_Set_Field    _ term) = term
getFieldUpdateTerm (Elaborable_Apply_To_Field _ term) = term


export
getFieldUpdatePath : Elaborable_Field_Update' nm -> List String
getFieldUpdatePath (Elaborable_Set_Field    path _) = path
getFieldUpdatePath (Elaborable_Apply_To_Field path _) = path


export
mapFieldUpdateTerm : (RawImp' nm -> RawImp' nm) -> Elaborable_Field_Update' nm -> Elaborable_Field_Update' nm
mapFieldUpdateTerm f (Elaborable_Set_Field    x term) = Elaborable_Set_Field    x (f term)
mapFieldUpdateTerm f (Elaborable_Apply_To_Field x term) = Elaborable_Apply_To_Field x (f term)


export
is_primitive_value : RawImp' nm -> Maybe Constant
is_primitive_value (Elaborable_Primitive_Value _ c) = Just c
is_primitive_value _ = Nothing

-- REPL commands for TTImp interaction
public export
data ImpREPL : Type where
     Eval : RawImp -> ImpREPL
     Check : RawImp -> ImpREPL
     ProofSearch : Name -> ImpREPL
     ExprSearch : Name -> ImpREPL
     GenerateDef : Int -> Name -> ImpREPL
     Missing : Name -> ImpREPL
     CheckTotal : Name -> ImpREPL
     DebugInfo : Name -> ImpREPL
     Quit : ImpREPL

export
mapAltType : (RawImp' nm -> RawImp' nm) -> AltType' nm -> AltType' nm
mapAltType f (UniqueDefault x) = UniqueDefault (f x)
mapAltType _ u = u

export
lhsInCurrentNS : {auto c : Ref Ctxt Defs} ->
                 NestedNames vars -> RawImp -> Core RawImp
lhsInCurrentNS nest (Elaborable_Apply loc f a)
    = do f' <- lhsInCurrentNS nest f
         pure (Elaborable_Apply loc f' a)
lhsInCurrentNS nest (Elaborable_Automatic_Apply loc f a)
    = do f' <- lhsInCurrentNS nest f
         pure (Elaborable_Automatic_Apply loc f' a)
lhsInCurrentNS nest (Elaborable_Named_Apply loc f n a)
    = do f' <- lhsInCurrentNS nest f
         pure (Elaborable_Named_Apply loc f' n a)
lhsInCurrentNS nest (Elaborable_With_Apply loc f a)
    = do f' <- lhsInCurrentNS nest f
         pure (Elaborable_With_Apply loc f' a)
lhsInCurrentNS nest tm@(Elaborable_Name loc (NS {})) = pure tm -- leave explicit NS alone
lhsInCurrentNS nest (Elaborable_Name loc n)
    = case lookup n (names nest) of
           Nothing =>
              do n' <- inCurrentNS n
                 pure (Elaborable_Name loc n')
           -- If it's one of the names in the current nested block, we'll
           -- be rewriting it during elaboration to be in the scope of the
           -- parent name.
           Just _ => pure (Elaborable_Name loc n)
lhsInCurrentNS nest tm = pure tm

export
find_names_to_bind : RawImp' nm -> List String
find_names_to_bind (Elaborable_Dependent_Function_Type fc rig p mn aty retty)
    = find_names_to_bind aty ++ find_names_to_bind retty
find_names_to_bind (Elaborable_Lambda fc rig p n aty sc)
    = find_names_to_bind aty ++ find_names_to_bind sc
find_names_to_bind (Elaborable_Apply fc fn av)
    = find_names_to_bind fn ++ find_names_to_bind av
find_names_to_bind (Elaborable_Automatic_Apply fc fn av)
    = find_names_to_bind fn ++ find_names_to_bind av
find_names_to_bind (Elaborable_Named_Apply _ fn _ av)
    = find_names_to_bind fn ++ find_names_to_bind av
find_names_to_bind (Elaborable_With_Apply fc fn av)
    = find_names_to_bind fn ++ find_names_to_bind av
find_names_to_bind (Elaborable_As_Pattern fc _ _ (UN (Basic n)) pat)
    = n :: find_names_to_bind pat
find_names_to_bind (Elaborable_As_Pattern fc _ _ n pat)
    = find_names_to_bind pat
find_names_to_bind (Elaborable_Must_Unify fc r pat)
    = find_names_to_bind pat
find_names_to_bind (Elaborable_Alternative fc u alts)
    = concatMap find_names_to_bind alts
find_names_to_bind (Elaborable_Delayed_Type fc _ ty) = find_names_to_bind ty
find_names_to_bind (Elaborable_Delay fc tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Force fc tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Quote fc tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Unquote fc tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Run_Elaborator fc _ tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Bind_Here _ _ tm) = find_names_to_bind tm
find_names_to_bind (Elaborable_Bind_Name _ (UN (Basic n))) = [n]
find_names_to_bind (Elaborable_Record_Update fc updates tm)
    = find_names_to_bind tm ++ concatMap (find_names_to_bind . getFieldUpdateTerm) updates
-- We've skipped lambda, case, let and local - rather than guess where the
-- name should be bound, leave it to the programmer
find_names_to_bind tm = []

export
findImplicits : RawImp' nm -> List String
findImplicits (Elaborable_Dependent_Function_Type fc rig p (Just (UN (Basic mn))) aty retty)
    = mn :: findImplicits aty ++ findImplicits retty
findImplicits (Elaborable_Dependent_Function_Type fc rig p mn aty retty)
    = findImplicits aty ++ findImplicits retty
findImplicits (Elaborable_Lambda fc rig p n aty sc)
    = findImplicits aty ++ findImplicits sc
findImplicits (Elaborable_Apply fc fn av)
    = findImplicits fn ++ findImplicits av
findImplicits (Elaborable_Automatic_Apply _ fn av)
    = findImplicits fn ++ findImplicits av
findImplicits (Elaborable_Named_Apply _ fn _ av)
    = findImplicits fn ++ findImplicits av
findImplicits (Elaborable_With_Apply fc fn av)
    = findImplicits fn ++ findImplicits av
findImplicits (Elaborable_As_Pattern fc _ _ n pat)
    = findImplicits pat
findImplicits (Elaborable_Must_Unify fc r pat)
    = findImplicits pat
findImplicits (Elaborable_Alternative fc u alts)
    = concatMap findImplicits alts
findImplicits (Elaborable_Delayed_Type fc _ ty) = findImplicits ty
findImplicits (Elaborable_Delay fc tm) = findImplicits tm
findImplicits (Elaborable_Force fc tm) = findImplicits tm
findImplicits (Elaborable_Quote fc tm) = findImplicits tm
findImplicits (Elaborable_Unquote fc tm) = findImplicits tm
findImplicits (Elaborable_Run_Elaborator fc _ tm) = findImplicits tm
findImplicits (Elaborable_Bind_Name _ (UN (Basic n))) = [n]
findImplicits (Elaborable_Record_Update fc updates tm)
    = findImplicits tm ++ concatMap (findImplicits . getFieldUpdateTerm) updates
findImplicits tm = []

-- Update the lhs of a clause so that any implicits named in the type are
-- bound as @-patterns (unless they're already explicitly bound or appear as
-- Elaborable_Bind_Name anywhere else in the pattern) so that they will be available on the
-- rhs
export
implicitsAs : {auto c : Ref Ctxt Defs} ->
              Int -> Defs ->
              (vars : List Name) ->
              RawImp -> Core RawImp
implicitsAs n defs ns tm
  = do let implicits = find_names_to_bind tm
       log "declare.def.lhs.implicits" 30 $ "Found implicits: " ++ show implicits
       setAs (map Just (ns ++ map (UN . Basic) implicits)) [] tm
  where
    -- Takes the function application expression which is the lhs of a clause
    -- and decomposes it into the underlying function symbol and the variables
    -- bound by appearing as arguments, and then passes this onto `findImps`.
    -- More precisely, implicit and explicit arguments are recorded separately,
    -- into `is` and `es` respectively.
    setAs : List (Maybe Name) -> List (Maybe Name) -> RawImp -> Core RawImp
    setAs is es (Elaborable_Apply loc f a)
        = do f' <- setAs is (Nothing :: es) f
             pure $ Elaborable_Apply loc f' a
    setAs is es (Elaborable_Automatic_Apply loc f a)
        = do f' <- setAs (Nothing :: is) es f
             pure $ Elaborable_Automatic_Apply loc f' a
    setAs is es (Elaborable_Named_Apply loc f n a)
        = do f' <- setAs (Just n :: is) (Just n :: es) f
             pure $ Elaborable_Named_Apply loc f' n a
    setAs is es (Elaborable_With_Apply loc f a)
        = do f' <- setAs is es f
             pure $ Elaborable_With_Apply loc f' a
    setAs is es (Elaborable_Name loc nm)
        -- #834 Use the (already) resolved name rather than the local one
        = case !(lookupTyExact (Resolved n) (gamma defs)) of
            Nothing =>
               do log "declare.def.lhs.implicits" 30 $
                    "Could not find variable " ++ show n
                  pure $ Elaborable_Name loc nm
            Just ty =>
               do ty' <- nf defs Env.empty ty
                  implicits <- findImps is es ns ty'
                  log "declare.def.lhs.implicits" 30 $
                    "\n  In the type of " ++ show n ++ ": " ++ show ty ++
                    "\n  Using locals: " ++ show ns ++
                    "\n  Found implicits: " ++ show implicits
                  pure $ impAs (virtualiseFC loc) implicits (Elaborable_Name loc nm)
      where
        -- If there's an @{c} in the list of given implicits, that's the next
        -- autoimplicit, so don't rewrite the LHS and update the list of given
        -- implicits
        updateNs : Name -> List (Maybe Name) -> Maybe (List (Maybe Name))
        updateNs n (Nothing :: ns) = Just ns
        updateNs n (x :: ns)
            = if Just n == x
                 then Just ns -- found it
                 else do ns' <- updateNs n ns
                         pure (x :: ns')
        updateNs n [] = Nothing

        -- Finds the missing implicits which should be added to the lhs of the
        -- original pattern clause.
        --
        -- The first argument, `ns`, specifies which implicit variables alredy
        -- appear in the lhs, and therefore need not be added.
        -- The second argument, `es`, specifies which *explicit* variables appear
        -- in the lhs: this is used to determine when to stop searching for further
        -- implicits to add.
        findImps : List (Maybe Name) -> List (Maybe Name) ->
                   List Name -> ClosedNF ->
                   Core (List (Name, PiInfo RawImp))
        -- #834 When we are in a local definition, we have an explicit telescope
        -- corresponding to the variables bound in the parent function.
        -- Parameter blocks also introduce additional telescope of implicit, auto,
        -- and explicit variables. So we first peel off all of the quantifiers
        -- corresponding to these variables.
        findImps ns es (_ :: locals) (NBind fc x (Pi {}) sc)
          = do body <- sc defs (toClosure defaultOpts Env.empty (Erased fc Placeholder))
               findImps ns es locals body
               -- ^ TODO? check that name of the pi matches name of local?
        -- don't add implicits coming after explicits that aren't given
        findImps ns es [] (NBind fc x (Pi _ _ Explicit _) sc)
            = do body <- sc defs (toClosure defaultOpts Env.empty (Erased fc Placeholder))
                 case es of
                   -- Explicits were skipped, therefore all explicits are given anyway
                   Just (UN Underscore) :: _ => findImps ns es [] body
                   -- Explicits weren't skipped, so we need to check
                   _ => case updateNs x es of
                          Nothing => pure [] -- explicit wasn't given
                          Just es' => findImps ns es' [] body
        -- if the implicit was given, skip it
        findImps ns es [] (NBind fc x (Pi _ _ AutoImplicit _) sc)
            = do body <- sc defs (toClosure defaultOpts Env.empty (Erased fc Placeholder))
                 case updateNs x ns of
                   Nothing => -- didn't find explicit call
                      pure $ (x, AutoImplicit) :: !(findImps ns es [] body)
                   Just ns' => findImps ns' es [] body
        findImps ns es [] (NBind fc x (Pi _ _ p _) sc)
            = do body <- sc defs (toClosure defaultOpts Env.empty (Erased fc Placeholder))
                 if Just x `elem` ns
                   then findImps ns es [] body
                   else pure $ (x, forgetDef p) :: !(findImps ns es [] body)
        findImps _ _ locals _
          = do log "declare.def.lhs.implicits" 50 $
                  "Giving up with the following locals left: " ++ show locals
               pure []

        impAs : FC -> List (Name, PiInfo RawImp) -> RawImp -> RawImp
        impAs loc' [] tm = tm
        impAs loc' ((nm@(UN (Basic _)), AutoImplicit) :: ns) tm
            = impAs loc' ns $
                 Elaborable_Named_Apply loc' tm nm (Elaborable_Bind_Name loc' nm)

        impAs loc' ((n, Implicit) :: ns) tm
            = impAs loc' ns $
                 Elaborable_Named_Apply loc' tm n
                     (Elaborable_As_Pattern loc' EmptyFC UseLeft n (Implicit loc' True))

        impAs loc' ((n, DefImplicit t) :: ns) tm
            = impAs loc' ns $
                 Elaborable_Named_Apply loc' tm n
                     (Elaborable_As_Pattern loc' EmptyFC UseLeft n (Implicit loc' True))

        impAs loc' (_ :: ns) tm = impAs loc' ns tm
    setAs is es tm = pure tm

||| `definedInBlock` is used to figure out which definitions should
||| receive the additional arguments introduced by a Parameters directive
export
definedInBlock : Namespace -> -- namespace to resolve names
                 List ImpDecl -> List Name
definedInBlock ns decls =
    Prelude.toList $ foldl (defName ns) empty decls
  where
    getName : ImpTy -> Name
    getName = (.tyName.val)

    getFieldName : Elaborable_Field -> Name
    getFieldName f = f.name.val

    expandNS : Namespace -> Name -> Name
    expandNS ns n
       = if ns == emptyNS then n else case n of
           UN {} => NS ns n
           MN {} => NS ns n
           DN {} => NS ns n
           _ => n

    defName : Namespace -> SortedSet Name -> ImpDecl -> SortedSet Name
    defName ns acc (Elaborable_Claim c) = insert (expandNS ns (getName c.val.type)) acc
    defName ns acc (Elaborable_Definition _ nm _) = insert (expandNS ns nm) acc
    defName ns acc (Elaborable_Data_Declaration _ _ _ (MkImpData _ n _ _ cons))
        = foldl (flip insert) acc $ expandNS ns n :: map (expandNS ns . getName) cons
    defName ns acc (Elaborable_Data_Declaration _ _ _ (MkImpLater _ n _)) = insert (expandNS ns n) acc
    defName ns acc (Elaborable_Parameter_Block _ _ pds) = foldl (defName ns) acc pds
    defName ns acc (Elaborable_Expected_Failure _ _ nds) = foldl (defName ns) acc nds
    defName ns acc (Elaborable_Namespace_Block _ n nds) = foldl (defName (ns <.> n)) acc nds
    defName ns acc (Elaborable_Record_Declaration _ fldns _ _ rec)
        = foldl (flip insert) acc $ expandNS ns rec.val.body.name.val :: all
      where
        fldns' : Namespace
        fldns' = maybe ns (\ f => ns <.> mkNamespace f) fldns

        toRF : Name -> Name
        toRF (UN (Basic n)) = UN (Field n)
        toRF n = n

        fnsUN : List Name
        fnsUN = map getFieldName rec.val.body.val

        fnsRF : List Name
        fnsRF = map toRF fnsUN

        -- Depending on %prefix_record_projections,
        -- the record may or may not produce prefix projections (fnsUN).
        --
        -- However, since definedInBlock is pure, we can't check that flag
        -- (and it would also be wrong if %prefix_record_projections appears
        -- inside the parameter block)
        -- so let's just declare all of them and some may go unused.
        all : List Name
        all = expandNS ns rec.val.header.name.val :: map (expandNS fldns') (fnsRF ++ fnsUN)

    defName ns acc (Elaborable_Pragma _ pns _) = foldl (flip insert) acc $ map (expandNS ns) pns
    defName _ acc _ = acc

export
is_elaborable_name : RawImp' nm -> Maybe (FC, nm)
is_elaborable_name (Elaborable_Name fc v) = Just (fc, v)
is_elaborable_name _ = Nothing

export
is_elaborable_bound_name : RawImp' nm -> Maybe (FC, Name)
is_elaborable_bound_name (Elaborable_Bind_Name fc v) = Just (fc, v)
is_elaborable_bound_name _ = Nothing

export
getFC : RawImp' nm -> FC
getFC (Elaborable_Name x _) = x
getFC (Elaborable_Dependent_Function_Type x _ _ _ _ _) = x
getFC (Elaborable_Lambda x _ _ _ _ _) = x
getFC (Elaborable_Binding x _ _ _ _ _ _) = x
getFC (Elaborable_Case x _ _ _ _) = x
getFC (Elaborable_Local_Definitions x _ _) = x
getFC (Elaborable_Case_Local_Definition x _ _ _ _) = x
getFC (Elaborable_Record_Update x _ _) = x
getFC (Elaborable_Apply x _ _) = x
getFC (Elaborable_Named_Apply x _ _ _) = x
getFC (Elaborable_Automatic_Apply x _ _) = x
getFC (Elaborable_With_Apply x _ _) = x
getFC (Elaborable_Search x _) = x
getFC (Elaborable_Alternative x _ _) = x
getFC (Elaborable_Rewrite x _ _) = x
getFC (Elaborable_Coerced x _) = x
getFC (Elaborable_Primitive_Value x _) = x
getFC (Elaborable_Hole x _) = x
getFC (Elaborable_Unification_Log x _ _) = x
getFC (Elaborable_Type_Universe x) = x
getFC (Elaborable_Bind_Name x _) = x
getFC (Elaborable_Bind_Here x _ _) = x
getFC (Elaborable_Must_Unify x _ _) = x
getFC (Elaborable_Delayed_Type x _ _) = x
getFC (Elaborable_Delay x _) = x
getFC (Elaborable_Force x _) = x
getFC (Elaborable_Quote x _) = x
getFC (Elaborable_Quote_Name x _) = x
getFC (Elaborable_Quote_Declarations x _) = x
getFC (Elaborable_Unquote x _) = x
getFC (Elaborable_Run_Elaborator x _ _) = x
getFC (Elaborable_As_Pattern x _ _ _ _) = x
getFC (Implicit x _) = x
getFC (Elaborable_With_Unambiguous_Names x _ _) = x

namespace ImpDecl

  public export
  getFC : ImpDecl' nm -> FC
  getFC (Elaborable_Claim c) = c.fc
  getFC (Elaborable_Data_Declaration fc _ _ _) = fc
  getFC (Elaborable_Definition fc _ _) = fc
  getFC (Elaborable_Parameter_Block fc _ _) = fc
  getFC (Elaborable_Record_Declaration fc _ _ _ _) = fc
  getFC (Elaborable_Expected_Failure fc _ _) = fc
  getFC (Elaborable_Namespace_Block fc _ _) = fc
  getFC (Elaborable_Transformation fc _ _ _) = fc
  getFC (Elaborable_Run_Elaborator_Declaration fc _) = fc
  getFC (Elaborable_Pragma fc _ _) = fc
  getFC (Elaborable_Logging _) = EmptyFC
  getFC (Elaborable_Builtin_Declaration fc _ _) = fc

public export
data Arg' nm
   = Explicit FC (RawImp' nm)
   | Auto     FC (RawImp' nm)
   | Named    FC Name (RawImp' nm)
%name Arg' arg

public export
Arg : Type
Arg = Arg' Name

public export
Kinded_Elaborable_Argument : Type
Kinded_Elaborable_Argument = Arg' KindedName

export
isExplicit : Arg' nm -> Maybe (FC, RawImp' nm)
isExplicit (Explicit fc t) = Just (fc, t)
isExplicit _ = Nothing

export
elaborable_argument_term : Arg' nm -> RawImp' nm
elaborable_argument_term (Explicit _ t) = t
elaborable_argument_term (Auto _ t) = t
elaborable_argument_term (Named _ _ t) = t

export
covering
Show nm => Show (Arg' nm) where
  show (Explicit fc t) = show t
  show (Auto fc t) = "@{" ++ show t ++ "}"
  show (Named fc n t) = "{" ++ show n ++ " = " ++ show t ++ "}"

export
getFnArgs : RawImp' nm -> List (Arg' nm) -> (RawImp' nm, List (Arg' nm))
getFnArgs (Elaborable_Apply fc f arg) args = getFnArgs f (Explicit fc arg :: args)
getFnArgs (Elaborable_Named_Apply fc f n arg) args = getFnArgs f (Named fc n arg :: args)
getFnArgs (Elaborable_Automatic_Apply fc f arg) args = getFnArgs f (Auto fc arg :: args)
getFnArgs tm args = (tm, args)

-- TODO: merge these definitions
namespace Arg
  export
  apply : RawImp' nm -> List (Arg' nm) -> RawImp' nm
  apply f (Explicit fc a :: args) = apply (Elaborable_Apply fc f a) args
  apply f (Auto fc a :: args) = apply (Elaborable_Automatic_Apply fc f a) args
  apply f (Named fc n a :: args) = apply (Elaborable_Named_Apply fc f n a) args
  apply f [] = f

export
apply : RawImp' nm -> List (RawImp' nm) -> RawImp' nm
apply f [] = f
apply f (x :: xs) =
  let fFC = getFC f in
  apply (Elaborable_Apply (fromMaybe fFC (mergeFC fFC (getFC x))) f x) xs

export
gapply : RawImp' nm -> List (Maybe Name, RawImp' nm) -> RawImp' nm
gapply f [] = f
gapply f (x :: xs) = gapply (uncurry (app f) x) xs where

  app : RawImp' nm -> Maybe Name -> RawImp' nm -> RawImp' nm
  app f Nothing   x = Elaborable_Apply (getFC f) f x
  app f (Just nm) x = Elaborable_Named_Apply (getFC f) f nm x


export
getFn : RawImp' nm -> RawImp' nm
getFn (Elaborable_Apply _ f _) = getFn f
getFn (Elaborable_With_Apply _ f _) = getFn f
getFn (Elaborable_Named_Apply _ f _ _) = getFn f
getFn (Elaborable_Automatic_Apply _ f _) = getFn f
getFn (Elaborable_As_Pattern _ _ _ _ f) = getFn f
getFn (Elaborable_Must_Unify _ _ f) = getFn f
getFn f = f

-- Log message with a RawImp
export
logRaw : {auto c : Ref Ctxt Defs} ->
         LogTopic -> Nat -> Lazy String -> RawImp -> Core ()
logRaw s n msg tm = log s n $ msg ++ ": " ++ show tm
