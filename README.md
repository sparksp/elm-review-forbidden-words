# review-forbidden-words

![elm package](https://img.shields.io/elm-package/v/sparksp/elm-review-forbidden-words)
![elm-review 2.0](https://img.shields.io/badge/elm--review-2.0-%231293D8)
![elm 0.19](https://img.shields.io/badge/elm-0.19-%231293D8)
![Tests](https://github.com/sparksp/elm-review-forbidden-words/workflows/Tests/badge.svg)

An [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rule to forbid certain words in Elm comments, README and elm.json.

## Example Configuration

```elm
import NoForbiddenWords
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoForbiddenWords.rule [ "TODO", "- [ ]" ]
    ]
```

Note: We search for the exact string that you enter, so if you're looking for "TODO" we won't report "todo".

## Failure Examples

Based on the configured words `"TODO"` and `"- [ ]"` the following examples would fail:

```elm
-- TODO: Finish writing this function
   ^^^^
-- [ ] Documentation
 ^^^^^
```

```elm
{- Actions
    - [ ] Documentation
    ^^^^^
    - [ ] Tests
    ^^^^^
-}
```

```json
{
    "summary": "TODO write a summary",
                ^^^^
}
```

## Ignore README.md

You can easily ignore forbidden words in the README file like this:

```elm
import NoForbiddenWords
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoForbiddenWords.rule [ "TODO", "- [ ]" ]
        |> Rule.ignoreErrorsForFiles [ "README.md" ]
    ]
```