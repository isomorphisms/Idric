module Prelude.Float16

import Builtin
import Prelude.Basics
import Prelude.EqOrd
import Prelude.Num
import Prelude.Show
import Prelude.Types

%default total

||| Idriç's ordinary floating value. The Prelude carrier is the compiler's
||| primitive floating value, not an inherited wider floating primitive.
||| Every constructor and arithmetic operation rounds through the IEEE-754
||| binary16 boundary. A later compiler slice can make binary16 itself a core
||| primitive without changing this source-level contract.
public export
record Float16 where
  constructor MkFloat16
  float16Carrier : Float

private
asFloat : Integer -> Float
asFloat = prim__cast_IntegerFloat

private
half : Float
half = assert_total (prim__div_Float (asFloat 1) (asFloat 2))

||| Find the integer floor of a nonnegative primitive floating value inside a
||| known integer interval. The recursion depth is supplied explicitly so the
||| Prelude never needs a floating-to-integer primitive.
private
floorBounded : Nat -> Integer -> Integer -> Float -> Integer
floorBounded Z lower upper value = lower
floorBounded (S fuel) lower upper value =
  let width = prim__sub_Integer upper lower in
    if width <= 1
       then lower
       else
         let midpoint = prim__add_Integer
                          lower
                          (assert_total (prim__div_Integer width 2))
             midpointValue = asFloat midpoint in
           if midpointValue <= value
              then floorBounded fuel midpoint upper value
              else floorBounded fuel lower midpoint value

private
roundNearestEven : Float -> Integer
roundNearestEven value =
  let lower = floorBounded 12 0 2048 value
      lowerValue = asFloat lower
      fraction = prim__sub_Float value lowerValue in
    if fraction < half
       then lower
       else if fraction > half
               then prim__add_Integer lower 1
               else if assert_total (prim__mod_Integer lower 2) == 0
                       then lower
                       else prim__add_Integer lower 1

||| Return the binary16 unit in the last place for a positive finite value.
||| The recursive bound is fixed by the binary16 exponent range.
private
halfStep : Nat -> Float -> Float -> Float
halfStep Z value threshold =
  assert_total (prim__div_Float (asFloat 1) (asFloat 16777216)) -- 2^-24
halfStep (S fuel) value threshold =
  if value >= threshold
     then assert_total (prim__div_Float threshold (asFloat 1024))
     else halfStep fuel value
                   (assert_total (prim__div_Float threshold (asFloat 2)))

private
quantizeFloat16Carrier : Float -> Float
quantizeFloat16Carrier value =
  if value /= value
     then value -- preserve NaN
     else if value == asFloat 0
             then value -- preserve signed zero
             else
               let negative = value < asFloat 0
                   magnitude = if negative then prim__negate_Float value else value in
                 if magnitude >= asFloat 65520
                    then let infinity = assert_total
                                          (prim__div_Float (asFloat 1) (asFloat 0)) in
                           if negative then prim__negate_Float infinity else infinity
                    else
                      let step = halfStep 29 magnitude (asFloat 32768)
                          scaled = assert_total (prim__div_Float magnitude step)
                          rounded = roundNearestEven scaled
                          roundedValue = prim__mul_Float (asFloat rounded) step in
                        if negative
                           then prim__negate_Float roundedValue
                           else roundedValue

||| Explicitly pass a primitive floating value through the binary16 rounding
||| boundary. The `.idric` lexer uses this for decimal literals.
public export
idricFloat16 : Float -> Float16
idricFloat16 value = MkFloat16 (quantizeFloat16Carrier value)

public export
Num Float16 where
  (MkFloat16 left) + (MkFloat16 right) =
    idricFloat16 (prim__add_Float left right)
  (MkFloat16 left) * (MkFloat16 right) =
    idricFloat16 (prim__mul_Float left right)
  fromInteger value = idricFloat16 (asFloat value)

public export
Neg Float16 where
  negate (MkFloat16 value) = idricFloat16 (prim__negate_Float value)
  (MkFloat16 left) - (MkFloat16 right) =
    idricFloat16 (prim__sub_Float left right)

public export
Abs Float16 where
  abs (MkFloat16 value) =
    if value < asFloat 0
       then idricFloat16 (prim__negate_Float value)
       else MkFloat16 value

public export
Fractional Float16 where
  (MkFloat16 left) / (MkFloat16 right) =
    idricFloat16 (assert_total (prim__div_Float left right))

public export
Eq Float16 where
  (MkFloat16 left) == (MkFloat16 right) = left == right

public export
Ord Float16 where
  (MkFloat16 left) < (MkFloat16 right) = left < right
  (MkFloat16 left) <= (MkFloat16 right) = left <= right
  (MkFloat16 left) > (MkFloat16 right) = left > right
  (MkFloat16 left) >= (MkFloat16 right) = left >= right

private
fractionDigits : Nat -> Float -> String
fractionDigits Z fraction = ""
fractionDigits (S fuel) fraction =
  let scaled = prim__mul_Float fraction (asFloat 10)
      digit = floorBounded 4 0 10 scaled
      rest = prim__sub_Float scaled (asFloat digit) in
    show digit ++ fractionDigits fuel rest

private
stripLeadingZeros : List Char -> List Char
stripLeadingZeros ('0' :: rest) = stripLeadingZeros rest
stripLeadingZeros rest = rest

private
trimTrailingZeros : String -> String
trimTrailingZeros digits =
  let trimmed = reverse (stripLeadingZeros (reverse (unpack digits))) in
    case trimmed of
      [] => "0"
      _ => pack trimmed

||| Format the binary16 value without routing through the inherited wide
||| floating primitive. Eight fractional decimal digits are enough to
||| distinguish every finite binary16 value; trailing zeroes are removed.
private
showFloat16Carrier : Float -> String
showFloat16Carrier value =
  if value /= value
     then "NaN"
     else
       let infinity = assert_total (prim__div_Float (asFloat 1) (asFloat 0)) in
         if value == infinity
            then "Infinity"
            else if value == prim__negate_Float infinity
                    then "-Infinity"
                    else
                      let negative = value < asFloat 0
                          magnitude = if negative then prim__negate_Float value else value
                          whole = floorBounded 17 0 65536 magnitude
                          fraction = prim__sub_Float magnitude (asFloat whole)
                          prefix = if negative then "-" else ""
                          decimals = trimTrailingZeros (fractionDigits 8 fraction) in
                        prefix ++ show whole ++ "." ++ decimals

export
Show Float16 where
  showPrec _ (MkFloat16 value) = showFloat16Carrier value
