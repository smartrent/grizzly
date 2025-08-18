defmodule Grizzly.ZIPGateway.ReadyChecker do
  @moduledoc false

  @ready_timeout :timer.seconds(60)

  # Waits for Z/IP Gateway to signal its readiness by waiting for a node list
  # report. If 60 seconds pass and we haven't received the node list report,
  # we'll try to solicit one by sending a Node List Get. If that succeeds,
  # we'll signal that we're ready.

  use GenServer, restart: :transient

  require Logger

  @type init_arg() :: {:status_reporter, module()}

  @doc """
  Returns true if Z/IP Gateway has reported that it is ready.
  """
  @spec ready?(GenServer.server()) :: boolean()
  def ready?(server \\ __MODULE__) do
    GenServer.call(server, :ready?)
  end

  @spec start_link([init_arg()]) :: GenServer.on_start()
  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl GenServer
  def init(args) do
    Grizzly.subscribe_command(:node_list_report)

    state = %{
      reporter: args[:status_reporter],
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
    _ =
      Task.Supervisor.start_child(Grizzly.TaskSupervisor, fn ->
        cond do
          is_function(state.reporter, 0) ->
            state.reporter.()

          function_exported?(state.reporter, :ready, 0) ->
            state.reporter.ready()

          true ->
            :ok
        end
      end)

    Grizzly.Events.broadcast(:ready, true)

    %{state | ready?: true}
  end
end
