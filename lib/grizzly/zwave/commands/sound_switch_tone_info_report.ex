defmodule Grizzly.ZWave.Commands.SoundSwitchToneInfoReport do
  @moduledoc """
  This command is used to advertise the information associated with a tone at a
  supporting node.

  ## Params

  * `:tone_identifier` - The identifier of the requested tone.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.SoundSwitch
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:tone_identifier, SoundSwitch.tone_identifier()}
          | {:tone_duration, 0..65535}
          | {:name, binary()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :sound_switch_tone_info_report,
      command_byte: 0x04,
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
    tone_duration = Command.param!(command, :tone_duration)
    name = Command.param!(command, :name)

    <<tone_identifier::8, tone_duration::16, byte_size(name)::8, name::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<tone_identifier::8, tone_duration::16, _name_length::8, name::binary>>) do
    {:ok,
     [
       tone_identifier: tone_identifier,
       tone_duration: tone_duration,
       name: name
     ]}
  end
end
