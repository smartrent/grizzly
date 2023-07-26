defmodule Grizzly.ZWave.Commands.SoundSwitchToneInfoGet do
  @moduledoc """
  This command is used to query the information associated with a tone at a
  supporting node.

  ## Params

  * `:tone_identifier` - The identifier of the requested tone.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SoundSwitch

  @type param :: {:tone_identifier, SoundSwitch.tone_identifier()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sound_switch_tone_info_get,
      command_byte: 0x03,
      command_class: SoundSwitch,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    tone_identifier = Command.param!(command, :tone_identifier)
    <<tone_identifier::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<tone_identifier::8>>) do
    {:ok, [tone_identifier: tone_identifier]}
  end
end
