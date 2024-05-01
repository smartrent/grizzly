defmodule Grizzly.NodeId do
  @moduledoc false

  @doc "Returns true if the given value is a valid classic Z-Wave node ID"
  defguard is_classic_node_id(node_id)
           when is_integer(node_id) and node_id >= 0 and node_id <= 232

  @doc "Returns true if the given value is a valid Z-Wave Long Range node ID"
  defguard is_long_range_node_id(node_id)
           when is_integer(node_id) and node_id > 255 and node_id <= 4000

  @doc "Returns true if the given value is a valid Z-Wave node ID (classic or long range)"
  defguard is_zwave_node_id(node_id)
           when is_classic_node_id(node_id) or is_long_range_node_id(node_id)

  @doc "Returns true if the given value is a virtual node ID"
  defguard is_virtual_node_id(node_id)
           when is_tuple(node_id) and tuple_size(node_id) == 2 and elem(node_id, 0) == :virtual and
                  is_integer(elem(node_id, 1))

  @doc "Returns true if the given value is a valid node ID (classic, long range, or virtual)"
  defguard is_node_id(node_id) when is_zwave_node_id(node_id) or is_virtual_node_id(node_id)
end
