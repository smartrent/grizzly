defmodule Grizzly.Conn.Supervisor do
  use DynamicSupervisor

  alias Grizzly.Conn.Server, as: ConnServer
  alias Grizzly.Conn.Config

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec start_child(Config.t()) :: DynamicSupervisor.on_start_child()
  def start_child(opts) do
    spec = ConnServer.child_spec([opts])

    __MODULE__
    |> DynamicSupervisor.start_child(spec)
  end

  @spec stop_connection_server(pid) :: :ok
  def stop_connection_server(conn_pid) do
    :ok = DynamicSupervisor.terminate_child(__MODULE__, conn_pid)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
