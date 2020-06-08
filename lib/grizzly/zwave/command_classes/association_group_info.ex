defmodule Grizzly.ZWave.CommandClasses.AssociationGroupInfo do
  @moduledoc """
  "AssociationGroupInfo" Command Class

  This command class allows a node to advertise the capabilities of
  each association group supported by a given application resource.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x59

  @impl true
  def name(), do: :association_group_info
end
