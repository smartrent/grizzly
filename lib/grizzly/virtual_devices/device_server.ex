defmodule Grizzly.VirtualDevices.DeviceServer do
  @moduledoc false

  use GenServer

  alias Grizzly.{Report, VirtualDevices}
  alias Grizzly.UnsolicitedServer.Messages
  alias Grizzly.VirtualDevices.Device
  alias Grizzly.ZWave.{Command, CommandClasses, DeviceClass, DeviceClasses}

  alias Grizzly.ZWave.Commands.{
    AssociationReport,
    BatteryReport,
    ManufacturerSpecificDeviceSpecificReport,
    ManufacturerSpecificReport,
    NodeInfoCacheReport,
    VersionCommandClassReport,
    VersionReport
  }

  @type tagged_command_classes() ::
          {:non_secure_supported, [CommandClasses.command_class()]}
          | {:non_secure_controlled, [CommandClasses.command_class()]}
          | {:secure_supported, [CommandClasses.command_class()]}
          | {:secure_controlled, [CommandClasses.command_class()]}

  @type device_class_info() :: %{
          command_classes: tagged_command_classes(),
          basic_device_class: DeviceClasses.basic_device_class(),
          specific_device_class: DeviceClasses.specific_device_class(),
          generic_device_class: DeviceClasses.generic_device_class()
        }

  @typedoc """
  Initial arguments to the device server

  * `:id` - the virtual device id, this is required
  * `:device` - the virtual device implementation module that will handle the
    specific commands, this is required
  """
  @type arg() ::
          {:id, VirtualDevices.id()} | {:device, Device.t()}

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      restart: :transient
    }
  end

  @doc """
  Start the device server
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    id = Keyword.fetch!(args, :id)
    GenServer.start_link(__MODULE__, args, name: name(id))
  end

  defp name(id) do
    {:via, Registry, {Grizzly.VirtualDevicesRegistry, id}}
  end

  @doc """
  Send a command to the virtual device
  """
  @spec send_command(VirtualDevices.id(), Command.t()) :: Grizzly.send_command_response()
  def send_command(id, command) do
    GenServer.call(name(id), {:send_command, command})
  end

  @doc """
  Get the basic device class info
  """
  @spec device_class_info(VirtualDevices.id()) :: device_class_info()
  def device_class_info(id) do
    GenServer.call(name(id), :info)
  end

  def stop(id) do
    GenServer.stop(name(id))
  end

  @impl GenServer
  def init(args) do
    node_id = Keyword.fetch!(args, :id)
    {device_impl, opts} = get_device_impl(args)

    try do
      case device_impl.init(opts) do
        {:ok, device_state, device_class} ->
          state =
            %{
              device_class: device_class,
              device_state: device_state,
              device: device_impl,
              node_id: node_id,
              notifications: false
            }
            |> include_battery_support()

          {:ok, state}

        error ->
          {:stop, error}
      end
    rescue
      _e in UndefinedFunctionError ->
        {:stop, :invalid_device}
    end
  end

  defp include_battery_support(state) do
    if DeviceClass.has_command_class?(state.device_class, :battery) do
      Map.put(state, :battery_level, 100)
    else
      state
    end
  end

  defp get_device_impl(args) do
    case Keyword.fetch!(args, :device) do
      {_device, _opts} = impl -> impl
      device -> {device, []}
    end
  end

  @impl GenServer
  def handle_call(:info, _from, state) do
    {:reply, make_info(state), state}
  end

  def handle_call(
        {:send_command, %Command{name: :node_info_cache_get} = node_info_get},
        _from,
        state
      ) do
    seq_number = Command.param!(node_info_get, :seq_number)
    info = make_info(state)

    {:ok, node_info_report} =
      NodeInfoCacheReport.new(
        seq_number: seq_number,
        status: :ok,
        age: 1,
        listening?: true,
        command_classes: info.command_classes,
        basic_device_class: info.basic_device_class,
        specific_device_class: info.specific_device_class,
        generic_device_class: info.generic_device_class
      )

    {:reply, build_report(node_info_report, state), state}
  end

  def handle_call({:send_command, %Command{name: :manufacturer_specific_get}}, _from, state) do
    {:ok, manufacturer_report} =
      ManufacturerSpecificReport.new(
        manufacturer_id: state.device_class.manufacturer_id,
        product_id: state.device_class.product_id,
        product_type_id: state.device_class.product_type_id
      )

    {:reply, build_report(manufacturer_report, state), state}
  end

  def handle_call(
        {:send_command, %Command{name: :version_command_class_get} = command},
        _from,
        state
      ) do
    command_class = Command.param!(command, :command_class)

    case DeviceClass.get_command_class_version(state.device_class, command_class) do
      nil ->
        {:reply, build_timeout_report(state), state}

      version ->
        {:ok, version_report} =
          VersionCommandClassReport.new(command_class: command_class, version: version)

        {:reply, build_report(version_report, state), state}
    end
  end

  def handle_call({:send_command, %Command{name: :association_set}}, _from, state) do
    {:reply, build_report(:ack_response, state), %{state | notifications: true}}
  end

  def handle_call({:send_command, %Command{name: :association_get}}, _from, state) do
    associated_nodes = get_associated_nodes(state)

    {:ok, report} =
      AssociationReport.new(
        nodes: associated_nodes,
        grouping_identifier: 1,
        max_nodes_supported: 1,
        reports_to_follow: 0
      )

    {:reply, build_report(report, state), state}
  end

  def handle_call({:send_command, %Command{name: :battery_get}}, _from, state) do
    case Map.get(state, :battery_level) do
      nil ->
        {:reply, build_timeout_report(state), state}

      battery_level ->
        {:ok, report} = BatteryReport.new(level: battery_level)

        {:reply, build_report(report, state), state}
    end
  end

  def handle_call({:send_command, %Command{name: :version_get}}, _from, state) do
    {:ok, report} =
      VersionReport.new(
        library_type: state.device_class.library_type,
        protocol_version: "7.16",
        firmware_version: "7.16",
        hardware_version: 1,
        other_firmware_versions: ["7.16"]
      )

    {:reply, build_report(report, state), state}
  end

  def handle_call(
        {:send_command, %Command{name: :manufacturer_specific_device_specific_get} = command},
        _from,
        state
      ) do
    case Command.param!(command, :device_id_type) do
      :serial_number ->
        {:ok, report} =
          ManufacturerSpecificDeviceSpecificReport.new(
            device_id_type: :serial_number,
            device_id: "0000"
          )

        {:reply, build_report(report, state), state}

      _other ->
        {:reply, build_timeout_report(state), state}
    end
  end

  def handle_call({:send_command, zwave_command}, _from, state) do
    case state.device.handle_command(zwave_command, state.device_state) do
      {:reply, :ack_response, new_device_state} ->
        {:reply, build_report(:ack_response, state), %{state | device_state: new_device_state}}

      {:reply, zwave_command_report, new_device_state} ->
        {:reply, build_report(zwave_command_report, state),
         %{state | device_state: new_device_state}}

      {:notify, command, new_device_state} ->
        maybe_send_notification(command, state)
        {:reply, build_report(:ack_response, state), %{state | device_state: new_device_state}}

      {:noreply, new_state} ->
        {:reply, build_timeout_report(state), %{state | device_state: new_state}}
    end
  end

  @impl GenServer
  def handle_info(msg, state) do
    case state.device.handle_info(msg, state.device_state) do
      {:noreply, new_state} ->
        {:noreply, %{state | device_state: new_state}}

      {:notify, command, new_state} ->
        maybe_send_notification(command, state)
        {:noreply, %{state | device_state: new_state}}
    end
  end

  defp maybe_send_notification(command, state) do
    # to keep with how Z-Wave is suppose to work we do not send
    # notifications unless the devices as been told to via association
    # to the lifeline group.
    if state.notifications do
      :ok = Messages.broadcast(state.node_id, command)
    end

    :ok
  end

  # helper function to transform a device class command class specification into
  # a format that NodeInfoCacheReport expects
  defp command_classes_for_device(device_class) do
    [
      non_secure_supported: Map.keys(device_class.command_classes.support),
      non_secure_controlled: Map.keys(device_class.command_classes.control)
    ]
  end

  # helper function that builds the expected grizzly report
  defp build_report(:ack_response, state) do
    {:ok, Report.new(:complete, :ack_response, state.node_id)}
  end

  defp build_report(command, state) do
    {:ok, Report.new(:complete, :command, state.node_id, command: command)}
  end

  defp build_timeout_report(state) do
    {:ok, Report.new(:complete, :timeout, state.node_id)}
  end

  defp make_info(state) do
    %{
      command_classes: command_classes_for_device(state.device_class),
      basic_device_class: state.device_class.basic_device_class,
      specific_device_class: state.device_class.specific_device_class,
      generic_device_class: state.device_class.generic_device_class
    }
  end

  defp get_associated_nodes(%{notifications: false}), do: []
  defp get_associated_nodes(%{notifications: true}), do: [1]
end
