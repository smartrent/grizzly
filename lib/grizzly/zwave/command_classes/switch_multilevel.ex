defmodule Grizzly.ZWave.CommandClasses.SwitchMultilevel do
  @moduledoc """
  Multilevel Switch Command Class

  This command class provides commands that work with multilevel switches.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x26

  @impl true
  def name(), do: :switch_multilevel
end
