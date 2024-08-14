defmodule Grizzly.ZWave.CommandClasses.SwitchMultilevel do
  @moduledoc """
  Multilevel Switch Command Class

  This command class provides commands that work with multilevel switches.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x26

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :switch_multilevel
end
