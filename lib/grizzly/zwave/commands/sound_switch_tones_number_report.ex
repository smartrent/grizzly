defmodule Grizzly.ZWave.Commands.SoundSwitchTonesNumberReport do
  @moduledoc """
  This command is used to advertise the number of tones supported by the sending
  node.

  ## Params

  * `:supported_tones` - the number of supported tones
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:supported_tones, 0..255}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    supported_tones = Command.param!(command, :supported_tones)
    <<supported_tones::8>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<supported_tones::8>>) do
    {:ok, [supported_tones: supported_tones]}
  end
end
