defmodule Grizzly.ZWave.Commands.FailedNodeRemove do
  @moduledoc """
  This command is used to remove a non-responding node. It will only succeed
  if the controller has already put the node on the failed nodes list.

  Params:

    * `:seq_number` - the sequence number of the networked command (required)
    * `:node_id` - The id of the node to be removed if failed as presumed (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type param :: {:node_id, byte} | {:seq_number, ZWave.seq_number()}

  @impl true
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

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    node_id = Command.param!(command, :node_id)
    <<seq_number, node_id>>
  end

  @impl true
  def decode_params(<<seq_number, node_id>>) do
    {:ok, [seq_number: seq_number, node_id: node_id]}
  end
end
