module Main

floatLarge : Float
floatLarge = 16777216.0

floatNext : Float
floatNext = floatLarge + 1.0

doubleLarge : Double
doubleLarge = 16777216.0

doubleNext : Double
doubleNext = doubleLarge + 1.0

floatHalfPlusQuarter : Float
floatHalfPlusQuarter = 0.5 + 0.25

floatThreeQuarters : Float
floatThreeQuarters = 0.75

floatThree : Float
floatThree = 3

floatThreeDecimal : Float
floatThreeDecimal = 3.0

main : IO ()
main = do
  printLn (floatNext == floatLarge)
  printLn (doubleNext > doubleLarge)
  printLn (floatHalfPlusQuarter == floatThreeQuarters)
  printLn (floatThree == floatThreeDecimal)
