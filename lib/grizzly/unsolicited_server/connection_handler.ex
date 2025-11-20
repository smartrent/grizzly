defmodule Grizzly.UnsolicitedServer.ConnectionHandler do
  @moduledoc false

  use ThousandIsland.Handler

  alias Grizzly.Report
  alias Grizzly.SeqNumber
  alias Grizzly.UnsolicitedServer.ResponseHandler
  alias Grizzly.ZIPGateway
  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, Commands.ZIPPacket}
  alias ThousandIsland.Socket

  require Logger

  @impl ThousandIsland.Handler
  def handle_connection(socket, _state) do
    case Socket.peername(socket) do
      {:ok, {ip, _port}} ->
        node_id = ZIPGateway.node_id_from_ip(ip)
        Logger.metadata(node_id: node_id)
        Logger.debug("[Grizzly.UnsolicitedServer] New connection from node #{node_id}")
        {:continue, %{node_id: node_id}}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{node_id: node_id} = state) do
    Grizzly.Trace.log(node_id, :grizzly, data)

    case Grizzly.ZWave.from_binary(data) do
      {:ok, zip_packet} ->
        actions = ResponseHandler.handle_response(node_id, zip_packet)
        Enum.each(actions, &run_response_action(&1, socket, zip_packet, state))

        {:continue, state}

      {:error, reason} ->
        Logger.error("""
        [Grizzly.UnsolicitedServer] Error parsing Z-Wave packet: #{inspect(reason)}

            binary: #{inspect(data, pretty: true, base: :hex, limit: 1024)}
        """)

        {:continue, state}
    end
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, state) do
    Logger.debug("[Grizzly.UnsolicitedServer] Socket closed for node #{state.node_id}")
  end

  defp run_response_action(:ack, socket, zip_packet, state) do
    header_extensions = Command.param!(zip_packet, :header_extensions)
    seq = Command.param!(zip_packet, :seq_number)

    ack_bin =
      seq
      |> ZIPPacket.make_ack_response(header_extensions: header_extensions)
      |> ZWave.to_binary()

    send_cmd(socket, ack_bin, state.node_id)
  end

  defp run_response_action({:send, command}, socket, zip_packet, state) do
    # We have to preserve the header extensions to ensure command encapsulation
    # is correct when sending the response back to the Z-Wave PAN.
    header_extensions = Command.param!(zip_packet, :header_extensions)

    {:ok, zip_packet} =
      ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(),
        flag: :ack_request,
        header_extensions: header_extensions
      )

    binary = ZWave.to_binary(zip_packet)
    send_cmd(socket, binary, state.node_id)
  end

  defp run_response_action({:send_raw, command}, socket, _zip_packet, state) do
    binary = ZWave.to_binary(command)
    send_cmd(socket, binary, state.node_id)
  end

  defp run_response_action({:notify, command}, _socket, _zip_packet, state) do
    state.node_id
    |> Report.unsolicited(command)
    |> Grizzly.Events.broadcast_report()
  end

  defp run_response_action({:forward_to_controller, command}, socket, _zip_packet, state) do
    case Grizzly.send_command(:gateway, command.name, command.params) do
      {:ok, report} ->
        handle_grizzly_report(report, socket, state)

      error ->
        error
    end
  end

  defp handle_grizzly_report(%Report{type: :ack_response}, socket, state) do
    zip_packet = ZIPPacket.make_ack_response(SeqNumber.get_and_inc())

    binary = ZWave.to_binary(zip_packet)

    send_cmd(socket, binary, state.node_id)
  end

  defp handle_grizzly_report(%Report{type: :command, command: command}, socket, state) do
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)

    send_cmd(socket, binary, state.node_id)
  end

  defp send_cmd(socket, binary, node_id) do
    Grizzly.Trace.log(:grizzly, node_id, binary)
    Socket.send(socket, binary)
  end
end
