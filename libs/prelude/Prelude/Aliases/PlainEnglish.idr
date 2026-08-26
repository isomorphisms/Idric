module Prelude.Aliases.PlainEnglish

import Builtin
import Prelude.IO
import Prelude.Show

-- Alternate plain-English spellings for the canonical descriptive I/O names.
-- This module contains aliases only; behavior belongs to Prelude.IO.

%inline export
write_string_of_characters : HasIO io => String -> io ()
write_string_of_characters = write_out_string_of_characters

%inline export
output_string_of_characters : HasIO io => String -> io ()
output_string_of_characters = write_out_string_of_characters

%inline export
write_string_of_characters_with_newline : HasIO io => String -> io ()
write_string_of_characters_with_newline = write_out_string_of_characters_with_newline

%inline export
write_line_of_characters : HasIO io => String -> io ()
write_line_of_characters = write_out_string_of_characters_with_newline

%inline export
output_line_of_characters : HasIO io => String -> io ()
output_line_of_characters = write_out_string_of_characters_with_newline

%inline export
read_line_of_characters : HasIO io => io String
read_line_of_characters = ingest_line_of_characters

%inline export
write_character : HasIO io => Char -> io ()
write_character = write_out_character

%inline export
write_single_character : HasIO io => Char -> io ()
write_single_character = write_out_character

%inline export
output_character : HasIO io => Char -> io ()
output_character = write_out_character

%inline export
write_character_with_newline : HasIO io => Char -> io ()
write_character_with_newline = write_out_character_with_newline

%inline export
write_single_character_with_newline : HasIO io => Char -> io ()
write_single_character_with_newline = write_out_character_with_newline

%inline export
output_character_with_newline : HasIO io => Char -> io ()
output_character_with_newline = write_out_character_with_newline

%inline export
read_character : HasIO io => io Char
read_character = ingest_character

%inline export
read_single_character : HasIO io => io Char
read_single_character = ingest_character

%inline export
write_showable_value : HasIO io => Show a => a -> io ()
write_showable_value = write_out_showable_value

%inline export
write_showable_value_with_newline : HasIO io => Show a => a -> io ()
write_showable_value_with_newline = write_out_showable_value_with_newline
