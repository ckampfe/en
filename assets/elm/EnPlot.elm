module EnPlot exposing (..)

import Json.Decode as JD exposing (field)
import Plot exposing (..)
import String exposing (toLower)
import Svg exposing (Svg)
import Svg.Attributes exposing (stroke)


---------------------
-- type defintions --
---------------------


type alias Point =
    { x : Float
    , y : Float
    }


type SeriesType
    = Area
    | Dots
    | Line
    | UnknownSeries


type PointType
    = Clear
    | Square
    | Circle
    | Diamond
    | Triangle
    | UnknownPoint


type alias Plot =
    { x_axis_label : String
    , y_axis_label : String
    , data : List Point
    , series_type : SeriesType
    , point_type : PointType
    , interpolation : ( Maybe String, String ) -> Plot.Interpolation
    , area_color : Maybe String
    , stroke_color : String
    }



---------------
-- functions --
---------------


series : Plot -> Svg msg
series plot =
    let
        pointType =
            case plot.point_type of
                Clear ->
                    \{ x, y } -> clear x y

                Square ->
                    \{ x, y } -> dot (viewSquare 10 plot.stroke_color) x y

                Circle ->
                    \{ x, y } -> dot (viewCircle 5 plot.stroke_color) x y

                Diamond ->
                    \{ x, y } -> dot (viewDiamond 10 10 plot.stroke_color) x y

                Triangle ->
                    \{ x, y } -> dot (viewTriangle plot.stroke_color) x y

                _ ->
                    -- default to circle
                    \{ x, y } -> dot (viewCircle 5 plot.stroke_color) x y

        seriesType =
            case plot.series_type of
                Area ->
                    area (List.map pointType)

                Dots ->
                    dots (List.map pointType)

                Line ->
                    line (List.map pointType)

                _ ->
                    -- default to line
                    line (List.map pointType)

        series seriesType =
            { axis = normalAxis
            , interpolation = plot.interpolation ( plot.area_color, plot.stroke_color )
            , toDataPoints = seriesType
            }
    in
    viewSeries [ series (List.map pointType) ] plot.data


translateToMaybeColor : String -> Maybe String
translateToMaybeColor str =
    case toLower str of
        "none" ->
            Nothing

        "pink" ->
            Just pink

        "lightblue" ->
            Just lightBlue

        "lightgreen" ->
            Just lightGreen

        "green" ->
            Just green

        "yellow" ->
            Just yellow

        anythingElse ->
            Just anythingElse



-------------------
-- JSON decoders --
-------------------


plotDecoder : JD.Decoder Plot
plotDecoder =
    JD.map8 Plot
        (field "x_axis_label" JD.string)
        (field "y_axis_label" JD.string)
        (field "data" (JD.list pointDecoder))
        (field "series_type" seriesTypeDecoder)
        (field "point_type" pointTypeDecoder)
        (field "interpolation" interpolationDecoder)
        (field "area_color" (JD.map translateToMaybeColor JD.string))
        (field "stroke_color" JD.string)


pointDecoder : JD.Decoder Point
pointDecoder =
    JD.map2 Point
        (field "x" JD.float)
        (field "y" JD.float)


seriesTypeDecoder : JD.Decoder SeriesType
seriesTypeDecoder =
    JD.map decodeSeriesType JD.string


decodeSeriesType : String -> SeriesType
decodeSeriesType seriesType =
    case toLower seriesType of
        "line" ->
            Line

        "dots" ->
            Dots

        "area" ->
            Area

        _ ->
            UnknownSeries


pointTypeDecoder : JD.Decoder PointType
pointTypeDecoder =
    JD.map decodePointType JD.string


decodePointType : String -> PointType
decodePointType pointType =
    case toLower pointType of
        "clear" ->
            Clear

        "square" ->
            Square

        "circle" ->
            Circle

        "diamond" ->
            Diamond

        "triangle" ->
            Triangle

        _ ->
            UnknownPoint


interpolationDecoder : JD.Decoder (( Maybe String, String ) -> Plot.Interpolation)
interpolationDecoder =
    JD.map decodeInterpolation JD.string


decodeInterpolation : String -> ( Maybe String, String ) -> Plot.Interpolation
decodeInterpolation interpolation =
    case toLower interpolation of
        "none" ->
            \( areaColor, strokeColor ) -> None

        "linear" ->
            \( areaColor, strokeColor ) -> Linear areaColor [ stroke strokeColor ]

        "monotone" ->
            \( areaColor, strokeColor ) -> Monotone areaColor [ stroke strokeColor ]

        _ ->
            -- default to linear
            \( areaColor, strokeColor ) -> Linear areaColor [ stroke strokeColor ]



------------
-- colors --
------------


pink : String
pink =
    "#ff9edf"


lightBlue : String
lightBlue =
    "#85c1e9"


lightGreen : String
lightGreen =
    "#7dcea0"


green : String
green =
    "#229954"


yellow : String
yellow =
    "#f7dc6f"
