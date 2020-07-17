defmodule Grizzly.ZWave.CommandClasses.TimeParameters do
  @moduledoc """
  "TimeParameters" Command Class

  The Time Parameters Command Class is used to set date and time.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x8B

  @impl true
  def name(), do: :time_parameters
end
