defmodule Grizzly.ZWave.CommandClasses.Battery do
  @moduledoc """
  "Battery" Command Class

  This command class is used to get the battery level.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x80

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :battery
end
