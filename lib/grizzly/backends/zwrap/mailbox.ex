defmodule Grizzly.Backends.Zwrap.Mailbox do
  @moduledoc """
  Bounded Elixir sleeping-node queues and awake leases. One in-flight logical
  request per node/command class avoids ambiguous report matching. Native code owns no queue
  or keep-awake policy. Queues are volatile and callers retain their deadlines.
  """
  use GenServer

  alias Grizzly.Backends.Zwrap, as: Backend
  alias Grizzly.Backends.Zwrap.Directory
  alias Grizzly.Backends.Zwrap.Management

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  def submit(node, command, ref, attempt, opts) do
    if Management.local?(command),
      do: Backend.submit(node, command, ref, attempt, opts),
      else: submit(__MODULE__, self(), node, command, ref, attempt, opts)
  end

  def submit(server, owner, node, command, ref, attempt, opts),
    do: GenServer.call(server, {:submit, owner, node, command, ref, attempt, opts}, 30_000)

  def cancel(owner, ref), do: GenServer.cast(__MODULE__, {:cancel, {owner, ref}})
  def wake(node), do: GenServer.cast(__MODULE__, {:wake, node})

  def set_mode(node, mode) when mode in [:sleeping, :listening, :unknown],
    do: GenServer.call(__MODULE__, {:mode, node, mode})

  def set_mode(_, _), do: {:error, :invalid_mode}
  def stats(server \\ __MODULE__), do: GenServer.call(server, :stats)

  @doc "Hold a sleeping node awake while an application session owns work."
  def hold(node, ttl \\ 120_000)

  def hold(node, ttl) when is_integer(ttl) and ttl in 1..3_600_000,
    do: GenServer.call(__MODULE__, {:hold, node, self(), ttl})

  def hold(_, _), do: {:error, :invalid_lease}
  def release(lease), do: GenServer.cast(__MODULE__, {:release, lease})

  @impl GenServer
  def init(opts) do
    {:ok,
     %{
       entries: %{},
       order: [],
       modes: %{},
       awake: MapSet.new(),
       leases: %{},
       idle_timers: %{},
       per_node: Keyword.get(opts, :per_node, 128),
       capacity: Keyword.get(opts, :capacity, 1024),
       grace: Keyword.get(opts, :grace, 500),
       transmit: Keyword.get(opts, :transmit, &Backend.submit_for/6),
       finish_wake: Keyword.get(opts, :finish_wake, &Backend.finish_wake/1),
       classify: Keyword.get(opts, :classify, &classify/1),
       counters: %{queued: 0, submitted: 0, expired: 0, cancelled: 0}
     }}
  end

  @impl GenServer
  def handle_call({:submit, owner, node, command, ref, attempt, opts}, _from, state) do
    key = {owner, ref}
    existing = state.entries[key]
    count = Enum.count(state.entries, fn {_, e} -> e.node == node end)

    cond do
      existing ->
        entry = %{existing | attempt: attempt, command: command, opts: opts}

        case transmit(state, entry) do
          :ok -> {:reply, :ok, put_in(state.entries[key], entry)}
          error -> {:reply, error, state}
        end

      map_size(state.entries) >= state.capacity or count >= state.per_node ->
        {:reply, {:error, :mailbox_full}, state}

      true ->
        state = ensure_mode(state, node)
        timer = Process.send_after(self(), {:expire, key}, Keyword.get(opts, :timeout, 15_000))

        entry = %{
          owner: owner,
          monitor: Process.monitor(owner),
          node: node,
          command: command,
          ref: ref,
          attempt: attempt,
          opts: opts,
          timer: timer,
          status: :queued
        }

        state = put_in(state.entries[key], entry)
        state = %{state | order: state.order ++ [key]}
        state = bump(state, :queued)
        awake? = state.modes[node] != :sleeping or MapSet.member?(state.awake, node)

        active? =
          Enum.any?(state.entries, fn {_, e} ->
            e.node == node and e.status == :active and
              e.command.command_class == command.command_class
          end)

        if awake? and not active? do
          case transmit(state, entry) do
            :ok ->
              {:reply, :ok,
               state |> put_in([:entries, key, :status], :active) |> bump(:submitted)}

            error ->
              {:reply, error, drop(state, key)}
          end
        else
          {:reply, :ok, state}
        end
    end
  end

  def handle_call({:mode, node, mode}, _from, state)
      when mode in [:sleeping, :listening, :unknown],
      do: {:reply, :ok, drain(put_in(state.modes[node], mode))}

  def handle_call(:stats, _from, state),
    do: {:reply, Map.put(state.counters, :pending, map_size(state.entries)), state}

  def handle_call({:hold, node, owner, ttl}, _from, state) when ttl in 1..3_600_000 do
    if map_size(state.leases) >= state.capacity do
      {:reply, {:error, :mailbox_full}, state}
    else
      hold_lease(node, owner, ttl, state)
    end
  end

  defp hold_lease(node, owner, ttl, state) do
    ref = make_ref()

    lease = %{
      node: node,
      owner: owner,
      monitor: Process.monitor(owner),
      timer: Process.send_after(self(), {:lease_expired, ref}, ttl)
    }

    {:reply, {:ok, ref}, put_in(state.leases[ref], lease)}
  end

  @impl GenServer
  def handle_cast({:cancel, key}, state),
    do: {:noreply, state |> drop(key) |> bump(:cancelled) |> drain()}

  def handle_cast({:release, ref}, state),
    do: {:noreply, state |> drop_lease(ref) |> schedule_idle()}

  def handle_cast({:wake, node}, state) do
    {:noreply, %{state | awake: MapSet.put(state.awake, node)} |> drain()}
  end

  @impl GenServer
  def handle_info({:expire, key}, state) do
    if entry = state.entries[key],
      do: send(entry.owner, {:backend_failure, entry.ref, entry.attempt, :mailbox_expired})

    {:noreply, state |> drop(key) |> bump(:expired) |> drain()}
  end

  def handle_info({:lease_expired, ref}, state),
    do: {:noreply, state |> drop_lease(ref) |> schedule_idle()}

  def handle_info({:idle, node, generation}, state) do
    if state.idle_timers[node] == generation and idle?(state, node) do
      state = %{state | idle_timers: Map.delete(state.idle_timers, node)}

      case state.finish_wake.(node) do
        :ok -> {:noreply, %{state | awake: MapSet.delete(state.awake, node)}}
        _ -> {:noreply, schedule_idle(state)}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info({:DOWN, monitor, :process, _pid, _reason}, state) do
    state =
      Enum.reduce(state.entries, state, fn {key, entry}, acc ->
        if entry.monitor == monitor, do: drop(acc, key), else: acc
      end)

    state =
      Enum.reduce(state.leases, state, fn {key, lease}, acc ->
        if lease.monitor == monitor, do: drop_lease(acc, key), else: acc
      end)

    {:noreply, drain(state)}
  end

  defp ensure_mode(state, :gateway), do: put_in(state.modes[:gateway], :listening)

  defp ensure_mode(state, node) do
    if Map.has_key?(state.modes, node),
      do: state,
      else: put_in(state.modes[node], state.classify.(node))
  end

  defp classify(node) do
    case Directory.get_node(node) do
      {:ok, %{mode: flags}} ->
        if flags[:mode] in [:wakeup, :wakeup_firmware_upgrade], do: :sleeping, else: :listening

      _ ->
        :unknown
    end
  catch
    :exit, _ -> :unknown
  end

  defp drain(state) do
    Enum.reduce(state.order, state, fn key, acc ->
      case acc.entries[key] do
        %{status: :queued, node: node} = entry ->
          awake? = acc.modes[node] != :sleeping or MapSet.member?(acc.awake, node)

          active? =
            Enum.any?(acc.entries, fn {_, e} ->
              e.node == node and e.status == :active and
                e.command.command_class == entry.command.command_class
            end)

          if awake? and not active? do
            start_entry(acc, key, entry)
          else
            acc
          end

        _ ->
          acc
      end
    end)
    |> schedule_idle()
  end

  defp start_entry(state, key, entry) do
    case transmit(state, entry) do
      :ok ->
        state |> put_in([:entries, key, :status], :active) |> bump(:submitted)

      {:error, reason} ->
        send(entry.owner, {:backend_rejected, entry.ref, reason})
        drop(state, key)
    end
  end

  defp transmit(state, entry) do
    state.transmit.(entry.owner, entry.node, entry.command, entry.ref, entry.attempt, entry.opts)
  end

  defp drop(state, key) do
    case Map.pop(state.entries, key) do
      {nil, _} ->
        state

      {entry, entries} ->
        Process.cancel_timer(entry.timer)
        Process.demonitor(entry.monitor, [:flush])
        state = %{state | entries: entries, order: List.delete(state.order, key)}

        if entry.opts[:more_info] do
          ref = {:more_info, entry.node, entry.owner}
          state = drop_lease(state, ref)

          lease = %{
            node: entry.node,
            owner: entry.owner,
            monitor: Process.monitor(entry.owner),
            timer: Process.send_after(self(), {:lease_expired, ref}, 1_000)
          }

          put_in(state.leases[ref], lease)
        else
          state
        end
    end
  end

  defp drop_lease(state, ref) do
    case Map.pop(state.leases, ref) do
      {nil, _} ->
        state

      {lease, leases} ->
        Process.cancel_timer(lease.timer)
        Process.demonitor(lease.monitor, [:flush])
        %{state | leases: leases}
    end
  end

  defp idle?(state, node) do
    not Enum.any?(state.entries, fn {_, e} -> e.node == node end) and
      not Enum.any?(state.leases, fn {_, e} -> e.node == node end)
  end

  defp schedule_idle(state) do
    Enum.reduce(state.awake, state, fn node, acc ->
      if idle?(acc, node) and not Map.has_key?(acc.idle_timers, node) do
        generation = make_ref()
        Process.send_after(self(), {:idle, node, generation}, acc.grace)
        put_in(acc.idle_timers[node], generation)
      else
        if idle?(acc, node),
          do: acc,
          else: %{acc | idle_timers: Map.delete(acc.idle_timers, node)}
      end
    end)
  end

  defp bump(state, name), do: update_in(state.counters[name], &(&1 + 1))
end
