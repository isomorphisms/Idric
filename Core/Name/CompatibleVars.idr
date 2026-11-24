module Core.Name.CompatibleVars

||| Slots correspond by position; the names in corresponding slots may differ.
public export
data CompatibleVars : (xs, ys : SnocList a) -> Type where
   Pre : CompatibleVars xs xs
   Ext : CompatibleVars xs ys -> CompatibleVars (xs :< n) (ys :< m)

export
invertExt : CompatibleVars (xs :< n) (ys :< m) -> CompatibleVars xs ys
invertExt Pre = Pre
invertExt (Ext remaining_alignment) = remaining_alignment

export
extendCompats : (args : SnocList a) ->
                CompatibleVars xs ys ->
                CompatibleVars (xs ++ args) (ys ++ args)
extendCompats args Pre = Pre
extendCompats args scope_alignment = go args scope_alignment where

  go : (args : SnocList a) ->
       CompatibleVars xs ys ->
       CompatibleVars (xs ++ args) (ys ++ args)
  go [<] scope_alignment = scope_alignment
  go (xs :< x) scope_alignment = Ext (go xs scope_alignment)

export
decCompatibleVars : (xs, ys : SnocList a) -> Dec (CompatibleVars xs ys)
decCompatibleVars [<] [<] = Yes Pre
decCompatibleVars [<] (xs :< x) = No (\case p impossible)
decCompatibleVars (xs :< x) [<] = No (\case p impossible)
decCompatibleVars (xs :< x) (ys :< y) = case decCompatibleVars xs ys of
  Yes remaining_alignment => Yes (Ext remaining_alignment)
  No refute_remaining_alignment => No (refute_remaining_alignment . invertExt)

export
areCompatibleVars : (xs, ys : SnocList a) ->
                    Maybe (CompatibleVars xs ys)
areCompatibleVars [<] [<] = pure Pre
areCompatibleVars (xs :< x) (ys :< y)
    = do remaining_alignment <- areCompatibleVars xs ys
         pure (Ext remaining_alignment)
areCompatibleVars _ _ = Nothing
