defmodule Grizzly.ZIPGateway.ReadyChecker do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  @ready_timeout :timer.seconds(60)

  # Waits for Z/IP Gateway to signal its readiness by waiting for a node list
  # report. If 60 seconds pass and we haven't received the node list report,
  # we'll try to solicit one by sending a Node List Get. If that succeeds,
  # we'll signal that we're ready.

  @doc """
  Returns true if Z/IP Gateway has reported that it is ready.
  """
  @spec ready?(GenServer.server()) :: boolean()
  def ready?(server \\ __MODULE__) do
    GenServer.call(server, :ready?)
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(_opts) do
    Grizzly.subscribe(:node_list_report)

    state = %{
      started_at: System.monotonic_time(),
      ready?: false
    }

    Process.send_after(self(), :check_ready, @ready_timeout)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:ready?, _from, state) do
    {:reply, state.ready?, state}
  end

  @impl GenServer
  def handle_info({:grizzly, :report, _report}, %{ready?: true} = state) do
    {:noreply, state}
  end

  def handle_info({:grizzly, :report, %Grizzly.Report{command: command}} = report, state) do
    Logger.info("[Grizzly.ZIPGateway.ReadyChecker] received report #{inspect(report)}")

    if command.name == :node_list_report do
      {:noreply, ready(state)}
    else
      {:noreply, state}
    end
  end

  def handle_info(:check_ready, %{ready?: true} = state), do: {:noreply, state}

  def handle_info(:check_ready, state) do
    case Grizzly.Network.get_all_node_ids() do
      {:ok, [_node_1 | _tail]} ->
        # If we got here, then we somehow missed the node list report, so that's awkward.
        Logger.warning(
          "[Grizzly.ZIPGateway.ReadyChecker] Timed out waiting for node list but Z/IP Gateway looks ready anyway."
        )

        {:noreply, ready(state)}

      {:error, reason} ->
        Logger.error(
          "[Grizzly.ZIPGateway.ReadyChecker] Timed out waiting for node list and test command failed: #{inspect(reason)}"
        )

        Process.send_after(self(), :check_ready, @ready_timeout)
        {:noreply, state}
    end
  end

  defp ready(state) do
    Grizzly.Events.broadcast_event(:ready, true)

    %{state | ready?: true}
  end
end
