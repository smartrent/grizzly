defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityGet do
  @moduledoc """
  Command to query the capabilities of one individual endpoint or aggregated
  end point

  Params:

  * `:seq_number` - the sequence number for this command
  * `:node_id` - the node id that has the end point to query
  * `:end_point` - the end point to query
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.NodeId

  @type param() ::
          {:seq_number, ZWave.seq_number()} | {:node_id, ZWave.node_id()} | {:end_point, 0..127}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    end_point = Command.param!(command, :end_point)

    <<seq_number, NodeId.encode_extended(node_id, delimiter: <<end_point>>)::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, params::binary>>) do
    <<_node_id_8, _reserved::1, end_point::7, _rest::binary>> = params

    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(params, delimiter_size: 1),
       end_point: end_point
     ]}
  end
end
