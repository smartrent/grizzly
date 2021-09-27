defmodule Grizzly.ZWave.CommandClasses.NetworkManagementInclusion do
  @moduledoc """
  Network Management Inclusion Command Class

  This command class provides the commands for adding and removing Z-Wave nodes
  to the Z-Wave network
  """

  @behaviour Grizzly.ZWave.CommandClass

  @typedoc """
  The status of the inclusion process

  * `:done` - the inclusion process is done without error
  * `:failed` - the inclusion process is done with failure, the device is not
    included
  * `:security_failed` - the inclusion process is done, the device is included
    but their was an error during the security negotiations. Device \
    functionality will be degraded.
  """
  @type node_add_status() :: :done | :failed | :security_failed

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x34

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :network_management_inclusion

  @doc """
  Parse the node add status byte into an atom
  """
  @spec parse_node_add_status(0x06 | 0x07 | 0x09) :: node_add_status()
  def parse_node_add_status(0x06), do: :done
  def parse_node_add_status(0x07), do: :failed
  def parse_node_add_status(0x09), do: :security_failed

  @doc """
  Encode a `node_add_status()` to a byte
  """
  @spec node_add_status_to_byte(node_add_status()) :: 0x06 | 0x07 | 0x09
  def node_add_status_to_byte(:done), do: 0x06
  def node_add_status_to_byte(:failed), do: 0x07
  def node_add_status_to_byte(:security_failed), do: 0x09
end
