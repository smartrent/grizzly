defmodule Grizzly.Backends.Zwrap.Connection do
  @moduledoc false
  use GenServer, restart: :transient

  alias Grizzly.Backends.Zwrap, as: Backend
  alias Grizzly.Backends.Zwrap.Mailbox
  alias Grizzly.Backends.Zwrap.Statistics
  alias Grizzly.Connections
  alias Grizzly.Report
  alias Grizzly.Requests.Request

  def child_spec(node_id, opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [node_id, opts]}, restart: :transient}
  end

  def start_link(options, node_id, opts) do
    mode = Keyword.get(opts, :mode, :sync)
    key = if mode == :async, do: {:async, node_id}, else: node_id
    name = if opts[:unnamed], do: [], else: [name: Connections.via_name(key)]
    GenServer.start_link(__MODULE__, {options, node_id, opts, mode}, name)
  end

  @impl GenServer
  def init({_options, node_id, opts, mode}) do
    backend = Process.whereis(Backend)

    if backend do
      owner = opts[:owner]
      owner_monitor = if mode == :async, do: Process.monitor(owner)

      if mode == :async and opts[:session_commands] do
        :ok =
          Backend.register_session(
            node_id,
            Keyword.get(opts, :destination, 0),
            opts[:session_commands]
          )
      end

      lease =
        if mode == :async do
          {:ok, lease} = Mailbox.hold(node_id, 3_600_000)
          lease
        end

      {:ok,
       %{
         awake_lease: lease,
         node_id: node_id,
         mode: mode,
         owner: owner,
         owner_monitor: owner_monitor,
         backend_monitor: Process.monitor(backend),
         requests: %{}
       }}
    else
      {:stop, :backend_down}
    end
  end

  @impl GenServer
  def handle_call({:send_command, command, _node_id, opts}, from, state) do
    submit(command, opts, from, state)
  end

  def handle_call({:send_command, command, opts}, from, state) do
    submit(command, opts, from, state)
  end

  def handle_call({:request_alive?, ref}, _from, state) do
    {:reply, Map.has_key?(state.requests, ref), state}
  end

  def handle_call({:stop_command, ref}, _from, state) do
    {:reply, :ok, drop(state, ref)}
  end

  defp submit(command, opts, from, state) do
    ref = Keyword.get_lazy(opts, :reference, &make_ref/0)
    waiter = if state.mode == :async, do: elem(from, 0), else: from
    opts = Keyword.merge(opts, reference: ref, waiter: waiter)
    request = Request.from_zwave_command(command, state.node_id, self(), opts)
    entry = %{request: request, waiter: waiter, opts: opts, attempt: make_ref()}

    case transmit(state, entry) do
      :ok ->
        timer = Process.send_after(self(), {:timeout, ref}, Keyword.get(opts, :timeout, 15_000))
        entry = put_in(entry.request.timeout_ref, timer)
        state = put_in(state.requests[ref], entry)
        if state.mode == :async, do: {:reply, {:ok, ref}, state}, else: {:noreply, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_info({:backend_ack, ref, attempt, tx_report}, state) do
    update_request(state, ref, attempt, fn entry ->
      stats =
        if entry.opts[:transmission_stats] && tx_report,
          do: Statistics.transmission_stats(tx_report),
          else: []

      Request.handle_ack(entry.request, stats)
    end)
  end

  def handle_info({:backend_failure, ref, attempt, reason}, state) do
    update_request(state, ref, attempt, &Request.handle_failure(&1.request, reason))
  end

  def handle_info({:backend_report, ref, command}, state) do
    case state.requests[ref] do
      nil -> {:noreply, state}
      entry -> apply_result(state, ref, Request.handle_command(entry.request, command))
    end
  end

  # Try candidates in submission order. This avoids delivering one incoming frame
  # to multiple concurrent requests/connections, without inventing Z/IP sequences.
  def handle_info({:backend_command, ref, node_id, command, rest, endpoint}, state) do
    case state.requests[ref] do
      nil ->
        Backend.route_command(node_id, command, rest, endpoint)
        {:noreply, state}

      entry ->
        result = Request.handle_command(entry.request, command)

        case result do
          {:continue, request} when request.handler_state == entry.request.handler_state ->
            Backend.route_command(node_id, command, rest, endpoint)

          _ ->
            :ok
        end

        apply_result(state, ref, result)
    end
  end

  def handle_info({:backend_session, command}, state) do
    send(
      state.owner,
      {:grizzly, :report, Report.new(:complete, :command, state.node_id, command: command)}
    )

    {:noreply, state}
  end

  def handle_info({:backend_intermediate, command}, state) do
    report = Report.new(:complete, :command, state.node_id, command: command)
    send(state.owner, {:grizzly, :report, report})
    Grizzly.Events.broadcast_report(report)
    {:noreply, state}
  end

  def handle_info({:backend_rejected, ref, reason}, state) do
    if entry = state.requests[ref], do: deliver(entry.waiter, {:error, reason})
    {:noreply, drop(state, ref)}
  end

  def handle_info({:backend_cancel, ref}, state), do: {:noreply, drop(state, ref)}

  def handle_info({:timeout, ref}, state) do
    case state.requests[ref] do
      nil ->
        {:noreply, state}

      entry ->
        report =
          Report.new(:complete, :timeout, state.node_id,
            command_ref: ref,
            acknowledged: entry.request.acknowledged
          )

        deliver(entry.waiter, {:ok, report})
        {:noreply, drop(state, ref)}
    end
  end

  def handle_info({:DOWN, monitor, :process, _pid, _reason}, state) do
    if monitor in [state.backend_monitor, state.owner_monitor] do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def terminate(_reason, state) do
    if state.awake_lease, do: Mailbox.release(state.awake_lease)

    for {ref, entry} <- state.requests do
      deliver(entry.waiter, {:error, :backend_down})
      Process.cancel_timer(entry.request.timeout_ref)
      Backend.release(self(), ref)
      Mailbox.cancel(self(), ref)
    end
  end

  defp update_request(state, ref, attempt, fun) do
    case state.requests[ref] do
      %{attempt: ^attempt} = entry -> apply_result(state, ref, fun.(entry))
      _ -> {:noreply, state}
    end
  end

  defp apply_result(state, ref, {:continue, request}) do
    {:noreply, put_in(state.requests[ref].request, request)}
  end

  defp apply_result(state, ref, {:retry, request}) do
    entry = %{state.requests[ref] | request: request, attempt: make_ref()}

    case transmit(state, entry) do
      :ok ->
        {:noreply, put_in(state.requests[ref], entry)}

      {:error, reason} ->
        deliver(entry.waiter, {:error, reason})
        {:noreply, drop(state, ref)}
    end
  end

  defp apply_result(state, ref, {%Report{} = report, _request}) do
    deliver(state.requests[ref].waiter, {:ok, report})
    Grizzly.Events.broadcast_report(report)
    {:noreply, drop(state, ref)}
  end

  defp transmit(state, entry) do
    Mailbox.submit(
      state.node_id,
      entry.request.source,
      entry.request.ref,
      entry.attempt,
      entry.opts
    )
  end

  defp drop(state, ref) do
    case Map.pop(state.requests, ref) do
      {nil, _} ->
        state

      {entry, requests} ->
        Process.cancel_timer(entry.request.timeout_ref)
        Backend.release(self(), ref)
        Mailbox.cancel(self(), ref)
        %{state | requests: requests}
    end
  end

  defp deliver(pid, {:ok, report}) when is_pid(pid), do: send(pid, {:grizzly, :report, report})
  defp deliver(pid, {:error, reason}) when is_pid(pid), do: send(pid, {:grizzly, :error, reason})
  defp deliver(from, result), do: GenServer.reply(from, result)
end
