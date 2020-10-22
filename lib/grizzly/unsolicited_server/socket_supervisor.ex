defmodule Grizzly.UnsolicitedServer.SocketSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.Socket

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start_socket(Transport.t()) :: DynamicSupervisor.on_start_child()
  def start_socket(transport) do
    child_spec = Socket.child_spec(transport)

    __MODULE__
    |> DynamicSupervisor.start_child(child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
