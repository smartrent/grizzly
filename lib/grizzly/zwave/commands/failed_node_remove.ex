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
  Grizzly.ZWave.Commands.FailedNodeRemove.encode_params(failed_node_remove)
  ```

  If there is no command class version specified this will encode to version 4 of the
  `NetworkManagementInclusion` command class. This version supports the use of 16 bit node
  ids.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.NodeId

  @type param() :: {:node_id, char()} | {:seq_number, ZWave.seq_number()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)

    <<seq_number, NodeId.encode_extended(node_id)::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, node_id::binary>>) do
    {:ok,
     [
       seq_number: seq_number,
       node_id: NodeId.parse(node_id)
     ]}
  end
end
