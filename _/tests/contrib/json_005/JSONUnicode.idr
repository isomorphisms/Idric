import Language.JSON
import System

main : IO ()
main =
  if parse "\"\\u002d\\u00e9\\ud83d\\ude00\"" == Just (JString "-é😀") &&
     parse "\"\\uD83D\\uDE00\"" == Just (JString "😀") &&
     parse "\"\\ud83d\"" == Nothing &&
     parse "\"\\ude00\"" == Nothing &&
     parse "\"\\ud83d\\u0041\"" == Nothing
  then putStrLn "PASS JSON Unicode scalar decoding"
  else exitFailure
