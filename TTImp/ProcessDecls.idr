module TTImp.ProcessDecls

import Core.Directory
import Core.Env
import Core.Metadata
import Core.Termination
import Core.UnifyState

import Idris.Error
import Idris.Pretty
import Idris.REPL.Opts
import Idris.Syntax
import Parser.Source

import TTImp.BindImplicits
import TTImp.Elab.Check
import TTImp.Parser
import TTImp.ProcessBuiltin
import TTImp.ProcessData
import TTImp.ProcessDef
import TTImp.ProcessParams
import TTImp.ProcessRecord
import TTImp.ProcessRunElab
import TTImp.ProcessTransform
import TTImp.ProcessType
import TTImp.TTImp

import TTImp.ProcessDecls.Totality

import Libraries.Text.PrettyPrint.Prettyprinter.Doc

%default covering

processFailing :
  {vars : _} ->
  {auto c : Ref Ctxt Defs} ->
  {auto m : Ref MD Metadata} ->
  {auto u : Ref UST UState} ->
  {auto s : Ref Syn SyntaxInfo} ->
  {auto o : Ref ROpts REPLOpts} ->
  List ElabOpt ->
  NestedNames vars -> Env Term vars ->
  FC -> Maybe String ->  List ImpDecl -> Core ()
processFailing eopts nest env fc mmsg decls
    = do -- save the state: the content of a failing block should be discarded
         ust <- get UST
         syn <- get Syn
         md <- get MD

         -- We expect the block to fail and so the definitions introduced
         -- in it should be discarded once we leave the block.
         defs <- branch

         -- We're going to run the elaboration, and then return:
         -- * Nothing     if the block correctly failed
         -- * Just err    if it either did not fail or failed with an invalid error message
         result <- catch
               (do -- Run the elaborator
                   before <- getTotalityErrors
                   traverse_ (processDecl eopts nest env) decls
                   after <- getTotalityErrors
                   let errs = after \\ before
                   let (e :: es) = errs
                     | [] => do -- We better have unsolved holes
                                -- checkUserHoles True -- do we need this one too?

                                 -- should we only look at the ones introduced in the block?
                                Nothing <- checkDelayedHoles
                                  | Just err => throw err

                                -- Or we have (unfortunately) succeeded
                                pure (Just $ FailingDidNotFail fc)
                   let Just msg = mmsg
                     | _ => pure Nothing
                   log "elab.failing" 10 $ "Failing block based on \{show msg} failed with \{show errs}"
                   test <- anyM (checkError msg) errs
                   pure $ do -- Unless the error is the expected one
                             guard (not test)
                             -- We should complain we had the wrong one
                             pure (FailingWrongError fc msg (e ::: es)))
               (\err => do let Just msg = mmsg
                                 | _ => pure Nothing
                           log "elab.failing" 10 $ "Failing block based on \{show msg} failed with \{show err}"
                           test <- checkError msg err
                           pure $ do -- Unless the error is the expected one
                                     guard (not test)
                                     -- We should complain we had the wrong one
                                     pure (FailingWrongError fc msg (err ::: [])))
         md' <- get MD
         -- Reset the state
         put UST ust
         put Syn syn
         -- For metadata, we preserve the syntax highlithing information (but none
         -- of the things that may include code that's dropped like types, LHSs, etc.)
         put MD ({ semanticHighlighting := semanticHighlighting md'
                 , semanticAliases := semanticAliases md'
                 , semanticDefaults := semanticDefaults md'
                 } md)
         put Ctxt defs
         -- And fail if the block was successfully accepted
         whenJust result throw


process_declarations_without_definition_order :
  {vars : _} ->
  {auto c : Ref Ctxt Defs} ->
  {auto m : Ref MD Metadata} ->
  {auto u : Ref UST UState} ->
  {auto s : Ref Syn SyntaxInfo} ->
  {auto o : Ref ROpts REPLOpts} ->
  List ElabOpt ->
  NestedNames vars -> Env Term vars ->
  List ImpDecl -> Core ()


-- Implements processDecl, declared in TTImp.Elab.Check
process : {vars : _} ->
          {auto c : Ref Ctxt Defs} ->
          {auto m : Ref MD Metadata} ->
          {auto u : Ref UST UState} ->
          {auto s : Ref Syn SyntaxInfo} ->
          {auto o : Ref ROpts REPLOpts} ->
          List ElabOpt ->
          NestedNames vars -> Env Term vars -> ImpDecl -> Core ()
process eopts nest env (Elaborable_Claim dat@(MkWithData fc (Make_Elaborable_Claim_Data rig vis opts ty)))
    = processType eopts nest env dat.fc rig vis opts ty
process eopts nest env (Elaborable_Data_Declaration fc vis mbtot ddef)
    = processData eopts nest env fc vis mbtot ddef
process eopts nest env (Elaborable_Definition fc fname def)
    = processDef eopts nest env fc fname def
process eopts nest env (Elaborable_Parameter_Block fc ps decls)
    = processParams nest env fc (forget ps) decls
process eopts nest env (Elaborable_Record_Declaration fc ns vis mbtot rec)
    = processRecord eopts nest env ns vis mbtot rec
process eopts nest env (Elaborable_Expected_Failure fc msg decls)
    = processFailing eopts nest env fc msg decls
process eopts nest env (Elaborable_Namespace_Block fc ns decls)
    = withExtendedNS ns $
         process_declarations_without_definition_order eopts nest env decls
process eopts nest env (Elaborable_Transformation fc n lhs rhs)
    = processTransform eopts nest env fc n lhs rhs
process eopts nest env (Elaborable_Run_Elaborator_Declaration fc tm)
    = processRunElab eopts nest env fc tm
process eopts nest env (Elaborable_Pragma _ _ act)
    = act nest env
process eopts nest env (Elaborable_Logging lvl)
    = addLogLevel (uncurry unsafeMkLogLevel <$> lvl)
process eopts nest env (Elaborable_Builtin_Declaration fc type name)
    = processBuiltin nest env fc type name

TTImp.Elab.Check.processDecl = process


-- Oodriç experiment: ordinary function bodies no longer prevent the compiler
-- from seeing declarations written later in the same module.  The first walk
-- establishes every non-definition declaration; the second checks function
-- bodies.  Namespace blocks participate in the same two walks so a reader may
-- put the purpose-level definitions before their supporting declarations.
--
-- This deliberately does not claim that every declaration kind is now fully
-- order-independent.  Parameter blocks, records, run-elaborator declarations,
-- transformations, and dependent declaration relationships still need their
-- own semantics.  Keeping that boundary explicit gives the experiment a place
-- to grow without pretending the first successful forward reference solved the
-- whole language-design problem.
process_non_definition_declarations :
  {vars : _} ->
  {auto c : Ref Ctxt Defs} ->
  {auto m : Ref MD Metadata} ->
  {auto u : Ref UST UState} ->
  {auto s : Ref Syn SyntaxInfo} ->
  {auto o : Ref ROpts REPLOpts} ->
  List ElabOpt ->
  NestedNames vars -> Env Term vars ->
  List ImpDecl -> Core ()
process_non_definition_declarations eopts nest env [] = pure ()
process_non_definition_declarations eopts nest env
    (Elaborable_Definition _ _ _ :: remaining_declarations)
    = process_non_definition_declarations eopts nest env remaining_declarations
process_non_definition_declarations eopts nest env
    (Elaborable_Namespace_Block _ namespace_name namespace_declarations :: remaining_declarations)
    = do withExtendedNS namespace_name $
           process_non_definition_declarations eopts nest env namespace_declarations
         process_non_definition_declarations eopts nest env remaining_declarations
process_non_definition_declarations eopts nest env
    (declaration :: remaining_declarations)
    = do processDecl eopts nest env declaration
         process_non_definition_declarations eopts nest env remaining_declarations

process_delayed_function_definitions :
  {vars : _} ->
  {auto c : Ref Ctxt Defs} ->
  {auto m : Ref MD Metadata} ->
  {auto u : Ref UST UState} ->
  {auto s : Ref Syn SyntaxInfo} ->
  {auto o : Ref ROpts REPLOpts} ->
  List ElabOpt ->
  NestedNames vars -> Env Term vars ->
  List ImpDecl -> Core ()
process_delayed_function_definitions eopts nest env [] = pure ()
process_delayed_function_definitions eopts nest env
    (declaration@(Elaborable_Definition _ _ _) :: remaining_declarations)
    = do processDecl eopts nest env declaration
         process_delayed_function_definitions eopts nest env remaining_declarations
process_delayed_function_definitions eopts nest env
    (Elaborable_Namespace_Block _ namespace_name namespace_declarations :: remaining_declarations)
    = do withExtendedNS namespace_name $
           process_delayed_function_definitions eopts nest env namespace_declarations
         process_delayed_function_definitions eopts nest env remaining_declarations
process_delayed_function_definitions eopts nest env
    (_ :: remaining_declarations)
    = process_delayed_function_definitions eopts nest env remaining_declarations

process_declarations_without_definition_order eopts nest env declarations
    = do process_non_definition_declarations eopts nest env declarations
         process_delayed_function_definitions eopts nest env declarations


export
processDecls : {vars : _} ->
               {auto c : Ref Ctxt Defs} ->
               {auto m : Ref MD Metadata} ->
               {auto u : Ref UST UState} ->
               {auto s : Ref Syn SyntaxInfo} ->
               {auto o : Ref ROpts REPLOpts} ->
               NestedNames vars -> Env Term vars -> List ImpDecl -> Core Bool
processDecls nest env declarations
    = do process_declarations_without_definition_order [] nest env declarations
         pure True -- TODO: False on error

processTTImpDecls : {vars : _} ->
                    {auto c : Ref Ctxt Defs} ->
                    {auto m : Ref MD Metadata} ->
                    {auto u : Ref UST UState} ->
                    {auto s : Ref Syn SyntaxInfo} ->
                    {auto o : Ref ROpts REPLOpts} ->
                    NestedNames vars -> Env Term vars -> List ImpDecl -> Core Bool
processTTImpDecls {vars} nest env declarations
    = do bound_declarations <- traverse bindNames declarations
         process_declarations_without_definition_order [] nest env bound_declarations
         pure True -- TODO: False on error
  where
    bindConNames : ImpTy -> Core ImpTy
    bindConNames ty
        = traverse (bindTypeNames ty.fc [] (toList vars)) ty

    bindDataNames : ImpData -> Core ImpData
    bindDataNames (MkImpData fc n t opts cons)
        = do t' <- traverseOpt (bindTypeNames fc [] (toList vars)) t
             cons' <- traverse bindConNames cons
             pure (MkImpData fc n t' opts cons')
    bindDataNames (MkImpLater fc n t)
        = do t' <- bindTypeNames fc [] (toList vars) t
             pure (MkImpLater fc n t')

    -- bind implicits to make raw TTImp source a bit friendlier
    bindNames : ImpDecl -> Core ImpDecl
    bindNames (Elaborable_Claim dat@(MkWithData fc (Make_Elaborable_Claim_Data c vis opts ty)))
        = do ty' <- bindTypeNames dat.fc [] (toList vars) ty.val
             pure (Elaborable_Claim (MkWithData fc (Make_Elaborable_Claim_Data c vis opts ({val := ty'} ty))))
    bindNames (Elaborable_Data_Declaration fc vis mbtot d)
        = do d' <- bindDataNames d
             pure (Elaborable_Data_Declaration fc vis mbtot d')
    bindNames d = pure d

export
processTTImpFile : {auto c : Ref Ctxt Defs} ->
                   {auto m : Ref MD Metadata} ->
                   {auto u : Ref UST UState} ->
                   {auto s : Ref Syn SyntaxInfo} ->
                   {auto o : Ref ROpts REPLOpts} ->
                   String -> Core Bool
processTTImpFile fname
    = do modIdent <- ctxtPathToNS fname
         Right (ws, decor, tti) <- logTime 0 "Parsing" $
                            coreLift $ parseFile fname (PhysicalIdrSrc modIdent)
                            (do decls <- prog (PhysicalIdrSrc modIdent)
                                eoi
                                pure decls)
               | Left err => do coreLift (putStrLn (show err))
                                pure False
         traverse_ recordWarning ws
         logTime 0 "Elaboration" $
            catch (do ignore $ processTTImpDecls (MkNested []) Env.empty tti
                      Nothing <- checkDelayedHoles
                          | Just err => throw err
                      pure True)
                  (\err => do coreLift_ (printLn err)
                              pure False)
