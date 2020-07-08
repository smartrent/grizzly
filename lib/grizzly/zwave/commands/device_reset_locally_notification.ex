defmodule Grizzly.ZWave.Commands.DeviceResetLocallyNotification do
  @moduledoc """
  The Device Reset Locally Notification Command is used to advertise that the device will be reset to
  default.

  Params: -none-

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.DeviceResetLocally

  @impl true
  def new(params) do
    command = %Command{
      name: :device_reset_locally_notification,
      command_byte: 0x01,
      command_class: DeviceResetLocally,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
