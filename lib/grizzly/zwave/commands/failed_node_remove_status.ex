defmodule Grizzly.ZWave.Commands.FailedNodeRemoveStatus do
  @moduledoc """
  This command reports on the attempted removal of a presumed failed node.

  Params:

    * `:node_id` - the id of the node which removal for failure was attempted
    * `:seq_number` - the sequence number of the removal command
    * `:status` - whether the presumed failed node was removed

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type status() :: :done | :failed_node_not_found | :failed_node_remove_fail
  @type param() :: {:node_id, char()} | {:seq_number, ZWave.seq_number()} | {:status, status}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :failed_node_remove_status,
      command_byte: 0x08,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    status_byte = Command.param!(command, :status) |> encode_status()
    <<seq_number, status_byte, node_id>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, status_byte, node_id>>) do
    do_decode_params(seq_number, status_byte, node_id)
  end

  def decode_params(<<seq_number, status_byte, node_id::size(16)>>) do
    do_decode_params(seq_number, status_byte, node_id)
  end

  defp do_decode_params(seq_number, status_byte, node_id) do
    with {:ok, status} <- decode_status(status_byte) do
      {:ok, [seq_number: seq_number, node_id: node_id, status: status]}
    else
      {:error, %DecodeError{} = error} ->
        error
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
