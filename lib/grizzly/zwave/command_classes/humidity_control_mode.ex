defmodule Grizzly.ZWave.CommandClasses.HumidityControlMode do
  @moduledoc """
  "HumidityControlMode" Command Class

  What type of commands does this command class support?
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x6D


  @impl Grizzly.ZWave.CommandClass
  def name(), do: :humidity_control_mode
end
