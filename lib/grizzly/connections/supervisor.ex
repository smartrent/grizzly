defmodule Grizzly.Connections.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.{Connection, Options, ZWave}
  alias Grizzly.Connections.{AsyncConnection, BinaryConnection, SyncConnection}

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    DynamicSupervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @spec start_connection(ZWave.node_id(), [Connection.opt()]) ::
          {:ok, pid()} | {:error, :timeout}
  def start_connection(node_id, opts \\ []) do
    case Keyword.get(opts, :mode, :sync) do
      :async ->
        # put the calling process as the owner if sine the supervisor
        # will be owner when calling form here.
        opts = Keyword.put_new(opts, :owner, self())
        do_start_connection(AsyncConnection, node_id, opts)

      :sync ->
        do_start_connection(SyncConnection, node_id)

      :binary ->
        do_start_connection(BinaryConnection, node_id, owner: self())
    end
  end

  @doc """
  Close all the connections
  """
  @spec close_all_connections() :: :ok
  def close_all_connections() do
    connections_pids = DynamicSupervisor.which_children(__MODULE__)

    Enum.each(connections_pids, fn {_, connection_pid, _, _} ->
      :ok = Connection.close(connection_pid)
    end)
  end

  @impl DynamicSupervisor
  def init(grizzly_options) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [grizzly_options])
  end

  defp do_start_connection(connection_module, node_id, command_opts \\ []) do
    case DynamicSupervisor.start_child(
           __MODULE__,
           connection_module.child_spec(node_id, command_opts)
         ) do
      {:ok, _} = ok -> ok
      {:error, :timeout} = timeout_error -> timeout_error
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end
end
