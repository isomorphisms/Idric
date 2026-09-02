module Compiler.ANF

import Compiler.LambdaLift

import Core.CompileExpr
import Core.Context

import Data.SortedSet
import Data.Vect

%default covering

-- Convert the lambda lifted form to Administrative_Normal_Form, with variable names made explicit.
-- i.e. turn intermediate expressions into let bindings. Every argument is
-- a variable as a result.

mutual
  public export
  data Administrative_Normal_Form_Variable : Type where
       Administrative_Normal_Form_Local_Variable : Int -> Administrative_Normal_Form_Variable
       Administrative_Normal_Form_Erased_Variable : Administrative_Normal_Form_Variable

  public export
  data Administrative_Normal_Form : Type where
    Administrative_Normal_Form_Variable_Expression : FC -> Administrative_Normal_Form_Variable -> Administrative_Normal_Form
    Administrative_Normal_Form_Named_Function_Application : FC -> (lazy : Maybe LazyReason) -> Name -> List Administrative_Normal_Form_Variable -> Administrative_Normal_Form
    Administrative_Normal_Form_Partial_Application : FC -> Name -> (missing : Nat) -> (args : List Administrative_Normal_Form_Variable) -> Administrative_Normal_Form
    Administrative_Normal_Form_Closure_Application : FC -> (lazy : Maybe LazyReason) -> (closure : Administrative_Normal_Form_Variable) -> (arg : Administrative_Normal_Form_Variable) -> Administrative_Normal_Form
    Administrative_Normal_Form_Binding : FC -> (var : Int) -> Administrative_Normal_Form -> Administrative_Normal_Form -> Administrative_Normal_Form
    Administrative_Normal_Form_Constructor_Value : FC -> Name -> ConInfo -> (tag : Maybe Int) -> List Administrative_Normal_Form_Variable -> Administrative_Normal_Form
    Administrative_Normal_Form_Primitive_Operation : {0 arity : Nat} -> FC -> (lazy : Maybe LazyReason) -> PrimFn arity -> Vect arity Administrative_Normal_Form_Variable -> Administrative_Normal_Form
        -- ^ we explicitly bind arity here to silence the warning that it shadows
        --   existing functions called arity.
    Administrative_Normal_Form_External_Primitive : FC -> (lazy : Maybe LazyReason) -> Name -> List Administrative_Normal_Form_Variable -> Administrative_Normal_Form
    Administrative_Normal_Form_Constructor_Case : FC -> Administrative_Normal_Form_Variable -> List Administrative_Normal_Form_Constructor_Alternative -> Maybe Administrative_Normal_Form -> Administrative_Normal_Form
    Administrative_Normal_Form_Constant_Case : FC -> Administrative_Normal_Form_Variable -> List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form -> Administrative_Normal_Form
    Administrative_Normal_Form_Primitive_Value : FC -> Constant -> Administrative_Normal_Form
    Administrative_Normal_Form_Erased_Value : FC -> Administrative_Normal_Form
    Administrative_Normal_Form_Crash : FC -> String -> Administrative_Normal_Form

  public export
  data Administrative_Normal_Form_Constructor_Alternative : Type where
       Make_Administrative_Normal_Form_Constructor_Alternative : Name -> ConInfo -> (tag : Maybe Int) -> (args : List Int) ->
                   Administrative_Normal_Form -> Administrative_Normal_Form_Constructor_Alternative

  public export
  data Administrative_Normal_Form_Constant_Alternative : Type where
       Make_Administrative_Normal_Form_Constant_Alternative : Constant -> Administrative_Normal_Form -> Administrative_Normal_Form_Constant_Alternative

public export
data Administrative_Normal_Form_Definition : Type where
     Make_Administrative_Normal_Form_Function : (args : List Int) -> Administrative_Normal_Form -> Administrative_Normal_Form_Definition
     Make_Administrative_Normal_Form_Constructor : (tag : Maybe Int) -> (arity : Nat) -> (nt : Maybe Nat) -> Administrative_Normal_Form_Definition
     Make_Administrative_Normal_Form_Foreign_Function : (ccs : List String) -> (fargs : List CFType) ->
                  CFType -> Administrative_Normal_Form_Definition
     Make_Administrative_Normal_Form_Error : Administrative_Normal_Form -> Administrative_Normal_Form_Definition

showLazy : Maybe LazyReason -> String
showLazy = maybe "" $ (" " ++) . show

