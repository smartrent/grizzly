defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  # module helper for handling various different responses from the Z-Wave PAN
  # network

  require Logger

  alias Grizzly.SeqNumber
  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command

  alias Grizzly.ZWave.Commands.{
    AssociationReport,
    AssociationGroupingsReport,
    AssociationSpecificGroupReport,
    ZIPPacket
  }

  @type opt() :: {:data_file, Path.t()}

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Transport.t(), Transport.Response.t(), [opt()]) :: :ok
  def handle_response(transport, response, opts \\ []) do
    internal_command = Command.param!(response.command, :command)

    case handle_command(internal_command, opts) do
      {:ok, zip_packet} ->
        binary = ZWave.to_binary(zip_packet)
        Transport.send(transport, binary, to: {response.ip_address, response.port})

      :notification ->
        :ok = Messages.broadcast(response.ip_address, response.command)

      {:notification, command} ->
        :ok = Messages.broadcast(response.ip_address, command)

      :ok ->
        :ok
    end
  end

  defp handle_command(%Command{name: :supervision_get} = command, _opt) do
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
    seq_number = SeqNumber.get_and_inc()
    {:ok, report} = AssociationSpecificGroupReport.new(group: 0)

    ZIPPacket.with_zwave_command(report, seq_number)
  end

  defp handle_command(%Command{name: :association_get}, opts) do
    seq_number = SeqNumber.get_and_inc()
    data_file = Keyword.fetch!(opts, :data_file)
    # According the the Z-Wave specification if a get request contains an
    # unsupported grouping identifier then we should report back the grouping
    # information for group number 1. Since right now we only support that
    # group we don't need to check because we will always just send back the
    # grouping information for group id 1.
    {grouping_identifier, nodes} = get_grouping_identifier_and_nodes(data_file)

    {:ok, association_report} =
      AssociationReport.new(
        grouping_identifier: grouping_identifier,
        max_nodes_supported: 1,
        nodes: nodes
      )

    ZIPPacket.with_zwave_command(association_report, seq_number, flag: nil)
  end

  defp handle_command(%Command{name: :association_set} = command, opts) do
    grouping_identifier = Command.param!(command, :grouping_identifier)

    # According the Z-Wave specification we should just ignore grouping ids that
    # we don't support. As of right now we are only supporting grouping id 1, so
    # if the command contains something other than one we will just move along.
    if grouping_identifier == 1 do
      nodes = Command.param!(command, :nodes)
      data_file = Keyword.fetch!(opts, :data_file)

      binary = :erlang.term_to_binary({grouping_identifier, nodes})

      File.write(data_file, binary)
    else
      :ok
    end
  end

  defp handle_command(%Command{name: :association_groupings_get}, _) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, groupings_report} = AssociationGroupingsReport.new(supported_groupings: 1)

    ZIPPacket.with_zwave_command(groupings_report, seq_number, flag: nil)
  end

  defp handle_command(%Command{name: :association_remove} = command, opts) do
    grouping_id = Command.param!(command, :grouping_identifier)
    nodes = Command.param!(command, :nodes)
    data_file = Keyword.get(opts, :data_file)

    # This case matching is based off a table from the Z-Wave specification
    # Right now we only have one association grouping, so the first and third
    # match are the same right now. I want to keep the matching explicit right
    # now as I hope it will enable quicker understand to any future work that
    # will be as it maps nicely to the documentation found in the Z-Wave
    # specification.
    case {grouping_id, nodes} do
      {1, []} ->
        remove_all_nodes_from_grouping(grouping_id, data_file)

      {1, _} ->
        remove_nodes_from_grouping(grouping_id, nodes, data_file)

      {0, []} ->
        remove_all_nodes_from_grouping(1, data_file)

      {0, _} ->
        remove_nodes_from_grouping(1, nodes, data_file)

      _ ->
        :ok
    end
  end

  defp handle_command(_command, _), do: :notification

  defp get_grouping_identifier_and_nodes(data_file) do
    case File.read(data_file) do
      {:error, :enoent} ->
        {1, []}

      {:ok, binary} ->
        :erlang.binary_to_term(binary)
    end
  end

  defp remove_nodes_from_grouping(1, nodes, data_file) do
    {1, current_nodes} = get_grouping_identifier_and_nodes(data_file)

    new_nodes = current_nodes -- nodes
    new_associations = :erlang.term_to_binary({1, new_nodes})

    File.write(data_file, new_associations)
  end

  defp remove_all_nodes_from_grouping(1, data_file) do
    binary = :erlang.term_to_binary({1, []})
    File.write(data_file, binary)
  end
end
