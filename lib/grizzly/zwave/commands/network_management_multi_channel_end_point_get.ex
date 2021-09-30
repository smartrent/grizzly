defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointGet do
  @moduledoc """
  Command is used to query the number of Multi Channel End Points and other
  relevant Multi Channel attributes

  Params:

  * `:seq_number` - the sequence number for this command
  * `:node_id` - the node id in question
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, NodeId}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :network_management_multi_channel_end_point_get,
      command_byte: 0x05,
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

    case Keyword.get(encode_opts, :command_class_version, 4) do
      4 ->
        <<seq_number, NodeId.encode_extended(node_id)::binary>>

      v when v < 4 ->
        <<seq_number, NodeId.encode(node_id)::binary>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, node_id::binary>>) do
    {:ok, [seq_number: seq_number, node_id: NodeId.parse(node_id)]}
  end
end
