defmodule Grizzly.ZWave.Commands.AssociationRemove do
  @moduledoc """
  This command is used to remove destinations from a given association group.

  Params:

    * `:grouping_identifiers` - the association grouping identifier (required)

    * `:nodes` - list of nodes to add the grouping identifier (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  @type param :: {:grouping_identifier, byte()} | {:nodes, [ZWave.node_id()]}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :association_remove,
      command_byte: 0x04,
      command_class: Association,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    nodes_bin = :erlang.list_to_binary(Command.param!(command, :nodes))
    <<Command.param!(command, :grouping_identifier)>> <> nodes_bin
  end

  @impl true
  @spec decode_params(binary) :: {:ok, [param()]}
  def decode_params(<<grouping_identifier, nodes_bin::binary>>) do
    {:ok, [grouping_identifier: grouping_identifier, nodes: :erlang.binary_to_list(nodes_bin)]}
  end
end
