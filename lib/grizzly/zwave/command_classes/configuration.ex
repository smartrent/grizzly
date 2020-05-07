defmodule Grizzly.ZWave.CommandClasses.Configuration do
  @moduledoc """
  Configuration command class

  This command class is used to configure manufacturer specific configuration
  parameters
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x70

  @impl true
  def name(), do: :configuration
end
