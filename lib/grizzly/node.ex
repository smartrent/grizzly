defmodule Grizzly.Node do
  @moduledoc """
  Functions for working directly with a Z-Wave node
  """

  alias Grizzly.SeqNumber
  alias Grizzly.ZWave

  @type id :: non_neg_integer()

  @type lifeline_opts :: {:controller_id, ZWave.node_id()} | {:extra_node_ids, [ZWave.node_id()]}

  @doc """
  Get the information for a node by its id

  The response to this command is the `NodeInfoCacheReport` command
  """
  @spec get_node_info(ZWave.node_id()) :: Grizzly.send_command_response()
  def get_node_info(node_id) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_info_cached_get,
      seq_number: seq_number,
      node_id: node_id
    )
  end

  @doc """
  Get a node's dsk.

  The response to this command is the `DSKReport` command
  """
  @spec get_dsk(ZWave.node_id(), :add | :learn, [Grizzly.command_opt()]) ::
          Grizzly.send_command_response()
  def get_dsk(node_id, add_mode, opts \\ []) do
    Grizzly.send_command(
      node_id,
      :dsk_get,
      [add_mode: add_mode, seq_number: SeqNumber.get_and_inc()],
      opts
    )
  end

  @doc """
  Set lifeline association for the node

  The lifeline associated is used to report events that happen at the Z-Wave
  device level back to the Z-Wave controller. For example, if you turn on a
  light and want to be notified, the device will need to have it's lifeline
  association set.

  Opts:

    * `:controller_id` - the idea of the main controller to send lifeline
      reports to (defaults to `1`)
    * `:extra_node_ids` - any extra nodes to set add to the association
      group
  """
  @spec set_lifeline_association(ZWave.node_id(), [lifeline_opts()]) :: :ok
  def set_lifeline_association(node_id, opts \\ []) do
    controller_id = Keyword.get(opts, :controller_id, 1)
    extra_node_ids = Keyword.get(opts, :extra_node_ids, [])
    nodes = [controller_id | extra_node_ids]

    Grizzly.send_command(node_id, :association_set, grouping_identifier: 0x01, nodes: nodes)
  end
end
