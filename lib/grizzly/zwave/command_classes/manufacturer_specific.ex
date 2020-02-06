defmodule Grizzly.ZWave.CommandClasses.ManufacturerSpecific do
  @moduledoc """
  ManufacturerSpecific Command Class

  This command class is used to advertise manufacturer information
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x72

  @impl true
  def name(), do: :manufacturer_specific
end
