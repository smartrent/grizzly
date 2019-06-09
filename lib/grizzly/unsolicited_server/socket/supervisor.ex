defmodule Grizzly.UnsolicitedServer.Socket.Supervisor do
  use DynamicSupervisor

  alias Grizzly.UnsolicitedServer.Socket

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start_socket(:ssl.sslsocket()) :: DynamicSupervisor.on_start_child()
  def start_socket(ssl_listen_sock) do
    child_spec = Socket.child_spec(ssl_listen_sock)

    __MODULE__
    |> DynamicSupervisor.start_child(child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
