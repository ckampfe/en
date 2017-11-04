defmodule EnWeb.RoomChannel do
  use Phoenix.Channel
  alias En.Renderable

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("new:msg", %{"body" => body, "user" => user}, socket) do
    result =
      case En.ElixirServer.call(body, __ENV__) do
        {result, binding}  ->
          result
        %CompileError{description: description, line: line} ->
          "#{description}, line: #{line}"
        %SyntaxError{description: description, line: line} ->
          "#{description}, line: #{line}"
        %ArgumentError{message: message} ->
          message
        %TokenMissingError{description: description, line: line} ->
          "#{description} line: #{line}"
      end

    broadcast!(socket, "new:msg", %{body: Renderable.render(result), user: user})
    {:noreply, socket}
  end
end
