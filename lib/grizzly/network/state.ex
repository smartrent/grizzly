defmodule Grizzly.Network.State do
  @moduledoc false

  use GenServer
  require Logger

  @type t :: pid

  @type state ::
          :not_ready
          | :idle
          | :including
          | :excluding
          | :resetting
          | :inclusion_stopping
          | :exclusion_stopping
          | :learning
          | :configurating_new_node

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Set the network state
  """
  @spec set(state) :: :ok
  def set(nil), do: :ok

  def set(new_state) do
    GenServer.call(__MODULE__, {:set, new_state})
  end

  @doc """
  Get the current state of the network
  """
  @spec get() :: state
  def get() do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Check to see if the network is busy.

  The network is busy when commands are not
  able to be processed.
  """
  @spec busy?() :: boolean
  def busy?() do
    GenServer.call(__MODULE__, :busy?)
  end

  @doc """
  Check to see if the network is allowed state to run a command.

  The network is busy when the network is not in one of the allowed states.
  """
  @spec in_allowed_state?([state]) :: boolean
  def in_allowed_state?(allowed_states) do
    GenServer.call(__MODULE__, {:in_allowed_state?, allowed_states})
  end

  @doc """
  Check to see if the network is ready.

  The network is ready when commands are
  able to be processed.
  """
  @spec ready?() :: boolean
  def ready?() do
    GenServer.call(__MODULE__, :ready?)
  end

  @impl true
  def init(_) do
    {:ok, :not_ready}
  end

  @impl true
  def handle_call({:set, new_state}, _from, _) do
    _ = Logger.debug("Network state set to #{inspect(new_state)}")
    {:reply, :ok, new_state}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call(:busy?, _from, state) when state not in [:idle, :not_ready],
    do: {:reply, true, state}

  # When no allowed state is specified, all states are allowed
  def handle_call({:in_allowed_state?, nil}, _from, state) do
    {:reply, true, state}
  end

  def handle_call({:in_allowed_state?, allowed_states}, _from, state) do
    in_allowed_state? = state in allowed_states

    :ok = maybe_log_not_in_allowed_state(!in_allowed_state?, state, allowed_states)

    {:reply, in_allowed_state?, state}
  end

  def handle_call(:busy?, _from, state), do: {:reply, false, state}

  def handle_call(:ready?, _from, :idle = state), do: {:reply, true, state}

  def handle_call(:ready?, _from, state), do: {:reply, false, state}

  defp maybe_log_not_in_allowed_state(true, state, allowed_states) do
    _ = Logger.warn("#{inspect(state)} is not in allowed states #{inspect(allowed_states)}")
    :ok
  end

  defp maybe_log_not_in_allowed_state(false, _, _) do
    :ok
  end
end
