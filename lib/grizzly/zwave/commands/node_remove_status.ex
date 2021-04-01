defmodule Grizzly.ZWave.Commands.NodeRemoveStatus do
  @moduledoc """
  Z-Wave command for NODE_REMOVE_STATUS

  This command is useful to respond to a `Grizzly.ZWave.Commands.NodeRemove`
  command.

  Params:

    * `:seq_number` - the sequence number from the original node remove command
    * `:status` - the status of the result of the node removal
    * `:node_id` the node id of the removed node

  All the parameters are required
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type status() :: :done | :failed

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_remove_status,
      command_byte: 0x04,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    status = Command.param!(command, :status)
    node_id = Command.param!(command, :node_id)

    <<seq_number, encode_status(status), node_id>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, status_byte, node_id>>) do
    do_decode_params(seq_number, status_byte, node_id)
  end

  def decode_params(<<seq_number, status_byte, node_id::size(16)>>) do
    do_decode_params(seq_number, status_byte, node_id)
  end

  defp do_decode_params(seq_number, status_byte, node_id) do
    case decode_status(status_byte) do
      {:ok, status} ->
        {:ok, [seq_number: seq_number, status: status, node_id: node_id]}

      {:error, %DecodeError{}} = error ->
        error
    end
  end

  @spec encode_status(status()) :: 0x06 | 0x07
  def encode_status(:done), do: 0x06
  def encode_status(:failed), do: 0x07

  @spec decode_status(byte()) :: {:ok, status()} | {:error, DecodeError.t()}
  def decode_status(0x06), do: {:ok, :done}
  def decode_status(0x07), do: {:ok, :failed}

  def decode_status(byte),
    do: {:error, %DecodeError{value: byte, param: :status, command: :node_remove_status}}
end
