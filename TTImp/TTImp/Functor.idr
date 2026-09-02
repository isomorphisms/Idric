module TTImp.TTImp.Functor

import Core.TT
import Core.WithData
import TTImp.TTImp

%default covering

mutual

  export
  Functor RawImp' where
    map f (Elaborable_Name fc nm) = Elaborable_Name fc (f nm)
    map f (Elaborable_Dependent_Function_Type fc rig info nm a sc)
      = Elaborable_Dependent_Function_Type fc rig (map (map f) info) nm (map f a) (map f sc)
    map f (Elaborable_Lambda fc rig info nm a sc)
      = Elaborable_Lambda fc rig (map (map f) info) nm (map f a) (map f sc)
    map f (Elaborable_Binding fc lhsFC rig nm ty val sc)
      = Elaborable_Binding fc lhsFC rig nm (map f ty) (map f val) (map f sc)
    map f (Elaborable_Case fc opts sc ty cls)
      = Elaborable_Case fc (map (map f) opts) (map f sc) (map f ty) (map (map f) cls)
    map f (Elaborable_Local_Definitions fc ds sc)
      = Elaborable_Local_Definitions fc (map (map f) ds) (map f sc)
    map f (Elaborable_Case_Local_Definition fc userN intN args sc)
      = Elaborable_Case_Local_Definition fc userN intN args (map f sc)
    map f (Elaborable_Record_Update fc upds rec)
      = Elaborable_Record_Update fc (map (map f) upds) (map f rec)
    map f (Elaborable_Apply fc fn t)
      = Elaborable_Apply fc (map f fn) (map f t)
    map f (Elaborable_Automatic_Apply fc fn t)
      = Elaborable_Automatic_Apply fc (map f fn) (map f t)
    map f (Elaborable_Named_Apply fc fn nm t)
      = Elaborable_Named_Apply fc (map f fn) nm (map f t)
    map f (Elaborable_With_Apply fc fn t)
      = Elaborable_With_Apply fc (map f fn) (map f t)
    map f (Elaborable_Search fc n)
      = Elaborable_Search fc n
    map f (Elaborable_Alternative fc alt ts)
      = Elaborable_Alternative fc (map f alt) (map (map f) ts)
    map f (Elaborable_Rewrite fc e t)
      = Elaborable_Rewrite fc (map f e) (map f t)
    map f (Elaborable_Coerced fc e)
      = Elaborable_Coerced fc (map f e)
    map f (Elaborable_Bind_Here fc bd t)
      = Elaborable_Bind_Here fc bd (map f t)
    map f (Elaborable_Bind_Name fc str)
      = Elaborable_Bind_Name fc str
    map f (Elaborable_As_Pattern fc nmFC side nm t)
      = Elaborable_As_Pattern fc nmFC side nm (map f t)
    map f (Elaborable_Must_Unify fc reason t)
      = Elaborable_Must_Unify fc reason (map f t)
    map f (Elaborable_Delayed_Type fc reason t)
      = Elaborable_Delayed_Type fc reason (map f t)
    map f (Elaborable_Delay fc t)
      = Elaborable_Delay fc (map f t)
    map f (Elaborable_Force fc t)
      = Elaborable_Force fc (map f t)
    map f (Elaborable_Quote fc t)
      = Elaborable_Quote fc (map f t)
    map f (Elaborable_Quote_Name fc nm)
      = Elaborable_Quote_Name fc nm
    map f (Elaborable_Quote_Declarations fc ds)
      = Elaborable_Quote_Declarations fc (map (map f) ds)
    map f (Elaborable_Unquote fc t)
      = Elaborable_Unquote fc (map f t)
    map f (Elaborable_Run_Elaborator fc re t)
      = Elaborable_Run_Elaborator fc re (map f t)
    map f (Elaborable_Primitive_Value fc c)
      = Elaborable_Primitive_Value fc c
    map f (Elaborable_Type_Universe fc)
      = Elaborable_Type_Universe fc
    map f (Elaborable_Hole fc str)
      = Elaborable_Hole fc str
    map f (Elaborable_Unification_Log fc lvl t)
      = Elaborable_Unification_Log fc lvl (map f t)
    map f (Implicit fc b)
      = Implicit fc b
    map f (Elaborable_With_Unambiguous_Names fc ns t)
      = Elaborable_With_Unambiguous_Names fc ns (map f t)

  export
  Functor ImpClause' where
    map f (PatClause fc lhs rhs)
      = PatClause fc (map f lhs) (map f rhs)
    map f (WithClause fc lhs rig wval prf flags xs)
      = WithClause fc (map f lhs) rig (map f wval) prf flags (map (map f) xs)
    map f (ImpossibleClause fc lhs)
      = ImpossibleClause fc (map f lhs)

  export
  Functor Elaborable_Claim_Data where
    map f (Make_Elaborable_Claim_Data rig vis opts ty)
      = Make_Elaborable_Claim_Data rig vis (map (map f) opts) (map (map f) ty)

  export
  Functor ImpDecl' where
    map f (Elaborable_Claim c)
      = Elaborable_Claim (map (map f) c)
    map f (Elaborable_Data_Declaration fc vis mbtot dt)
      = Elaborable_Data_Declaration fc vis mbtot (map f dt)
    map f (Elaborable_Definition fc nm cls)
      = Elaborable_Definition fc nm (map (map f) cls)
    map f (Elaborable_Parameter_Block fc ps ds)
      = Elaborable_Parameter_Block fc (map (map (map (map f))) ps) (map (map f) ds)
    map f (Elaborable_Record_Declaration fc cs vis mbtot rec)
      = Elaborable_Record_Declaration fc cs vis mbtot (map (map f) rec)
    map f (Elaborable_Expected_Failure fc msg ds)
      = Elaborable_Expected_Failure fc msg (map (map f) ds)
    map f (Elaborable_Namespace_Block fc ns ds)
      = Elaborable_Namespace_Block fc ns (map (map f) ds)
    map f (Elaborable_Transformation fc n lhs rhs)
      = Elaborable_Transformation fc n (map f lhs) (map f rhs)
    map f (Elaborable_Run_Elaborator_Declaration fc t)
      = Elaborable_Run_Elaborator_Declaration fc (map f t)
    map f (Elaborable_Pragma fc xs k) = Elaborable_Pragma fc xs k
    map f (Elaborable_Logging x) = Elaborable_Logging x
    map f (Elaborable_Builtin_Declaration fc ty n) = Elaborable_Builtin_Declaration fc ty n

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
  Functor Elaborable_Field_Update' where
    map f (Elaborable_Set_Field path t) = Elaborable_Set_Field path (map f t)
    map f (Elaborable_Apply_To_Field path t) = Elaborable_Apply_To_Field path (map f t)

  export
  Functor AltType' where
    map f FirstSuccess = FirstSuccess
    map f Unique = Unique
    map f (UniqueDefault t) = UniqueDefault (map f t)
