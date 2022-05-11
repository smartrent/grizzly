defmodule Grizzly.VirtualDevices.DeviceServer do
  @moduledoc false

  use GenServer

  alias Grizzly.{Report, VirtualDevices}
  alias Grizzly.VirtualDevices.Device
  alias Grizzly.ZWave.{Command, CommandClasses, DeviceClasses}
  alias Grizzly.ZWave.Commands.NodeInfoCacheReport

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
    device_impl = Keyword.fetch!(args, :device)
    {:ok, device_state, device_class} = device_impl.init()

    {:ok,
     %{
       device_class: device_class,
       device_state: device_state,
       device: device_impl,
       node_id: node_id
     }}
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

  # helper function to transform a device class command class specification into
  # a format that NodeInfoCacheReport expects
  defp command_classes_for_device(device_class) do
    [
      non_secure_supported: device_class.command_classes.support,
      non_secure_controlled: device_class.command_classes.control
    ]
  end

  # helper function that builds the expected grizzly report
  defp build_report(command, state) do
    Report.new(:complete, :command, state.node_id, command: command)
  end

  defp make_info(state) do
    %{
      command_classes: command_classes_for_device(state.device_class),
      basic_device_class: state.device_class.basic_device_class,
      specific_device_class: state.device_class.specific_device_class,
      generic_device_class: state.device_class.generic_device_class
    }
  end
end
