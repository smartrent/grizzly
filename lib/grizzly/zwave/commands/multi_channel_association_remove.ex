defmodule Grizzly.ZWave.Commands.MultiChannelAssociationRemove do
  @moduledoc """
  This command is used to remove NodeID and End Point destinations from a given association group.
  The destinations MAY be a mix of NodeID destinations and End Point destinations.

  Params:

   * `:grouping_identifier` - the association grouping identifier (required)

    * `:nodes` - list of nodes to add the grouping identifier (required)

    * `:node_endpoints` - Endpoints of multichannel nodes

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannelAssociation

  @type param ::
          {:grouping_identifier, byte()}
          | {:nodes, [ZWave.node_id()]}
          | {:node_endpoints, [MultiChannelAssociation.node_endpoint()]}

  @marker 0x00

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :multi_channel_association_remove,
      command_byte: 0x04,
      command_class: MultiChannelAssociation,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    grouping_identifier = Command.param!(command, :grouping_identifier)
    nodes_bin = :erlang.list_to_binary(Command.param!(command, :nodes))
    node_endpoints = Command.param!(command, :node_endpoints)

    if Enum.empty?(node_endpoints) do
      <<Command.param!(command, :grouping_identifier)>> <> nodes_bin
    else
      encoded_node_endpoints = MultiChannelAssociation.encode_node_endpoints(node_endpoints)

      <<grouping_identifier>> <>
        nodes_bin <>
        <<@marker>> <>
        encoded_node_endpoints
    end
  end

  @impl true
  @spec decode_params(binary) :: {:ok, [param()]}
  def decode_params(<<grouping_identifier, rest::binary>>) do
    {node_ids, node_endpoints} = MultiChannelAssociation.decode_nodes_and_node_endpoints(rest)

    {:ok,
     [grouping_identifier: grouping_identifier, nodes: node_ids, node_endpoints: node_endpoints]}
  end
end
