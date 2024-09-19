defmodule Grizzly.ZWave.CommandClasses.Association do
  @moduledoc """
  Association Command Class

  This command class provides commands for associating Z-Wave nodes together
  that are the same network. That means when some event happens on Z-Wave node
  A it can send messages to another node on the network node B.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x85

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :association
end
