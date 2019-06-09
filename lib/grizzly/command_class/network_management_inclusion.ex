defmodule Grizzly.CommandClass.NetworkManagementInclusion do
  @type node_neighbor_update_status :: :done | :failed

  @spec decode_node_neighbor_update_status(0x22 | 0x23) :: node_neighbor_update_status
  def decode_node_neighbor_update_status(0x22), do: :done
  def decode_node_neighbor_update_status(0x23), do: :failed
end
