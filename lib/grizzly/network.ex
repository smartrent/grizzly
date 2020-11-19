defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """

  alias Grizzly.{Associations, Connections, Report, SeqNumber, ZWave}
  alias Grizzly.ZWave.Command

  @typedoc """
  Options for when you want to reset the device

  - `:notify` - if the flag is set to true this will try to notify any node that
    is part of the lifeline association group (default `true`)
  """
  @type reset_opt() :: {:notify, boolean()}

  @doc """
  Get a list of node ids from the network

  Just because a node id might be in the list does not mean the node is on the
  network. A device might have been reset or unpaired from the controller with
  out the controller knowing. However, in most use cases this shouldn't be an
  issue.
  """
  @spec get_node_ids() :: Grizzly.send_command_response()
  def get_node_ids() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_list_get, seq_number: seq_number)
  end

  @doc """
  Reset the Z-Wave controller

  This command takes a few seconds to run.
  """
  @spec reset_controller([reset_opt()]) :: Grizzly.send_command_response()
  def reset_controller(opts \\ []) do
    # close all the connections before resetting the controller. It's okay
    # to blindly close all connections because when we send the command to
    # the controller Grizzly will automatically reconnect to the controller
    # at that point in time. We do this because the connections to the Z-Wave
    # devices are still reachable after being removed and we will still be
    # sending keep alive messages when we don't need to and will have
    # unnecessary connections hanging out just taking up resources.
    :ok = Connections.close_all()
    seq_number = SeqNumber.get_and_inc()

    case Grizzly.send_command(1, :default_set, [seq_number: seq_number], timeout: 10_000) do
      {:ok, %Report{type: :command, status: :complete}} = response ->
        maybe_notify_reset(response, opts)

      other ->
        other
    end
  end

  @doc """
  Delete a node from the network's provisioning list via the node's DSK
  """
  @spec delete_node_provisioning(Grizzly.ZWave.DSK.dsk_string()) ::
          Grizzly.send_command_response()
  def delete_node_provisioning(dsk) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_provisioning_delete, seq_number: seq_number, dsk: dsk)
  end

  @doc """
  Get the nodes provisioning list information via the node's DSK
  """
  @spec get_node_provisioning(Grizzly.ZWave.DSK.dsk_string()) ::
          Grizzly.send_command_response()
  def get_node_provisioning(dsk) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :node_provisioning_get, seq_number: seq_number, dsk: dsk)
  end

  @doc """
  A node to the network provisioning list
  """
  @spec set_node_provisioning(
          Grizzly.ZWave.DSK.dsk_string(),
          [Grizzly.ZWave.SmartStart.MetaExtension.t()]
        ) :: Grizzly.send_command_response()
  def set_node_provisioning(dsk, meta_extensions) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      1,
      :node_provisioning_set,
      seq_number: seq_number,
      dsk: dsk,
      meta_extensions: meta_extensions
    )
  end

  @doc """
  List all the nodes on the provisioning list
  """
  @spec list_node_provisionings(integer) :: Grizzly.send_command_response()
  def list_node_provisionings(remaining_counter) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(
      1,
      :node_provisioning_list_iteration_get,
      seq_number: seq_number,
      remaining_counter: remaining_counter
    )
  end

  @doc """
  Remove a (presumably) failed node
  """
  @spec remove_failed_node(ZWave.node_id()) ::
          Grizzly.send_command_response()
  def remove_failed_node(node_id) do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :failed_node_remove, seq_number: seq_number, node_id: node_id)
  end

  @doc """
  Request a network update (network healing)
  """
  @spec request_network_update() ::
          Grizzly.send_command_response()
  def request_network_update() do
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :network_update_request, seq_number: seq_number)
  end

  defp maybe_notify_reset(response, opts) do
    {:ok, %Report{command: command}} = response

    case Command.param!(command, :status) do
      :done ->
        maybe_notify_reset(opts)
        response

      :busy ->
        response
    end
  end

  defp maybe_notify_reset(opts) do
    if Keyword.get(opts, :notify, true) do
      notify_reset()
    else
      :ok
    end
  end

  defp notify_reset() do
    # get the nodes in the lifeline group
    case Associations.get(1) do
      nil ->
        :ok

      association ->
        Enum.each(association.node_ids, fn node_id ->
          Grizzly.send_command(node_id, :device_reset_locally_notification)
        end)
    end
  end
end
