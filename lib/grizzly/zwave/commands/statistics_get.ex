defmodule Grizzly.ZWave.Commands.StatisticsGet do
  @moduledoc """
   This command is used to query Installation and Maintenance statistics from a node.

  Params:

   * `:node_id` - the node destination for which the current network route is requested (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance

  # give me some type specs for your params
  @type param :: {:node_id, byte}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :statistics_get,
      command_byte: 0x04,
      command_class: NetworkManagementInstallationMaintenance,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    node_id = Command.param!(command, :node_id)
    <<node_id>>
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<node_id>>) do
    {:ok, [node_id: node_id]}
  end
end
