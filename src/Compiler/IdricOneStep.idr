module Compiler.IdricOneStep

import Compiler.ANF
import Compiler.Common
import Compiler.CompileExpr

import Core.Name

import Idris.Syntax

import Libraries.Utils.Path

%default covering

renderName : Name -> String
renderName (DN _ name) = show name
renderName name = show name

renderDefinition : (Name, ANFDef) -> String
renderDefinition (name, definition) =
  renderName name ++ " = " ++ show definition ++ "\n"

compileOneStep :
  Ref Ctxt Defs ->
  Ref Syn SyntaxInfo ->
  (temporaryDirectory : String) ->
  (outputDirectory : String) ->
  ClosedTerm ->
  (outputFile : String) ->
  Core (Maybe String)
compileOneStep _ _ _ outputDirectory term outputFile = do
  checked <- getCompileData False ANF term
  let output = outputDirectory </> outputFile
  let body = "EDRIC_ONE_STEP_BODY\t1\n" ++
             concat (map renderDefinition (anf checked))
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
