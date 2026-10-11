module Prelude.LowPrecision

import Builtin
import Prelude.Cast
import Prelude.EqOrd
import Prelude.Num
import Prelude.Types

%default total

-- These are two distinct SIGNED OCP OFP8 interchange formats.  Each has
-- precisely one eight-bit payload, including signed zeros and special codes.
-- Do not alias either format to unsigned Ootomo-Naruse E5M3 storage, to
-- PTX UE5M3 scaling, or to experimental nine-bit signed IDK E5M3.
--
-- This source slice deliberately does not implement scalar arithmetic.
-- The canonical Idriç branch does not yet provide the owned binary32 Float
-- primitive that the old Float16/LowPrecision feature branch used for its
-- widen-one-operation-and-requantize rule.  Using Double instead would
-- silently change the numeric contract.  Leave that boundary explicit.

||| Signed OFP8 E4M3: one sign, four exponent, three fraction bits; bias 7.
||| Exponent 15/fraction 7 encodes NaN; finite maximum is 448.
public export
record E4M3 where
  constructor MkE4M3
  e4m3_payload : Bits8

||| Signed OFP8 E5M2: one sign, five exponent, two fraction bits; bias 15.
||| Exponent 31/fraction 0 is infinity; fraction nonzero is NaN.
||| Finite maximum is 57344.
public export
record E5M2 where
  constructor MkE5M2
  e5m2_payload : Bits8

public export
e4m3_from_code : Bits8 -> E4M3
e4m3_from_code = MkE4M3

public export
e5m2_from_code : Bits8 -> E5M2
e5m2_from_code = MkE5M2

public export
e4m3_code : E4M3 -> Bits8
e4m3_code (MkE4M3 code) = code

public export
e5m2_code : E5M2 -> Bits8
e5m2_code (MkE5M2 code) = code

private
code_integer : Bits8 -> Integer
code_integer = prim__cast_Bits8Integer

private
quotient : Integer -> Integer -> Integer
quotient numerator denominator =
  assert_total (prim__div_Integer numerator denominator)

private
remainder : Integer -> Integer -> Integer
remainder numerator denominator =
  assert_total (prim__mod_Integer numerator denominator)

private
magnitude_code : Bits8 -> Integer
magnitude_code code = remainder (code_integer code) 128

private
has_negative_sign : Bits8 -> Bool
has_negative_sign code = code_integer code >= 128

public export
e4m3_negative : E4M3 -> Bool
e4m3_negative (MkE4M3 code) = has_negative_sign code

public export
e5m2_negative : E5M2 -> Bool
e5m2_negative (MkE5M2 code) = has_negative_sign code

public export
e4m3_is_nan : E4M3 -> Bool
e4m3_is_nan (MkE4M3 code) = magnitude_code code == 127

public export
e5m2_is_nan : E5M2 -> Bool
e5m2_is_nan (MkE5M2 code) = magnitude_code code >= 125

public export
e5m2_is_infinite : E5M2 -> Bool
e5m2_is_infinite (MkE5M2 code) = magnitude_code code == 124

public export
e4m3_is_zero : E4M3 -> Bool
e4m3_is_zero (MkE4M3 code) = magnitude_code code == 0

public export
e5m2_is_zero : E5M2 -> Bool
e5m2_is_zero (MkE5M2 code) = magnitude_code code == 0

private
power_of_two : Integer -> Integer
power_of_two exponent = prim__shl_Integer 1 exponent

-- Exact dyadic value of a finite payload.  Both fields are integers.
-- The pair (numerator, denominator) is not necessarily reduced.
-- The sign bit of zero must be retrieved separately.
private
finite_fraction :
  (mantissa_bits : Integer) ->
  (bias : Integer) ->
  (raw_code : Bits8) ->
  (Integer, Integer)
finite_fraction mantissa_bits bias raw_code =
  let mantissa_scale = power_of_two mantissa_bits
      positive = magnitude_code raw_code
      mantissa = remainder positive mantissa_scale
      exponent = quotient positive mantissa_scale
      significand = if exponent == 0
                      then mantissa
                      else mantissa_scale + mantissa
      bin_exponent = (if exponent == 0 then 1 else exponent)
                     - bias - mantissa_bits
      numerator_sign = if has_negative_sign raw_code then -1 else 1
  in if bin_exponent >= 0
        then (numerator_sign * significand
              * power_of_two bin_exponent, 1)
        else (numerator_sign * significand,
              power_of_two (-bin_exponent))

||| Exact signed dyadic finite value, or Nothing for NaN.
||| Inspect e4m3_negative separately to distinguish -0 from +0.
public export
e4m3_finite_fraction : E4M3 -> Maybe (Integer, Integer)
e4m3_finite_fraction value =
  if e4m3_is_nan value then Nothing
    else Just (finite_fraction 3 7 (e4m3_code value))

||| Exact signed dyadic finite value, or Nothing for infinity/NaN.
||| Inspect e5m2_negative separately to distinguish -0 from +0.
public export
e5m2_finite_fraction : E5M2 -> Maybe (Integer, Integer)
e5m2_finite_fraction value =
  if e5m2_is_nan value || e5m2_is_infinite value
    then Nothing
    else Just (finite_fraction 2 15 (e5m2_code value))
