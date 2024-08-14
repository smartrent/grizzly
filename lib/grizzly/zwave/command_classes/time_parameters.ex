defmodule Grizzly.ZWave.CommandClasses.TimeParameters do
  @moduledoc """
  "TimeParameters" Command Class

  The Time Parameters Command Class is used to set date and time.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x8B

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :time_parameters
end
