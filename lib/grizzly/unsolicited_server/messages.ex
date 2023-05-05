defmodule Grizzly.UnsolicitedServer.Messages do
  @moduledoc false

  require Logger

  alias Grizzly.{Report, VirtualDevices, ZIPGateway}
  alias Grizzly.ZWave.Command

  @registry __MODULE__.Registry

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link() do
    Registry.start_link(keys: :duplicate, name: @registry)
  end

  @spec subscribe(Grizzly.command()) :: :ok
  def subscribe(event) do
    _ = Registry.register(@registry, event, [])
    :ok
  end

  @spec unsubscribe(Grizzly.command()) :: :ok
  def unsubscribe(command_name) do
    Registry.unregister(@registry, command_name)
  end

  @spec subscribe_node(Grizzly.node_id() | VirtualDevices.id()) :: :ok
  def subscribe_node(node_id) do
    _ = Registry.register(@registry, node_id, [])
    :ok
  end

  @spec unsubscribe_node(Grizzly.node_id() | VirtualDevices.id()) :: :ok
  def unsubscribe_node(node_id) do
    Registry.unregister(@registry, node_id)
  end

  @spec broadcast(:inet.ip_address() | VirtualDevices.id(), Command.t()) :: :ok
  def broadcast({:virtual, _id} = id, command) do
    do_broadcast(id, command)
  end

  def broadcast(node_ip_address, zip_packet_or_command) do
    node_id = ZIPGateway.node_id_from_ip(node_ip_address)

    command =
      case zip_packet_or_command.name do
        :zip_packet ->
          Command.param!(zip_packet_or_command, :command)

        _name ->
          zip_packet_or_command
      end

    do_broadcast(node_id, command)
  end

  def do_broadcast(node_id, command) do
    Logger.debug(
      "[GRIZZLY] Unsolicited Message for node #{inspect(node_id)}: #{inspect(command)}"
    )

    report = Report.new(:complete, :unsolicited, node_id, command: command)

    Registry.dispatch(@registry, command.name, fn listeners ->
      for {pid, _} <- listeners,
          do: send(pid, {:grizzly, :report, report})
    end)

    Registry.dispatch(@registry, node_id, fn listeners ->
      for {pid, _} <- listeners,
          do: send(pid, {:grizzly, :report, report})
    end)
  end
end
