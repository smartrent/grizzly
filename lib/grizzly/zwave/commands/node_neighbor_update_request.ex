defmodule Grizzly.ZWave.Commands.NodeNeighborUpdateRequest do
  @moduledoc """
  This command is used to instruct a node to perform a Node Neighbor Update
  operation in order to update the network topology on the controller.

  ### Params

    * `:seq_number` - the sequence number of the node neighbor update request command (required)
    * `:node_id` - the node that should perform the neighbor update operation (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    <<seq_number, node_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, node_id>>) do
    {:ok, [seq_number: seq_number, node_id: node_id]}
  end
end
