defmodule En.PlotTest do
  use ExUnit.Case, async: true
  alias En.{Plot, Renderable}
  require Poison

  test "it outputs the right %Plot{}" do
    data = [1,2,2,3,3,7,4,9]

    expected_data = [
      %{x: 1, y: 2},
      %{x: 2, y: 3},
      %{x: 3, y: 7},
      %{x: 4, y: 9}
    ]

    assert %Plot{
      data: expected_data,
      x_axis_label: "",
      y_axis_label: ""
    } == Plot.series(data)

    assert %Plot{
      data: expected_data,
      x_axis_label: "some x label",
      y_axis_label: "some y"
    } == Plot.series(
      data,
      x_axis_label: "some x label",
      y_axis_label: "some y"
    )
  end

  test "it renders properly" do
    data = [1,2,2,3,3,7,4,9]

    expected_data = [
      %{x: 1, y: 2},
      %{x: 2, y: 3},
      %{x: 3, y: 7},
      %{x: 4, y: 9}
    ]

    expected_struct =
      %Plot{
        data: expected_data,
        x_axis_label: "",
        y_axis_label: ""
      }

    expected_json = Poison.encode!(expected_struct)

    assert %{kind: "plot", content: expected_json} == data |> Plot.series |> Renderable.render
  end

  test "it translates datapoints into proper format" do
    assert %{x: 5, y: 4} == Plot.to_datapoint([5, 4])
    assert %{x: 5, y: 4} == Plot.to_datapoint(%{"x" => 5, "y" => 4})
  end
end
