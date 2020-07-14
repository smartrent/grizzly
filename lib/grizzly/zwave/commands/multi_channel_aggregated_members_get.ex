defmodule Grizzly.ZWave.Commands.MultiChannelAggregatedMembersGet do
  @moduledoc """
  This command is used to query the members of an Aggregated End Point.

  Params:

    * `:aggregated_end_point` - an aggregated end point

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param :: {:end_point, MultiChannel.end_point()}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_aggregated_members_get,
      command_byte: 0x0E,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    aggregated_end_point = Command.param!(command, :aggregated_end_point)
    <<0x00::size(1), aggregated_end_point::size(7)>>
  end

  @impl true
  def decode_params(<<0x00::size(1), aggregated_end_point::size(7)>>) do
    {:ok, [aggregated_end_point: aggregated_end_point]}
  end
end
