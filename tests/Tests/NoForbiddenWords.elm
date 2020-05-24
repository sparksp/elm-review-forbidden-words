module Tests.NoForbiddenWords exposing (all)

import NoForbiddenWords exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoForbiddenWords"
        [ test "with no words reports nothing" <|
            \() ->
                """
module A exposing (..)
-- TODO: Write main
main = Debug.todo ""
"""
                    |> Review.Test.run (rule [])
                    |> Review.Test.expectNoErrors
        , test "reports any found words" <|
            \() ->
                """
module A exposing (..)
-- TODO: Write main
main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports any found words in multi-line comments" <|
            \() ->
                """
module A exposing (..)
{- The entry point for our project.

TODO: Write main

-}
main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports `-- [ ]` as `- [ ]`" <|
            \() ->
                """
module A exposing (..)
-- [ ] Documentation
main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "- [ ]" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "- [ ]"
                        ]
        ]


forbiddenWordError : String -> Review.Test.ExpectedError
forbiddenWordError word =
    Review.Test.error
        { message = "`" ++ word ++ "` is not allowed comments."
        , details =
            [ "You should review this comment and make sure the forbidden word has been removed before publishing your code."
            ]
        , under = word
        }
