defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusion do
  @moduledoc """
  Network Management Inclusion Command Class

  This command class provides the commands for adding and removing Z-Wave nodes
  to the Z-Wave network
  """

  @behaviour Grizzly.ZWave.CommandClass

  @typedoc """

  """
  @type node_add_status() :: :done | :failed | :security_failed

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x34

  @impl true
  def name(), do: :network_management_inclusion
end
