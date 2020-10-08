defmodule Grizzly.UnsolicitedServer.ResponseHandler do
  @moduledoc false

  # module helper for handling various different responses from the Z-Wave PAN
  # network

  alias Grizzly.SeqNumber
  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.ZWave
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.{AssociationReport, AssociationGroupingsReport, ZIPPacket}

  @type opt() :: {:data_file, Path.t()}

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Transport.t(), Transport.Response.t(), [opt()]) :: :ok
  def handle_response(transport, response, opts \\ []) do
    case Command.param!(response.command, :flag) do
      :ack_request ->
        seq_number = Command.param!(response.command, :seq_number)
        command = ZIPPacket.make_ack_response(seq_number)
        binary = ZWave.to_binary(command)

        :ok = Transport.send(transport, binary, to: {response.ip_address, response.port})
        :ok = maybe_handle_extra_command(transport, response, opts)

      _ ->
        :ok = Messages.broadcast(response.ip_address, response.command)
    end
  end

  defp maybe_handle_extra_command(transport, response, opts) do
    internal_command = Command.param!(response.command, :command)

    case handle_command(internal_command, opts) do
      {:ok, zip_packet} ->
        binary = ZWave.to_binary(zip_packet)
        Transport.send(transport, binary, to: {response.ip_address, response.port})

      _ ->
        :ok
    end
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

  defp handle_command(_command, _), do: :ok

  defp get_grouping_identifier_and_nodes(data_file) do
    case File.read(data_file) do
      {:error, :enoent} ->
        {1, []}

      {:ok, binary} ->
        :erlang.binary_to_term(binary)
    end
  end
end
