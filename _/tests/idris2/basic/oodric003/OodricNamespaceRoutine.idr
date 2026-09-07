module OodricNamespaceRoutine

namespace Farm
  export
  run_morning_routine : IO ()
  run_morning_routine = do
    open_chicken_coop
    turn_on_spigot

  export
  open_chicken_coop : IO ()
  open_chicken_coop = pure ()

  export
  turn_on_spigot : IO ()
  turn_on_spigot = pure ()

main : IO ()
main = do
  Farm.run_morning_routine
  putStrLn "OODRIC_NAMESPACE_ROUTINE_OK"
