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

canonicalizeIdricToken : Token -> Token
canonicalizeIdricToken (Ident "choice") = Keyword "choice"
canonicalizeIdricToken (Ident "ℕ") = Ident "Nat"
canonicalizeIdricToken (Keyword "prefix") = Ident "prefix"
canonicalizeIdricToken tok = tok

sourceSyntax : Maybe String -> SourceSyntax
sourceSyntax (Just fname) = if isSuffixOf ".idric" fname
                               then IdricSyntax
                               else IdrisSyntax
sourceSyntax Nothing = IdrisSyntax

sourceTokens : Maybe String -> List (WithBounds Token) -> List (WithBounds Token)
sourceTokens (Just fname) toks
    = if isSuffixOf ".idric" fname
         then map (map canonicalizeIdricToken) toks
         else toks
sourceTokens Nothing toks = toks

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
         let state : State
             state = { decorations $= (cs++) } (toState decs)
         pure (ws, state, parsed)

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
