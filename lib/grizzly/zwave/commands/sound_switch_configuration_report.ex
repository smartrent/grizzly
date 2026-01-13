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
  def encode_params(_spec, command) do
    volume = Command.param!(command, :volume)
    default_tone_identifier = Command.param!(command, :default_tone_identifier)
    <<volume::8, default_tone_identifier::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<volume::8, default_tone_identifier::8>>) do
    {:ok, [volume: volume, default_tone_identifier: default_tone_identifier]}
  end
end
