defmodule Grizzly.ZWave.CommandClasses.SwitchBinary do
  @moduledoc """
  Switch Binary Command Class

  This command class provides command work with switches that are either on
  or off.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x25

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :switch_binary
end
