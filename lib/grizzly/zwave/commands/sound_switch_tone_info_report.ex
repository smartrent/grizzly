defmodule Grizzly.ZWave.Commands.SoundSwitchToneInfoReport do
  @moduledoc """
  This command is used to advertise the information associated with a tone at a
  supporting node.

  ## Params

  * `:tone_identifier` - The identifier of the requested tone.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param ::
          {:tone_identifier, byte()}
          | {:tone_duration, 0..65535}
          | {:name, binary()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    tone_identifier = Command.param!(command, :tone_identifier)
    tone_duration = Command.param!(command, :tone_duration)
    name = Command.param!(command, :name)

    <<tone_identifier::8, tone_duration::16, byte_size(name)::8, name::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<tone_identifier::8, tone_duration::16, _name_length::8, name::binary>>
      ) do
    {:ok,
     [
       tone_identifier: tone_identifier,
       tone_duration: tone_duration,
       name: name
     ]}
  end
end
