module Compiler.MathematicalExport

import Compiler.Common
import Compiler.MathematicalIR
import Core.Normalise
import Core.Env
import Core.Name
import Idris.Syntax
import IdrisPaths
import Data.List
import Data.String
import Libraries.Utils.Path

%default covering

constructorArguments : String -> ClosedTerm -> Either String (List ClosedTerm)
constructorArguments expected term = case getFnArgs term of
  (Ref _ (DataCon _ _) name, arguments) =>
    if show name == expected then Right arguments else Left ("unsupported mathematical constructor: " ++ show name)
  _ => Left "mathematical export requires a closed constructor term"

naturalTerm : ClosedTerm -> Either String Nat
naturalTerm term = case getFnArgs term of
  (Ref _ (DataCon _ _) name, []) =>
    if show name == "Prelude.Types.Z" then Right Z else Left "invalid coordinate rank or axis"
  (Ref _ (DataCon _ _) name, [rest]) =>
    if show name == "Prelude.Types.S" then S <$> naturalTerm rest else Left "invalid coordinate rank or axis"
  _ => Left "unresolved coordinate rank or axis"

integerTerm : ClosedTerm -> Either String Integer
integerTerm (PrimVal _ (BI value)) = Right value
integerTerm _ = Left "unresolved exact coefficient"

textTerm : ClosedTerm -> Either String String
textTerm (PrimVal _ (Str value)) =
  if validLabel value then Right value else Left "invalid space or frame label"
textTerm _ = Left "unresolved space or frame label"

spaceName : Nat -> ClosedTerm -> Either String String
spaceName rank term = case getFnArgs term of
  (Ref _ (DataCon _ _) name, [rankTerm, label]) =>
    if show name == "MathematicalSpaces.AdditionalSpaceName"
       then do actual <- naturalTerm rankTerm
               if actual == rank then ("named:" ++) <$> textTerm label else Left "space-name rank mismatch"
       else Left "unsupported nominal finite space"
  (Ref _ (DataCon _ _) name, []) =>
    case lookup (show name)
      [("MathematicalSpaces.PlaneName", (2, "Plane")),
       ("MathematicalSpaces.ImagePlaneName", (2, "ImagePlane")),
       ("MathematicalSpaces.RealThreeName", (3, "RealThree")),
       ("MathematicalSpaces.Real32Name", (32, "Real32")),
       ("MathematicalSpaces.OtherReal32Name", (32, "OtherReal32")),
       ("MathematicalSpaces.Real128Name", (128, "Real128"))] of
      Just (actual, label) => if rank == actual then Right label else Left "space-name rank mismatch"
      Nothing => Left "unsupported nominal finite space"
  _ => Left "unresolved nominal finite space"

decodeSpace : ClosedTerm -> ClosedTerm -> ClosedTerm -> Either String RotationSpace
decodeSpace space metric frame = do
  [rankTerm, nameTerm] <- constructorArguments "MathematicalSpaces.NamedFiniteSpace" space
    | _ => Left "invalid finite space"
  rank <- naturalTerm rankTerm
  name <- spaceName rank nameTerm
  [metricRank, metricName] <- constructorArguments "EuclideanGeometry.StandardCoordinate" metric
    | _ => Left "unsupported Euclidean metric"
  actualRank <- naturalTerm metricRank
  actualName <- spaceName actualRank metricName
  if rank == actualRank && name == actualName
     then Right () else Left "metric belongs to another finite space"
  frame <- textTerm frame
  Right (MkRotationSpace name rank frame)

sameSpace : RotationSpace -> RotationSpace -> Bool
sameSpace left right = left.dimension == right.dimension &&
  left.nominalName == right.nominalName && left.orientedFrame == right.orientedFrame

decodeGraph : RotationSpace -> ClosedTerm -> Either String RotationGraph
decodeGraph expected term = case getFnArgs term of
  (Ref _ (DataCon _ _) name, space :: metric :: frame :: rest) => do
    actual <- decodeSpace space metric frame
    if sameSpace expected actual then Right () else Left "rotation space, dimension or frame mismatch"
    case (show name, rest) of
      ("MathematicalRotations.ClosedIdentity", []) => Right Identity
      ("MathematicalRotations.ClosedPlane", [first, second, cosine, sine, denominator, evidence]) => do
        [] <- constructorArguments "Data.So.Oh" evidence
          | _ => Left "unresolved or forged plane evidence"
        result <- Plane <$> naturalTerm first <*> naturalTerm second <*>
                    integerTerm cosine <*> integerTerm sine <*> integerTerm denominator
        validateGraph expected result
        Right result
      ("MathematicalRotations.ClosedInverse", [rotation]) => Inverse <$> decodeGraph expected rotation
      ("MathematicalRotations.ClosedComposition", [left, right]) =>
        Composition <$> decodeGraph expected left <*> decodeGraph expected right
      _ => Left "unknown or incomplete mathematical rotation constructor"
  _ => Left "mathematical root is not a closed rotation"

decodeType : ClosedTerm -> Either String RotationSpace
decodeType term = case getFnArgs term of
  (Ref _ (TyCon _) name, [space, metric, frame]) =>
    if show name == "MathematicalRotations.Rotation"
       then decodeSpace space metric frame else Left "mathematical root has the wrong type"
  _ => Left "mathematical root has the wrong type"

require : Either String a -> Core a
require (Right value) = pure value
require (Left message) = throw (InternalError ("mathematical export: " ++ message))

compileMathematical :
  Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> String ->
  ClosedTerm -> String -> Core (Maybe String)
compileMathematical context _ _ outputDirectory _ outputFile = do
  directives <- getDirectives (Other "idric-mathematical")
  [root] <- pure $ mapMaybe
    (\directive => if isPrefixOf "root=" directive
                     then Just (substr 5 (length directive) directive) else Nothing) directives
    | _ => throw (InternalError "mathematical export: supply exactly one --directive root=NAME")
  defs <- get Ctxt
  [(name, _, definition)] <- lookupCtxtName (UN (Basic root)) (gamma defs)
    | _ => throw (InternalError "mathematical export: root name is missing or ambiguous")
  -- Unlike getCompileData, normaliseAll reads the checked Core term without
  -- passing through CompileExpr or its erasure rules. Every node is decoded;
  -- no hard-coded R128 body or trusted status string is printed.
  checkedType <- toFullNames !(normaliseAll defs [] definition.type)
  checkedTerm <- toFullNames !(normaliseAll defs [] (the ClosedTerm (Ref definition.location Func name)))
  space <- require (decodeType checkedType)
  graph <- require (decodeGraph space checkedTerm)
  let provenance = [("definition", show name), ("span", show definition.location),
                    ("checked_type", show (show checkedType)),
                    ("normalized_term", show (show checkedTerm)),
                    ("checker", show idrisVersion)]
  body <- require (renderArtifact space graph provenance)
  _ <- require (parseArtifact body)
  let output = outputDirectory </> outputFile
  Core.writeFile output body
  pure (Just output)

executeMathematical : Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> ClosedTerm -> Core ()
executeMathematical _ _ _ _ = throw (InternalError "mathematical export does not execute machine code")

export
codegenMathematical : Codegen
codegenMathematical = MkCG compileMathematical executeMathematical Nothing Nothing
