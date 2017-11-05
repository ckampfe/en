module EnPlot exposing (..)

import Json.Decode as JD exposing (field)
import Plot exposing (..)
import String exposing (toLower)
import Svg exposing (Svg)


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
                    \{ x, y } -> square x y

                Circle ->
                    \{ x, y } -> circle x y

                Diamond ->
                    \{ x, y } -> diamond x y

                Triangle ->
                    \{ x, y } -> triangle x y

                _ ->
                    -- default to circle
                    \{ x, y } -> circle x y

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
    in
    viewSeries
        [ seriesType ]
        plot.data



-------------------
-- JSON decoders --
-------------------


plotDecoder : JD.Decoder Plot
plotDecoder =
    JD.map5 Plot
        (field "x_axis_label" JD.string)
        (field "y_axis_label" JD.string)
        (field "data" (JD.list pointDecoder))
        (field "series_type" seriesTypeDecoder)
        (field "point_type" pointTypeDecoder)


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
