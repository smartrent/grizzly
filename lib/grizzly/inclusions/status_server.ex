defmodule Grizzly.Inclusions.StatusServer do
  @moduledoc false

  # Server for keeping track of the inclusion status.

  # Separating this into it's own process allows for error isolation between the
  # inclusion server and the status of the inclusion process. The reason for the
  # isolation is if the inclusion server crashes for whatever reason the Z-Wave
  # controller will be in an non-operable state and there would be no why for
  # the runtime to know this. Therefore, the status is kept separate from the
  # more complex code around managing the communication back and forth during
  # an inclusion/exclusion of a Z-Wave device. The goal of this is to provide
  # system recoverability after a crash during inclusion/exclusion.

  use GenServer

  alias Grizzly.Inclusions

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Set the status of the inclusion process
  """
  @spec set(Inclusions.status()) :: :ok
  def set(status) do
    GenServer.call(__MODULE__, {:set, status})
  end

  @doc """
  Get the status of the inclusion process
  """
  @spec get() :: Inclusions.status()
  def get() do
    GenServer.call(__MODULE__, :get)
  end

  @impl GenServer
  def init(_args) do
    {:ok, :idle}
  end

  @impl GenServer
  def handle_call({:set, status}, _from, old_status) do
    Logger.debug("[Grizzly.Inclusions.StatusServer] #{old_status} -> #{status}")
    {:reply, :ok, status}
  end

  def handle_call(:get, _from, status) do
    {:reply, status, status}
  end
end
