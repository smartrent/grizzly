defmodule Grizzly.ZWave.CommandClasses.ZIPGateway do
  @moduledoc """
  ZIPGateway Command Class

  This command class is used for configuration Z/IP Gateway at runtime
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x5F

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :zip_gateway
end
