defmodule Grizzly.UnsolicitedServer.Socket do
  @moduledoc false

  use GenServer

  require Logger

  alias Grizzly.{Report, SeqNumber, Transport, ZIPGateway, ZWave}
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
         {:ok, _sock} <- Transport.handshake(accept_transport) do
      # Start a new listen socket to replace this one as this one is now not
      # open for more traffic now
      {:ok, _} = SocketSupervisor.start_socket(listening_transport)
    else
      other ->
        Logger.warn(
          "grizzly: Failed to start socket. Got this on SSL handshake: #{inspect(other)}"
        )
    end

    {:noreply, listening_transport}
  end

  @impl GenServer
  def handle_info({:ssl_closed, _} = message, transport) do
    Logger.error("[CLOSED]: #{inspect(message)}")
    {:stop, :normal, transport}
  end

  def handle_info({:grizzly, :binary_response, _does_not_matter}, transport) do
    {:noreply, transport}
  end

  def handle_info(response, transport) do
    {:ok, transport_response} = Transport.parse_response(transport, response)

    case ResponseHandler.handle_response(transport_response) do
      [] ->
        :ok

      actions ->
        Enum.each(actions, &run_response_action(transport_response, &1))
    end

    {:noreply, transport}
  end

  defp run_response_action(response, {:send, command}) do
    %Transport.Response{ip_address: ip_address, command: zippacket} = response
    # We have to perverse the header extensions to ensure command encapsulation
    # is correct when sending the response back to the Z-Wave PAN.
    header_extensions = Command.param!(zippacket, :header_extensions)
    node_id = ZIPGateway.node_id_from_ip(ip_address)

    _ = send_ack_response(node_id, zippacket)

    {:ok, zip_packet} =
      ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(),
        flag: :ack_request,
        header_extensions: header_extensions
      )

    binary = ZWave.to_binary(zip_packet)

    Grizzly.send_binary(node_id, binary)
  end

  defp run_response_action(response, {:notify, command}) do
    :ok = Messages.broadcast(response.ip_address, command)
  end

  defp run_response_action(response, {:forward_to_controller, command}) do
    case Grizzly.send_command(:gateway, command.name, command.params) do
      {:ok, report} ->
        handle_grizzly_report(report, response)

      error ->
        error
    end
  end

  defp handle_grizzly_report(%Report{type: :ack_response}, response) do
    %Transport.Response{ip_address: ip_address} = response
    zip_packet = ZIPPacket.make_ack_response(SeqNumber.get_and_inc())

    binary = ZWave.to_binary(zip_packet)
    node_id = ZIPGateway.node_id_from_ip(ip_address)

    Grizzly.send_binary(node_id, binary)
  end

  defp handle_grizzly_report(%Report{type: :command, command: command}, response) do
    %Transport.Response{ip_address: ip_address} = response
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)
    node_id = ZIPGateway.node_id_from_ip(ip_address)

    Grizzly.send_binary(node_id, binary)
  end

  defp send_ack_response(node_id, zippacket) do
    header_extensions = Command.param!(zippacket, :header_extensions)
    seq = Command.param!(zippacket, :seq_number)

    ack_bin =
      seq
      |> ZIPPacket.make_ack_response(header_extensions: header_extensions)
      |> ZWave.to_binary()

    Grizzly.send_binary(node_id, ack_bin)
  end
end
