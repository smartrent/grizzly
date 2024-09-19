defmodule Grizzly.ZWave.CommandClasses.FirmwareUpdateMD do
  @moduledoc """
  The Firmware Update Meta Data Command Class may be used to transfer a firmware image to a
  Z-Wave device.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x7A

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :firmware_update_md
end
