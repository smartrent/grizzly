defmodule Grizzly.ZWave.CommandClasses.HumidityControlOperatingState do
  @moduledoc """
  "HumidityControlOperatingState" Command Class

  What type of commands does this command class support?
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x6E

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :humidity_control_operating_state
end
