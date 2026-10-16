defmodule Grizzly.Backends.Zwrap.Directory do
  @moduledoc """
  Direct SQLite access, serialized behind an exclusive native maintenance lease.

  Edits never mean RF exclusion. A durable `.host-maintenance` journal prevents
  automatic helper startup after an interrupted or unsynchronized transaction.
  Do not remove that journal until the DB and native lifecycle are reconciled.
  """
  use GenServer

  alias Exqlite.Sqlite3
  alias Grizzly.Directory.Database

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, if(name, do: [name: name], else: []))
  end

  def journal(path), do: path <> ".host-maintenance"

  @doc "Read a coherent network/node/endpoint snapshot, including incomplete rows."
  def snapshot(server \\ __MODULE__) do
    transaction(server, :read, fn db ->
      with {:ok, network} <- Database.select_one(db, "SELECT * FROM network"),
           {:ok, nodes} <- Database.all_nodes(db),
           {:ok, endpoints} <- Database.select_all(db, "SELECT * FROM endpoints") do
        {:ok, %{network: network, nodes: nodes, endpoints: endpoints}}
      end
    end)
  end

  def get_node(node_id, server \\ __MODULE__) do
    transaction(server, :read, &Database.get_node(&1, node_id))
  end

  @doc "Edit persisted node metadata; synchronize the native cache before return."
  def edit_node(node_id, attrs, server \\ __MODULE__) when is_map(attrs) do
    fields = %{
      wake_up_interval: {"wakeUp_interval", 0xFFFFFFFF},
      manufacturer_id: {"manufacturerID", 65535},
      product_type: {"productType", 65535},
      product_id: {"productID", 65535},
      state: {"state", 15},
      probe_flags: {"probe_flags", 3}
    }

    with :ok <- validate_id(node_id), {:ok, changes} <- changes(attrs, fields) do
      transaction(server, :write, fn db ->
        update(db, "nodes", changes, "nodeid = ?", [node_id])
      end)
    end
  end

  @doc "Remove cached records only, without excluding a radio device."
  def remove_cache(node_id, server \\ __MODULE__) do
    with :ok <- validate_id(node_id) do
      transaction(server, :write, fn db ->
        with {:ok, network} <- Database.select_one(db, "SELECT nodeid FROM network"),
             false <- network["nodeid"] == node_id,
             :ok <- Database.execute(db, "DELETE FROM endpoints WHERE nodeid = ?", [node_id]),
             :ok <- Database.execute(db, "DELETE FROM nodes WHERE nodeid = ?", [node_id]) do
          :ok
        else
          true -> {:error, :controller_record_protected}
          error -> error
        end
      end)
    end
  end

  @doc false
  def transaction(server, mode, fun) when mode in [:read, :write] and is_function(fun, 1),
    do: GenServer.call(server, {:transaction, mode, fun}, :infinity)

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    {:ok,
     %{
       path: Keyword.fetch!(opts, :path),
       api: Keyword.get(opts, :api, Zwrap),
       controller: Keyword.fetch!(opts, :controller),
       timeout: Keyword.get(opts, :timeout, 30_000),
       active: nil
     }}
  end

  @impl GenServer
  def handle_call({:transaction, mode, fun}, from, %{active: nil} = state) do
    if File.exists?(journal(state.path)) do
      {:reply, {:error, :recovery_required}, state}
    else
      parent = self()
      ref = make_ref()

      {pid, worker_monitor} =
        :erlang.spawn_opt(
          fn ->
            send(parent, {:transaction_result, ref, run(state, mode, fun)})
          end,
          [:link, :monitor]
        )

      owner_monitor = Process.monitor(elem(from, 0))
      timer = Process.send_after(self(), {:transaction_timeout, ref}, state.timeout)

      active = %{
        ref: ref,
        pid: pid,
        from: from,
        worker_monitor: worker_monitor,
        owner_monitor: owner_monitor,
        timer: timer
      }

      {:noreply, %{state | active: active}}
    end
  end

  def handle_call({:transaction, _, _}, _from, state), do: {:reply, {:error, :busy}, state}

  @impl GenServer
  def handle_info({:transaction_result, ref, result}, %{active: %{ref: ref} = active} = state) do
    GenServer.reply(active.from, result)
    {:noreply, finish(state)}
  end

  def handle_info({:transaction_timeout, ref}, %{active: %{ref: ref} = active} = state) do
    Process.exit(active.pid, :kill)
    GenServer.reply(active.from, {:error, :maintenance_timeout})
    {:noreply, finish(state)}
  end

  def handle_info({:DOWN, monitor, :process, _pid, _reason}, %{active: active} = state)
      when not is_nil(active) do
    if monitor in [active.owner_monitor, active.worker_monitor] do
      Process.exit(active.pid, :kill)
      GenServer.reply(active.from, {:error, :maintenance_owner_down})
      {:noreply, finish(state)}
    else
      {:noreply, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_, %{active: nil}), do: :ok
  def terminate(_, %{active: active}), do: Process.exit(active.pid, :kill)

  defp finish(%{active: active} = state) do
    Process.cancel_timer(active.timer)
    Process.demonitor(active.owner_monitor, [:flush])
    Process.demonitor(active.worker_monitor, [:flush])
    %{state | active: nil}
  end

  defp run(state, mode, fun) do
    path = journal(state.path)

    with {:ok, io} <- File.open(path, [:write, :exclusive, :binary]) do
      try do
        :ok = IO.binwrite(io, "v1 acquiring #{mode}\n")
        :ok = :file.sync(io)

        controller =
          if is_function(state.controller, 0), do: state.controller.(), else: state.controller

        case state.api.maintenance_acquire(controller) do
          {:ok, token} ->
            sql_window(state, controller, token, mode, fun, io)

          {:error, :busy} = error ->
            File.rm(path)
            error

          error ->
            error
        end
      after
        File.close(io)
      end
    else
      {:error, :eexist} -> {:error, :recovery_required}
      error -> error
    end
  end

  defp sql_window(state, controller, token, mode, fun, journal_io) do
    result =
      if File.exists?(state.path) do
        with {:ok, db} <- Sqlite3.open(state.path) do
          try do
            transact(db, mode, fun)
          after
            Sqlite3.close(db)
          end
        end
      else
        {:error, :database_missing}
      end

    committed? = mode == :write and match?({:ok, _}, result)
    :ok = IO.binwrite(journal_io, if(committed?, do: "committed\n", else: "read-or-rollback\n"))
    :ok = :file.sync(journal_io)

    case state.api.maintenance_release(controller, token, committed?) do
      :ok ->
        File.rm!(journal(state.path))
        result

      error ->
        {:error, {:synchronization_failed, error}}
    end
  end

  defp transact(db, mode, fun) do
    begin_sql = if mode == :write, do: "BEGIN IMMEDIATE", else: "PRAGMA query_only=ON; BEGIN"

    with :ok <- Sqlite3.execute(db, "PRAGMA busy_timeout=250"),
         :ok <- Sqlite3.execute(db, begin_sql) do
      try do
        with {:ok, %{"version_major" => 1, "version_minor" => 0}} <-
               Database.select_one(db, "SELECT * FROM network"),
             {:ok, value} <- normalize(fun.(db)),
             :ok <- Sqlite3.execute(db, "COMMIT") do
          {:ok, value}
        else
          {:ok, _} -> {:error, :unsupported_schema}
          error -> error
        end
      rescue
        _ -> {:error, :transaction_failed}
      after
        # Harmless after COMMIT; essential for every error path.
        Sqlite3.execute(db, "ROLLBACK")
      end
    end
  end

  defp normalize(:ok), do: {:ok, :ok}
  defp normalize({:ok, _} = result), do: result
  defp normalize({:error, _} = error), do: error
  defp normalize(_), do: {:error, :invalid_transaction_result}

  defp update(db, table, changes, where, bindings) do
    setters = Enum.map_join(changes, ", ", fn {key, _} -> key <> " = ?" end)
    values = Enum.map(changes, &elem(&1, 1))
    Database.execute(db, "UPDATE #{table} SET #{setters} WHERE #{where}", values ++ bindings)
  end

  defp changes(attrs, fields) when map_size(attrs) > 0 do
    Enum.reduce_while(attrs, {:ok, []}, fn {key, value}, {:ok, acc} ->
      case fields[key] do
        {column, max} when is_integer(value) and value >= 0 and value <= max ->
          {:cont, {:ok, [{column, value} | acc]}}

        _ ->
          {:halt, {:error, :invalid_metadata}}
      end
    end)
  end

  defp changes(_, _), do: {:error, :invalid_metadata}

  defp validate_id(id) when id in 1..232 or id in 256..4000, do: :ok
  defp validate_id(_), do: {:error, :invalid_node_id}
end
