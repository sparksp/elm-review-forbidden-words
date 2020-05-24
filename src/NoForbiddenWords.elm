module NoForbiddenWords exposing (rule)

{-|

@docs rule

-}

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
        |> Rule.fromModuleRuleSchema



--- PRIVATE


commentsVisitor : List String -> List (Node String) -> List (Rule.Error {})
commentsVisitor words comments =
    List.concatMap (\word -> List.concatMap (reviewComment word) comments) words


reviewComment : String -> Node String -> List (Rule.Error {})
reviewComment word comment =
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
