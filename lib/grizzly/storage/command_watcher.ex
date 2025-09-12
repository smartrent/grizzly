defmodule Grizzly.Storage.CommandWatcher do
  @moduledoc false

  # A genserver that listens for certain commands (unsolicited or as responses)
  # and updates storage.

  use GenServer

  alias Grizzly.{Report, Storage}
  alias Grizzly.ZWave.Command

  require Logger

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(:ok) do
    Grizzly.subscribe([
      :version_command_class_report,
      :wake_up_interval_report,
      :wake_up_notification
    ])

    {:ok, %{}}
  end

  @impl GenServer
  def handle_info({:grizzly, :report, %Report{node_id: node_id, command: command}}, state) do
    Logger.info("CommandWatcher received command #{inspect(command)} for node #{node_id}")
    handle_command(node_id, command)
    {:noreply, state}
  end

  defp handle_command(node_id, %Command{name: :wake_up_interval_report} = cmd) do
    interval = Command.param!(cmd, :seconds)
    Storage.put_node_wakeup_interval(node_id, interval)
  end

  defp handle_command(node_id, %Command{name: :wake_up_notification}) do
    Storage.put_node_last_awake(node_id, DateTime.utc_now())
  end

  defp handle_command(node_id, %Command{name: :version_command_class_report} = cmd) do
    command_class = Command.param!(cmd, :command_class)
    version = Command.param!(cmd, :version)
    Storage.put_node_command_class_version(node_id, command_class, version)
  end
end
