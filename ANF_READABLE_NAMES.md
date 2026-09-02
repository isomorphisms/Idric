# Readable administrative-normal-form names

The `A` at the beginning of these compiler constructors marked the administrative-normal-form layer. This branch spells out that layer instead of requiring the reader to remember the initial.

The module path remains `Compiler.ANF`, which is the conventional short name for the compiler pass. The datatype and the terms being read inside the module use complete names.

## Main expression vocabulary

| Old name | Readable name |
|---|---|
| `ANF` | `Administrative_Normal_Form` |
| `AVar` | `Administrative_Normal_Form_Variable` |
| `ALocal` | `Administrative_Normal_Form_Local_Variable` |
| `ANull` | `Administrative_Normal_Form_Erased_Variable` |
| `AV` | `Administrative_Normal_Form_Variable_Expression` |
| `AAppName` | `Administrative_Normal_Form_Named_Function_Application` |
| `AUnderApp` | `Administrative_Normal_Form_Partial_Application` |
| `AApp` | `Administrative_Normal_Form_Closure_Application` |
| `ALet` | `Administrative_Normal_Form_Binding` |
| `ACon` | `Administrative_Normal_Form_Constructor_Value` |
| `AOp` | `Administrative_Normal_Form_Primitive_Operation` |
| `AExtPrim` | `Administrative_Normal_Form_External_Primitive` |
| `AConCase` | `Administrative_Normal_Form_Constructor_Case` |
| `AConstCase` | `Administrative_Normal_Form_Constant_Case` |
| `APrimVal` | `Administrative_Normal_Form_Primitive_Value` |
| `AErased` | `Administrative_Normal_Form_Erased_Value` |
| `ACrash` | `Administrative_Normal_Form_Crash` |

## Case alternatives and definitions

| Old name | Readable name |
|---|---|
| `AConAlt` | `Administrative_Normal_Form_Constructor_Alternative` |
| `MkAConAlt` | `Make_Administrative_Normal_Form_Constructor_Alternative` |
| `AConstAlt` | `Administrative_Normal_Form_Constant_Alternative` |
| `MkAConstAlt` | `Make_Administrative_Normal_Form_Constant_Alternative` |
| `ANFDef` | `Administrative_Normal_Form_Definition` |
| `MkAFun` | `Make_Administrative_Normal_Form_Function` |
| `MkACon` | `Make_Administrative_Normal_Form_Constructor` |
| `MkAForeign` | `Make_Administrative_Normal_Form_Foreign_Function` |
| `MkAError` | `Make_Administrative_Normal_Form_Error` |

## Nearby helper names

| Old name | Readable name |
|---|---|
| `AVars` | `Administrative_Normal_Form_Variable_Environment` |
| `toANF` | `to_administrative_normal_form` |
| `anf` | `convert_expression_to_administrative_normal_form` |
| `anfArgs` | `convert_arguments_to_administrative_normal_form` |
| `anfConAlt` | `convert_constructor_alternative_to_administrative_normal_form` |
| `anfConstAlt` | `convert_constant_alternative_to_administrative_normal_form` |

The earlier TTImp names also use `Elaborable_` now, replacing the awkward `Elaboratable_` spelling.
