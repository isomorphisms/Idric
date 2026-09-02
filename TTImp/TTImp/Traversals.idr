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
  mapImpDecl (Elaboratable_Claim (MkWithData fc (Make_Elaboratable_Claim_Data rig vis opts ty)))
    = Elaboratable_Claim (MkWithData fc (Make_Elaboratable_Claim_Data rig vis (map mapFnOpt opts) (map mapTTImp ty)))
  mapImpDecl (Elaboratable_Data_Declaration fc vis mtreq dat) = Elaboratable_Data_Declaration fc vis mtreq (mapImpData dat)
  mapImpDecl (Elaboratable_Definition fc n cls) = Elaboratable_Definition fc n (map mapImpClause cls)
  mapImpDecl (Elaboratable_Parameter_Block fc params xs) = Elaboratable_Parameter_Block fc params (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaboratable_Record_Declaration fc mstr x y rec) = Elaboratable_Record_Declaration fc mstr x y (map mapImpRecord rec)
  mapImpDecl (Elaboratable_Expected_Failure fc mstr xs) = Elaboratable_Expected_Failure fc mstr (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaboratable_Namespace_Block fc mi xs) = Elaboratable_Namespace_Block fc mi (assert_total $ map mapImpDecl xs)
  mapImpDecl (Elaboratable_Transformation fc n t u) = Elaboratable_Transformation fc n (mapTTImp t) (mapTTImp u)
  mapImpDecl (Elaboratable_Run_Elaborator_Declaration fc t) = Elaboratable_Run_Elaborator_Declaration fc (mapTTImp t)
  mapImpDecl (Elaboratable_Pragma fc ns g) = Elaboratable_Pragma fc ns g
  mapImpDecl (Elaboratable_Logging x) = Elaboratable_Logging x
  mapImpDecl (Elaboratable_Builtin_Declaration fc x n) = Elaboratable_Builtin_Declaration fc x n

  export
  mapIFieldUpdate : Elaboratable_Field_Update' nm -> Elaboratable_Field_Update' nm
  mapIFieldUpdate (Elaboratable_Set_Field path t) = Elaboratable_Set_Field path (mapTTImp t)
  mapIFieldUpdate (Elaboratable_Apply_To_Field path t) = Elaboratable_Apply_To_Field path (mapTTImp t)

  export
  mapAltType : AltType' nm -> AltType' nm
  mapAltType FirstSuccess = FirstSuccess
  mapAltType Unique = Unique
  mapAltType (UniqueDefault t) = UniqueDefault (mapTTImp t)

  mapTTImp t@(Elaboratable_Name {}) = f t
  mapTTImp (Elaboratable_Dependent_Function_Type fc rig pinfo x argTy retTy)
    = f $ Elaboratable_Dependent_Function_Type fc rig (mapPiInfo pinfo) x (mapTTImp argTy) (mapTTImp retTy)
  mapTTImp (Elaboratable_Lambda fc rig pinfo x argTy lamTy)
    = f $ Elaboratable_Lambda fc rig (mapPiInfo pinfo) x (mapTTImp argTy) (mapTTImp lamTy)
  mapTTImp (Elaboratable_Binding fc lhsFC rig n nTy nVal scope)
    = f $ Elaboratable_Binding fc lhsFC rig n (mapTTImp nTy) (mapTTImp nVal) (mapTTImp scope)
  mapTTImp (Elaboratable_Case fc opts t ty cls)
    = f $ Elaboratable_Case fc opts (mapTTImp t) (mapTTImp ty) (assert_total $ map mapImpClause cls)
  mapTTImp (Elaboratable_Local_Definitions fc xs t)
    = f $ Elaboratable_Local_Definitions fc (assert_total $ map mapImpDecl xs) (mapTTImp t)
  mapTTImp (Elaboratable_Case_Local_Definition fc unm inm args t) = f $ Elaboratable_Case_Local_Definition fc unm inm args (mapTTImp t)
  mapTTImp (Elaboratable_Record_Update fc upds t) = f $ Elaboratable_Record_Update fc (assert_total map mapIFieldUpdate upds) (mapTTImp t)
  mapTTImp (Elaboratable_Apply fc t u) = f $ Elaboratable_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaboratable_Automatic_Apply fc t u) = f $ Elaboratable_Automatic_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaboratable_Named_Apply fc t n u) = f $ Elaboratable_Named_Apply fc (mapTTImp t) n (mapTTImp u)
  mapTTImp (Elaboratable_With_Apply fc t u) = f $ Elaboratable_With_Apply fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaboratable_Search fc depth) = f $ Elaboratable_Search fc depth
  mapTTImp (Elaboratable_Alternative fc alt ts) = f $ Elaboratable_Alternative fc (mapAltType alt) (assert_total map mapTTImp ts)
  mapTTImp (Elaboratable_Rewrite fc t u) = f $ Elaboratable_Rewrite fc (mapTTImp t) (mapTTImp u)
  mapTTImp (Elaboratable_Coerced fc t) = f $ Elaboratable_Coerced fc (mapTTImp t)
  mapTTImp (Elaboratable_Bind_Here fc bm t) = f $ Elaboratable_Bind_Here fc bm (mapTTImp t)
  mapTTImp (Elaboratable_Bind_Name fc str) = f $ Elaboratable_Bind_Name fc str
  mapTTImp (Elaboratable_As_Pattern fc nameFC side n t) = f $ Elaboratable_As_Pattern fc nameFC side n (mapTTImp t)
  mapTTImp (Elaboratable_Must_Unify fc x t) = f $ Elaboratable_Must_Unify fc x (mapTTImp t)
  mapTTImp (Elaboratable_Delayed_Type fc lz t) = f $ Elaboratable_Delayed_Type fc lz (mapTTImp t)
  mapTTImp (Elaboratable_Delay fc t) = f $ Elaboratable_Delay fc (mapTTImp t)
  mapTTImp (Elaboratable_Force fc t) = f $ Elaboratable_Force fc (mapTTImp t)
  mapTTImp (Elaboratable_Quote fc t) = f $ Elaboratable_Quote fc (mapTTImp t)
  mapTTImp (Elaboratable_Quote_Name fc n) = f $ Elaboratable_Quote_Name fc n
  mapTTImp (Elaboratable_Quote_Declarations fc xs) = f $ Elaboratable_Quote_Declarations fc (assert_total $ map mapImpDecl xs)
  mapTTImp (Elaboratable_Unquote fc t) = f $ Elaboratable_Unquote fc (mapTTImp t)
  mapTTImp (Elaboratable_Run_Elaborator fc re t) = f $ Elaboratable_Run_Elaborator fc re (mapTTImp t)
  mapTTImp (Elaboratable_Primitive_Value fc c) = f $ Elaboratable_Primitive_Value fc c
  mapTTImp (Elaboratable_Type_Universe fc) = f $ Elaboratable_Type_Universe fc
  mapTTImp (Elaboratable_Hole fc str) = f $ Elaboratable_Hole fc str
  mapTTImp (Elaboratable_Unification_Log fc x t) = f $ Elaboratable_Unification_Log fc x (mapTTImp t)
  mapTTImp (Implicit fc bindIfUnsolved) = f $ Implicit fc bindIfUnsolved
  mapTTImp (Elaboratable_With_Unambiguous_Names fc xs t) = f $ Elaboratable_With_Unambiguous_Names fc xs (mapTTImp t)
