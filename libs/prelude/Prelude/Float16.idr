module Prelude.Float16

import Builtin
import Prelude.Basics
import Prelude.EqOrd
import Prelude.Num
import Prelude.Show

%default total

||| Idriç's ordinary floating value. The current compiler carries the value in
||| a Double internally, but every constructor and arithmetic operation rounds
||| through the IEEE-754 binary16 boundary. Backends may replace this carrier
||| with a native/unboxed representation without changing source semantics.
public export
record Float16 where
  constructor MkFloat16
  float16Carrier : Double

private
roundNearestEven : Double -> Integer
roundNearestEven value =
  let lower = prim__cast_DoubleInteger value
      lowerValue = prim__cast_IntegerDouble lower
      fraction = prim__sub_Double value lowerValue in
    if fraction < 0.5
       then lower
       else if fraction > 0.5
               then prim__add_Integer lower 1
               else if prim__mod_Integer lower 2 == 0
                       then lower
                       else prim__add_Integer lower 1

||| Return the binary16 unit in the last place for a positive finite value.
||| The recursive bound is fixed by the binary16 exponent range, so this is a
||| small deterministic source-semantics operation rather than an unbounded
||| numeric search.
private
halfStep : Nat -> Double -> Double -> Double
halfStep Z value threshold = 0.000000059604644775390625 -- 2^-24, subnormal step
halfStep (S fuel) value threshold =
  if value >= threshold
     then prim__div_Double threshold 1024.0
     else halfStep fuel value (prim__div_Double threshold 2.0)

private
quantizeFloat16Carrier : Double -> Double
quantizeFloat16Carrier value =
  if value /= value
     then value -- preserve NaN
     else if value == 0.0
             then value -- preserve signed zero
             else
               let negative = value < 0.0
                   magnitude = if negative then prim__negate_Double value else value in
                 if magnitude >= 65520.0
                    then let infinity = prim__div_Double 1.0 0.0 in
                           if negative then prim__negate_Double infinity else infinity
                    else
                      let step = halfStep 29 magnitude 32768.0
                          scaled = prim__div_Double magnitude step
                          rounded = roundNearestEven scaled
                          roundedValue = prim__mul_Double
                                           (prim__cast_IntegerDouble rounded)
                                           step in
                        if negative
                           then prim__negate_Double roundedValue
                           else roundedValue

||| Explicitly pass a host/compiler floating carrier through the binary16
||| rounding boundary.
public export
idricFloat16 : Double -> Float16
idricFloat16 value = MkFloat16 (quantizeFloat16Carrier value)

public export
FromDouble Float16 where
  fromDouble = idricFloat16

public export
Num Float16 where
  (MkFloat16 left) + (MkFloat16 right) =
    idricFloat16 (prim__add_Double left right)
  (MkFloat16 left) * (MkFloat16 right) =
    idricFloat16 (prim__mul_Double left right)
  fromInteger value = idricFloat16 (prim__cast_IntegerDouble value)

public export
Neg Float16 where
  negate (MkFloat16 value) = idricFloat16 (prim__negate_Double value)
  (MkFloat16 left) - (MkFloat16 right) =
    idricFloat16 (prim__sub_Double left right)

public export
Abs Float16 where
  abs (MkFloat16 value) =
    if value < 0.0
       then idricFloat16 (prim__negate_Double value)
       else MkFloat16 value

public export
Fractional Float16 where
  (MkFloat16 left) / (MkFloat16 right) =
    idricFloat16 (prim__div_Double left right)

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
  showPrec precedence (MkFloat16 value) = showPrec precedence value
