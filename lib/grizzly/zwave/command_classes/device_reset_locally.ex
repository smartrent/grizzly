defmodule Grizzly.ZWave.CommandClasses.DeviceResetLocally do
  @moduledoc """
  "DeviceResetLocally" Command Class

  The Device Reset Locally Command Class is used to notify central controllers that a Z-Wave device is
  resetting its network specific parameters.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x5A

  @impl true
  def name(), do: :device_reset_locally
end
