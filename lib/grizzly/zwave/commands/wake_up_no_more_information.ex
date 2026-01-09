defmodule Grizzly.ZWave.Commands.WakeUpNoMoreInformation do
  @moduledoc """
  This module implements the WAKE_UP_NO_MORE_INFORMATION command of the
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
