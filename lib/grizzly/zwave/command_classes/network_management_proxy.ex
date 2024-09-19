defmodule Grizzly.ZWave.CommandClasses.NetworkManagementProxy do
  @moduledoc """
  Network Management Proxy Command Class

  This command class is used to report information about the Z-Wave nodes on
  the network such has node ids, supported command classes and their security
  support, multi channel end points (version 2 only), and basic, generic, and
  specific device classes.
  """

  @behaviour Grizzly.ZWave.CommandClass

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x52

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :network_management_proxy
end
