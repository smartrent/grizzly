defmodule Grizzly.ZWave.CommandClasses.WakeUp do
  @moduledoc """
  "WakeUp" Command Class

  This command class is used to get and set the wake-up intervals of wake-up devices.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x84

  @impl true
  def name(), do: :wake_up
end
