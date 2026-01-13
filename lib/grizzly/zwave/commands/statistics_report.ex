defmodule Grizzly.ZWave.Commands.StatisticsReport do
  @moduledoc """
  This command is used to query Installation and Maintenance statistics from a node.

  Params:

    * `:node_id` - the NodeID for which statistics are requested

    * `:statistics` - statistics collected about the node

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:node_id, byte} | {:statistics, NetworkManagementInstallationMaintenance.statistics()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    node_id = Command.param!(command, :node_id)

    statistics_binary =
      Command.param!(command, :statistics)
      |> NetworkManagementInstallationMaintenance.statistics_to_binary()

    <<node_id>> <> statistics_binary
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<node_id, statistics_binary::binary>>) do
    with {:ok, statistics} <-
           NetworkManagementInstallationMaintenance.statistics_from_binary(statistics_binary) do
      {:ok, [node_id: node_id, statistics: statistics]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :statistics_report}}
    end
  end
end
