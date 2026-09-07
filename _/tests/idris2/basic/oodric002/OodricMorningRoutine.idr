module OodricMorningRoutine

main : IO ()
main = do
  open_chicken_coop
  turn_on_spigot
  putStrLn "OODRIC_MORNING_ROUTINE_OK"

open_chicken_coop : IO ()
open_chicken_coop = pure ()

turn_on_spigot : IO ()
turn_on_spigot = pure ()
