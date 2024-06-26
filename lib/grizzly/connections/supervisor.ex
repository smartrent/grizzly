defmodule Grizzly.Connections.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.{Connection, Options, ZWave}
  alias Grizzly.Connections.{AsyncConnection, BinaryConnection, SyncConnection}

  @spec start_link(Options.t()) :: Supervisor.on_start()
  def start_link(options) do
    DynamicSupervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  @doc """
  Start a connection to a Z-Wave Node or the Z/IP Gateway
  """
  @spec start_connection(ZWave.node_id() | :gateway, [Connection.opt()]) ::
          DynamicSupervisor.on_start_child()
  def start_connection(node_id, opts \\ []) do
    case Keyword.get(opts, :mode, :sync) do
      :async ->
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
    if GenServer.whereis(__MODULE__) != nil do
      connections_pids = DynamicSupervisor.which_children(__MODULE__)

      Enum.each(connections_pids, fn {_, connection_pid, _, _} ->
        :ok = Connection.close(connection_pid)
      end)
    end

    :ok
  catch
    :exit, {:noproc, _} -> :ok
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
      {:ok, pid, _} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _reason} = other_error -> other_error
    end
  end
end
