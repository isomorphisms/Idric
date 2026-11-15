module Language.JSON.String.Parser

import Language.JSON.String.Tokens
import Text.Lexer
import Text.Parser

%default total

private
singleUnicodeUnit : Int -> Grammar state JSONStringToken False Char
singleUnicodeUnit unit =
  if unit >= 0xD800 && unit <= 0xDFFF
    then fail "isolated surrogate"
    else pure $ chr unit

private
surrogatePairValue : Int -> Int -> Grammar state JSONStringToken False Char
surrogatePairValue first second =
  if first >= 0xD800 && first <= 0xDBFF && second >= 0xDC00 && second <= 0xDFFF
    then pure $ chr (0x10000 + (first - 0xD800) * 0x400 + second - 0xDC00)
    else fail "invalid surrogate pair"

private
unicodePair : Grammar state JSONStringToken True Char
unicodePair = do
  first <- match JSTUnicodeEscape
  -- JSON spells supplementary scalars with a UTF-16 high/low surrogate pair.
  second <- match JSTUnicodeEscape
  surrogatePairValue first second

private
unicodeChar : Grammar state JSONStringToken True Char
unicodeChar = unicodePair <|> do
  unit <- match JSTUnicodeEscape
  singleUnicodeUnit unit

private
stringChar : Grammar state JSONStringToken True Char
stringChar = match JSTChar
         <|> match JSTSimpleEscape
         <|> unicodeChar

private
quotedString : Grammar state JSONStringToken True String
quotedString = let q = match JSTQuote in
                   do chars <- between q q (many stringChar)
                      eof
                      pure $ pack chars

export
parseString : List (WithBounds JSONStringToken) -> Maybe String
parseString toks = case parse quotedString toks of
                        Right (str, []) => Just str
                        _ => Nothing
