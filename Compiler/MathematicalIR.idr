module Compiler.MathematicalIR

import Data.List
import Data.List1
import Data.String

%default total

-- Internal interchange, not source syntax. This deliberately independent
-- validator never consumes a textual PASS or a digest as mathematical evidence.
public export
record RotationSpace where
  constructor MkRotationSpace
  nominalName : String
  dimension : Nat
  orientedFrame : String

public export
data RotationGraph
  = Identity
  | Plane Nat Nat Integer Integer Integer
  | Inverse RotationGraph
  | Composition RotationGraph RotationGraph

public export
record MathematicalArtifact where
  constructor MkMathematicalArtifact
  space : RotationSpace
  graph : RotationGraph
  provenance : List (String, String)
  originalArtifact : String

export
validLabel : String -> Bool
validLabel value = value /= "" && all (\c => c >= ' ' && c /= '\127') (unpack value)

export
validateGraph : RotationSpace -> RotationGraph -> Either String ()
validateGraph space Identity = Right ()
validateGraph space (Plane first second cosine sine denominator) =
  if first >= space.dimension || second >= space.dimension || first == second
     then Left "rotation axes must be distinct and inside the dimension"
     else if denominator <= 0 || cosine * cosine + sine * sine /= denominator * denominator
       then Left "rotation coefficients must form an exact rational unit pair"
       else Right ()
validateGraph space (Inverse rotation) = validateGraph space rotation
validateGraph space (Composition left right) = do
  validateGraph space left
  validateGraph space right

renderNodes : String -> RotationGraph -> List String
renderNodes identifier Identity = ["node\t" ++ identifier ++ "\tidentity"]
renderNodes identifier (Plane first second cosine sine denominator) =
  [concat ["node\t", identifier, "\tplane\t", show first, "\t", show second,
           "\t", show cosine, "\t", show sine, "\t", show denominator]]
renderNodes identifier (Inverse rotation) =
  ("node\t" ++ identifier ++ "\tinverse\t" ++ identifier ++ ".i") ::
  renderNodes (identifier ++ ".i") rotation
renderNodes identifier (Composition left right) =
  ("node\t" ++ identifier ++ "\tcomposition\t" ++ identifier ++ ".l\t" ++ identifier ++ ".r") ::
  (renderNodes (identifier ++ ".l") left ++ renderNodes (identifier ++ ".r") right)

-- A fixed provenance vocabulary prevents unrecognized authority claims.
export
provenanceKeys : List String
provenanceKeys = ["definition", "span", "checked_type", "normalized_term", "checker"]

export
renderArtifact : RotationSpace -> RotationGraph -> List (String, String) -> Either String String
renderArtifact space graph provenance = do
  if validLabel space.nominalName && validLabel space.orientedFrame
     then Right () else Left "space and frame labels must be nonempty single-line text"
  if map fst provenance == provenanceKeys && all (validLabel . snd) provenance
     then Right () else Left "missing or malformed mathematical provenance"
  validateGraph space graph
  Right $ unlines $
    ["IDRIC_MATHEMATICAL\t1",
     "space\t" ++ space.nominalName ++ "\t" ++ show space.dimension ++
       "\tstandard-euclidean\t" ++ space.orientedFrame ++ "\tpositive",
     "evidence\tindependently-validated-closed-constructor"] ++
    renderNodes "r" graph ++
    map (\(key, value) => "source\t" ++ key ++ "\t" ++ value) provenance ++ ["end"]

natural : String -> Either String Nat
natural value = case parsePositive {a = Nat} value of
  Just result => if show result == value then Right result else Left "noncanonical dimension or axis"
  Nothing => Left "invalid dimension or axis"

integer : String -> Either String Integer
integer value = case parseInteger value of
  Just result => if show result == value then Right result else Left "noncanonical integer coefficient"
  Nothing => Left "invalid integer coefficient"

parseNodes : Nat -> String -> List (List String) -> Either String (RotationGraph, List (List String))
parseNodes Z _ _ = Left "incomplete mathematical graph"
parseNodes (S fuel) identifier (["node", actual, "identity"] :: rest) =
  if actual == identifier then Right (Identity, rest) else Left "incorrect mathematical node identity"
parseNodes (S fuel) identifier (["node", actual, "plane", first, second, cosine, sine, denominator] :: rest) = do
  if actual == identifier then Right () else Left "incorrect mathematical node identity"
  first <- natural first
  second <- natural second
  cosine <- integer cosine
  sine <- integer sine
  denominator <- integer denominator
  Right (Plane first second cosine sine denominator, rest)
parseNodes (S fuel) identifier (["node", actual, "inverse", child] :: rest) = do
  if actual == identifier && child == identifier ++ ".i"
     then Right () else Left "invalid inverse node reference"
  (rotation, rest) <- parseNodes fuel child rest
  Right (Inverse rotation, rest)
parseNodes (S fuel) identifier (["node", actual, "composition", left, right] :: rest) = do
  if actual == identifier && left == identifier ++ ".l" && right == identifier ++ ".r"
     then Right () else Left "invalid composition node references"
  (leftGraph, rest) <- parseNodes fuel left rest
  (rightGraph, rest) <- parseNodes fuel right rest
  Right (Composition leftGraph rightGraph, rest)
parseNodes _ _ _ = Left "unknown, incomplete or malformed mathematical node"

parseProvenance : List String -> List (List String) -> Either String (List (String, String))
parseProvenance [] [["end"]] = Right []
parseProvenance (key :: keys) (["source", actual, value] :: rest) =
  if key == actual && validLabel value
     then ((key, value) ::) <$> parseProvenance keys rest
     else Left "missing or malformed mathematical provenance"
parseProvenance _ _ = Left "missing provenance, unexpected fields or trailing artifact data"

export
parseArtifact : String -> Either String MathematicalArtifact
parseArtifact original = case map (forget . split (== '\t')) (lines original) of
  ["IDRIC_MATHEMATICAL", "1"] ::
    ["space", nominalName, rank, "standard-euclidean", frame, "positive"] ::
    ["evidence", "independently-validated-closed-constructor"] :: rest => do
      rank <- natural rank
      let space = MkRotationSpace nominalName rank frame
      if validLabel nominalName && validLabel frame
         then Right () else Left "invalid nominal space or frame"
      (graph, rest) <- parseNodes (length rest) "r" rest
      validateGraph space graph
      provenance <- parseProvenance provenanceKeys rest
      Right (MkMathematicalArtifact space graph provenance original)
  _ => Left "unsupported mathematical schema, metric, orientation or evidence category"
