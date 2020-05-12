defmodule Grizzly.ZWave.CommandClasses.Meter do
  @moduledoc """
  "Meter" Command Class

  The Meter Command Class is used to advertise instantaneous and accumulated numerical readings.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x32

  @impl true
  def name(), do: :meter
end
