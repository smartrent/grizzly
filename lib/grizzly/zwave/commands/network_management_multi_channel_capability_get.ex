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
  alias Grizzly.ZWave.{Command, NodeId}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @type param() ::
          {:seq_number, ZWave.seq_number()} | {:node_id, ZWave.node_id()} | {:end_point, 0..127}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :network_management_multi_channel_capability_get,
      command_byte: 0x07,
      command_class: NetworkManagementProxy,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command, encode_opts \\ []) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    end_point = Command.param!(command, :end_point)

    case Keyword.get(encode_opts, :command_class_version, 4) do
      4 ->
        <<seq_number, NodeId.encode_extended(node_id, delimiter: <<end_point>>)::binary>>

      v when v < 4 ->
        <<seq_number, NodeId.encode(node_id)::binary, 0::1, end_point::7>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, params::binary>>) do
    <<_node_id_8, _reserved::1, end_point::7, _rest::binary>> = params

    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(params, delimiter_size: 1),
       end_point: end_point
     ]}
  end
end
