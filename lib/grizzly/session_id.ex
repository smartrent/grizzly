defmodule Grizzly.SessionId do
  @moduledoc false

  use GenServer

  @type option :: {:seed, :rand.seed()}

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Returns a supervision session id for the given node.
  """
  @spec get_and_inc(GenServer.name(), Grizzly.node_id()) :: 0..31
  def get_and_inc(name \\ __MODULE__, node_id) do
    GenServer.call(name, {:get_and_inc, node_id})
  end

  @impl GenServer
  def init(opts) do
    _ =
      if seed = Keyword.get(opts, :seed) do
        :rand.seed(:default, seed)
      end

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:get_and_inc, node_id}, _from, state) do
    number = Map.get_lazy(state, node_id, fn -> Enum.random(0..31) end)
    next_state = Map.put(state, node_id, inc(number))
    {:reply, number, next_state}
  end

  defp inc(31), do: 0
  defp inc(n), do: n + 1
end
