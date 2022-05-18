defmodule Grizzly.VirtualDevices.Network do
  @moduledoc false

  use GenServer

  alias Grizzly.{Report, VirtualDevices}
  alias Grizzly.VirtualDevices.{Device, DeviceServer, DevicesSupervisor}
  alias Grizzly.ZWave.Commands.{NodeAddStatus, NodeRemoveStatus}

  @type arg() :: {:inclusion_handler, Grizzly.handler()}

  @doc """
  Start the virtual device network
  """
  @spec start_link([arg()]) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Add a virtual device to the network
  """
  @spec add_device(Device.t(), [VirtualDevices.add_opt()]) :: {:ok, VirtualDevices.id()}
  def add_device(device, opts) do
    GenServer.call(__MODULE__, {:add_device, device, opts})
  end

  @doc """
  List the virtual devices
  """
  @spec list_nodes() :: [VirtualDevices.id()]
  def list_nodes() do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Remove a virtual device
  """
  @spec remove_device(VirtualDevices.id(), [VirtualDevices.remove_opt()]) :: :ok
  def remove_device(id, opts) do
    GenServer.call(__MODULE__, {:remove, id, opts})
  end

  @impl GenServer
  def init(args) do
    inclusion_handler = args[:inclusion_handler]

    {:ok, %{network: %{}, current_id: 0, inclusion_handler: inclusion_handler}}
  end

  @impl GenServer
  def handle_call({:add_device, device, opts}, _from, state) do
    id = state.current_id + 1

    case DevicesSupervisor.start_device({:virtual, id}, device) do
      {:ok, _pid} ->
        updated_network = Map.put(state.network, id, device)
        :ok = send_node_add_status({:virtual, id}, opts, state)

        {:reply, {:ok, {:virtual, id}}, %{state | network: updated_network, current_id: id}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:list, _from, state) do
    list = Enum.map(state.network, fn {id, _} -> {:virtual, id} end)

    {:reply, list, state}
  end

  def handle_call({:remove, {:virtual, id} = vid, opts}, _from, state) do
    case Map.get(state.network, id) do
      nil ->
        {:reply, :ok, state}

      _device ->
        :ok = DeviceServer.stop(vid)
        new_networks = Map.delete(state.network, id)
        :ok = send_node_remove_status(vid, opts, state)
        {:reply, :ok, %{state | network: new_networks}}
    end
  end

  defp get_inclusion_handler(opts, state) do
    case opts[:inclusion_handler] do
      nil ->
        state.inclusion_handler

      handler ->
        handler
    end
  end

  defp send_node_add_status(device_id, opts, state) do
    case get_inclusion_handler(opts, state) do
      nil ->
        :ok

      handler ->
        info = DeviceServer.device_class_info(device_id)

        {:ok, node_add_status} =
          NodeAddStatus.new(
            seq_number: 0x00,
            node_id: device_id,
            status: :done,
            listening?: true,
            basic_device_class: info.basic_device_class,
            generic_device_class: info.generic_device_class,
            specific_device_class: info.specific_device_class,
            command_classes: info.command_classes,
            granted_keys: [],
            kex_fail_type: :none,
            input_dsk: Grizzly.ZWave.DSK.new("")
          )

        send_network_command(device_id, node_add_status, handler)
    end
  end

  defp send_node_remove_status(device_id, opts, state) do
    case get_inclusion_handler(opts, state) do
      nil ->
        :ok

      handler ->
        {:ok, remove_status} =
          NodeRemoveStatus.new(
            seq_number: 0x00,
            status: :done,
            node_id: device_id
          )

        send_network_command(device_id, remove_status, handler)
    end
  end

  defp send_network_command(device_id, command, handler_module) when is_atom(handler_module) do
    report = build_command_report(device_id, command)

    handler_module.handle_report(report, [])
  end

  defp send_network_command(device_id, command, {module, args}) do
    report = build_command_report(device_id, command)

    module.handle_report(report, args)
  end

  defp build_command_report(device_id, command) do
    Report.new(:complete, :command, device_id, command: command)
  end
end
