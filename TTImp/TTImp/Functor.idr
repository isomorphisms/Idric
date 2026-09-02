module TTImp.TTImp.Functor

import Core.TT
import Core.WithData
import TTImp.TTImp

%default covering

mutual

  export
  Functor RawImp' where
    map f (Elaboratable_Name fc nm) = Elaboratable_Name fc (f nm)
    map f (Elaboratable_Dependent_Function_Type fc rig info nm a sc)
      = Elaboratable_Dependent_Function_Type fc rig (map (map f) info) nm (map f a) (map f sc)
    map f (Elaboratable_Lambda fc rig info nm a sc)
      = Elaboratable_Lambda fc rig (map (map f) info) nm (map f a) (map f sc)
    map f (Elaboratable_Binding fc lhsFC rig nm ty val sc)
      = Elaboratable_Binding fc lhsFC rig nm (map f ty) (map f val) (map f sc)
    map f (Elaboratable_Case fc opts sc ty cls)
      = Elaboratable_Case fc (map (map f) opts) (map f sc) (map f ty) (map (map f) cls)
    map f (Elaboratable_Local_Definitions fc ds sc)
      = Elaboratable_Local_Definitions fc (map (map f) ds) (map f sc)
    map f (Elaboratable_Case_Local_Definition fc userN intN args sc)
      = Elaboratable_Case_Local_Definition fc userN intN args (map f sc)
    map f (Elaboratable_Record_Update fc upds rec)
      = Elaboratable_Record_Update fc (map (map f) upds) (map f rec)
    map f (Elaboratable_Apply fc fn t)
      = Elaboratable_Apply fc (map f fn) (map f t)
    map f (Elaboratable_Automatic_Apply fc fn t)
      = Elaboratable_Automatic_Apply fc (map f fn) (map f t)
    map f (Elaboratable_Named_Apply fc fn nm t)
      = Elaboratable_Named_Apply fc (map f fn) nm (map f t)
    map f (Elaboratable_With_Apply fc fn t)
      = Elaboratable_With_Apply fc (map f fn) (map f t)
    map f (Elaboratable_Search fc n)
      = Elaboratable_Search fc n
    map f (Elaboratable_Alternative fc alt ts)
      = Elaboratable_Alternative fc (map f alt) (map (map f) ts)
    map f (Elaboratable_Rewrite fc e t)
      = Elaboratable_Rewrite fc (map f e) (map f t)
    map f (Elaboratable_Coerced fc e)
      = Elaboratable_Coerced fc (map f e)
    map f (Elaboratable_Bind_Here fc bd t)
      = Elaboratable_Bind_Here fc bd (map f t)
    map f (Elaboratable_Bind_Name fc str)
      = Elaboratable_Bind_Name fc str
    map f (Elaboratable_As_Pattern fc nmFC side nm t)
      = Elaboratable_As_Pattern fc nmFC side nm (map f t)
    map f (Elaboratable_Must_Unify fc reason t)
      = Elaboratable_Must_Unify fc reason (map f t)
    map f (Elaboratable_Delayed_Type fc reason t)
      = Elaboratable_Delayed_Type fc reason (map f t)
    map f (Elaboratable_Delay fc t)
      = Elaboratable_Delay fc (map f t)
    map f (Elaboratable_Force fc t)
      = Elaboratable_Force fc (map f t)
    map f (Elaboratable_Quote fc t)
      = Elaboratable_Quote fc (map f t)
    map f (Elaboratable_Quote_Name fc nm)
      = Elaboratable_Quote_Name fc nm
    map f (Elaboratable_Quote_Declarations fc ds)
      = Elaboratable_Quote_Declarations fc (map (map f) ds)
    map f (Elaboratable_Unquote fc t)
      = Elaboratable_Unquote fc (map f t)
    map f (Elaboratable_Run_Elaborator fc re t)
      = Elaboratable_Run_Elaborator fc re (map f t)
    map f (Elaboratable_Primitive_Value fc c)
      = Elaboratable_Primitive_Value fc c
    map f (Elaboratable_Type_Universe fc)
      = Elaboratable_Type_Universe fc
    map f (Elaboratable_Hole fc str)
      = Elaboratable_Hole fc str
    map f (Elaboratable_Unification_Log fc lvl t)
      = Elaboratable_Unification_Log fc lvl (map f t)
    map f (Implicit fc b)
      = Implicit fc b
    map f (Elaboratable_With_Unambiguous_Names fc ns t)
      = Elaboratable_With_Unambiguous_Names fc ns (map f t)

  export
  Functor ImpClause' where
    map f (PatClause fc lhs rhs)
      = PatClause fc (map f lhs) (map f rhs)
    map f (WithClause fc lhs rig wval prf flags xs)
      = WithClause fc (map f lhs) rig (map f wval) prf flags (map (map f) xs)
    map f (ImpossibleClause fc lhs)
      = ImpossibleClause fc (map f lhs)

  export
  Functor Elaboratable_Claim_Data where
    map f (Make_Elaboratable_Claim_Data rig vis opts ty)
      = Make_Elaboratable_Claim_Data rig vis (map (map f) opts) (map (map f) ty)

  export
  Functor ImpDecl' where
    map f (Elaboratable_Claim c)
      = Elaboratable_Claim (map (map f) c)
    map f (Elaboratable_Data_Declaration fc vis mbtot dt)
      = Elaboratable_Data_Declaration fc vis mbtot (map f dt)
    map f (Elaboratable_Definition fc nm cls)
      = Elaboratable_Definition fc nm (map (map f) cls)
    map f (Elaboratable_Parameter_Block fc ps ds)
      = Elaboratable_Parameter_Block fc (map (map (map (map f))) ps) (map (map f) ds)
    map f (Elaboratable_Record_Declaration fc cs vis mbtot rec)
      = Elaboratable_Record_Declaration fc cs vis mbtot (map (map f) rec)
    map f (Elaboratable_Expected_Failure fc msg ds)
      = Elaboratable_Expected_Failure fc msg (map (map f) ds)
    map f (Elaboratable_Namespace_Block fc ns ds)
      = Elaboratable_Namespace_Block fc ns (map (map f) ds)
    map f (Elaboratable_Transformation fc n lhs rhs)
      = Elaboratable_Transformation fc n (map f lhs) (map f rhs)
    map f (Elaboratable_Run_Elaborator_Declaration fc t)
      = Elaboratable_Run_Elaborator_Declaration fc (map f t)
    map f (Elaboratable_Pragma fc xs k) = Elaboratable_Pragma fc xs k
    map f (Elaboratable_Logging x) = Elaboratable_Logging x
    map f (Elaboratable_Builtin_Declaration fc ty n) = Elaboratable_Builtin_Declaration fc ty n

  export
  Functor FnOpt' where
    map f Unsafe = Unsafe
    map f Inline = Inline
    map f NoInline = NoInline
    map f Deprecate = Deprecate
    map f TCInline = TCInline
    map f (Hint b) = Hint b
    map f (GlobalHint b) = GlobalHint b
    map f ExternFn = ExternFn
    map f (ForeignFn ts) = ForeignFn (map (map f) ts)
    map f (ForeignExport ts) = ForeignExport (map (map f) ts)
    map f Invertible = Invertible
    map f (Totality tot) = Totality tot
    map f Macro = Macro
    map f (SpecArgs ns) = SpecArgs ns

  export
  Functor ImpData' where
    map f (MkImpData fc n tycon opts datacons)
      = MkImpData fc n (map (map f) tycon) opts (map (map (map f)) datacons)
    map f (MkImpLater fc n tycon)
      = MkImpLater fc n (map f tycon)

  export
  Functor ImpRecordData where
    map f (MkImpRecord header body)
      = MkImpRecord (map (map (map (map (map f)))) header)
                    (map (map (map (map (map f)))) body)

  export
  Functor Elaboratable_Field_Update' where
    map f (Elaboratable_Set_Field path t) = Elaboratable_Set_Field path (map f t)
    map f (Elaboratable_Apply_To_Field path t) = Elaboratable_Apply_To_Field path (map f t)

  export
  Functor AltType' where
    map f FirstSuccess = FirstSuccess
    map f Unique = Unique
    map f (UniqueDefault t) = UniqueDefault (map f t)
