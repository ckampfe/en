defmodule En.ElixirServer do
  use GenServer
  @behaviour En.Execute

  # api

  def start_link do
    # pass in the current `__ENV__` by default
    GenServer.start_link(__MODULE__, __ENV__, name: __MODULE__)
  end

  def init(env) do
    {:ok, {[], env}}
  end

  def call(expression, _environment) do
    GenServer.call(__MODULE__, {:call, expression})
  end

  # callbacks

  def handle_call({:call, expression}, _sender, {bindings, env}) do
    reply =
      try do
        quoted = Code.string_to_quoted!(expression)

        # this uses low-level eval_quoted/3,
        # defined in `elixir.erl`:
        # https://github.com/elixir-lang/elixir/blob/v1.5.2/lib/elixir/src/elixir.erl#L214-L217
        # this is in lieu of using `Code.eval_quoted/3`,
        # because that function does not
        # return the result environment, whereas the erl version does
        {result, bindings, new_env, _scope} =
          :elixir.eval_quoted(
            quoted,
            bindings,
            env
          )

        {{result, bindings}, new_env}
      rescue
         e -> e
      end

    case reply do
      {{result, new_bindings}, new_env} ->
        {:reply, {result, new_bindings}, {new_bindings, new_env}}
      _error ->
        {:reply, reply, {bindings, env}}
    end
  end
end
