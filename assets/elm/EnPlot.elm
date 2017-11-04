module EnPlot exposing (..)

import Json.Decode as JD exposing (field)
import Plot exposing (..)
import Svg exposing (Svg)


---------------------
-- type defintions --
---------------------


type alias Point =
    { x : Float
    , y : Float
    }


type alias Plot =
    { x_axis_label : String
    , y_axis_label : String
    , data : List Point
    }



---------------
-- functions --
---------------


series : Plot -> Svg msg
series plot =
    viewSeries
        [ area (List.map (\{ x, y } -> circle x y)) ]
        plot.data



-------------------
-- JSON decoders --
-------------------


decodePlot : JD.Decoder Plot
decodePlot =
    JD.map3 Plot
        (field "x_axis_label" JD.string)
        (field "y_axis_label" JD.string)
        (field "data" (JD.list decodePoint))


decodePoint : JD.Decoder Point
decodePoint =
    JD.map2 Point
        (field "x" JD.float)
        (field "y" JD.float)