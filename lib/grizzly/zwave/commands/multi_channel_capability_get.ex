defmodule Grizzly.ZWave.Commands.MultiChannelCapabilityGet do
  @moduledoc """
  This command is used to query the non-secure Command Class capabilities of an End Point.

  Params:

    * `:end_point` - an end point (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @type param :: {:end_point, MultiChannel.end_point()}

  @impl true
  def new(params) do
    command = %Command{
      name: :multi_channel_capability_get,
      command_byte: 0x09,
      command_class: MultiChannel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    end_point = Command.param!(command, :end_point)
    <<0x00::1, end_point::7>>
  end

  @impl true
  def decode_params(<<0x00::1, end_point::7>>) do
    {:ok, [end_point: end_point]}
  end
end
