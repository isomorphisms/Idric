module Compatibility

-- Ordinary Idris keeps Unicode minus inside an ordinary identifier.
subtract−interval : Integer -> Integer -> Integer
subtract−interval left right = left + right

main : IO ()
main = do
  printLn (subtract−interval 12 7)
  putStrLn "Keep − in Idris text"
