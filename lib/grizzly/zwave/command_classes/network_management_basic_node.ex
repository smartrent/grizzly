defmodule Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode do
  @moduledoc """
  Command class for working with Z-Wave network updates and resetting the
  controller back to the factor defaults
  """
  @behaviour Grizzly.ZWave.CommandClass

  @impl true
  def byte(), do: 0x4D

  @impl true
  def name(), do: :network_management_basic_node
end
