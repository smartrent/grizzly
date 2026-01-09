defmodule Grizzly.ZWave.Commands.DeviceResetLocallyNotification do
  @moduledoc """
  The Device Reset Locally Notification Command is used to advertise that the device will be reset to
  default.

  Params: -none-

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
