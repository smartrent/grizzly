defmodule Grizzly.Connections.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Connections.{AsyncConnection, SyncConnection}

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_connection(node_id, opts \\ []) do
    case Keyword.get(opts, :mode, :sync) do
      :async ->
        # don't allow async connections if they are not already started
        # maybe move async connections to be call an inclusion connection?
        do_start_connection(AsyncConnection, node_id)

      :sync ->
        do_start_connection(SyncConnection, node_id)
    end
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp do_start_connection(connection_module, node_id) do
    case DynamicSupervisor.start_child(__MODULE__, connection_module.child_spec(node_id)) do
      {:ok, _} = ok -> ok
      {:error, :timeout} = timeout_error -> timeout_error
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end
end
