module Tests.NoForbiddenWords exposing (all)

import NoForbiddenWords exposing (rule)
import Review.Project as Project exposing (Project)
import Review.Rule
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
        , test "reports forbidden words in module documentation" <|
            \() ->
                """
module A exposing (..)
{-| Module A

TODO: Write the documentation
-}
import Foo

main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports forbidden words in function documentation" <|
            \() ->
                """
module A exposing (..)
{-| Module A
-}
import Foo

{-| Main

TODO: Write the documentation
-}
main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports forbidden words in type documentation" <|
            \() ->
                """
module A exposing (..)
import Foo

{-| Page

TODO: Add more pages
-}
type Page
    = Page

main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports forbidden words in type alias documentation" <|
            \() ->
                """
module A exposing (..)
import Foo

{-| Page

TODO: Add footer
-}
type alias Page =
    { title : String, body : List (Html msg) }

main = Debug.todo ""
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "reports forbidden words in port documentation" <|
            \() ->
                """
port module Ports exposing (..)
import Foo

{-| Save

TODO: Use Json.Encode.Value here.
-}
port save : String -> Cmd Msg
"""
                    |> Review.Test.run (rule [ "TODO" ])
                    |> Review.Test.expectErrors
                        [ forbiddenWordError "TODO"
                        ]
        , test "checks forbidden words in README.md" <|
            \() ->
                let
                    project : Project
                    project =
                        Project.new
                            |> Project.addReadme
                                { path = "README.md"
                                , content = """
# My Awesome Project

TODO: Write the readme
"""
                                }
                in
                """
module A exposing (..)
a = 1"""
                    |> Review.Test.runWithProjectData project (rule [ "TODO" ])
                    |> Review.Test.expectErrorsForReadme
                        [ forbiddenWordErrorForReadme "TODO"
                        ]
        , test "forbidden words in README.md can be ignored" <|
            \() ->
                let
                    project : Project
                    project =
                        Project.new
                            |> Project.addReadme
                                { path = "README.md"
                                , content = """
# My Awesome Project

TODO: Write the readme
"""
                                }
                in
                """
module A exposing (..)
a = 1"""
                    |> Review.Test.runWithProjectData project
                        (rule [ "TODO" ]
                            |> Review.Rule.ignoreErrorsForFiles [ "README.md" ]
                        )
                    |> Review.Test.expectNoErrors
        ]


forbiddenWordError : String -> Review.Test.ExpectedError
forbiddenWordError word =
    Review.Test.error
        { message = "`" ++ word ++ "` is not allowed in comments."
        , details =
            [ "You should review this comment and make sure the forbidden word has been removed before publishing your code."
            ]
        , under = word
        }


forbiddenWordErrorForReadme : String -> Review.Test.ExpectedError
forbiddenWordErrorForReadme word =
    Review.Test.error
        { message = "`" ++ word ++ "` is not allowed in README file."
        , details =
            [ "You should review this section and make sure the forbidden word has been removed before publishing your code."
            ]
        , under = word
        }
