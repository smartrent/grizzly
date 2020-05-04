defmodule Grizzly.ZWave.CommandClasses.FirmwareUpdateMD do
  @moduledoc """
  The Firmware Update Meta Data Command Class may be used to transfer a firmware image to a
  Z-Wave device.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x7A

  @impl true
  def name(), do: :firmware_update_md
end
