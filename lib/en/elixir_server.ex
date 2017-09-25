defmodule En.ElixirServer do
  use GenServer
  @behaviour En.Execute

  # api

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def initialize(_arg) do
    nil
  end

  def call(expression, _environment) do
    GenServer.call(__MODULE__, {:call, expression})
  end

  # callbacks

  def handle_call({:call, expression}, _sender, binding) do
    reply =
      try do
        Code.eval_string(expression, binding)
      rescue
         e -> e
      end

    case reply do
      {result, new_binding} ->
        {:reply, reply, new_binding}
      _error ->
        {:reply, reply, binding}
    end
  end
end