defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationSet do
  @moduledoc """
  This command is used to set the configuration for playing tones at the
  supporting node.

  ## Params

  * `:volume` - specifies the volume at which the node will play tones
  * `:default_tone_identifier` - sets the default tone that will be played when
    no tone is specified
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SoundSwitch

  @type param ::
          {:volume, SoundSwitch.volume()}
          | {:default_tone_identifier, SoundSwitch.tone_identifier()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sound_switch_configuration_set,
      command_byte: 0x05,
      command_class: SoundSwitch,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

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
