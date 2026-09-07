module OodricLiteralForeignForward

read_columns : PrimIO Int
read_columns = prim__getTermCols

%foreign "C:idris2_getTermCols, libidris2_support, idris_term.h"
prim__getTermCols : PrimIO Int
