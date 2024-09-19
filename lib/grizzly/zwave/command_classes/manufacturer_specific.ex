defmodule Grizzly.ZWave.CommandClasses.ManufacturerSpecific do
  @moduledoc """
  ManufacturerSpecific Command Class

  This command class is used to advertise manufacturer information
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x72

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :manufacturer_specific
end
