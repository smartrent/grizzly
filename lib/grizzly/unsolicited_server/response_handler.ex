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

  @doc """
  When a transport receives a response from the Z-Wave network handle it
  and send any other commands back over the Z-Wave PAN if needed
  """
  @spec handle_response(Transport.t(), Transport.Response.t()) :: :ok
  def handle_response(transport, response) do
    case Command.param!(response.command, :flag) do
      :ack_request ->
        seq_number = Command.param!(response.command, :seq_number)
        command = ZIPPacket.make_ack_response(seq_number)
        binary = ZWave.to_binary(command)

        :ok = Transport.send(transport, binary, to: {response.ip_address, response.port})
        :ok = maybe_handle_extra_command(transport, response)

      _ ->
        :ok = Messages.broadcast(response.ip_address, response.command)
    end
  end

  defp maybe_handle_extra_command(transport, response) do
    internal_command = Command.param!(response.command, :command)

    case handle_command(internal_command) do
      {:ok, zip_packet} ->
        binary = ZWave.to_binary(zip_packet)
        Transport.send(transport, binary, to: {response.ip_address, response.port})

      _ ->
        :ok
    end
  end

  defp handle_command(%Command{name: :association_get} = command) do
    grouping_identifier = Command.param!(command, :grouping_identifier)
    seq_number = SeqNumber.get_and_inc()

    {:ok, association_report} =
      AssociationReport.new(
        grouping_identifier: grouping_identifier,
        max_nodes_supported: 1,
        nodes: []
      )

    ZIPPacket.with_zwave_command(association_report, seq_number, flag: nil)
  end

  defp handle_command(%Command{name: :association_groupings_get}) do
    seq_number = SeqNumber.get_and_inc()

    {:ok, groupings_report} = AssociationGroupingsReport.new(supported_groupings: 1)

    ZIPPacket.with_zwave_command(groupings_report, seq_number, flag: nil)
  end

  defp handle_command(_command), do: :ok
end
