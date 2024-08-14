defmodule Grizzly.ZWave.CommandClasses.DeviceResetLocally do
  @moduledoc """
  "DeviceResetLocally" Command Class

  The Device Reset Locally Command Class is used to notify central controllers that a Z-Wave device is
  resetting its network specific parameters.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x5A

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :device_reset_locally
end
