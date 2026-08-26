module Prelude.IO

import Builtin
import PrimIO
import Prelude.Basics
import Prelude.Interfaces
import Prelude.Show

%default total

--------
-- IO --
--------

public export
Functor IO where
  map f io = io_bind io $ io_pure . f

%inline
public export
Applicative IO where
  pure x = io_pure x
  f <*> a
      = io_bind f (\f' =>
          io_bind a (\a' =>
            io_pure (f' a')))

%inline
public export
Monad IO where
  b >>= k = io_bind b k

public export
interface Monad io => HasIO io where
  constructor MkHasIO
  liftIO : IO a -> io a

public export
interface Monad io => HasLinearIO io where
  constructor MkHasLinearIO
  liftIO1 : (1 _ : IO a) -> io a

public export %inline
HasLinearIO IO where
  liftIO1 x = x

public export %inline
HasLinearIO io => HasIO io where
  liftIO x = liftIO1 x

export %inline
primIO : HasIO io => (fn : (1 x : %World) -> IORes a) -> io a
primIO op = liftIO (fromPrim op)

export %inline
primIO1 : HasLinearIO io => (1 fn : (1 x : %World) -> IORes a) -> io a
primIO1 op = liftIO1 (fromPrim op)

%extern
prim__onCollectAny : AnyPtr -> (AnyPtr -> PrimIO ()) -> PrimIO GCAnyPtr
%extern
prim__onCollect : Ptr t -> (Ptr t -> PrimIO ()) -> PrimIO (GCPtr t)

export
onCollectAny : HasIO io => AnyPtr -> (AnyPtr -> IO ()) -> io GCAnyPtr
onCollectAny ptr c = primIO (prim__onCollectAny ptr (\x => toPrim (c x)))

export
onCollect : HasIO io => Ptr t -> (Ptr t -> IO ()) -> io (GCPtr t)
onCollect ptr c = primIO (prim__onCollect ptr (\x => toPrim (c x)))

%foreign "C:idris2_getString, libidris2_support, idris_support.h"
         "javascript:lambda:x=>x"
export
prim__getString : Ptr String -> String

%foreign "C:putchar,libc 6"
         "node:lambda:x=>process.stdout.write(x)"
         "browser:lambda:x=>console.log(x)"
prim__putChar : Char -> (1 x : %World) -> IORes ()

%foreign "C:getchar,libc 6"
         "node:support:getChar,support_system_file"
%extern prim__getChar : (1 x : %World) -> IORes Char

%foreign "C:idris2_getStr, libidris2_support, idris_support.h"
         "node:support:getStr,support_system_file"
prim__getStr : PrimIO String

%foreign "C:idris2_putStr, libidris2_support, idris_support.h"
         "node:lambda:x=>process.stdout.write(x)"
         "browser:lambda:x=>console.log(x)"
prim__putStr : String -> PrimIO ()

-- The descriptive snake_case names below are the primary language-facing names.
-- Traditional short names remain as thin compatibility aliases.

||| Write a string of characters to stdout without a trailing newline.
%inline export
write_out_string_of_characters : HasIO io => String -> io ()
write_out_string_of_characters characters = primIO (prim__putStr characters)

%inline export
write_string_of_characters : HasIO io => String -> io ()
write_string_of_characters = write_out_string_of_characters

%inline export
output_string_of_characters : HasIO io => String -> io ()
output_string_of_characters = write_out_string_of_characters

%inline export
putStr : HasIO io => String -> io ()
putStr = write_out_string_of_characters

||| Write a string of characters to stdout followed by a newline.
%inline export
write_out_string_of_characters_with_newline : HasIO io => String -> io ()
write_out_string_of_characters_with_newline characters =
  write_out_string_of_characters (prim__strAppend characters "\n")

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
putStrLn : HasIO io => String -> io ()
putStrLn = write_out_string_of_characters_with_newline

||| Ingest one line of characters from stdin, without the trailing newline.
%inline export
ingest_line_of_characters : HasIO io => io String
ingest_line_of_characters = primIO prim__getStr

%inline export
read_line_of_characters : HasIO io => io String
read_line_of_characters = ingest_line_of_characters

%inline export
getLine : HasIO io => io String
getLine = ingest_line_of_characters

||| Write one single-byte character to stdout.
%inline export
write_out_character : HasIO io => Char -> io ()
write_out_character character = primIO (prim__putChar character)

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
putChar : HasIO io => Char -> io ()
putChar = write_out_character

||| Write one character to stdout followed by a newline.
%inline export
write_out_character_with_newline : HasIO io => Char -> io ()
write_out_character_with_newline character =
  write_out_string_of_characters_with_newline (prim__cast_CharString character)

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
putCharLn : HasIO io => Char -> io ()
putCharLn = write_out_character_with_newline

||| Ingest one single-byte character from stdin.
%inline export
ingest_character : HasIO io => io Char
ingest_character = primIO prim__getChar

%inline export
read_character : HasIO io => io Char
read_character = ingest_character

%inline export
read_single_character : HasIO io => io Char
read_single_character = ingest_character

%inline export
getChar : HasIO io => io Char
getChar = ingest_character

%foreign "scheme:blodwen-thread"
         "C:refc_fork"
export
prim__fork : (1 prog : PrimIO ()) -> PrimIO ThreadID

export
fork : (1 prog : IO ()) -> IO ThreadID
fork act = fromPrim (prim__fork (toPrim act))

%foreign "scheme:blodwen-thread-wait"
export
prim__threadWait : (1 threadID : ThreadID) -> PrimIO ()

export
threadWait : (1 threadID : ThreadID) -> IO ()
threadWait threadID = fromPrim (prim__threadWait threadID)

||| Write a showable value to stdout without a trailing newline.
%inline export
write_out_showable_value : HasIO io => Show a => a -> io ()
write_out_showable_value = write_out_string_of_characters . show

%inline export
write_showable_value : HasIO io => Show a => a -> io ()
write_showable_value = write_out_showable_value

%inline export
print : HasIO io => Show a => a -> io ()
print = write_out_showable_value

||| Write a showable value to stdout followed by a newline.
%inline export
write_out_showable_value_with_newline : HasIO io => Show a => a -> io ()
write_out_showable_value_with_newline = write_out_string_of_characters_with_newline . show

%inline export
write_showable_value_with_newline : HasIO io => Show a => a -> io ()
write_showable_value_with_newline = write_out_showable_value_with_newline

%inline export
printLn : HasIO io => Show a => a -> io ()
printLn = write_out_showable_value_with_newline
