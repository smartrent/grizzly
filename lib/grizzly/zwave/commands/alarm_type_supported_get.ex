defmodule Grizzly.ZWave.Commands.AlarmTypeSupportedGet do
  @moduledoc """
  This command is used to request supported Alarm/Notification Types.

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<>>) do
    {:ok, []}
  end
end
