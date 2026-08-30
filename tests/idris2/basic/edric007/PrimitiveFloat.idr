module PrimitiveFloat

main : IO ()
main =
  let left : Float
      left = 1.5
      right : Float
      right = 2.25
      expected : Float
      expected = 3.75 in
    if left + right == expected
       then putStrLn "primitive-float: PASS"
       else putStrLn "primitive-float: FAIL"
