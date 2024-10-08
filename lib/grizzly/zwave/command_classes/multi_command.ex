defmodule Grizzly.ZWave.CommandClasses.MultiCommand do
  @moduledoc """
  "MultiCommand" Command Class

  The Multi Command Command Class is used to bundle multiple commands in one encapsulation
  Command.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x8F

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :multi_cmd
end
