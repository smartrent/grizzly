defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationReport do
  @moduledoc """
  This command is used to advertise the current configuration for playing tones
  at the sending node.

  ## Params

  * `:volume` - the volume at which the node will play tones
  * `:default_tone_identifier` - the default tone that will be played
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param ::
          {:volume, Grizzly.ZWave.sound_switch_volume()}
          | {:default_tone_identifier, byte()}

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    volume = Command.param!(command, :volume)
    default_tone_identifier = Command.param!(command, :default_tone_identifier)
    <<volume::8, default_tone_identifier::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<volume::8, default_tone_identifier::8>>) do
    {:ok, [volume: volume, default_tone_identifier: default_tone_identifier]}
  end
end
