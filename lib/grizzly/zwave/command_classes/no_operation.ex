defmodule Grizzly.ZWave.CommandClasses.NoOperation do
  @moduledoc """
  "NoOperation" Command Class

  Supports the :no_operation command which does nothing other than confirming that the device is responsive.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x00

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :no_operation
end
