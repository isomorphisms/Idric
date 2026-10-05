module Main

choice : a -> a
choice value = value

one_of : Nat -> Nat
one_of value = S value

main : IO ()
main = printLn $ choice (one_of 41)
