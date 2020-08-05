defmodule Grizzly.UnsolicitedServer.Messages do
  @moduledoc false

  require Logger

  alias Grizzly.{Report, ZIPGateway, ZWave}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.ZIPPacket

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

  @spec broadcast(:inet.ip_address(), binary()) :: :ok
  def broadcast(node_ip_address, zip_packet_bin) do
    node_id = ZIPGateway.node_id_from_ip(node_ip_address)

    case ZWave.from_binary(zip_packet_bin) do
      {:ok, zip_packet} ->
        _ =
          Logger.debug(
            "[GRIZZLY] Unsolicited Message for node #{inspect(node_id)}: #{inspect(zip_packet)}"
          )

        Registry.dispatch(@registry, ZIPPacket.command_name(zip_packet), fn listeners ->
          for {pid, _} <- listeners,
              do: send_report(pid, node_id, zip_packet)
        end)
    end
  end

  defp send_report(pid, node_id, zip_packet) do
    report =
      Report.new(:complete, :unsolicited, node_id, command: Command.param!(zip_packet, :command))

    send(pid, {:grizzly, :report, report})
  end
end
