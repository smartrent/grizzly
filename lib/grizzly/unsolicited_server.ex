defmodule Grizzly.UnsolicitedServer do
  @moduledoc false
  use GenServer

  require Logger

  alias Grizzly.{Options, Report, SeqNumber, Transport, ZWave}
  alias Grizzly.ZWave.Commands.ZIPPacket
  alias Grizzly.UnsolicitedServer.{Messages, ResponseHandler, SocketSupervisor}

  defmodule State do
    @moduledoc false
    defstruct transport: nil
  end

  @doc """
  Start the unsolicited server
  """
  @spec start_link(Options.t()) :: GenServer.on_start()
  def start_link(grizzly_opts) do
    GenServer.start_link(__MODULE__, grizzly_opts, name: __MODULE__)
  end

  @impl GenServer
  def init(%Options{} = grizzly_opts) do
    {ip, port} = grizzly_opts.unsolicited_destination

    transport =
      Transport.new(grizzly_opts.transport, %{
        ip_address: ip,
        port: port
      })

    {:ok, %State{transport: transport}, {:continue, :listen}}
  end

  @impl GenServer
  def handle_continue(:listen, state) do
    %State{transport: transport} = state

    case listen(transport) do
      {:ok, listening_transport, listen_opts} ->
        maybe_start_accept_sockets(listening_transport, listen_opts)
        {:noreply, %State{state | transport: listening_transport}}

      _error ->
        # wait 2 seconds to try again
        Logger.warning("[Grizzly]: Unsolicited server unable to listen")
        :timer.sleep(2000)
        {:noreply, state, {:continue, :listen}}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    %State{transport: transport} = state

    case Transport.parse_response(transport, message) do
      {:ok, transport_response} ->
        case ResponseHandler.handle_response(transport_response) do
          [] ->
            :ok

          actions ->
            Enum.each(actions, &run_response_action(transport, transport_response, &1))
        end

        {:noreply, state}
    end
  end

  defp run_response_action(transport, response, {:send, command}) do
    %Transport.Response{ip_address: ip_address, port: port} = response
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary, to: {ip_address, port})
  end

  defp run_response_action(_transport, response, {:notify, command}) do
    :ok = Messages.broadcast(response.ip_address, command)
  end

  defp run_response_action(transport, response, {:forward_to_controller, command}) do
    case Grizzly.send_command(1, command.name, command.params) do
      {:ok, report} ->
        handle_grizzly_report(report, transport, response)

      error ->
        error
    end
  end

  defp handle_grizzly_report(%Report{type: :ack_response}, transport, response) do
    %Transport.Response{ip_address: ip_address, port: port} = response
    zip_packet = ZIPPacket.make_ack_response(SeqNumber.get_and_inc())

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary, to: {ip_address, port})
  end

  defp handle_grizzly_report(%Report{type: :command, command: command}, transport, response) do
    %Transport.Response{ip_address: ip_address, port: port} = response
    {:ok, zip_packet} = ZIPPacket.with_zwave_command(command, SeqNumber.get_and_inc(), flag: nil)

    binary = ZWave.to_binary(zip_packet)

    Transport.send(transport, binary, to: {ip_address, port})
  end

  def listen(transport) do
    Transport.listen(transport)
  rescue
    error -> error
  end

  def maybe_start_accept_sockets(listening_transport, listen_opts) do
    case Keyword.get(listen_opts, :strategy) do
      :accept ->
        Enum.each(1..10, fn _ ->
          SocketSupervisor.start_socket(listening_transport)
        end)

      :none ->
        :ok
    end
  end
end
