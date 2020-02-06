defmodule Grizzly.ZWave.CommandClasses.Version do
  @moduledoc """
  Version Command Class

  This command class is used to get version information about the Z-Wave
  protocol, command classes, and vendor specific versions
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x86

  @impl true
  def name(), do: :version
end
