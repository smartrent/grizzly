defmodule Grizzly.ZWave.Commands.AssociationSet do
  @moduledoc """
  Module for the `ASSOCIATION_SET` command

  The node receiving this command should add the specified node ids to the
  association group. However, if the association group for the node is full
  this command is ignored.

  Params:

    - `:grouping_identifier` - the association grouping identifier (required)
    - `:nodes` - list of nodes to add the grouping identifier (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Association

  # I think grouping identifier is list that gets masked, but for now we will
  # just work as if if the identifier is only one.
  @type param :: {:grouping_identifier, byte()} | {:nodes, [ZWave.node_id()]}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    # TODO: validate params
    command = %Command{
      name: :association_set,
      command_byte: 0x01,
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
