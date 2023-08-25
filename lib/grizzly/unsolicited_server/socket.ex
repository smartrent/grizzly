defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.{Report, SeqNumber, Transport, ZWave}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket
  alias Grizzly.UnsolicitedServer.{Messages, ResponseHandler, SocketSupervisor}

  @spec child_spec(Transport.t()) :: map()
  def child_spec(transport) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [transport]},
      restart: :temporary
    }
  end

  @spec start_link(Transport.t()) :: GenServer.on_start()
  def start_link(listening_transport) do
    GenServer.start_link(__MODULE__, listening_transport)
  end

  @impl GenServer
  def init(transport) do
    {:ok, transport, {:continue, :accept}}
  end

  @impl GenServer
  def handle_continue(:accept, listening_transport) do
    with {:ok, accept_transport} <- Transport.accept(listening_transport),
         {:ok, transport} <- Transport.handshake(accept_transport) do
      # Start a new listen socket to replace this one as this one is now bound
      # to a single node in the Z-Wave PAN.
      {:ok, _} = SocketSupervisor.start_socket(listening_transport)
      {:noreply, transport}
    else
      other ->
        Logger.warning(
          "[Grizzly] UnsolicitedServer socket accept/handshake failed: #{inspect(other)}"
        )

        {:stop, :handshake_error, listening_transport}
    end
  end

  @impl GenServer
  def handle_info({:ssl_closed, sslsocket}, transport) do
    ip = client_ip(sslsocket)
    Logger.debug("[Grizzly] UnsolicitedServer socket closed by client #{ip}")
    {:stop, :normal, transport}
  end

  def handle_info({:grizzly, :binary_response, _does_not_matter}, transport) do
    {:noreply, transport}
  end

  def handle_info(response, transport) do
    {:ok, transport_response} = Transport.parse_response(transport, response)

    actions = [:ack | ResponseHandler.handle_response(transport_response)]
    Enum.each(actions, &run_response_action(transport_response, &1, transport))

    {:noreply, transport}
  end

  defp run_response_action(response, :ack, transport) do
    %Transport.Response{command: zippacket} = response

    _ = send_ack_response(zippacket, transport)
  end

  defp run_response_action(response, {:send, command}, transport) do
    %Transport.Response{command: zippacket} = response
    # We have to preserve the header extensions to ensure command encapsulation
    # is correct when sending the response back to the Z-Wave PAN.
    header_extensions = Command.param!(zippacket, :header_extensions)

    {:ok, zip_packet} =
      ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(),
        flag: :ack_request,
        header_extensions: header_extensions
      )

    binary = ZWave.to_binary(zip_packet)
    Transport.send(transport, binary)
  end

  defp run_response_action(_response, {:send_raw, command}, transport) do
    binary = ZWave.to_binary(command)
    Transport.send(transport, binary)
  end

  defp run_response_action(response, {:notify, command}, _transport) do
    :ok = Messages.broadcast(response.ip_address, command)
  end

  defp run_response_action(_response, {:forward_to_controller, command}, transport) do
    case Grizzly.send_command(:gateway, command.name, command.params) do
      {:ok, report} ->
        handle_grizzly_report(report, transport)

      error ->
        error
    end
  end

  defp handle_grizzly_report(%Report{type: :ack_response}, transport) do
    zip_packet = ZIPPacket.make_ack_response(SeqNumber.get_and_inc())

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary)
  end

  defp handle_grizzly_report(%Report{type: :command, command: command}, transport) do
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary)
  end

  defp send_ack_response(zippacket, transport) do
    header_extensions = Command.param!(zippacket, :header_extensions)
    seq = Command.param!(zippacket, :seq_number)
    more_info = more_info?(zippacket)

    if more_info do
      Logger.debug("[Grizzly] Adding More Information flag to ACK response")
    end

    ack_bin =
      seq
      |> ZIPPacket.make_ack_response(
        header_extensions: header_extensions,
        more_info: more_info
      )
      |> ZWave.to_binary()

    Transport.send(transport, ack_bin)
  end

  defp more_info?(zip_packet) do
    encapsulated_command = Command.param(zip_packet, :command)

    if encapsulated_command && encapsulated_command.name == :supervision_get do
      true
    else
      false
    end
  end

  defp client_ip(sslsocket) do
    with {:ok, {ip, _port}} <- :ssl.peername(sslsocket),
         ip_str when is_list(ip_str) <- :inet.ntoa(ip) do
      to_string(ip_str)
    else
      _ ->
        "unknown"
    end
  end
end
