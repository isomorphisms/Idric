module ScopeAlignment

import Core.Name.CompatibleVars as Snoc
import Core.Name.Scoped as Cons
import ScopeTransport

snoc_shape : Snoc.CompatibleVars xs ys -> List Nat
snoc_shape Snoc.Pre = []
snoc_shape (Snoc.Ext remaining) = 1 :: snoc_shape remaining

list_shape : Cons.CompatibleVars xs ys -> List Nat
list_shape Cons.Pre = []
list_shape (Cons.Ext remaining) = 1 :: list_shape remaining

decision : Dec a -> Bool
decision (Yes _) = True
decision (No _) = False

some : Maybe a -> Bool
some (Just _) = True
some Nothing = False

-- The same unequal depths must be rejected in either direction, including
-- when recursion has already matched one outer slot.
snoc_decision : SnocList Nat -> SnocList Nat -> (Bool, Bool)
snoc_decision xs ys = (decision (Snoc.decCompatibleVars xs ys),
                       some (Snoc.areCompatibleVars xs ys))

list_decision : List Nat -> List Nat -> (Bool, Bool)
list_decision xs ys = (decision (Cons.decCompatibleVars xs ys),
                       some (Cons.areCompatibleVars xs ys))

snoc_input : Snoc.CompatibleVars (the (SnocList Nat) [<1]) [<2]
snoc_input = Snoc.Ext Snoc.Pre

list_input : Cons.CompatibleVars (the (List Nat) [1]) [2]
list_input = Cons.Ext Cons.Pre

failing "While processing right hand side of incompatible_snoc."
  incompatible_snoc : Snoc.CompatibleVars (the (SnocList Nat) [<1]) [<2,3]
  incompatible_snoc = Snoc.Pre

failing "While processing right hand side of incompatible_list."
  incompatible_list : Cons.CompatibleVars (the (List Nat) [1,2]) [3]
  incompatible_list = Cons.Pre

main : IO ()
main = do
  printLn $ map (uncurry snoc_decision)
    [([<],[<]), ([<1],[<1]), ([<1,2],[<5,6]), ([<1],[<2,3]), ([<1,2],[<3])]
  printLn $ map (uncurry list_decision)
    [([],[]), ([1],[1]), ([1,2],[5,6]), ([1],[2,3]), ([1,2],[3])]
  let snoc_added = Snoc.extendCompats [<3,4] snoc_input
  let list_added = Cons.extendCompats [3,4] list_input
  printLn (snoc_shape snoc_added, snoc_shape (Snoc.invertExt snoc_added))
  printLn (list_shape list_added, list_shape (Cons.invertExt list_added))
  printLn $ snoc_shape (Snoc.extendCompats [<3,4] (the (Snoc.CompatibleVars [<1] [<1]) Snoc.Pre))
  printLn $ list_shape (Cons.extendCompats [3,4] (the (Cons.CompatibleVars [1] [1]) Cons.Pre))
  observe_transport
