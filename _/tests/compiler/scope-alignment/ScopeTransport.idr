module ScopeTransport

import Core.Env
import Core.TT

shadowed : Name
shadowed = UN (Basic "sensor")

-- The newest binder's type refers to the oldest slot. The intermediate
-- binder already occupies the first machine name that freshness would try.
input_scope : Scope
input_scope = [shadowed, MN "sensor" 0, shadowed]

input_environment : Env Term ScopeTransport.input_scope
input_environment =
  [PVar emptyFC linear Explicit (Local emptyFC Nothing 1 (Later First)),
   PVar emptyFC top Explicit (Erased emptyFC Placeholder),
   PVar emptyFC erased Explicit (Erased emptyFC Placeholder)]

slot_info : {vars : _} -> Env Term vars -> Var vars -> (Nat, Name, RigCount)
slot_info env (MkVar {varIdx} position) =
  (varIdx, nameAt position, multiplicity (getBinder position env))

referenced_slot : {vars : _} -> Env Term vars -> Maybe (Nat, Name)
referenced_slot {vars = _ :: outer}
                (PVar _ _ _ (Local _ _ idx position) :: _) =
  Just (idx, nameAt {vars = outer} position)
referenced_slot _ = Nothing

export
observe_transport : IO ()
observe_transport = do
  let (renamed ** (env, alignment)) = uniqifyEnv input_environment
  printLn renamed
  printLn $ map (slot_info env . compatNs alignment) (allVars input_environment)
  printLn $ referenced_slot env