mutual
  export
  Show Administrative_Normal_Form_Variable where
    show (Administrative_Normal_Form_Local_Variable i) = "v" ++ show i
    show Administrative_Normal_Form_Erased_Variable = "[__]"

  export
  Eq Administrative_Normal_Form_Variable where
    (Administrative_Normal_Form_Local_Variable i1) == (Administrative_Normal_Form_Local_Variable i2) = i1 == i2
    Administrative_Normal_Form_Erased_Variable == Administrative_Normal_Form_Erased_Variable = True
    _ == _ = False

  export
  Ord Administrative_Normal_Form_Variable where
    compare (Administrative_Normal_Form_Local_Variable i1) (Administrative_Normal_Form_Local_Variable i2) = compare i1 i2
    compare (Administrative_Normal_Form_Local_Variable _) Administrative_Normal_Form_Erased_Variable = GT
    compare Administrative_Normal_Form_Erased_Variable (Administrative_Normal_Form_Local_Variable _) = LT
    compare Administrative_Normal_Form_Erased_Variable Administrative_Normal_Form_Erased_Variable = EQ

  export
  covering
  Show Administrative_Normal_Form where
    show (Administrative_Normal_Form_Variable_Expression _ v) = show v
    show (Administrative_Normal_Form_Named_Function_Application fc lazy n args)
        = show n ++ showLazy lazy ++ "(" ++ showSep ", " (map show args) ++ ")"
    show (Administrative_Normal_Form_Partial_Application fc n m args)
        = "<" ++ show n ++ " underapp " ++ show m ++ ">(" ++
          showSep ", " (map show args) ++ ")"
    show (Administrative_Normal_Form_Closure_Application fc lazy c arg)
        = show c ++ showLazy lazy ++ " @ (" ++ show arg ++ ")"
    show (Administrative_Normal_Form_Binding fc x val sc)
        = "%let v" ++ show x ++ " = (" ++ show val ++ ") in (" ++ show sc ++ ")"
    show (Administrative_Normal_Form_Constructor_Value fc n _ t args)
        = "%con " ++ show n ++ "(" ++ showSep ", " (map show args) ++ ")"
    show (Administrative_Normal_Form_Primitive_Operation fc lazy op args)
        = "%op " ++ show op ++ showLazy lazy ++ "(" ++ showSep ", " (toList (map show args)) ++ ")"
    show (Administrative_Normal_Form_External_Primitive fc lazy p args)
        = "%extprim " ++ show p ++ showLazy lazy ++ "(" ++ showSep ", " (map show args) ++ ")"
    show (Administrative_Normal_Form_Constructor_Case fc sc alts def)
        = "%case " ++ show sc ++ " of { "
             ++ showSep "| " (map show alts) ++ " " ++ show def ++ " }"
    show (Administrative_Normal_Form_Constant_Case fc sc alts def)
        = "%case " ++ show sc ++ " of { "
             ++ showSep "| " (map show alts) ++ " " ++ show def ++ " }"
    show (Administrative_Normal_Form_Primitive_Value _ x) = show x
    show (Administrative_Normal_Form_Erased_Value _) = "___"
    show (Administrative_Normal_Form_Crash _ x) = "%CRASH(" ++ show x ++ ")"

  export
  covering
  Show Administrative_Normal_Form_Constructor_Alternative where
    show (Make_Administrative_Normal_Form_Constructor_Alternative n _ t args sc)
        = "%conalt " ++ show n ++
             "(" ++ showSep ", " (map showArg args) ++ ") => " ++ show sc
      where
        showArg : Int -> String
        showArg i = "v" ++ show i

  export
  covering
  Show Administrative_Normal_Form_Constant_Alternative where
    show (Make_Administrative_Normal_Form_Constant_Alternative c sc)
        = "%constalt(" ++ show c ++ ") => " ++ show sc

export
covering
Show Administrative_Normal_Form_Definition where
  show (Make_Administrative_Normal_Form_Function args exp) = show args ++ ": " ++ show exp
  show (Make_Administrative_Normal_Form_Constructor tag arity nt)
      = "Constructor tag " ++ show tag ++ " arity " ++ show arity ++ " newtype by " ++ show nt
  show (Make_Administrative_Normal_Form_Foreign_Function ccs args ret)
      = "Foreign call " ++ show ccs ++ " " ++
        show args ++ " -> " ++ show ret
  show (Make_Administrative_Normal_Form_Error exp) = "Error: " ++ show exp

