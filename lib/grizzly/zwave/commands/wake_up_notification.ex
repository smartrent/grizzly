defmodule Grizzly.ZWave.Commands.WakeUpNotification do
  @moduledoc """
  This module implements the WAKE_UP_NOTIFICATION command of the
  COMMAND_CLASS_WAKE_UP command class

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
