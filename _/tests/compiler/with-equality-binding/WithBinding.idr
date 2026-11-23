module WithBinding

import Core.Binary
import Core.TT
import Idris.Syntax
import System
import System.File
import TTImp.TTImp
import TTImp.TTImp.TTC

binding : String -> Name
binding spelling = UN (Basic spelling)

field : String -> RawImp
field spelling = Elaborable_Name emptyFC (binding spelling)

clause : Maybe (RigCount, Name) -> ImpClause
clause equality_binding =
  let parsed : PWithProblem = MkPWithProblem top (PType emptyFC) equality_binding
  in WithClause emptyFC (field "left") top (field "right") (withRigProof parsed)
       [] [ImpossibleClause emptyFC (field "child")]

bindings : List (Maybe (RigCount, Name))
bindings = [Nothing, Just (erased, binding "ignored"),
            Just (linear, binding "once"), Just (top, binding "many")]

write_fixture : String -> Core ()
write_fixture path = do
  output <- initBinary
  toBuf (map clause bindings)
  Right () <- coreLift $ writeToFile path !(get Bin)
    | Left _ => throw (InternalError "could not write with-clause fixture")
  pure ()

binding_matches : Maybe (RigCount, Name) -> ImpClause -> Bool
binding_matches expected
    (WithClause _ (Elaborable_Name _ lhs) quantity (Elaborable_Name _ rhs) actual []
      [ImpossibleClause _ (Elaborable_Name _ child)]) =
        lhs == binding "left" && quantity == top && rhs == binding "right" &&
        actual == expected && child == binding "child"
binding_matches _ _ = False

read_fixture : String -> Core ()
read_fixture path = do
  Right input <- coreLift $ readFromFile path
    | Left _ => throw (InternalError "could not read with-clause fixture")
  buffer <- newRef Bin input
  decoded <- the (Core (List ImpClause)) fromBuf
  unless (length decoded == length bindings && all id (zipWith binding_matches bindings decoded)) $
    throw (InternalError "decoded clause or optional binding changed")

main : IO ()
main = do
  [_, action, path] <- getArgs | _ => die "expected read or write and a file"
  case action of
    "write" => coreRun (write_fixture path) (const $ die "write failed") pure
    "read" => coreRun (read_fixture path) (const $ die "with-clause round trip failed") pure
    _ => die "expected read or write"
