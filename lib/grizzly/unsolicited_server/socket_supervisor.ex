defmodule Grizzly.UnsolicitedServer.SocketSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grizzly.Transport
  alias Grizzly.UnsolicitedServer.Socket

  @type opt() :: {:data_file, Path.t()}

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start_socket(Transport.t(), [opt()]) :: DynamicSupervisor.on_start_child()
  def start_socket(transport, opts) do
    child_spec = Socket.child_spec(transport, opts)

    __MODULE__
    |> DynamicSupervisor.start_child(child_spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
