defmodule Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointReport do
  @moduledoc """
  Command use to advertise the number of Multi Channel End Points

  Params:

  * `:seq_number` - the sequence number for this command
  * `:node_id` - the node id in question
  * `:individual_end_points` - the number of individual end points this device
    supports
  * `:aggregated_end_points` - the number of aggregated end points this device
    supports (optional, defaults to 0)

  Aggregated end points are used for reporting accumulated consumption of a
  physical resource via Meter and Multilevel Sensor Command Class. For example,
  if there is a power switch with 3 binary switches it could support support 1
  aggregated endpoint that can report the total accumulated power consumption
  for all 3 switches on the power strip.

  For more information on Z-Wave Multi Channel see:
  https://www.silabs.com/documents/public/application-notes/APL12955-Z-Wave-Multi-Channel-Basics.pdf
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementProxy
  alias Grizzly.ZWave.NodeId

  @type param() ::
          {:seq_number, ZWave.seq_number()}
          | {:node_id, ZWave.node_id()}
          | {:individual_end_points, 0..127}
          | {:aggregated_end_points, 0..127}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params \\ []) do
    command = %Command{
      name: :network_management_multi_channel_end_point_report,
      command_byte: 0x06,
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
    individual_end_points = Command.param!(command, :individual_end_points)
    aggregated_end_points = Command.param(command, :aggregated_end_points, 0)

    # first byte is 0x00 as it is marked as reserved in the Z-Wave specification
    end_points_bin = <<0x00, 0::1, individual_end_points::7, 0::1, aggregated_end_points::7>>

    case Keyword.get(encode_opts, :command_class_version, 4) do
      4 ->
        <<seq_number, NodeId.encode_extended(node_id, delimiter: end_points_bin)::binary>>

      v when v < 4 ->
        <<seq_number, node_id, end_points_bin::binary>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, params::binary>>) do
    <<_node_id, _reserved_byte, _reserved1::1, individual_end_points::7, _reversed2::1,
      aggregated_end_points::7, _rest::binary>> = params

    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(params, delimiter_size: 3),
       individual_end_points: individual_end_points,
       aggregated_end_points: aggregated_end_points
     ]}
  end
end
