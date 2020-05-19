defmodule Grizzly.ZWave.CommandClasses.Supervision do
  @moduledoc """
  The Supervision Command Class allows a sending node to request application-level delivery
   confirmation from a receiving node.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x6C

  @impl true
  def name(), do: :supervision
end
