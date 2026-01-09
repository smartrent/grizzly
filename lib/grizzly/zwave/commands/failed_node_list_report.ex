defmodule Grizzly.ZWave.Commands.FailedNodeListReport do
  @moduledoc """
  This command is used to advertise the current list of failing nodes in the network.

  Params:

    * `:seq_number` - Sequence number
    * `:node_ids` - The ids of all nodes in the network found to be unresponsive

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.NodeIdList

  @type param() :: {:node_ids, [ZWave.node_id()]} | {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_ids = Command.param!(command, :node_ids)
    node_id_bytes = NodeIdList.to_binary(node_ids)
    <<seq_number>> <> node_id_bytes
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, node_id_bytes::binary>>) do
    node_ids = NodeIdList.parse(node_id_bytes)
    {:ok, [seq_number: seq_number, node_ids: node_ids]}
  end
end
