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

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandHandlers.AckResponse

  @type status :: :done | :failed

  @impl true
  def new(params) do
    # TODO validate params
    command = %Command{
      name: :node_remove_status,
      command_class_name: :network_management_inclusion,
      command_class_byte: 0x34,
      command_byte: 0x04,
      params: params,
      handler: AckResponse,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    status = Command.param!(command, :status)
    node_id = Command.param!(command, :node_id)

    <<seq_number, encode_status(status), node_id>>
  end

  @impl true
  def decode_params(<<seq_number, status_byte, node_id>>) do
    [seq_number: seq_number, status: decode_status(status_byte), node_id: node_id]
  end

  @spec encode_status(status()) :: 0x06 | 0x07
  def encode_status(:done), do: 0x06
  def encode_status(:failed), do: 0x07

  @spec decode_status(byte()) :: status()
  def decode_status(0x06), do: :done
  def decode_status(0x07), do: :failed
end
