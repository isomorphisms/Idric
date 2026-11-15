module Language.JSON.String.Tokens

import Data.List
import Data.String.Extra
import Text.Token

%default total

public export
data JSONStringTokenKind
  = JSTQuote
  | JSTChar
  | JSTSimpleEscape
  | JSTUnicodeEscape

public export
JSONStringToken : Type
JSONStringToken = Token JSONStringTokenKind

public export
Eq JSONStringTokenKind where
  (==) JSTQuote JSTQuote = True
  (==) JSTChar JSTChar = True
  (==) JSTSimpleEscape JSTSimpleEscape = True
  (==) JSTUnicodeEscape JSTUnicodeEscape = True
  (==) _ _ = False

private
charValue : String -> Char
charValue x = case index 0 x of
                   Nothing => '\NUL'
                   Just c  => c

private
simpleEscapeValue : String -> Char
simpleEscapeValue x
  = case index 1 x of
         Nothing => '\NUL'
         Just c => case c of
                        '"'  => '"'
                        '\\' => '\\'
                        '/'  => '/'
                        'b'  => '\b'
                        'f'  => '\f'
                        'n'  => '\n'
                        'r'  => '\r'
                        't'  => '\t'
                        _    => '\NUL'

private
-- Keep a UTF-16 code unit as an integer until the parser checks surrogate pairs.
-- Constructing a host Char for an isolated surrogate is not valid Unicode.
unicodeEscapeValue : String -> Int
unicodeEscapeValue x = fromHex (drop 2 $ fastUnpack x) 0
  where hexVal : Char -> Int
        hexVal c = if c >= 'a' && c <= 'f'
                      then ord c - ord 'a' + 10
                      else if c >= 'A' && c <= 'F'
                           then ord c - ord 'A' + 10
                           else ord c - ord '0'

        fromHex : List Char -> Int -> Int
        fromHex       [] acc = acc
        fromHex (h :: t) acc = fromHex t (hexVal h + 16 * acc)

public export
TokenKind JSONStringTokenKind where
  TokType JSTQuote = ()
  TokType JSTChar = Char
  TokType JSTSimpleEscape = Char
  TokType JSTUnicodeEscape = Int

  tokValue JSTQuote = const ()
  tokValue JSTChar = charValue
  tokValue JSTSimpleEscape = simpleEscapeValue
  tokValue JSTUnicodeEscape = unicodeEscapeValue
