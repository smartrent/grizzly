defmodule Grizzly.ZWave.CommandClasses.ZIP do
  @moduledoc """
  ZIP Command Class

  The Z/IP command class is useful for encapsulating Z-Wave commands to be sent
  via IP.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x23

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :zip
end
