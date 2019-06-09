defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """
  alias Grizzly.Network.Server
  alias Grizzly.Node
  alias Grizzly.Network.State, as: NetworkState

  @doc """
  List the nodes that known to the network
  """
  @spec list_nodes() :: [Node.t()]
  def list_nodes() do
    Server.all()
  end

  @doc """
  Reset the network
  """
  @spec reset() :: :ok | {:error, :network_busy}
  def reset() do
    Server.reset()
  end

  @doc """
  Get nodes from network
  """
  @spec get_node(Node.node_id()) :: {:ok, Node.t()} | {:error, :node_not_found}
  def get_node(node_id) do
    Server.get_node(node_id)
  end

  @doc """
  Check to see if the network is busy
  """
  @spec busy?() :: boolean()
  def busy?() do
    NetworkState.busy?()
  end

  @doc """
  Check to see if the network is ready
  """
  @spec ready?() :: boolean()
  def ready?() do
    NetworkState.ready?()
  end

  @doc """
  Get the current state of the Network
  """
  @spec get_state() :: NetworkState.state()
  def get_state() do
    NetworkState.get()
  end

  @doc """
  Set the Z-Wave network state
  """
  @spec set_state(NetworkState.state()) :: :ok
  def set_state(state) do
    NetworkState.set(state)
  end
end
