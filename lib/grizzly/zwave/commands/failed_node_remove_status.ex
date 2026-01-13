defmodule Grizzly.ZWave.Commands.FailedNodeRemoveStatus do
  @moduledoc """
  This command reports on the attempted removal of a presumed failed node.

  Params:

    * `:node_id` - the id of the node which removal for failure was attempted
    * `:seq_number` - the sequence number of the removal command
    * `:status` - whether the presumed failed node was removed

  When encoding the params you can encode for a specific command class version
  by passing the `:command_class_version` to the encode options

  ```elixir
  Grizzly.ZWave.Commands.FailedNodeRemoveStatus.encode_params(failed_node_remove_status)
  ```

  If there is no command class version specified this will encode to version 4 of
  the `NetworkManagementInclusion` command class. This version supports the use
  of 16 bit node ids.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.NodeId

  @type status() :: :done | :failed_node_not_found | :failed_node_remove_fail
  @type param() :: {:node_id, char()} | {:seq_number, ZWave.seq_number()} | {:status, status}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    status_byte = Command.param!(command, :status) |> encode_status()

    <<seq_number, status_byte, NodeId.encode_extended(node_id)::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, status_byte, node_id_bin::binary>>) do
    with {:ok, status} <- decode_status(status_byte) do
      node_id = NodeId.parse(node_id_bin)

      {:ok, [seq_number: seq_number, node_id: node_id, status: status]}
    else
      {:error, %DecodeError{} = error} ->
        {:error, error}
    end
  end

  defp encode_status(:failed_node_not_found), do: 0x00
  defp encode_status(:done), do: 0x01
  defp encode_status(:failed_node_remove_fail), do: 0x02

  defp decode_status(0x00), do: {:ok, :failed_node_not_found}
  defp decode_status(0x01), do: {:ok, :done}
  defp decode_status(0x02), do: {:ok, :failed_node_remove_fail}

  defp decode_status(byte),
    do: {:error, %DecodeError{value: byte, param: :status, command: :failed_node_remove_status}}
end
