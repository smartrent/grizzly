defmodule Grizzly.ZWave.Commands.PriorityRouteGet do
  @moduledoc """
  This command is used to query the current network route from a node for a given destination.

  Params:

   * `:node_id` - the node destination for which the current network route is requested (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: {:node_id, byte}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    node_id = Command.param!(command, :node_id)
    <<node_id>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<node_id>>) do
    {:ok, [node_id: node_id]}
  end
end
