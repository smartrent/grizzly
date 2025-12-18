defmodule Grizzly.Node do
  @moduledoc """
  Functions for working directly with a Z-Wave node
  """

  alias Grizzly.Report
  alias Grizzly.SeqNumber
  alias Grizzly.VirtualDevices
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance, as: NMIM

  @type id :: non_neg_integer()

  @type lifeline_opts :: {:controller_id, ZWave.node_id()} | {:extra_node_ids, [ZWave.node_id()]}

  @typedoc """
  Options to use when getting device info.

  * `:force_update` - By default there is a cache managed by `zipgateway` that
    tracks the device information. Sometimes that can get out of date, so you
    can pass `[force_update: true]` to force the cache to update the device
    info. By default this is `false`
  """
  @type info_opt() :: {:force_update, boolean()} | info_opt()

  @type opt() :: {:seq_number, integer()} | {:timeout, non_neg_integer()}

  @doc """
  Get the information for a node by its id

  The response to this command is the `NodeInfoCachedReport` command
  """
  @spec get_info(ZWave.node_id() | VirtualDevices.id(), [info_opt() | opt()]) ::
          Grizzly.send_command_response()
  def get_info(node_id, opts \\ [])

  def get_info({:virtual, _} = node_id, opts) do
    seq_number = opts[:seq_number] || SeqNumber.get_and_inc()
    send_command_opts = Keyword.drop(opts, [:seq_number])

    params = [
      seq_number: seq_number,
      node_id: node_id
    ]

    Grizzly.send_command(node_id, :node_info_cached_get, params, send_command_opts)
  end

  def get_info(node_id, opts) do
    {info_opts, send_command_opts} = Keyword.split(opts, [:seq_number, :max_age, :force_update])
    seq_number = info_opts[:seq_number] || SeqNumber.get_and_inc()
    max_age = info_get_max_age(info_opts)

    # we set the timeout to default to 30 seconds because Z-Wave will have to
    # do the node interrogation flow again. In cases where using the cache is
    # ok, the response is immediate.
    send_command_opts = Keyword.put_new(send_command_opts, :timeout, 30_000)

    params = [
      seq_number: seq_number,
      node_id: node_id,
      max_age: max_age
    ]

    with {:ok, %Grizzly.Report{command: %Command{name: :node_info_cached_report} = cmd} = report} <-
           Grizzly.send_command(:gateway, :node_info_cached_get, params, send_command_opts) do
      Grizzly.Storage.put_node_info(node_id, cmd)
      {:ok, report}
    end
  end

  defp info_get_max_age(info_opt) do
    cond do
      info_opt[:force_update] -> :force_update
      info_opt[:max_age] -> info_opt[:max_age]
      # if the caller does not want to force a cache update this default
      # allowing records up to 32 minutes old. This is calculated at the Z-Wave
      # level as 2^5.
      true -> 5
    end
  end

  @doc """
  Get a node's dsk.

  The response to this command is the `DSKReport` command

  Sending this command with `:gateway` will always go to your Z-Wave controller
  """
  @spec get_dsk(ZWave.node_id() | :gateway, :add | :learn, [Grizzly.command_opt()]) ::
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
  @spec set_lifeline_association(ZWave.node_id() | VirtualDevices.id(), [lifeline_opts()]) ::
          Grizzly.send_command_response()
  def set_lifeline_association(node_id, opts \\ []) do
    controller_id = Keyword.get(opts, :controller_id, 1)
    extra_node_ids = Keyword.get(opts, :extra_node_ids, [])
    nodes = [controller_id | extra_node_ids]

    Grizzly.send_command(node_id, :association_set, grouping_identifier: 0x01, nodes: nodes)
  end

  @doc """
  Get the lifeline association group for a node.
  """
  @spec get_lifeline_association(ZWave.node_id() | VirtualDevices.id()) ::
          Grizzly.send_command_response()
  def get_lifeline_association(node_id) do
    Grizzly.send_command(node_id, :association_get, grouping_identifier: 0x01)
  end

  @doc """
  Gets a node's statistics from Z/IP Gateway.
  """
  @spec get_statistics(ZWave.node_id() | VirtualDevices.id()) ::
          {:ok, NMIM.statistics()} | {:error, any()}
  def get_statistics(node_id) do
    with {:ok, %Report{command: %Command{} = cmd}} <-
           Grizzly.send_command(:gateway, :statistics_get, node_id: node_id),
         stats when is_list(stats) <- Command.param(cmd, :statistics) do
      {:ok, stats}
    else
      nil ->
        {:error, :unavailable}

      {_, %Grizzly.Report{type: :timeout}} ->
        {:error, :timeout}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
