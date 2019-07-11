defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """
  require Logger

  alias Grizzly.{Node, SeqNumber, Controller}
  alias Grizzly.Network.State, as: NetworkState

  alias Grizzly.CommandClass.NetworkManagementProxy.{
    NodeListGet,
    NodeInfoCache
  }

  alias Grizzly.CommandClass.NetworkManagementBasic.DefaultSet

  @doc """
  Reset the network
  """
  @spec reset() :: :ok | {:error, :network_busy}
  def reset() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      Controller.conn(),
      DefaultSet,
      seq_number: seq_number
    )
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

  @doc """
  Get a list of nodes from the network
  """
  @spec get_nodes() :: {:ok, [Node.t()]} | {:error, :unable_to_get_node_list}
  def get_nodes() do
    seq_number = SeqNumber.get_and_inc()

    node_list =
      Grizzly.send_command(
        Controller.conn(),
        NodeListGet,
        seq_number: seq_number
      )

    case node_list do
      {:ok, node_list} ->
        nodes =
          Enum.map(node_list, fn node_id ->
            case get_node(node_id) do
              {:ok, zw_node} ->
                zw_node

              {:error, reason} ->
                _ = Logger.warn("Error getting node info for #{node_id} reason: #{reason}")
                Node.new(id: node_id)
            end
          end)

        {:ok, nodes}

      {:error, _} ->
        {:error, :unable_to_get_node_list}
    end
  end

  @doc """
  Get a Node from the Z-Wave network
  """
  @spec get_node(Node.node_id()) :: {:ok, Node.t()} | {:error, :nack_response}
  def get_node(node_id) do
    with {:ok, node_info} <- get_node_info(node_id),
         {:ok, ip_address} <- Node.get_ip(node_id) do
      zw_node =
        node_info
        |> Map.put(:id, node_id)
        |> Map.put(:ip_address, ip_address)
        |> Map.to_list()
        |> Node.new()

      {:ok, zw_node}
    else
      {:error, _} = error ->
        error
    end
  end

  @spec get_node_info(Node.node_id()) :: {:ok, map()} | {:error, :nack_response}
  def get_node_info(node_id) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      Controller.conn(),
      NodeInfoCache,
      cached_minutes_passed: 0x01,
      node_id: node_id,
      seq_number: seq_number
    )
  end
end
