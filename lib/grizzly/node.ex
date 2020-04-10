defmodule Grizzly.Node do
  @moduledoc """
  Functions for working directly with a Z-Wave node
  """

  alias Grizzly.SeqNumber

  @type id :: non_neg_integer()

  @doc """
  Get the information for a node by its id

  The response to this command is the `NodeInfoCacheReport` command
  """
  @spec get_node_info(id()) :: Grizzly.send_command_response()
  def get_node_info(node_id) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_info_cached_get,
      seq_number: seq_number,
      node_id: node_id
    )
  end
end
