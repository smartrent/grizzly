defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  # module helper for handling various different responses from the Z-Wave PAN
  # network

  require Logger

  alias Grizzly.Transport
  alias Grizzly.{Associations, ZWave}
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationReport,
    AssociationGroupingsReport,
    AssociationSpecificGroupReport
  }

  @type opt() :: {:association_server, GenServer.name()}

  @type handle_response_result() :: :ok | {:notify, Command.t()} | {:send, Command.t()}

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Transport.Response.t(), [opt()]) :: handle_response_result()
  def handle_response(response, opts \\ []) do
    internal_command = Command.param!(response.command, :command)

    case handle_command(internal_command, opts) do
      {:ok, command} ->
        # binary = ZWave.to_binary(zip_packet)
        # Transport.send(transport, binary, to: {response.ip_address, response.port})
        {:send, command}

      :notification ->
        # :ok = Messages.broadcast(response.ip_address, response.command)
        {:notify, internal_command}

      {:notification, command} ->
        # :ok = Messages.broadcast(response.ip_address, command)
        {:notify, command}

      :ok ->
        :ok
    end
  end

  defp handle_command(%Command{name: :supervision_get} = command, _) do
    encapsulated_command = Command.param!(command, :encapsulated_command)

    case ZWave.from_binary(encapsulated_command) do
      {:ok, report} ->
        {:notification, report}

      {:error, reason} ->
        Logger.warn(
          "Failed to parse: #{inspect(encapsulated_command)} notification for reason: #{
            inspect(reason)
          }"
        )

        :ok
    end
  end

  defp handle_command(%Command{name: :association_specific_group_get}, _) do
    AssociationSpecificGroupReport.new(group: 0)
  end

  defp handle_command(%Command{name: :association_get}, opts) do
    # According the the Z-Wave specification if a get request contains an
    # unsupported grouping identifier then we should report back the grouping
    # information for group number 1. Since right now we only support that
    # group we don't need to check because we will always just send back the
    # grouping information for group id 1.
    associations_server = Keyword.get(opts, :associations_server, Associations)

    case Associations.get(associations_server, 1) do
      nil ->
        AssociationReport.new(
          grouping_identifier: 1,
          max_nodes_supported: 1,
          nodes: []
        )

      association ->
        AssociationReport.new(
          grouping_identifier: association.grouping_id,
          max_nodes_supported: 1,
          nodes: association.node_ids
        )
    end
  end

  defp handle_command(%Command{name: :association_set} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)
      Associations.save(associations_server, grouping_identifier, nodes)
    else
      :ok
    end
  end

  defp handle_command(%Command{name: :association_groupings_get}, _opts) do
    AssociationGroupingsReport.new(supported_groupings: 1)
  end

  defp handle_command(%Command{name: :association_remove} = command, opts) do
    associations_server = Keyword.get(opts, :associations_server, Associations)
    grouping_id = Command.param!(command, :grouping_identifier)
    nodes = Command.param!(command, :nodes)

    # This case matching is based off a table from the Z-Wave specification
    # Right now we only have one association grouping, so the first and third
    # match are the same right now. I want to keep the matching explicit right
    # now as I hope it will enable quicker understand to any future work that
    # will be as it maps nicely to the documentation found in the Z-Wave
    # specification.
    case {grouping_id, nodes} do
      {1, []} ->
        Associations.delete_all_nodes_from_grouping(associations_server, grouping_id)

      {1, nodes} ->
        Associations.delete_nodes_from_grouping(associations_server, grouping_id, nodes)

      {0, []} ->
        Associations.delete_all(associations_server)

      {0, nodes} ->
        Associations.delete_nodes_from_all_groupings(associations_server, nodes)

      _ ->
        :ok
    end
  end

  defp handle_command(_command, _opts), do: :notification
end
