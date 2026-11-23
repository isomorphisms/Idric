module Compiler.IdricOneStep

import Compiler.ANF
import Compiler.Common
import Compiler.CompileExpr

import Core.Name

import Data.Maybe
import Data.SortedMap

import Idris.Syntax

import Libraries.Utils.Path

%default covering

renderName : Name -> String
renderName (DN _ name) = show name
renderName name = show name

-- Pretty names may hide which implementation of an interface was selected.
-- Preserve the spelling of unambiguous names for existing scalar consumers.
-- Assign colliding definitions distinct names and reuse that table at call sites.
artifactAliases : List Name -> SortedMap Name String
artifactAliases names =
  let counts : SortedMap String Nat =
        foldl (\seen, name => insertWith (+) (renderName name) 1 seen) empty names
      colliding = filter (\name => lookup (renderName name) counts /= Just 1) names
   in assign counts 0 colliding empty
  where
    assign : SortedMap String Nat -> Nat -> List Name -> SortedMap Name String -> SortedMap Name String
    assign _ _ [] aliases = aliases
    assign counts index remaining@(name :: rest) aliases =
      let symbol = "__idric_one_step_" ++ show index in
        case lookup symbol counts of
          Just _ => assign counts (S index) remaining aliases
          Nothing => assign counts (S index) rest (insert name symbol aliases)

renderDefinition : (Name -> String) -> (Name, Administrative_Normal_Form_Definition) -> String
renderDefinition symbol (name, definition) =
  symbol name ++ " = " ++ renderDefinitionWith symbol definition ++ "\n"

compileOneStep :
  Ref Ctxt Defs ->
  Ref Syn SyntaxInfo ->
  (temporaryDirectory : String) ->
  (outputDirectory : String) ->
  ClosedTerm ->
  (outputFile : String) ->
  Core (Maybe String)
compileOneStep _ _ _ outputDirectory term outputFile = do
  checked <- getCompileData False Administrative_Normal_Form term
  let output = outputDirectory </> outputFile
  let aliases = artifactAliases (map fst (anf checked))
  let symbol = \name => fromMaybe (renderName name) (lookup name aliases)
  let body = "EDRIC_ONE_STEP_BODY\t1\n" ++
             concat (map (renderDefinition symbol) (anf checked))
  Core.writeFile output body
  pure (Just output)

executeOneStep :
  Ref Ctxt Defs ->
  Ref Syn SyntaxInfo ->
  (temporaryDirectory : String) ->
  ClosedTerm ->
  Core ()
executeOneStep _ _ _ _ =
  throw (InternalError "the one-step-at-a-time emitter does not execute programs")

export
codegenIdricOneStep : Codegen
codegenIdricOneStep = MkCG compileOneStep executeOneStep Nothing Nothing
