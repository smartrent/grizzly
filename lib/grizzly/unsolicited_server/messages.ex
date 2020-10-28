defmodule Grizzly.UnsolicitedServer.Messages do
  @moduledoc false

  require Logger

  alias Grizzly.{Report, ZIPGateway}
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

  @spec broadcast(:inet.ip_address(), Command.t()) :: :ok
  def broadcast(node_ip_address, zip_packet_or_command) do
    node_id = ZIPGateway.node_id_from_ip(node_ip_address)

    Logger.debug(
      "[GRIZZLY] Unsolicited Message for node #{inspect(node_id)}: #{
        inspect(zip_packet_or_command)
      }"
    )

    command =
      case zip_packet_or_command.name do
        :zip_packet ->
          Command.param!(zip_packet_or_command, :command)

        _name ->
          zip_packet_or_command
      end

    report = Report.new(:complete, :unsolicited, node_id, command: command)

    Registry.dispatch(@registry, command.name, fn listeners ->
      for {pid, _} <- listeners,
          do: send(pid, {:grizzly, :report, report})
    end)
  end
end