Administrative_Normal_Form_Variable_Environment : Scope -> Type
Administrative_Normal_Form_Variable_Environment = All (\_ => Int)

data Next : Type where

nextVar : {auto v : Ref Next Int} ->
          Core Int
nextVar
    = do i <- get Next
         put Next (i + 1)
         pure i

lookup : {idx : _} -> (0 p : IsVar x idx vs) -> Administrative_Normal_Form_Variable_Environment vs -> Int
lookup First (x :: xs) = x
lookup (Later p) (x :: xs) = lookup p xs

bindArgs : {auto v : Ref Next Int} ->
           List Administrative_Normal_Form -> Core (List (Administrative_Normal_Form_Variable, Maybe Administrative_Normal_Form))
bindArgs [] = pure []
bindArgs (Administrative_Normal_Form_Variable_Expression fc var :: xs)
    = do xs' <- bindArgs xs
         pure $ (var, Nothing) :: xs'
bindArgs (Administrative_Normal_Form_Erased_Value fc :: xs)
    = do xs' <- bindArgs xs
         pure $ (Administrative_Normal_Form_Erased_Variable, Nothing) :: xs'
bindArgs (x :: xs)
    = do i <- nextVar
         xs' <- bindArgs xs
         pure $ (Administrative_Normal_Form_Local_Variable i, Just x) :: xs'

letBind : {auto v : Ref Next Int} ->
          FC -> List Administrative_Normal_Form -> (List Administrative_Normal_Form_Variable -> Administrative_Normal_Form) -> Core Administrative_Normal_Form
letBind fc args f
    = do bargs <- bindArgs args
         pure $ doBind [] bargs
  where
    doBind : List Administrative_Normal_Form_Variable -> List (Administrative_Normal_Form_Variable, Maybe Administrative_Normal_Form) -> Administrative_Normal_Form
    doBind vs [] = f (reverse vs)
    doBind vs ((Administrative_Normal_Form_Local_Variable i, Just t) :: xs)
        = Administrative_Normal_Form_Binding fc i t (doBind (Administrative_Normal_Form_Local_Variable i :: vs) xs)
    doBind vs ((var, _) :: xs) = doBind (var :: vs) xs


mlet : {auto v : Ref Next Int} ->
       FC -> Administrative_Normal_Form -> (Administrative_Normal_Form_Variable -> Administrative_Normal_Form) -> Core Administrative_Normal_Form
mlet fc (Administrative_Normal_Form_Variable_Expression _ var) sc = pure $ sc var
mlet fc val sc
    = do i <- nextVar
         pure $ Administrative_Normal_Form_Binding fc i val (sc (Administrative_Normal_Form_Local_Variable i))

