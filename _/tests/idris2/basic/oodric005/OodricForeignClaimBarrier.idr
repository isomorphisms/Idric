module OodricForeignClaimBarrier

library_call : String -> String
library_call symbol = "C:" ++ symbol ++ ", libidris2_support, idris_term.h"

%foreign library_call "idris2_getTermCols"
prim__getTermCols : PrimIO Int
