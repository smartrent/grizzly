defmodule Grizzly.VirtualDevices.Network do
  @moduledoc false

  use GenServer

  alias Grizzly.VirtualDevices
  alias Grizzly.VirtualDevices.{DeviceServer, DevicesSupervisor}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Add a virtual device to the network
  """
  def add_device(device) do
    GenServer.call(__MODULE__, {:add_device, device})
  end

  @doc """
  List the virtual devices
  """
  @spec list_nodes() :: [VirtualDevices.id()]
  def list_nodes() do
    GenServer.call(__MODULE__, :list)
  end

  def remove_device(id) do
    GenServer.call(__MODULE__, {:remove, id})
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{network: %{}, current_id: 0}}
  end

  @impl GenServer
  def handle_call({:add_device, device}, _from, state) do
    id = state.current_id + 1

    case DevicesSupervisor.start_device({:virtual, id}, device) do
      {:ok, _pid} ->
        updated_network = Map.put(state.network, id, device)

        {:reply, {:ok, {:virtual, id}}, %{state | network: updated_network, current_id: id}}
    end
  end

  def handle_call(:list, _from, state) do
    list = Enum.map(state.network, fn {id, _} -> {:virtual, id} end)

    {:reply, list, state}
  end

  def handle_call({:remove, {:virtual, id} = vid}, _from, state) do
    case Map.get(state.network, id) do
      nil ->
        {:reply, :ok, state}

      _device ->
        :ok = DeviceServer.stop(vid)
        new_networks = Map.delete(state.network, id)
        {:reply, :ok, %{state | network: new_networks}}
    end
  end
end
