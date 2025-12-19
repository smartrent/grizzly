defmodule Grizzly.ZWave.Commands.NodeRemoveStatus do
  @moduledoc """
  Z-Wave command for NODE_REMOVE_STATUS

  This command is useful to respond to a `Grizzly.ZWave.Commands.NodeRemove`
  command.

  Params:

    * `:seq_number` - the sequence number from the original node remove command
    * `:status` - the status of the result of the node removal
    * `:node_id` - the node id of the removed node
    * `:command_class_version` - explicitly set the command class version used
      to encode the command (optional - defaults to NetworkManagementInclusion v4)

  When encoding the params you can encode for a specific command class version
  by passing the `:command_class_version` to the encode options

  ```elixir
  Grizzly.ZWave.Commands.NodeRemoveStatus.encode_params(node_remove_status, command_class_version: 3)
  ```

  If there is no command class version specified this will encode to version 4 of the
  `NetworkManagementInclusion` command class. This version supports the use of 16 bit node
  ids.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.NodeId

  @type status() :: :done | :failed

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
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
  def encode_params(command, opts \\ []) do
    seq_number = Command.param!(command, :seq_number)
    status = Command.param!(command, :status)
    node_id = Command.param!(command, :node_id)

    case Keyword.get(opts, :command_class_version, 4) do
      4 ->
        <<seq_number, encode_status(status), NodeId.encode_extended(node_id)::binary>>

      n when n < 4 ->
        <<seq_number, encode_status(status), node_id>>
    end
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, keyword()} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, status_byte, node_id::binary>>) do
    case decode_status(status_byte) do
      {:ok, status} ->
        {:ok,
         [
           seq_number: seq_number,
           status: status,
           node_id: NodeId.parse(node_id)
         ]}

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
