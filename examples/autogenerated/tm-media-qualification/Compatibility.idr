module Compatibility

-- Inherited .idr spellings and contextual names must remain available.
choice : Integer
choice = 180

one_of : String
one_of = "compatibility"

main : IO ()
main = do
  printLn (choice == 180)
  printLn (one_of == "compatibility")
