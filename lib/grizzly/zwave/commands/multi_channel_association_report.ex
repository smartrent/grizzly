defmodule Grizzly.ZWave.Commands.MultiChannelAssociationReport do
  @moduledoc """
  This command is used to advertise the current destinations for a given association group.

  Params:

    * `:grouping_identifier` - the association grouping identifier (required)
    * `:max_nodes_supported` - the maximum number of destinations supported by the advertised association group. Each destination
                               may be a NodeID destination or an End Point destination.
    * `:reports_to_follow` - if the full destination list is too long for one
                             report this field reports the number of follow up reports (optional
                             default `0`)
    * `:nodes` - list of nodes to add the grouping identifier (required)
    * `:node_endpoints` - Endpoints of multichannel nodes

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.MultiChannelAssociation

  @type param() ::
          {:grouping_identifier, byte()}
          | {:max_nodes_supported, byte()}
          | {:reports_to_follow, byte()}
          | {:nodes, [ZWave.node_id()]}
          | {:node_endpoints, [MultiChannelAssociation.node_endpoint()]}

  @marker 0x00

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    grouping_identifier = Command.param!(command, :grouping_identifier)
    max_nodes_supported = Command.param!(command, :max_nodes_supported)
    reports_to_follow = Command.param!(command, :reports_to_follow)
    nodes_bin = :erlang.list_to_binary(Command.param!(command, :nodes))
    node_endpoints = Command.param!(command, :node_endpoints)

    if Enum.empty?(node_endpoints) do
      <<grouping_identifier, max_nodes_supported, reports_to_follow>> <> nodes_bin
    else
      encoded_node_endpoints = MultiChannelAssociation.encode_node_endpoints(node_endpoints)

      <<grouping_identifier, max_nodes_supported, reports_to_follow>> <>
        nodes_bin <>
        <<@marker>> <>
        encoded_node_endpoints
    end
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<grouping_identifier, max_nodes_supported, reports_to_follow, rest::binary>>
      ) do
    {node_ids, node_endpoints} = MultiChannelAssociation.decode_nodes_and_node_endpoints(rest)

    {:ok,
     [
       grouping_identifier: grouping_identifier,
       max_nodes_supported: max_nodes_supported,
       reports_to_follow: reports_to_follow,
       nodes: node_ids,
       node_endpoints: node_endpoints
     ]}
  end
end
