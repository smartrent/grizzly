defmodule Grizzly.VirtualDevices do
  @moduledoc """
  Virtual devices

  Virtual devices are in-memory devices that act like a Z-Wave device
  """

  alias Grizzly.VirtualDevicesRegistry
  alias Grizzly.VirtualDevices.{Device, Reports}
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DeviceClass

  @typedoc """
  Options for adding a virtual devices

  * `:inclusion_handler` - if an inclusion handler is provider via the add
    options it will override the initial inclusion handle argument to the
    network server if one was provided only for that one call to `add_device/2`.

  You may also include other device options that will passed to your callback
  functions for implementation specific support.
  """
  @type add_opt() :: {:inclusion_handler, Grizzly.handler()} | Device.device_opt()

  @typedoc """
  Options for removing virtual devices

  * `:inclusion_handler` - if an inclusion handler is provider via the add
    options it will override the initial inclusion handle argument to the
    network server if one was provided only for that one call to
    `remove_device/2`.
  """
  @type remove_opt() :: {:inclusion_handler, Grizzly.handler()}

  @typedoc """
  Id for a virtual device
  """
  @type id() :: {:virtual, non_neg_integer()}

  @type device_entry() :: %{
          device_impl: Device.t(),
          device_class: DeviceClass.t(),
          device_opts: [Device.device_opt()],
          id: id(),
          pid: pid()
        }

  @doc """
  Add a new virtual device to the virtual device network

  To add a virtual device you must supply a module that implements the
  `Grizzly.VirtualDevices.Device` behaviour.

  If the device takes any options you can pass a tuple of `{device, opts}`.
  """
  @spec add_device(id(), Device.t(), [add_opt()]) ::
          {:ok, id()} | {:error, {:already_registered, device_entry()}}
  def add_device(device_id, device_impl, opts \\ []) do
    device_opts = Keyword.drop(opts, [:inclusion_handler])

    case register(device_id, device_impl, device_opts) do
      {:ok, device_entry} ->
        if handler = opts[:inclusion_handler] || VirtualDevicesRegistry.get_handler() do
          Reports.send_node_add_status(device_entry, handler)
        end

        {:ok, device_entry.id}

      {:error, {:already_registered, entry}} ->
        {:error, {:already_registered, entry}}
    end
  end

  @doc """
  Same as `add_device/3` but raises an ArgumentError if a device with the requested
  id is already registered.
  """
  @spec add_device!(id(), Device.t(), [add_opt()]) :: id()
  def add_device!(device_id, device_impl, opts \\ []) do
    case add_device(device_id, device_impl, opts) do
      {:ok, device_id} -> device_id
      {:error, {:already_registered, _entry}} -> raise ArgumentError, "Device already registered"
    end
  end

  defp register(device_id, device_impl, device_opts) do
    device_class = device_impl.device_spec(device_opts)

    VirtualDevicesRegistry.register(device_id, device_impl, device_class, device_opts)
  end

  @doc """
  Broadcast a command to the rest of the Z-Wave network
  """
  @spec broadcast_command(id(), Command.t()) :: :ok
  def broadcast_command(device_id, command) do
    device_id
    |> Grizzly.Report.unsolicited(command)
    |> Grizzly.Events.broadcast_report()
  end

  @doc """
  Remove a device from the virtual device network
  """
  @spec remove_device(id(), [remove_opt()]) :: :ok
  def remove_device(device_id, opts \\ []) do
    :ok = VirtualDevicesRegistry.unregister(device_id)

    if handler = opts[:inclusion_handler] || VirtualDevicesRegistry.get_handler() do
      Reports.send_node_remove_status(device_id, handler)
    end

    :ok
  end

  @doc """
  Get the pid for the device id

  This is useful for when you device is processed-based and you need to send
  messages to it.
  """
  @spec whereis(id()) :: pid() | nil
  def whereis(device_id) do
    case VirtualDevicesRegistry.get(device_id) do
      nil ->
        nil

      entry ->
        entry.pid
    end
  end

  @doc """
  List the nodes in the virtual devices network
  """
  @spec list_nodes() :: [id()]
  def list_nodes() do
    VirtualDevicesRegistry.list_ids()
  end

  @doc """
  Send a Z-Wave command to the virtual device
  """
  @spec send_command(id(), Command.t()) ::
          {:ok, Grizzly.Report.t()} | {:error, :device_not_found | Grizzly.Report.t()}
  def send_command(device_id, %Command{name: :node_info_cached_get} = node_info_get) do
    with_entry(device_id, &Reports.build_node_info_cache_report(&1, node_info_get))
  end

  def send_command(device_id, %Command{name: :manufacturer_specific_get}) do
    with_entry(device_id, &Reports.build_manufacturer_specific_report/1)
  end

  def send_command(device_id, %Command{name: :version_command_class_get} = command) do
    with_entry(device_id, &Reports.build_version_command_class_get_report(&1, command))
  end

  def send_command(device_id, %Command{name: :association_get}) do
    with_entry(device_id, &Reports.build_association_report/1)
  end

  def send_command(device_id, %Command{name: :battery_get}) do
    with_entry(device_id, &Reports.build_battery_report/1)
  end

  def send_command(device_id, %Command{name: :version_get}) do
    with_entry(device_id, &Reports.build_version_report/1)
  end

  def send_command(
        device_id,
        %Command{name: :manufacturer_specific_device_specific_get} = command
      ) do
    with_entry(
      device_id,
      &Reports.build_manufacturer_specific_device_specific_report(&1, command)
    )
  end

  def send_command(device_id, %Command{name: :association_set}) do
    with_entry(device_id, &Reports.build_ack_response/1)
  end

  def send_command(device_id, command) do
    case VirtualDevicesRegistry.get(device_id) do
      nil ->
        {:error, :device_not_found}

      entry ->
        case entry.device_impl.handle_command(command, entry.device_opts) do
          :ok ->
            {:ok, Reports.build_ack_response(entry)}

          {:ok, command} ->
            report = Reports.build_report(entry, command)
            Grizzly.Events.broadcast_report(report)
            {:ok, report}

          {:error, :timeout} ->
            {:error, Reports.build_timeout_report(entry.id)}

          {:notify, command} ->
            broadcast_command(device_id, command)
            {:ok, Reports.build_ack_response(entry)}
        end
    end
  end

  defp with_entry(device_id, callback) do
    case VirtualDevicesRegistry.get(device_id) do
      nil ->
        {:ok, Reports.build_timeout_report(device_id)}

      entry ->
        result = callback.(entry)

        {:ok, result}
    end
  end
end
