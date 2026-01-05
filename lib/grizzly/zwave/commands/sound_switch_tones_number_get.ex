defmodule Grizzly.ZWave.Commands.SoundSwitchTonesNumberGet do
  @moduledoc """
  This command is used to request the number of tones supported by the receiving
  node.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SoundSwitch

  @impl Grizzly.ZWave.Command
  @spec new([]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sound_switch_tones_number_get,
      command_byte: 0x01,
      command_class: SoundSwitch,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, []}
  def decode_params(_binary) do
    {:ok, []}
  end
end
