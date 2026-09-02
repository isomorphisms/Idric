# Readable TTImp names

This branch spells out the constructor vocabulary of Idris's compiler-internal raw, elaboratable term layer.
`Elaboratable_` replaces the unexplained one-letter constructor prefix and keeps these names distinct from the checked core term constructors.
The compiler source itself describes this layer as the raw form which is elaborated into checked core terms.

## Main reading vocabulary

| Upstream name | Name on this branch | Meaning |
|---|---|---|
| `IVar` | `Elaboratable_Name` | a referenced name |
| `IApp` | `Elaboratable_Apply` | apply one term to another |
| `ILet` | `Elaboratable_Binding` | a local binding |
| `IPi` | `Elaboratable_Dependent_Function_Type` | a function type whose result may depend on its input |
| `ILam` | `Elaboratable_Lambda` | a lambda expression |
| `ICase` | `Elaboratable_Case` | a case expression |

## Complete compiler-internal rename

| Upstream name | Name on this branch | Source occurrences changed |
|---|---|---:|
| `IAlternative` | `Elaboratable_Alternative` | 46 |
| `IApp` | `Elaboratable_Apply` | 108 |
| `IArg` | `Kinded_Elaboratable_Argument` | 3 |
| `IAs` | `Elaboratable_As_Pattern` | 59 |
| `IAutoApp` | `Elaboratable_Automatic_Apply` | 82 |
| `IBindHere` | `Elaboratable_Bind_Here` | 35 |
| `IBindVar` | `Elaboratable_Bind_Name` | 54 |
| `IBuiltin` | `Elaboratable_Builtin_Declaration` | 15 |
| `ICase` | `Elaboratable_Case` | 34 |
| `ICaseLocal` | `Elaboratable_Case_Local_Definition` | 15 |
| `IClaim` | `Elaboratable_Claim` | 39 |
| `IClaimData` | `Elaboratable_Claim_Data` | 6 |
| `ICoerced` | `Elaboratable_Coerced` | 21 |
| `IData` | `Elaboratable_Data_Declaration` | 35 |
| `IDef` | `Elaboratable_Definition` | 46 |
| `IDelay` | `Elaboratable_Delay` | 34 |
| `IDelayed` | `Elaboratable_Delayed_Type` | 35 |
| `IFail` | `Elaboratable_Expected_Failure` | 21 |
| `IField` | `Elaboratable_Field` | 15 |
| `IField'` | `Elaboratable_Field'` | 6 |
| `IFieldUpdate` | `Elaboratable_Field_Update` | 16 |
| `IFieldUpdate'` | `Elaboratable_Field_Update'` | 15 |
| `IForce` | `Elaboratable_Force` | 34 |
| `IHole` | `Elaboratable_Hole` | 24 |
| `IImpClause` | `Kinded_Elaboratable_Clause` | 3 |
| `ILam` | `Elaboratable_Lambda` | 61 |
| `ILet` | `Elaboratable_Binding` | 28 |
| `ILocal` | `Elaboratable_Local_Definitions` | 30 |
| `ILog` | `Elaboratable_Logging` | 17 |
| `IMustUnify` | `Elaboratable_Must_Unify` | 39 |
| `INamedApp` | `Elaboratable_Named_Apply` | 101 |
| `INamespace` | `Elaboratable_Namespace_Block` | 29 |
| `IParameters` | `Elaboratable_Parameter_Block` | 22 |
| `IPi` | `Elaboratable_Dependent_Function_Type` | 75 |
| `IPragma` | `Elaboratable_Pragma` | 45 |
| `IPrimVal` | `Elaboratable_Primitive_Value` | 45 |
| `IQuote` | `Elaboratable_Quote` | 25 |
| `IQuoteDecl` | `Elaboratable_Quote_Declarations` | 18 |
| `IQuoteName` | `Elaboratable_Quote_Name` | 17 |
| `IRawImp` | `Kinded_Elaboratable_Term` | 25 |
| `IRecord` | `Elaboratable_Record_Declaration` | 23 |
| `IRewrite` | `Elaboratable_Rewrite` | 22 |
| `IRunElab` | `Elaboratable_Run_Elaborator` | 17 |
| `IRunElabDecl` | `Elaboratable_Run_Elaborator_Declaration` | 14 |
| `ISearch` | `Elaboratable_Search` | 22 |
| `ISetField` | `Elaboratable_Set_Field` | 22 |
| `ISetFieldApp` | `Elaboratable_Apply_To_Field` | 22 |
| `ITransform` | `Elaboratable_Transformation` | 18 |
| `IType` | `Elaboratable_Type_Universe` | 25 |
| `IUnifyLog` | `Elaboratable_Unification_Log` | 13 |
| `IUnquote` | `Elaboratable_Unquote` | 23 |
| `IUpdate` | `Elaboratable_Record_Update` | 35 |
| `IVar` | `Elaboratable_Name` | 206 |
| `IWithApp` | `Elaboratable_With_Apply` | 52 |
| `IWithUnambigNames` | `Elaboratable_With_Unambiguous_Names` | 16 |
| `MkIClaimData` | `Make_Elaboratable_Claim_Data` | 29 |
| `findIBinds` | `find_names_to_bind` | 49 |
| `isIBindVar` | `is_elaboratable_bound_name` | 4 |
| `isIPrimVal` | `is_primitive_value` | 4 |
| `isIVar` | `is_elaboratable_name` | 4 |
| `unIArg` | `elaboratable_argument_term` | 4 |

## Reflection compatibility boundary

The public constructors in `_/libs/base/Language/Reflection/TTImp.idr` retain their upstream names.
Those names are part of the elaborator-reflection interface and are embedded in the checked-in bootstrap compiler.
`TTImp/Reflect.idr` uses readable constructors internally while translating to and from the established serialized names.