mutual
  convert_arguments_to_administrative_normal_form : {auto v : Ref Next Int} ->
            FC -> Administrative_Normal_Form_Variable_Environment vars ->
            List (Lifted vars) -> (List Administrative_Normal_Form_Variable -> Administrative_Normal_Form) -> Core Administrative_Normal_Form
  convert_arguments_to_administrative_normal_form fc vs args f
      = do args' <- traverse (convert_expression_to_administrative_normal_form vs) args
           letBind fc args' f

  convert_expression_to_administrative_normal_form : {auto v : Ref Next Int} ->
        Administrative_Normal_Form_Variable_Environment vars -> Lifted vars -> Core Administrative_Normal_Form
  convert_expression_to_administrative_normal_form vs (LLocal fc p) = pure $ Administrative_Normal_Form_Variable_Expression fc (Administrative_Normal_Form_Local_Variable (lookup p vs))
  convert_expression_to_administrative_normal_form vs (LAppName fc lazy n args)
      = convert_arguments_to_administrative_normal_form fc vs args (Administrative_Normal_Form_Named_Function_Application fc lazy n)
  convert_expression_to_administrative_normal_form vs (LUnderApp fc n m args)
      = convert_arguments_to_administrative_normal_form fc vs args (Administrative_Normal_Form_Partial_Application fc n m)
  convert_expression_to_administrative_normal_form vs (LApp fc lazy f a)
      = convert_arguments_to_administrative_normal_form fc vs [f, a] $
                \case
                  [fvar, avar] => Administrative_Normal_Form_Closure_Application fc lazy fvar avar
                  _ => Administrative_Normal_Form_Crash fc "Can't happen (Administrative_Normal_Form_Closure_Application)"
  convert_expression_to_administrative_normal_form vs (LLet fc x val sc)
      = do i <- nextVar
           let vs' = i :: vs
           pure $ Administrative_Normal_Form_Binding fc i !(convert_expression_to_administrative_normal_form vs val) !(convert_expression_to_administrative_normal_form vs' sc)
  convert_expression_to_administrative_normal_form vs (LCon fc n ci t args)
      = convert_arguments_to_administrative_normal_form fc vs args (Administrative_Normal_Form_Constructor_Value fc n ci t)
  convert_expression_to_administrative_normal_form vs (LOp {arity} fc lazy op args)
      = do args' <- traverse (convert_expression_to_administrative_normal_form vs) (toList args)
           letBind fc args'
                (\args => case toVect arity args of
                               Nothing => Administrative_Normal_Form_Crash fc "Can't happen (Administrative_Normal_Form_Primitive_Operation)"
                               Just argsv => Administrative_Normal_Form_Primitive_Operation fc lazy op argsv)
  convert_expression_to_administrative_normal_form vs (LExtPrim fc lazy p args)
      = convert_arguments_to_administrative_normal_form fc vs args (Administrative_Normal_Form_External_Primitive fc lazy p)
  convert_expression_to_administrative_normal_form vs (LConCase fc scr alts def)
      = do scr' <- convert_expression_to_administrative_normal_form vs scr
           alts' <- traverse (convert_constructor_alternative_to_administrative_normal_form vs) alts
           def' <- traverseOpt (convert_expression_to_administrative_normal_form vs) def
           mlet fc scr' (\x => Administrative_Normal_Form_Constructor_Case fc x alts' def')
  convert_expression_to_administrative_normal_form vs (LConstCase fc scr alts def)
      = do scr' <- convert_expression_to_administrative_normal_form vs scr
           alts' <- traverse (convert_constant_alternative_to_administrative_normal_form vs) alts
           def' <- traverseOpt (convert_expression_to_administrative_normal_form vs) def
           mlet fc scr' (\x => Administrative_Normal_Form_Constant_Case fc x alts' def')
  convert_expression_to_administrative_normal_form vs (LPrimVal fc c) = pure $ Administrative_Normal_Form_Primitive_Value fc c
  convert_expression_to_administrative_normal_form vs (LErased fc) = pure $ Administrative_Normal_Form_Erased_Value fc
  convert_expression_to_administrative_normal_form vs (LCrash fc err) = pure $ Administrative_Normal_Form_Crash fc err

  convert_constructor_alternative_to_administrative_normal_form : {auto v : Ref Next Int} ->
              Administrative_Normal_Form_Variable_Environment vars -> LiftedConAlt vars -> Core Administrative_Normal_Form_Constructor_Alternative
  convert_constructor_alternative_to_administrative_normal_form vs (MkLConAlt n ci t args sc)
      = do (is, vs') <- bindArgs args vs
           pure $ Make_Administrative_Normal_Form_Constructor_Alternative n ci t is !(convert_expression_to_administrative_normal_form vs' sc)
    where
      bindArgs : (args : List Name) -> Administrative_Normal_Form_Variable_Environment vars' ->
                 Core (List Int, Administrative_Normal_Form_Variable_Environment (args ++ vars'))
      bindArgs [] vs = pure ([], vs)
      bindArgs (n :: ns) vs
          = do i <- nextVar
               (is, vs') <- bindArgs ns vs
               pure (i :: is, i :: vs')

  convert_constant_alternative_to_administrative_normal_form : {auto v : Ref Next Int} ->
                Administrative_Normal_Form_Variable_Environment vars -> LiftedConstAlt vars -> Core Administrative_Normal_Form_Constant_Alternative
  convert_constant_alternative_to_administrative_normal_form vs (MkLConstAlt c sc)
      = pure $ Make_Administrative_Normal_Form_Constant_Alternative c !(convert_expression_to_administrative_normal_form vs sc)

export
to_administrative_normal_form : LiftedDef -> Core Administrative_Normal_Form_Definition
to_administrative_normal_form (MkLFun args scope sc)
    = do v <- newRef Next (the Int 0)
         (iargs, vsNil) <- bindArgs args []
         let vs : Administrative_Normal_Form_Variable_Environment args = rewrite sym (appendNilRightNeutral args) in
                                      vsNil
         (iargs', vs) <- bindArgs scope vs
         pure $ Make_Administrative_Normal_Form_Function (iargs ++ reverse iargs') !(convert_expression_to_administrative_normal_form vs sc)
  where
    bindArgs : {auto v : Ref Next Int} ->
               (args : List Name) -> Administrative_Normal_Form_Variable_Environment vars' ->
               Core (List Int, Administrative_Normal_Form_Variable_Environment (args ++ vars'))
    bindArgs [] vs = pure ([], vs)
    bindArgs (n :: ns) vs
        = do i <- nextVar
             (is, vs') <- bindArgs ns vs
             pure (i :: is, i :: vs')
to_administrative_normal_form (MkLCon t a ns) = pure $ Make_Administrative_Normal_Form_Constructor t a ns
to_administrative_normal_form (MkLForeign ccs fargs t) = pure $ Make_Administrative_Normal_Form_Foreign_Function ccs fargs t
to_administrative_normal_form (MkLError err)
    = do v <- newRef Next (the Int 0)
         pure $ Make_Administrative_Normal_Form_Error !(convert_expression_to_administrative_normal_form [] err)

export
freeVariables : Administrative_Normal_Form -> SortedSet Administrative_Normal_Form_Variable
freeVariables (Administrative_Normal_Form_Variable_Expression _ x) = singleton x
freeVariables (Administrative_Normal_Form_Named_Function_Application _ _ n args) = fromList args
freeVariables (Administrative_Normal_Form_Partial_Application _ n _ args) = fromList args
freeVariables (Administrative_Normal_Form_Closure_Application _ _ closure arg) = fromList [closure, arg]
freeVariables (Administrative_Normal_Form_Binding _ var value body) =
    union (freeVariables value) (delete (Administrative_Normal_Form_Local_Variable var) $ freeVariables body)
freeVariables (Administrative_Normal_Form_Constructor_Value _ _ _ _ args) = fromList args
freeVariables (Administrative_Normal_Form_Primitive_Operation _ _ _ args) = fromList $ toList args
freeVariables (Administrative_Normal_Form_External_Primitive _ _ _ args) = fromList args
freeVariables (Administrative_Normal_Form_Constructor_Case _ sc alts mDef) =
    let altsAnf =
        map (\(Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ args caseBody) =>
                difference (freeVariables caseBody) (fromList $ Administrative_Normal_Form_Local_Variable <$> args)) alts in
    let vars : List (SortedSet Administrative_Normal_Form_Variable) = case mDef of
                Just anf => freeVariables anf :: altsAnf
                Nothing => altsAnf in
    insert sc $ concat vars
freeVariables (Administrative_Normal_Form_Constant_Case _ sc alts mDef) =
    let altsAnf = map (\(Make_Administrative_Normal_Form_Constant_Alternative _ caseBody) => caseBody) alts in
    let anfs : List Administrative_Normal_Form = case mDef of
                Just anf => anf :: altsAnf
                Nothing => altsAnf in
    insert sc $ foldMap freeVariables anfs
freeVariables _ = empty

export
usedConstructors : Administrative_Normal_Form -> SortedSet Name
usedConstructors (Administrative_Normal_Form_Variable_Expression _ x) = empty
usedConstructors (Administrative_Normal_Form_Named_Function_Application _ _ n args) = empty
usedConstructors (Administrative_Normal_Form_Partial_Application _ n _ args) = empty
usedConstructors (Administrative_Normal_Form_Closure_Application _ _ closure arg) = empty
usedConstructors (Administrative_Normal_Form_Binding _ var value body) = union (usedConstructors value) (usedConstructors body)
usedConstructors (Administrative_Normal_Form_Constructor_Value _ n _ _ args) = singleton n
usedConstructors (Administrative_Normal_Form_Primitive_Operation _ _ _ args) = empty
usedConstructors (Administrative_Normal_Form_External_Primitive _ _ _ args) = empty
usedConstructors (Administrative_Normal_Form_Constructor_Case _ sc alts mDef) =
    let altsAnf =
        map (\(Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ args caseBody) => usedConstructors caseBody) alts in
    let anfs : List (SortedSet Name) = case mDef of
                Just anf => usedConstructors anf :: altsAnf
                Nothing => altsAnf in
    concat anfs
usedConstructors (Administrative_Normal_Form_Constant_Case _ sc alts mDef) =
    let altsAnf = map (\(Make_Administrative_Normal_Form_Constant_Alternative _ caseBody) => caseBody) alts in
    let anfs : List Administrative_Normal_Form = case mDef of
                Just anf => anf :: altsAnf
                Nothing => altsAnf in
    foldMap usedConstructors anfs
usedConstructors _ = empty
