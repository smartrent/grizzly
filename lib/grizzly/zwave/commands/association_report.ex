defmodule Grizzly.ZWave.Commands.AssociationReport do
  @moduledoc """
  Report the destinations for the given association group

  Params:

    * `:grouping_identifier` - the grouping identifier for the the association
      group (required)
    * `:max_nodes_supported` - the max number of destinations for the
      association group (required)
    * `:reports_to_follow` - if the full destination list is too long for one
      report this field reports the number of follow up reports (optional
      default `0`)
    * `:nodes` - the destination nodes in the association group (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  @type param ::
          {:grouping_identifier, byte()}
          | {:max_nodes_supported, byte()}
          | {:reports_to_follow, byte()}
          | {:nodes, [ZWave.node_id()]}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    gi = Command.param!(command, :grouping_identifier)
    max_nodes = Command.param!(command, :max_nodes_supported)
    reports_to_follow = Command.param!(command, :reports_to_follow)
    nodes_bin = :erlang.list_to_binary(Command.param!(command, :nodes))
    <<gi, max_nodes, reports_to_follow>> <> nodes_bin
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<gi, max_nodes, reports_to_follow, nodes_bin::binary>>) do
    {:ok,
     [
       grouping_identifier: gi,
       max_nodes_supported: max_nodes,
       reports_to_follow: reports_to_follow,
       nodes: :erlang.binary_to_list(nodes_bin)
     ]}
  end
end
