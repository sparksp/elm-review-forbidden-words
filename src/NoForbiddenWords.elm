module NoForbiddenWords exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Review.Rule as Rule exposing (Rule)


{-| Forbid certain words in comments.

    config : List Rule
    config =
        [ NoForbiddenWords.rule [ "TODO", "- [ ]" ]
        ]


## Failure Examples

Based on the configured words `TODO` and `- [ ]` the following examples would fail:

    -- TODO: Finish writing this function




    {- Actions
       - [ ] Documentation
       - [ ] Tests
    -}

-}
rule : List String -> Rule
rule words =
    Rule.newModuleRuleSchema "NoForbiddenWords" ()
        |> Rule.withSimpleCommentsVisitor (commentsVisitor words)
        |> Rule.withSimpleDeclarationVisitor (declarationVisitor words)
        |> Rule.fromModuleRuleSchema



--- PRIVATE


commentsVisitor : List String -> List (Node String) -> List (Rule.Error {})
commentsVisitor words comments =
    List.concatMap (commentVisitor words) comments


declarationVisitor : List String -> Node Declaration -> List (Rule.Error {})
declarationVisitor words (Node _ declaration) =
    case declaration of
        Declaration.FunctionDeclaration { documentation } ->
            documentation
                |> Maybe.map (commentVisitor words)
                |> Maybe.withDefault []

        Declaration.CustomTypeDeclaration { documentation } ->
            documentation
                |> Maybe.map (commentVisitor words)
                |> Maybe.withDefault []

        Declaration.AliasDeclaration { documentation } ->
            documentation
                |> Maybe.map (commentVisitor words)
                |> Maybe.withDefault []

        _ ->
            []


commentVisitor : List String -> Node String -> List (Rule.Error {})
commentVisitor words comment =
    List.concatMap (checkForbiddenWord comment) words


checkForbiddenWord : Node String -> String -> List (Rule.Error {})
checkForbiddenWord comment word =
    ranges word comment
        |> List.map (forbiddenWordError word)


ranges : String -> Node String -> List Range
ranges needle (Node range haystack) =
    String.lines haystack
        |> List.indexedMap
            (\row line ->
                String.indexes needle line
                    |> List.map
                        (\index ->
                            if row == 0 then
                                { start =
                                    { row = range.start.row
                                    , column = range.start.column + index
                                    }
                                , end =
                                    { row = range.start.row
                                    , column = range.start.column + index + String.length needle
                                    }
                                }

                            else
                                { start =
                                    { row = range.start.row + row
                                    , column = index + 1
                                    }
                                , end =
                                    { row = range.start.row + row
                                    , column = index + 1 + String.length needle
                                    }
                                }
                        )
            )
        |> List.concat


forbiddenWordError : String -> Range -> Rule.Error {}
forbiddenWordError word range =
    Rule.error
        { message = "`" ++ word ++ "` is not allowed comments."
        , details =
            [ "You should review this comment and make sure the forbidden word has been removed before publishing your code."
            ]
        }
        range
