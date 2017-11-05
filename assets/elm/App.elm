module App exposing (..)

import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import EnPlot as EnPlot exposing (Plot, Point, plotDecoder)
import Highlight exposing (highlight)
import Html exposing (..)
import Html.Attributes exposing (attribute, type_, value)
import Html.Events exposing (..)
import Json.Decode as JD exposing (field)
import Json.Encode as JE
import Keyboard
import List exposing (..)
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket
import Process exposing (sleep)
import String exposing (toLower)
import Task
import Time exposing (Time, now)


---------------------
-- type defintions --
---------------------


type alias Model =
    { outputCells : List Renderable
    , inputCells : List String
    , phoenixSocket : Phoenix.Socket.Socket Msg
    , inputState : String
    , shiftDown : Bool
    , updatedAt : Maybe Time
    }


type alias ChatMessage =
    { user : String
    , body : Renderable
    }


type Msg
    = Input String
    | KeyDown Keyboard.KeyCode
    | KeyUp Keyboard.KeyCode
    | SendMessage
    | ReceiveChatMessage JE.Value
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | SetUpdatedAt Time
    | Highlight ()


type alias Renderable =
    { kind : RenderableKind
    , content : String
    }


type RenderableKind
    = Text
    | HTML
    | Plot
    | KindError String



---------------
-- functions --
---------------


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    let
        socket =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "new:msg" "room:lobby" ReceiveChatMessage

        channel =
            Phoenix.Channel.init "room:lobby"
                |> Phoenix.Channel.withPayload userParams

        ( phoenixSocket, phxCmd ) =
            Phoenix.Socket.join channel socket
    in
    ( { outputCells = []
      , inputCells = []
      , phoenixSocket = phoenixSocket
      , inputState = ""
      , shiftDown = False
      , updatedAt = Nothing
      }
    , Cmd.map PhoenixMsg phxCmd
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.phoenixSocket PhoenixMsg
        , Keyboard.downs KeyDown
        , Keyboard.ups KeyUp
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendMessage ->
            let
                payload =
                    JE.object [ ( "user", JE.string "user" ), ( "body", JE.string model.inputState ) ]

                push_ =
                    Phoenix.Push.init "new:msg" "room:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phoenixSocket, phxCmd ) =
                    Phoenix.Socket.push push_ model.phoenixSocket
            in
            ( { model
                | phoenixSocket = phoenixSocket
                , inputState = ""
                , inputCells = String.trim model.inputState :: model.inputCells
              }
            , Cmd.map PhoenixMsg phxCmd
            )

        Input str ->
            ( { model | inputState = str }
            , Cmd.none
            )

        ReceiveChatMessage msg ->
            case JD.decodeValue chatMessageDecoder msg of
                Ok chatMessage ->
                    { model | outputCells = chatMessage.body :: model.outputCells } ! [ Task.perform SetUpdatedAt Time.now, Task.perform Highlight (Process.sleep (100 * Time.millisecond)) ]

                Err error ->
                    model ! [ Task.perform SetUpdatedAt Time.now, Task.perform Highlight (Process.sleep (100 * Time.millisecond)) ]

        KeyDown keycode ->
            if keycode == 16 then
                ( { model | shiftDown = True }, Cmd.none )
            else
                ( model, Cmd.none )

        KeyUp keycode ->
            if keycode == 16 then
                ( { model | shiftDown = False }, Cmd.none )
            else if model.shiftDown && keycode == 13 then
                update SendMessage model
            else
                ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( phoenixSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phoenixSocket
            in
            ( { model | phoenixSocket = phoenixSocket }
            , Cmd.map PhoenixMsg phxCmd
            )

        SetUpdatedAt time ->
            ( { model | updatedAt = Just (Time.inMilliseconds time) }, Cmd.none )

        Highlight _ ->
            ( model, highlight () )


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet
        , div []
            [ drawCellsList model.inputCells model.outputCells
            , inputStateForm model
            ]
        ]


render : Renderable -> Html Msg
render data =
    case data.kind of
        Text ->
            -- Text is the default, and it highlights things as if they are Elixir values
            codeBlock data.content "Elixir"

        HTML ->
            -- HTML injects the string into the dom as raw HTML
            rawHtml data.content

        Plot ->
            case JD.decodeString plotDecoder data.content of
                Ok plot ->
                    EnPlot.series plot

                Err error ->
                    div []
                        [ div [] [ text "Invalid data returned. This should never happen. Please file a bug." ]
                        , br [] []
                        , div [] [ text "Args:" ]
                        , div [] [ text data.content ]
                        , br [] []
                        , div [] [ text "Error:" ]
                        , div [] [ text error ]
                        ]

        KindError err ->
            div [] [ text err ]


inputStateForm : Model -> Html Msg
inputStateForm model =
    form
        [ attribute "id" "cellForm"
        , onSubmit SendMessage
        ]
        [ textarea
            [ attribute "type" "text"
            , attribute "class" "form-control"
            , attribute "form" "cellForm"
            , attribute "style" "outline-color:#FF29D2;outline-width:1px;outline-style:solid"
            , value model.inputState
            , onInput Input
            , attribute "rows" "5"
            ]
            []
        ]


drawCellsList : List String -> List Renderable -> Html Msg
drawCellsList inputCells outputCells =
    div [ attribute "class" "cell" ]
        (List.map2
            (\inputCell outputCell -> [ drawCells inputCell outputCell ])
            (List.reverse inputCells)
            (List.reverse outputCells)
            |> foldr (++) []
        )


drawCells : String -> Renderable -> Html Msg
drawCells inputCell outputCell =
    div []
        [ div [ attribute "class" "input-cell" ]
            [ codeBlock inputCell "elixir" ]
        , div [ attribute "class" "output-cell" ] [ render outputCell ]
        ]


rawHtml : String -> Html msg
rawHtml string =
    -- this is some hack shit because Elm is pure
    div [ Html.Attributes.property "innerHTML" (JE.string string) ] []


codeBlock : String -> String -> Html msg
codeBlock a lang =
    pre []
        [ code [ attribute "class" lang ]
            [ text a ]
        ]



-------------------
-- JSON encoders --
-------------------


userParams : JE.Value
userParams =
    JE.object [ ( "user_id", JE.string "123" ) ]



-------------------
-- JSON decoders --
-------------------


chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
    JD.map2 ChatMessage
        (field "user" JD.string)
        (field "body" renderableDecoder)


renderableDecoder : JD.Decoder Renderable
renderableDecoder =
    JD.map2 Renderable
        (field "kind" renderableKindDecoder)
        (field "content" JD.string)


renderableKindDecoder : JD.Decoder RenderableKind
renderableKindDecoder =
    JD.map decodeRenderableKind JD.string


decodeRenderableKind : String -> RenderableKind
decodeRenderableKind string =
    case toLower string of
        "text" ->
            Text

        "html" ->
            HTML

        "plot" ->
            Plot

        _ ->
            KindError ("cannot parse kind " ++ string)
