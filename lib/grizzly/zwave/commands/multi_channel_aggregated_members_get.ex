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

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    aggregated_end_point = Command.param!(command, :aggregated_end_point)
    <<0x00::1, aggregated_end_point::7>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<0x00::1, aggregated_end_point::7>>) do
    {:ok, [aggregated_end_point: aggregated_end_point]}
  end
end
