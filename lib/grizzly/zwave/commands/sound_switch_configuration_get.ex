defmodule Grizzly.ZWave.Commands.SoundSwitchConfigurationGet do
  @moduledoc """
  This command is used to request the current configuration for playing tones at
  the supporting node.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

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
