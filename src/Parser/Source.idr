module Parser.Source

import public Parser.Lexer.Source
import public Parser.Rule.Source
import public Parser.Unlit

import Core.Core
import Core.Name
import Core.Metadata
import Core.FC

import Data.String
import System.File

%default total

idricWideFloatName : String -> Bool
idricWideFloatName "Double" = True
idricWideFloatName "Float" = True
idricWideFloatName "Float32" = True
idricWideFloatName "Float64" = True
idricWideFloatName _ = False

||| Idriç treats explicit precision names as ragged input rather than a hard
||| contract. Wider floating requests are normalized to the ordinary Float16
||| source type; the original spelling is retained separately for a warning.
promoteIdricToken : Token -> Token
promoteIdricToken (Ident "choice") = Keyword "choice"
promoteIdricToken (Ident n) =
    if idricWideFloatName n
       then Ident "Float16"
       else Ident n
promoteIdricToken tok = tok

||| A decimal token is still lexed with the inherited Double carrier. Wrap it
||| immediately in the Float16 constructor so the source-visible value crosses
||| a binary16 rounding boundary before it participates in Idriç arithmetic.
||| Parentheses keep the injected application atomic when the literal is itself
||| an argument, for example `the Double 1.5`.
promoteIdricBoundedToken : WithBounds Token -> List (WithBounds Token)
promoteIdricBoundedToken tok =
    case tok.val of
         DoubleLit _ =>
           [ map (const (Symbol "(")) tok
           , map (const (Ident "idricFloat16")) tok
           , tok
           , map (const (Symbol ")")) tok
           ]
         _ => [map promoteIdricToken tok]

sourceSyntax : Maybe String -> SourceSyntax
sourceSyntax (Just fname) = if isSuffixOf ".idric" fname
                               then IdricSyntax
                               else IdrisSyntax
sourceSyntax Nothing = IdrisSyntax

sourceTokens : Maybe String -> List (WithBounds Token) -> List (WithBounds Token)
sourceTokens (Just fname) toks
    = if isSuffixOf ".idric" fname
         then concatMap promoteIdricBoundedToken toks
         else toks
sourceTokens Nothing toks = toks

idricFloatWarnings : Maybe String -> OriginDesc -> List (WithBounds Token) -> List Warning
idricFloatWarnings (Just fname) origin toks =
    if isSuffixOf ".idric" fname
       then warnings toks
       else []
  where
    warnings : List (WithBounds Token) -> List Warning
    warnings [] = []
    warnings (tok :: rest) =
      case tok.val of
           Ident n =>
             if idricWideFloatName n
                then ParserWarning
                       (boundToFC origin tok)
                       ("Idriç: requested " ++ n ++ "; running this as Float16")
                       :: warnings rest
                else warnings rest
           _ => warnings rest
idricFloatWarnings Nothing origin toks = []

runParserToSource : {e : _} ->
                    Maybe String ->
                    (origin : OriginDesc) ->
                    Maybe LiterateStyle -> Lexer ->
                    String -> Grammar ParsingState Token e ty ->
                    Either Error (List Warning, State, ty)
runParserToSource sourceFile origin lit reject str p
    = do str        <- mapFst (fromLitError origin) $ unlit lit str
         (cs, toks) <- mapFst (fromLexError origin) $
                         lexToWith (sourceSyntax sourceFile) reject str
         (decs, ws, (parsed, _)) <- mapFst (fromParsingErrors origin) $
                                      parseWith p (sourceTokens sourceFile toks)
         let cs : SemanticDecorations
                = cs <&> \ c => ((origin, start c, end c), Comment, Nothing)
         let ws = ws <&> \ (mb, warn) =>
                    let mkFC = \ b => MkFC origin (startBounds b) (endBounds b)
                    in ParserWarning (maybe EmptyFC mkFC mb) warn
         let profileWarnings = idricFloatWarnings sourceFile origin toks
         let state : State
             state = { decorations $= (cs++) } (toState decs)
         pure (profileWarnings ++ ws, state, parsed)

export
runParserTo : {e : _} ->
              (origin : OriginDesc) ->
              Maybe LiterateStyle -> Lexer ->
              String -> Grammar ParsingState Token e ty ->
              Either Error (List Warning, State, ty)
runParserTo origin lit reject str p
    = runParserToSource Nothing origin lit reject str p

export
runParserToFile : {e : _} ->
                  (sourceFile : String) ->
                  (origin : OriginDesc) ->
                  Maybe LiterateStyle -> Lexer ->
                  String -> Grammar ParsingState Token e ty ->
                  Either Error (List Warning, State, ty)
runParserToFile sourceFile origin lit reject str p
    = runParserToSource (Just sourceFile) origin lit reject str p

export
runParser : {e : _} ->
            (origin : OriginDesc) -> Maybe LiterateStyle -> String ->
            Grammar ParsingState Token e ty ->
            Either Error (List Warning, State, ty)
runParser origin lit = runParserTo origin lit (pred $ const False)

export
runParserFile : {e : _} ->
                (sourceFile : String) ->
                (origin : OriginDesc) -> Maybe LiterateStyle -> String ->
                Grammar ParsingState Token e ty ->
                Either Error (List Warning, State, ty)
runParserFile sourceFile origin lit
    = runParserToFile sourceFile origin lit (pred $ const False)

export covering
parseFile : (fname : String)
         -> (origin : OriginDesc)
         -> Rule ty
         -> IO (Either Error (List Warning, State, ty))
parseFile fname origin p
    = do Right str <- readFile fname
             | Left err => pure (Left (FileErr fname err))
         pure (runParserFile fname origin (isLitFile fname) str p)
