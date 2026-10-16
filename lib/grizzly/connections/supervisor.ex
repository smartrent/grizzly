defmodule Grizzly.Connections.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Connection
  alias Grizzly.Options
  alias Grizzly.ZWave

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
    with {:ok, spec} <- Grizzly.Backend.connection_spec(node_id, opts) do
      do_start_connection(spec)
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

  defp do_start_connection(spec) do
    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _} = ok -> ok
      {:ok, pid, _} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _reason} = other_error -> other_error
    end
  end
end
