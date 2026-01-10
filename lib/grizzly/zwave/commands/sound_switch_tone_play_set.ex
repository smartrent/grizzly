defmodule Grizzly.ZWave.Commands.SoundSwitchTonePlaySet do
  @moduledoc """
  This command is used to instruct a supporting node to play (or stop playing) a
  tone.

  ## Params

  * `:tone_identifier` - The tone identifier to play. If the value is 0, the node
    MUST stop playing any tone. If the value is 255 or is a value not supported
    by the receiving node, the node MUST play the default configured tone.

  * `:volume` (v2) - The volume to play the tone at, overriding the configured
    volume.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError

  @type param :: {:tone_identifier, 0..255} | {:volume, Grizzly.ZWave.sound_switch_volume()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    tone_identifier = Command.param!(command, :tone_identifier)
    volume = Command.param(command, :volume)

    if is_nil(volume) do
      # V1
      <<tone_identifier::8>>
    else
      # V2
      <<tone_identifier::8, volume::8>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<tone_identifier::8, volume::8>>) do
    {:ok, [tone_identifier: tone_identifier, volume: volume]}
  end

  def decode_params(<<tone_identifier::8>>) do
    {:ok, [tone_identifier: tone_identifier, volume: nil]}
  end
end
