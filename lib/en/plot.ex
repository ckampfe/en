defmodule En.Plot do
  require Poison

  defstruct [data: [],
             x_axis_label: "",
             y_axis_label: "",
             series_type: :line,
             point_type: :circle,
             debug: false
             ]

  def to_datapoint([x, y]) do
    %{x: x,
      y: y}
  end
  def to_datapoint(%{"x" => x, "y" => y}) do
    %{x: x,
      y: y}
  end

  def series(datapoints, options \\ [debug: false])
  def series([%{x: _x, y: _y} | _] = datapoints, options) do
    new_series(datapoints, options)
  end
  def series([%{"x" => _x, "y" => _y} | _] = data, options) do
    datapoints = Enum.map(data, &to_datapoint/1)

    new_series(datapoints, options)
  end
  def series(data, options) when is_list(data) do
    datapoints =
      data
      |> Enum.chunk_every(2)
      |> Enum.map(&to_datapoint/1)

    new_series(datapoints, options)
  end

  def new_series(datapoints, options) do
    %__MODULE__{
      data: datapoints,
      x_axis_label: Keyword.get(options, :x_axis_label, ""),
      y_axis_label: Keyword.get(options, :y_axis_label, ""),
      series_type:  Keyword.get(options, :series_type, :line),
      point_type:   Keyword.get(options, :point_type, :circle),
      debug:        Keyword.get(options, :debug, false)
    }
  end

  def bar(data, options \\ [])
  def bar(data, options) do
  end
end


defimpl En.Renderable, for: En.Plot do
  def render(plot) do
    case Map.fetch!(plot, :debug) do
      false ->
        %{kind: "plot", content: Poison.encode!(plot)}
      true ->
        %{kind: "text", content: Poison.encode!(plot, pretty: true)}
    end
  end
end
