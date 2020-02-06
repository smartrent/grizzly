defmodule Grizzly.Connection.Socket do
  @moduledoc false

  use GenServer

  alias Grizzly.{ConnectionRegistry, ZWaveCommand}
  alias Grizzly.Commands.ZIPPacket

  @type opt :: {:transport, module()} | {:host, :inet.ip_address()} | {:port, :inet.port_number()}

  defmodule State do
    defstruct transport: nil, host: nil, port: nil, socket: nil, commands: []
  end

  def start_link(node_id, opts) do
    name = ConnectionRegistry.via_name(node_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def open(connection) do
    name = ConnectionRegistry.via_name(connection)
    GenServer.call(name, :open)
  end

  def send(socket, command) do
    name = ConnectionRegistry.via_name(socket)
    GenServer.call(name, {:send, command})
  end

  def close(socket) do
    name = ConnectionRegistry.via_name(socket)
    GenServer.stop(name)
  end

  def init(opts) do
    transport = Keyword.fetch!(opts, :transport)
    host = Keyword.fetch!(opts, :host)
    port = Keyword.fetch!(opts, :port)
    {:ok, %State{transport: transport, host: host, port: port}}
  end

  def handle_call(:open, _from, state) do
    %State{transport: transport, host: host, port: port} = state

    case transport.open(host, port) do
      {:ok, socket} ->
        {:reply, :ok, %{state | socket: socket}}
    end
  end

  def handle_call({:send, command}, from, state) do
    %State{transport: transport, socket: socket} = state
    packet = ZIPPacket.with_zwave_command(command)
    {:ok, binary} = ZIPPacket.to_binary(packet)

    case transport.send(socket, binary) do
      :ok ->
        {:noreply, %{state | commands: {from, packet}}}
    end
  end

  def handle_info(data, state) do
    %State{transport: transport, commands: {from, _binary}} = state

    case transport.parse_response(data) do
      {:ok, rbinary} ->
        GenServer.reply(from, {:ok, rbinary})

        {:noreply, %{state | commands: []}}
    end
  end

  def terminate(:normal, state) do
    %State{transport: transport, socket: socket} = state
    :ok = transport.close(socket)

    :ok
  end
end
