defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointGet do
  @moduledoc """
  Command is used to query the number of Multi Channel End Points and other
  relevant Multi Channel attributes

  Params:

  * `:seq_number` - the sequence number for this command
  * `:node_id` - the node id in question
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.NodeId

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)

    <<seq_number, NodeId.encode_extended(node_id)::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, node_id::binary>>) do
    {:ok, [seq_number: seq_number, node_id: NodeId.parse(node_id)]}
  end
end
