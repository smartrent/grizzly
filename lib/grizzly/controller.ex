defmodule Grizzly.Controller do
  @moduledoc """
  This module is for Z-Wave controller level operations.

  That mostly having to handle network related calls like
  adding/removing a node, geting nodes' IP, listing nodes,
  and etc.
  """
  use GenServer

  require Logger

  alias Grizzly
  alias Grizzly.{Conn, Notifications}
  alias Grizzly.Conn.Config
  alias Grizzly.Network.State, as: NetworkState

  defmodule State do
    @moduledoc false
    defstruct conn: nil
  end

  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(grizzly) do
    GenServer.start_link(__MODULE__, grizzly, name: __MODULE__)
  end

  @doc """
  Check to see if the connection is connected to
  the gateway server.
  """
  @spec connected?() :: boolean
  def connected?() do
    GenServer.call(__MODULE__, :connected?)
  end

  @spec conn() :: Conn.t()
  def conn() do
    GenServer.call(__MODULE__, :conn)
  end

  @doc "Get the connection but set to the given mode"
  @spec conn(Config.mode()) :: Conn.t()
  def conn(mode) do
    GenServer.call(__MODULE__, {:conn, mode})
  end

  @impl true
  def init(conn_config) do
    _ = Notifications.subscribe(:connection_established)
    conn = Conn.open(conn_config)
    {:ok, %State{conn: conn}}
  end

  @impl true
  def handle_call(:connected?, _from, %State{conn: conn} = state) when conn in [nil, false] do
    {:reply, false, state}
  end

  def handle_call(:connected?, _from, %State{conn: conn} = state) do
    {:reply, Conn.connected?(conn), state}
  end

  def handle_call(:conn, _from, %State{conn: conn} = state) do
    {:reply, conn, state}
  end

  def handle_call({:conn, mode}, _from, %State{conn: conn} = state) do
    {:reply, Conn.override_mode(conn, mode), state}
  end

  @impl true
  def handle_info(
        {:connection_established, %Config{ip: ip}},
        %State{conn: %Conn{ip_address: ip}} = state
      ) do
    NetworkState.set(:idle)
    Notifications.broadcast(:controller_connected)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
