defmodule Grizzly.ZWave.Commands.WakeUpIntervalCapabilitiesGet do
  @moduledoc """
  This module implements the WAKE_UP_INTERVAL_CAPABILITIES_GET command of the
  COMMAND_CLASS_WAKE_UP command class.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
