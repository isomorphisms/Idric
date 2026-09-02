# Readable TTImp names

This branch spells out the constructor vocabulary of Idris's compiler-internal raw, elaborable term layer.
`Elaborable_` replaces the unexplained one-letter constructor prefix and keeps these names distinct from the checked core term constructors.
The compiler source itself describes this layer as the raw form which is elaborated into checked core terms.

## Main reading vocabulary

| Upstream name | Name on this branch | Meaning |
|---|---|---|
| `IVar` | `Elaborable_Name` | a referenced name |
| `IApp` | `Elaborable_Apply` | apply one term to another |
| `ILet` | `Elaborable_Binding` | a local binding |
| `IPi` | `Elaborable_Dependent_Function_Type` | a function type whose result may depend on its input |
| `ILam` | `Elaborable_Lambda` | a lambda expression |
| `ICase` | `Elaborable_Case` | a case expression |

## Complete compiler-internal rename

| Upstream name | Name on this branch | Source occurrences changed |
|---|---|---:|
| `IAlternative` | `Elaborable_Alternative` | 46 |
| `IApp` | `Elaborable_Apply` | 108 |
| `IArg` | `Kinded_Elaborable_Argument` | 3 |
| `IAs` | `Elaborable_As_Pattern` | 59 |
| `IAutoApp` | `Elaborable_Automatic_Apply` | 82 |
| `IBindHere` | `Elaborable_Bind_Here` | 35 |
| `IBindVar` | `Elaborable_Bind_Name` | 54 |
| `IBuiltin` | `Elaborable_Builtin_Declaration` | 15 |
| `ICase` | `Elaborable_Case` | 34 |
| `ICaseLocal` | `Elaborable_Case_Local_Definition` | 15 |
| `IClaim` | `Elaborable_Claim` | 39 |
| `IClaimData` | `Elaborable_Claim_Data` | 6 |
| `ICoerced` | `Elaborable_Coerced` | 21 |
| `IData` | `Elaborable_Data_Declaration` | 35 |
| `IDef` | `Elaborable_Definition` | 46 |
| `IDelay` | `Elaborable_Delay` | 34 |
| `IDelayed` | `Elaborable_Delayed_Type` | 35 |
| `IFail` | `Elaborable_Expected_Failure` | 21 |
| `IField` | `Elaborable_Field` | 15 |
| `IField'` | `Elaborable_Field'` | 6 |
| `IFieldUpdate` | `Elaborable_Field_Update` | 16 |
| `IFieldUpdate'` | `Elaborable_Field_Update'` | 15 |
| `IForce` | `Elaborable_Force` | 34 |
| `IHole` | `Elaborable_Hole` | 24 |
| `IImpClause` | `Kinded_Elaborable_Clause` | 3 |
| `ILam` | `Elaborable_Lambda` | 61 |
| `ILet` | `Elaborable_Binding` | 28 |
| `ILocal` | `Elaborable_Local_Definitions` | 30 |
| `ILog` | `Elaborable_Logging` | 17 |
| `IMustUnify` | `Elaborable_Must_Unify` | 39 |
| `INamedApp` | `Elaborable_Named_Apply` | 101 |
| `INamespace` | `Elaborable_Namespace_Block` | 29 |
| `IParameters` | `Elaborable_Parameter_Block` | 22 |
| `IPi` | `Elaborable_Dependent_Function_Type` | 75 |
| `IPragma` | `Elaborable_Pragma` | 45 |
| `IPrimVal` | `Elaborable_Primitive_Value` | 45 |
| `IQuote` | `Elaborable_Quote` | 25 |
| `IQuoteDecl` | `Elaborable_Quote_Declarations` | 18 |
| `IQuoteName` | `Elaborable_Quote_Name` | 17 |
| `IRawImp` | `Kinded_Elaborable_Term` | 25 |
| `IRecord` | `Elaborable_Record_Declaration` | 23 |
| `IRewrite` | `Elaborable_Rewrite` | 22 |
| `IRunElab` | `Elaborable_Run_Elaborator` | 17 |
| `IRunElabDecl` | `Elaborable_Run_Elaborator_Declaration` | 14 |
| `ISearch` | `Elaborable_Search` | 22 |
| `ISetField` | `Elaborable_Set_Field` | 22 |
| `ISetFieldApp` | `Elaborable_Apply_To_Field` | 22 |
| `ITransform` | `Elaborable_Transformation` | 18 |
| `IType` | `Elaborable_Type_Universe` | 25 |
| `IUnifyLog` | `Elaborable_Unification_Log` | 13 |
| `IUnquote` | `Elaborable_Unquote` | 23 |
| `IUpdate` | `Elaborable_Record_Update` | 35 |
| `IVar` | `Elaborable_Name` | 206 |
| `IWithApp` | `Elaborable_With_Apply` | 52 |
| `IWithUnambigNames` | `Elaborable_With_Unambiguous_Names` | 16 |
| `MkIClaimData` | `Make_Elaborable_Claim_Data` | 29 |
| `findIBinds` | `find_names_to_bind` | 49 |
| `isIBindVar` | `is_elaborable_bound_name` | 4 |
| `isIPrimVal` | `is_primitive_value` | 4 |
| `isIVar` | `is_elaborable_name` | 4 |
| `unIArg` | `elaborable_argument_term` | 4 |

## Reflection compatibility boundary

The public constructors in `_/libs/base/Language/Reflection/TTImp.idr` retain their upstream names.
Those names are part of the elaborator-reflection interface and are embedded in the checked-in bootstrap compiler.
`TTImp/Reflect.idr` uses readable constructors internally while translating to and from the established serialized names.
