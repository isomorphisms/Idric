module OodricForwardReference

run_morning_routine : IO ()
run_morning_routine = do
  open_chicken_coop

open_chicken_coop : IO ()
open_chicken_coop = pure ()
