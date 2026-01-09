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
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    supported_tones = Command.param!(command, :supported_tones)
    <<supported_tones::8>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<supported_tones::8>>) do
    {:ok, [supported_tones: supported_tones]}
  end
end
