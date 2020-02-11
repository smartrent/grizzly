defmodule Grizzly.Node do
  @moduledoc """
  Functions for working directly with a Z-Wave node
  """

  @type id :: non_neg_integer()

  @spec get_node_info(id()) :: :ok
  def get_node_info(node_id) do
    :ok
  end
end
