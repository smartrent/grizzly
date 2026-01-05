defmodule Grizzly.ZWave.Commands.PriorityRouteGet do
  @moduledoc """
  This command is used to query the current network route from a node for a given destination.

  Params:

   * `:node_id` - the node destination for which the current network route is requested (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  @type param :: {:node_id, byte}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :priority_route_get,
      command_byte: 0x02,
      command_class: NetworkManagementInstallationMaintenance,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    <<node_id>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<node_id>>) do
    {:ok, [node_id: node_id]}
  end
end
