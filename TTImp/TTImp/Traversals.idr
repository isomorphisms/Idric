module TTImp.TTImp.Traversals

import Core.TT
import TTImp.TTImp
import Core.WithData

%default total

parameters (f : RawImp' nm -> RawImp' nm)

  export
  mapTTImp : RawImp' nm -> RawImp' nm

  export
  mapPiInfo : PiInfo (RawImp' nm) -> PiInfo (RawImp' nm)
  mapPiInfo Implicit = Implicit
  mapPiInfo Explicit = Explicit
  mapPiInfo AutoImplicit = AutoImplicit
  mapPiInfo (DefImplicit t) = DefImplicit (mapTTImp t)

  export
  mapImpClause : ImpClause' nm -> ImpClause' nm
  mapImpClause (PatClause fc lhs rhs) = PatClause fc (mapTTImp lhs) (mapTTImp rhs)
  mapImpClause (WithClause fc lhs rig wval prf flags cls)
    = WithClause fc (mapTTImp lhs) rig (mapTTImp wval) prf flags (assert_total $ map mapImpClause cls)
  mapImpClause (ImpossibleClause fc lhs) = ImpossibleClause fc (mapTTImp lhs)

  export
  mapFnOpt : FnOpt' nm -> FnOpt' nm
  mapFnOpt Unsafe = Unsafe
  mapFnOpt Inline = Inline
  mapFnOpt NoInline = NoInline
  mapFnOpt Deprecate = Deprecate
  mapFnOpt TCInline = TCInline
  mapFnOpt (Hint b) = Hint b
  mapFnOpt (GlobalHint b) = GlobalHint b
  mapFnOpt ExternFn = ExternFn
  mapFnOpt (ForeignFn ts) = ForeignFn (map mapTTImp ts)
  mapFnOpt (ForeignExport ts) = ForeignExport (map mapTTImp ts)
  mapFnOpt Invertible = Invertible
  mapFnOpt (Totality treq) = Totality treq
  mapFnOpt Macro = Macro
  mapFnOpt (SpecArgs ns) = SpecArgs ns

  export
  mapImpData : ImpData' nm -> ImpData' nm
  mapImpData (MkImpData fc n tycon opts datacons)
    = MkImpData fc n (map mapTTImp tycon) opts (map (map mapTTImp) datacons)
  mapImpData (MkImpLater fc n tycon) = MkImpLater fc n (mapTTImp tycon)

  export
  mapImpRecord : ImpRecordData nm -> ImpRecordData nm
  mapImpRecord (MkImpRecord header body)
    = MkImpRecord (map (map (map (map mapTTImp))) header)
                  (map (map (map (map mapTTImp))) body)

  export
  mapImpDecl : ImpDecl' nm -> ImpDecl' nm
  mapImpDecl (Elaborable_Claim (MkWithData fc (Make_Elaborable_Claim_Data rig vis opts ty)))
    = Elaborable_Claim (MkWithData fc (Make_Elaborable_Claim_Data rig vis (map mapFnOpt opts) (map mapTTImp ty)))
  mapImpDecl (Elaborable_Data_Declaration fc vis mtreq dat) = Elaborable_Data_Declaration fc vis mtreq (mapImpData dat)
  mapImpDecl (Elaborable_Definition fc n cls) = Elaborable_Definition fc n (map mapImpClause cls)
  mapImpDecl (Elaborable_Parameter_Block fc params xs) = Elaborable_Parameter_Block fc params (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaborable_Record_Declaration fc mstr x y rec) = Elaborable_Record_Declaration fc mstr x y (map mapImpRecord rec)
  mapImpDecl (Elaborable_Expected_Failure fc mstr xs) = Elaborable_Expected_Failure fc mstr (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaborable_Namespace_Block fc mi xs) = Elaborable_Namespace_Block fc mi (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaborable_Transformation fc n t u) = Elaborable_Transformation fc n (mapTTImp t) (mapTTImp u)
  mapImpDecl (Elaborable_Run_Elaborator_Declaration fc t) = Elaborable_Run_Elaborator_Declaration fc (mapTTImp t)
  mapImpDecl (Elaborable_Pragma fc ns g) = Elaborable_Pragma fc ns g
  mapImpDecl (Elaborable_Logging x) = Elaborable_Logging x
  mapImpDecl (Elaborable_Builtin_Declaration fc x n) = Elaborable_Builtin_Declaration fc x n

  export
  mapIFieldUpdate : Elaborable_Field_Update' nm -> Elaborable_Field_Update' nm
  mapIFieldUpdate (Elaborable_Set_Field path t) = Elaborable_Set_Field path (mapTTImp t)
  mapIFieldUpdate (Elaborable_Apply_To_Field path t) = Elaborable_Apply_To_Field path (mapTTImp t)

  export
  mapAltType : AltType' nm -> AltType' nm
  mapAltType FirstSuccess = FirstSuccess
  mapAltType Unique = Unique
  mapAltType (UniqueDefault t) = UniqueDefault (mapTTImp t)

  mapTTImp t@(Elaborable_Name {}) = f t
  mapTTImp (Elaborable_Dependent_Function_Type fc rig pinfo x argTy retTy)
    = f $ Elaborable_Dependent_Function_Type fc rig (mapPiInfo pinfo) x (mapTTImp argTy) (mapTTImp retTy)
  mapTTImp (Elaborable_Lambda fc rig pinfo x argTy lamTy)
    = f $ Elaborable_Lambda fc rig (mapPiInfo pinfo) x (mapTTImp argTy) (mapTTImp lamTy)
  mapTTImp (Elaborable_Binding fc lhsFC rig n nTy nVal scope)
    = f $ Elaborable_Binding fc lhsFC rig n (mapTTImp nTy) (mapTTImp nVal) (mapTTImp scope)
  mapTTImp (Elaborable_Case fc opts t ty cls)
    = f $ Elaborable_Case fc opts (mapTTImp t) (mapTTImp ty) (assert_total $ map mapImpClause cls)
  mapTTImp (Elaborable_Local_Definitions fc xs t)
    = f $ Elaborable_Local_Definitions fc (assert_total $ map mapImpDecl xs) (mapTTImp t)
  mapTTImp (Elaborable_Case_Local_Definition fc unm inm args t) = f $ Elaborable_Case_Local_Definition fc unm inm args (mapTTImp t)
  mapTTImp (Elaborable_Record_Update fc upds t) = f $ Elaborable_Record_Update fc (assert_total map mapIFieldUpdate upds) (mapTTImp t)
  mapTTImp (Elaborable_Apply fc t u) = f $ Elaborable_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaborable_Automatic_Apply fc t u) = f $ Elaborable_Automatic_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaborable_Named_Apply fc t n u) = f $ Elaborable_Named_Apply fc (mapTTImp t) n (mapTTImp u)
  mapTTImp (Elaborable_With_Apply fc t u) = f $ Elaborable_With_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaborable_Search fc depth) = f $ Elaborable_Search fc depth
  mapTTImp (Elaborable_Alternative fc alt ts) = f $ Elaborable_Alternative fc (mapAltType alt) (assert_total map mapTTImp ts)
  mapTTImp (Elaborable_Rewrite fc t u) = f $ Elaborable_Rewrite fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaborable_Coerced fc t) = f $ Elaborable_Coerced fc (mapTTImp t)
  mapTTImp (Elaborable_Bind_Here fc bm t) = f $ Elaborable_Bind_Here fc bm (mapTTImp t)
  mapTTImp (Elaborable_Bind_Name fc str) = f $ Elaborable_Bind_Name fc str
  mapTTImp (Elaborable_As_Pattern fc nameFC side n t) = f $ Elaborable_As_Pattern fc nameFC side n (mapTTImp t)
  mapTTImp (Elaborable_Must_Unify fc x t) = f $ Elaborable_Must_Unify fc x (mapTTImp t)
  mapTTImp (Elaborable_Delayed_Type fc lz t) = f $ Elaborable_Delayed_Type fc lz (mapTTImp t)
  mapTTImp (Elaborable_Delay fc t) = f $ Elaborable_Delay fc (mapTTImp t)
  mapTTImp (Elaborable_Force fc t) = f $ Elaborable_Force fc (mapTTImp t)
  mapTTImp (Elaborable_Quote fc t) = f $ Elaborable_Quote fc (mapTTImp t)
  mapTTImp (Elaborable_Quote_Name fc n) = f $ Elaborable_Quote_Name fc n
  mapTTImp (Elaborable_Quote_Declarations fc xs) = f $ Elaborable_Quote_Declarations fc (assert_total $ map mapImpDecl xs)
  mapTTImp (Elaborable_Unquote fc t) = f $ Elaborable_Unquote fc (mapTTImp t)
  mapTTImp (Elaborable_Run_Elaborator fc re t) = f $ Elaborable_Run_Elaborator fc re (mapTTImp t)
  mapTTImp (Elaborable_Primitive_Value fc c) = f $ Elaborable_Primitive_Value fc c
  mapTTImp (Elaborable_Type_Universe fc) = f $ Elaborable_Type_Universe fc
  mapTTImp (Elaborable_Hole fc str) = f $ Elaborable_Hole fc str
  mapTTImp (Elaborable_Unification_Log fc x t) = f $ Elaborable_Unification_Log fc x (mapTTImp t)
  mapTTImp (Implicit fc bindIfUnsolved) = f $ Implicit fc bindIfUnsolved
  mapTTImp (Elaborable_With_Unambiguous_Names fc xs t) = f $ Elaborable_With_Unambiguous_Names fc xs (mapTTImp t)
