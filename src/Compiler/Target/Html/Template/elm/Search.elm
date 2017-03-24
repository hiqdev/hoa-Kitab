module Search exposing (..)

import Platform.Cmd exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (..)
import Html.Events exposing (..)
import ElmTextSearch exposing (..)

type alias SearchIndexDocument =
    { id: String
    , normalizedName: String
    , description: String
    }

type alias SearchDatabaseDocument =
    { id: String
    , name: String
    , description: String
    , url: String
    }

searchConfiguration =
    { ref = .id
    , fields =
        [ (.normalizedName, 3.0)
        , (.description, 1.0)
        ]
    , listFields = []
    }
        
searchIndex: ElmTextSearch.Index SearchIndexDocument
searchIndex =
    ElmTextSearch.new searchConfiguration

emptySearchDatabaseDocument: SearchDatabaseDocument
emptySearchDatabaseDocument =
    { id = ""
    , name = "(unknown)"
    , description = "(unknown)"
    , url = ""
    }

type alias InitInput =
    { serializedSearchIndex:  String
    , searchDatabase: List SearchDatabaseDocument
    }

init: InitInput -> (Model, Cmd Message)
init input =
    (
        { content = ""
        , searchDatabase = input.searchDatabase
        , searchIndex = Result.withDefault searchIndex (ElmTextSearch.fromString searchConfiguration input.serializedSearchIndex)
        }
        , Cmd.none
    )

type alias Model =
    { content: String
    , searchDatabase: List SearchDatabaseDocument
    , searchIndex: ElmTextSearch.Index SearchIndexDocument
    }

model: Model
model =
    { content = ""
    , searchDatabase = []
    , searchIndex = searchIndex
    }

type Message =
    Search String

update: Message -> Model -> (Model, Cmd Message)
update message model =
    case message of
        Search newContent ->
            ({ model | content = newContent }, Cmd.none)

view: Model -> Html Message
view model =
    let
        searchResults = Result.map (\x -> List.map Tuple.first (Tuple.second x) ) (ElmTextSearch.search model.content model.searchIndex)
    in
    div []
        [ input [ type_ "search" , id "searchInput", value model.content, placeholder "Search anything…" , autocomplete False, onInput Search ] []
        , output [ ariaHidden (String.isEmpty model.content) ]
            [ section [] [ h1 [] [ text ("Search results for “" ++ model.content ++ "”") ] ]
            , case searchResults of
                  Ok searchResults ->
                      ol [ class "list--flat" ]
                          (List.map
                               (\searchResult ->
                                    let
                                        document = Maybe.withDefault emptySearchDatabaseDocument (find (\l -> .id l == searchResult) model.searchDatabase) 
                                    in
                                        li []
                                            [ a [ href ( .url document ) ]
                                                [ code [] [ text ( .name document ) ] ]
                                            , span [] [ text ( .description document ) ] ] )
                               searchResults)
                  _ ->
                      p [] [ text "No result found, sorry!" ]
            ]
        ]

find: (a -> Bool) -> List a -> Maybe a
find predicate list =
    case list of
        [] ->
            Nothing

        first::rest ->
            if predicate first then
                Just first
            else
                find predicate rest

subscriptions: Model -> Sub Message
subscriptions model =
    Sub.none

main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
