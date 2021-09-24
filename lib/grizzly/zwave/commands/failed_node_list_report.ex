defmodule Grizzly.ZWave.Commands.FailedNodeListReport do
  @moduledoc """
  This command is used to advertise the current list of failing nodes in the network.

  Params:

    * `:seq_number` - Sequence number
    * `:node_ids` - The ids of all nodes in the network found to be unresponsive

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError, NodeIdList}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @type param() :: {:node_ids, [ZWave.node_id()]} | {:seq_number, ZWave.seq_number()}

  @impl true
  def new(params) do
    command = %Command{
      name: :failed_node_list_report,
      command_byte: 0x0C,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_ids = Command.param!(command, :node_ids)
    node_id_bytes = NodeIdList.to_binary(node_ids)
    <<seq_number>> <> node_id_bytes
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, node_id_bytes::binary>>) do
    node_ids = NodeIdList.parse(node_id_bytes)
    {:ok, [seq_number: seq_number, node_ids: node_ids]}
  end
end
