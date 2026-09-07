module OodricNamespaceRoutine

main : IO ()
main = do
  Farm.open_chicken_coop
  Farm.turn_on_spigot
  putStrLn "OODRIC_NAMESPACE_ROUTINE_OK"

namespace Farm
  export
  open_chicken_coop : IO ()
  open_chicken_coop = pure ()

  export
  turn_on_spigot : IO ()
  turn_on_spigot = pure ()
