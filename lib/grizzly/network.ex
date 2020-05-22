defmodule Grizzly.Network do
  @moduledoc """
  Module for working with the Z-Wave network
  """

  alias Grizzly.{Connections, SeqNumber}

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
  @spec reset_controller() :: Grizzly.send_command_response()
  def reset_controller() do
    # close all the connections before resetting the controller. It's okay
    # to blindly close all connections because when we send the command to
    # the controller Grizzly will automatically reconnect to the controller
    # at that point in time. We do this because the connections to the Z-Wave
    # devices are still reachable after being removed and we will still be
    # sending keep alive messages when we don't need to and will have
    # unnecessary connections hanging out just taking up resources.
    :ok = Connections.close_all()
    seq_number = SeqNumber.get_and_inc()

    Grizzly.send_command(1, :default_set, [seq_number: seq_number], timeout: 10_000)
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
end
