defmodule Grizzly.ZWave.Commands.MultiChannelEndpointGet do
  @moduledoc """
  This command is used to query the number of End Points implemented by the receiving node.

  Params: - none

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannel

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :multi_channel_endpoint_get,
      command_byte: 0x07,
      command_class: MultiChannel,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<>>) do
    {:ok, []}
  end
end
