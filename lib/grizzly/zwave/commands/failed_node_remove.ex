defmodule Grizzly.ZWave.Commands.FailedNodeRemove do
  @moduledoc """
  This command is used to remove a non-responding node. It will only succeed
  if the controller has already put the node on the failed nodes list.

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:node_id` - The id of the node to be removed if failed as presumed (required)

  When encoding the params you can encode for a specific command class version
  by passing the `:command_class_version` to the encode options

  ```elixir
  Grizzly.ZWave.Commands.FailedNodeRemove.encode_params(failed_node_remove, command_class_version: 3)
  ```

  If there is no command class version specified this will encode to version 4 of the
  `NetworkManagementInclusion` command class. This version supports the use of 16 bit node
  ids.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, NodeId}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type param() :: {:node_id, char()} | {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :failed_node_remove,
      command_byte: 0x07,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command, opts \\ []) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)

    case Keyword.get(opts, :command_class_version, 4) do
      4 ->
        <<seq_number, NodeId.encode_extended(node_id)::binary>>

      n when n < 4 ->
        <<seq_number, node_id>>
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<seq_number, node_id::binary>>) do
    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(node_id)
     ]}
  end
end
