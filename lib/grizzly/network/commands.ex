defmodule Grizzly.Network.Commands do
  @moduledoc false

  alias Grizzly.{Node, Controller, SeqNumber}

  alias Grizzly.CommandClass.NetworkManagementProxy.{
    NodeListGet,
    NodeInfoCache
  }

  alias Grizzly.CommandClass.NetworkManagementBasic.DefaultSet

  @spec get_nodes_on_network() :: {:ok, [Node.t()]} | {:error, :nack_response}
  def get_nodes_on_network() do
    seq_number = SeqNumber.get_and_inc()

    case Grizzly.send_command(
           Controller.conn(),
           NodeListGet,
           seq_number: seq_number
         ) do
      {:ok, node_list} ->
        node_list = Enum.map(node_list, fn node_id -> Node.new(id: node_id) end)
        {:ok, node_list}

      error ->
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

  @spec reset_controller() :: {:ok, :done} | {:error, :network_busy}
  def reset_controller() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      Controller.conn(),
      DefaultSet,
      seq_number: seq_number
    )
  end
end
