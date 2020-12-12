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

  @type opt() :: {:node_id, ZWave.node_id()}

  @doc """
  Get a list of node ids from the network

  Just because a node id might be in the list does not mean the node is on the
  network. A device might have been reset or unpaired from the controller with
  out the controller knowing. However, in most use cases this shouldn't be an
  issue.

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec get_node_ids([opt()]) :: Grizzly.send_command_response()
  def get_node_ids(opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(node_id, :node_list_get, seq_number: seq_number)
  end

  @doc """
  Reset the Z-Wave controller

  This command takes a few seconds to run.

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec reset_controller([reset_opt() | opt()]) :: Grizzly.send_command_response()
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
    node_id = node_id_from_opts(opts)

    case Grizzly.send_command(node_id, :default_set, [seq_number: seq_number], timeout: 10_000) do
      {:ok, %Report{type: :command, status: :complete}} = response ->
        maybe_notify_reset(response, opts)

      other ->
        other
    end
  end

  @doc """
  Delete a node from the network's provisioning list via the node's DSK

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec delete_node_provisioning(Grizzly.ZWave.DSK.dsk_string(), [opt()]) ::
          Grizzly.send_command_response()
  def delete_node_provisioning(dsk, opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(node_id, :node_provisioning_delete, seq_number: seq_number, dsk: dsk)
  end

  @doc """
  Get the nodes provisioning list information via the node's DSK

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec get_node_provisioning(Grizzly.ZWave.DSK.dsk_string(), [opt()]) ::
          Grizzly.send_command_response()
  def get_node_provisioning(dsk, opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(node_id, :node_provisioning_get, seq_number: seq_number, dsk: dsk)
  end

  @doc """
  A node to the network provisioning list

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec set_node_provisioning(
          Grizzly.ZWave.DSK.dsk_string(),
          [Grizzly.ZWave.SmartStart.MetaExtension.t()],
          [opt()]
        ) :: Grizzly.send_command_response()
  def set_node_provisioning(dsk, meta_extensions, opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(
      node_id,
      :node_provisioning_set,
      seq_number: seq_number,
      dsk: dsk,
      meta_extensions: meta_extensions
    )
  end

  @doc """
  List all the nodes on the provisioning list

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec list_node_provisionings(integer(), [opt()]) :: Grizzly.send_command_response()
  def list_node_provisionings(remaining_counter, opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(
      node_id,
      :node_provisioning_list_iteration_get,
      seq_number: seq_number,
      remaining_counter: remaining_counter
    )
  end

  @doc """
  Remove a (presumably) failed node

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec remove_failed_node([opt()]) ::
          Grizzly.send_command_response()
  def remove_failed_node(opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(:gateway, :failed_node_remove, seq_number: seq_number, node_id: node_id)
  end

  @doc """
  Request a network update (network healing)

  Options

    * `:node_id` - If your controller is part of another controller's network
      you might want to issue network commands to that controller. By default
      this option will chose your controller.
  """
  @spec request_network_update([opt()]) ::
          Grizzly.send_command_response()
  def request_network_update(opts \\ []) do
    seq_number = SeqNumber.get_and_inc()
    node_id = node_id_from_opts(opts)

    Grizzly.send_command(node_id, :network_update_request, seq_number: seq_number)
  end

  defp node_id_from_opts(opts) do
    Keyword.get(opts, :node_id, :gateway)
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
