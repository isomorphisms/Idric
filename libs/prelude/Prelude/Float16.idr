module Prelude.Float16

import Builtin
import Prelude.Basics
import Prelude.EqOrd
import Prelude.Num
import Prelude.Show
import Prelude.Types

%default total

||| Idriç's ordinary floating value. The Prelude carrier is the compiler's
||| primitive floating value, not the inherited wide floating primitive.
||| Every constructor and arithmetic operation rounds through the IEEE-754
||| binary16 boundary. A later compiler slice can make binary16 itself a core
||| primitive without changing this source-level contract.
public export
record Float16 where
  constructor MkFloat16
  float16Carrier : Float

private
roundNearestEven : Float -> Integer
roundNearestEven value =
  let lower = prim__cast_FloatInteger value
      lowerValue = prim__cast_IntegerFloat lower
      fraction = prim__sub_Float value lowerValue in
    if fraction < 0.5
       then lower
       else if fraction > 0.5
               then prim__add_Integer lower 1
               else if assert_total (prim__mod_Integer lower 2) == 0
                       then lower
                       else prim__add_Integer lower 1

||| Return the binary16 unit in the last place for a positive finite value.
||| The recursive bound is fixed by the binary16 exponent range.
private
halfStep : Nat -> Float -> Float -> Float
halfStep Z value threshold = 0.000000059604644775390625 -- 2^-24, subnormal step
halfStep (S fuel) value threshold =
  if value >= threshold
     then assert_total (prim__div_Float threshold 1024.0)
     else halfStep fuel value (assert_total (prim__div_Float threshold 2.0))

private
quantizeFloat16Carrier : Float -> Float
quantizeFloat16Carrier value =
  if value /= value
     then value -- preserve NaN
     else if value == 0.0
             then value -- preserve signed zero
             else
               let negative = value < 0.0
                   magnitude = if negative then prim__negate_Float value else value in
                 if magnitude >= 65520.0
                    then let infinity = assert_total (prim__div_Float 1.0 0.0) in
                           if negative then prim__negate_Float infinity else infinity
                    else
                      let step = halfStep 29 magnitude 32768.0
                          scaled = assert_total (prim__div_Float magnitude step)
                          rounded = roundNearestEven scaled
                          roundedValue = prim__mul_Float
                                           (prim__cast_IntegerFloat rounded)
                                           step in
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
  fromInteger value = idricFloat16 (prim__cast_IntegerFloat value)

public export
Neg Float16 where
  negate (MkFloat16 value) = idricFloat16 (prim__negate_Float value)
  (MkFloat16 left) - (MkFloat16 right) =
    idricFloat16 (prim__sub_Float left right)

public export
Abs Float16 where
  abs (MkFloat16 value) =
    if value < 0.0
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

export
Show Float16 where
  showPrec precedence (MkFloat16 value) =
    showPrec precedence (prim__cast_FloatDouble value)
