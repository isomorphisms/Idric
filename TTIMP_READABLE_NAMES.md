# Readable TTImp vocabulary

This study branch spells out the compiler-internal constructor vocabulary of Idris's raw TTImp tree.

Idris describes TTImp as the higher-level **TT with implicit arguments** language that is elaborated into checked core TT. The prefix `Elaboratable_` marks that stage. It does not mean that every node is itself an implicit argument.

## Main reading vocabulary

| Meaning | Upstream name | Readable name |
|---|---|---|
| name | `IVar` | `Elaboratable_Name` |
| apply | `IApp` | `Elaboratable_Apply` |
| binding | `ILet` | `Elaboratable_Binding` |
| function type whose result may depend on its input | `IPi` | `Elaboratable_Dependent_Function_Type` |
| lambda | `ILam` | `Elaboratable_Lambda` |
| case | `ICase` | `Elaboratable_Case` |

## Complete compiler-internal rename

### Terms

| Upstream | Readable |
|---|---|
| `IVar` | `Elaboratable_Name` |
| `IPi` | `Elaboratable_Dependent_Function_Type` |
| `ILam` | `Elaboratable_Lambda` |
| `ILet` | `Elaboratable_Binding` |
| `ICase` | `Elaboratable_Case` |
| `ILocal` | `Elaboratable_Local_Definitions` |
| `ICaseLocal` | `Elaboratable_Case_Local_Definition` |
| `IUpdate` | `Elaboratable_Record_Update` |
| `IApp` | `Elaboratable_Apply` |
| `IAutoApp` | `Elaboratable_Automatic_Apply` |
| `INamedApp` | `Elaboratable_Named_Apply` |
| `IWithApp` | `Elaboratable_With_Apply` |
| `ISearch` | `Elaboratable_Search` |
| `IAlternative` | `Elaboratable_Alternative` |
| `IRewrite` | `Elaboratable_Rewrite` |
| `ICoerced` | `Elaboratable_Coerced` |
| `IBindHere` | `Elaboratable_Bind_Here` |
| `IBindVar` | `Elaboratable_Bind_Name` |
| `IAs` | `Elaboratable_As_Pattern` |
| `IMustUnify` | `Elaboratable_Must_Unify` |
| `IDelayed` | `Elaboratable_Delayed_Type` |
| `IDelay` | `Elaboratable_Delay` |
| `IForce` | `Elaboratable_Force` |
| `IQuote` | `Elaboratable_Quote` |
| `IQuoteName` | `Elaboratable_Quote_Name` |
| `IQuoteDecl` | `Elaboratable_Quote_Declarations` |
| `IUnquote` | `Elaboratable_Unquote` |
| `IRunElab` | `Elaboratable_Run_Elaborator` |
| `IPrimVal` | `Elaboratable_Primitive_Value` |
| `IType` | `Elaboratable_Type_Universe` |
| `IHole` | `Elaboratable_Hole` |
| `IUnifyLog` | `Elaboratable_Unification_Log` |
| `IWithUnambigNames` | `Elaboratable_With_Unambiguous_Names` |

### Record-field updates

| Upstream | Readable |
|---|---|
| `IField` | `Elaboratable_Field` |
| `IField'` | `Elaboratable_Field'` |
| `IFieldUpdate` | `Elaboratable_Field_Update` |
| `IFieldUpdate'` | `Elaboratable_Field_Update'` |
| `ISetField` | `Elaboratable_Set_Field` |
| `ISetFieldApp` | `Elaboratable_Apply_To_Field` |

### Declarations

| Upstream | Readable |
|---|---|
| `IClaim` | `Elaboratable_Claim` |
| `IData` | `Elaboratable_Data_Declaration` |
| `IDef` | `Elaboratable_Definition` |
| `IParameters` | `Elaboratable_Parameter_Block` |
| `IRecord` | `Elaboratable_Record_Declaration` |
| `INamespace` | `Elaboratable_Namespace_Block` |
| `ITransform` | `Elaboratable_Transformation` |
| `IRunElabDecl` | `Elaboratable_Run_Elaborator_Declaration` |
| `IBuiltin` | `Elaboratable_Builtin_Declaration` |
| `IFail` | `Elaboratable_Expected_Failure` |
| `IPragma` | `Elaboratable_Pragma` |
| `ILog` | `Elaboratable_Logging` |

### Nearby names

| Upstream | Readable |
|---|---|
| `IRawImp` | `Kinded_Elaboratable_Term` |
| `IImpClause` | `Kinded_Elaboratable_Clause` |
| `IClaimData` | `Elaboratable_Claim_Data` |
| `MkIClaimData` | `Make_Elaboratable_Claim_Data` |
| `isIPrimVal` | `isPrimitiveValue` |
| `findIBinds` | `findNamesToBind` |

## Reflection compatibility boundary

The public elaborator-reflection type at `_/libs/base/Language/Reflection/TTImp.idr` retains the established upstream constructor names. The checked-in bootstrap compiler and elaborator-reflection programs refer to that public vocabulary.

`TTImp/Reflect.idr` is the translation boundary: its compiler-internal tree uses the readable names, while its quoted public reflection names such as `"IVar"` remain unchanged.
