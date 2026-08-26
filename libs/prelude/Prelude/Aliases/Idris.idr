module Prelude.Aliases.Idris

import Prelude.IO
import Prelude.Show

-- Traditional Idris spellings retained as compatibility aliases.
-- This module contains aliases only; behavior belongs to Prelude.IO.

%inline export
putStr : HasIO io => String -> io ()
putStr = write_out_string_of_characters

%inline export
putStrLn : HasIO io => String -> io ()
putStrLn = write_out_string_of_characters_with_newline

%inline export
getLine : HasIO io => io String
getLine = ingest_line_of_characters

%inline export
putChar : HasIO io => Char -> io ()
putChar = write_out_character

%inline export
putCharLn : HasIO io => Char -> io ()
putCharLn = write_out_character_with_newline

%inline export
getChar : HasIO io => io Char
getChar = ingest_character

%inline export
print : HasIO io => Show a => a -> io ()
print = write_out_showable_value

%inline export
printLn : HasIO io => Show a => a -> io ()
printLn = write_out_showable_value_with_newline
