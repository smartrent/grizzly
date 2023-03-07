defmodule Grizzly.VirtualDevices.Reports do
  @moduledoc false

  # Helper module for building various general reports for a virtual device

  alias Grizzly.{Report, VirtualDevices, VirtualDevicesRegistry}
  alias Grizzly.ZWave.{Command, DeviceClass, DSK}

  alias Grizzly.ZWave.Commands.{
    AssociationReport,
    BatteryReport,
    ManufacturerSpecificDeviceSpecificReport,
    ManufacturerSpecificReport,
    NodeAddStatus,
    NodeInfoCacheReport,
    NodeRemoveStatus,
    VersionCommandClassReport,
    VersionReport
  }

  @doc """
  Send the node add status message to the handler
  """
  @spec send_node_add_status(VirtualDevicesRegistry.device_entry(), Grizzly.handler()) :: :ok
  def send_node_add_status(device_entry, handler) do
    {handler, handler_opts} = ensure_handler_with_opts(handler)

    {:ok, node_add_status} =
      NodeAddStatus.new(
        seq_number: 0x00,
        node_id: device_entry.id,
        status: :done,
        listening?: true,
        basic_device_class: device_entry.device_class.basic_device_class,
        generic_device_class: device_entry.device_class.generic_device_class,
        specific_device_class: device_entry.device_class.specific_device_class,
        command_classes: command_classes_for_device(device_entry.device_class),
        granted_keys: [],
        kex_fail_type: :none,
        input_dsk: DSK.new("")
      )

    report = Report.new(:complete, :command, device_entry.id, command: node_add_status)

    handler.handle_report(report, handler_opts)

    :ok
  end

  def send_node_remove_status(device_id, handler) do
    {handler, handler_opts} = ensure_handler_with_opts(handler)

    {:ok, node_remove_status} =
      NodeRemoveStatus.new(seq_number: 0x01, status: :done, node_id: device_id)

    report = Report.new(:complete, :command, device_id, command: node_remove_status)

    handler.handle_report(report, handler_opts)

    :ok
  end

  defp ensure_handler_with_opts(handler_spec) when is_tuple(handler_spec), do: handler_spec

  defp ensure_handler_with_opts(handler_module) when is_atom(handler_module),
    do: {handler_module, []}

  @doc """
  Build a node info cached report based of a node info get command
  """
  @spec build_node_info_cache_report(VirtualDevicesRegistry.device_entry(), Command.t()) ::
          Report.t()
  def build_node_info_cache_report(entry, node_info_get) do
    seq_number = Command.param!(node_info_get, :seq_number)

    {:ok, node_info_report} =
      NodeInfoCacheReport.new(
        seq_number: seq_number,
        status: :ok,
        age: 1,
        listening?: true,
        command_classes: command_classes_for_device(entry.device_class),
        basic_device_class: entry.device_class.basic_device_class,
        specific_device_class: entry.device_class.specific_device_class,
        generic_device_class: entry.device_class.generic_device_class
      )

    Report.new(:complete, :command, entry.id, command: node_info_report)
  end

  @doc """
  Build manufacturer specific report for the device entry
  """
  @spec build_manufacturer_specific_report(VirtualDevicesRegistry.device_entry()) :: Report.t()
  def build_manufacturer_specific_report(entry) do
    {:ok, manufacturer_report} =
      ManufacturerSpecificReport.new(
        manufacturer_id: entry.device_class.manufacturer_id,
        product_id: entry.device_class.product_id,
        product_type_id: entry.device_class.product_type_id
      )

    Report.new(:complete, :command, entry.id, command: manufacturer_report)
  end

  @doc """
  Build version command class get for a command class in the entry's device
  class
  """
  @spec build_version_command_class_get_report(VirtualDevicesRegistry.device_entry(), Command.t()) ::
          Report.t()
  def build_version_command_class_get_report(entry, version_command_class_get) do
    command_class = Command.param!(version_command_class_get, :command_class)

    case DeviceClass.get_command_class_version(entry.device_class, command_class) do
      nil ->
        build_timeout_report(entry.id)

      version ->
        {:ok, version_report} =
          VersionCommandClassReport.new(command_class: command_class, version: version)

        build_report(entry, version_report)
    end
  end

  @doc """
  Build the association report from the association get command
  """
  @spec build_association_report(VirtualDevicesRegistry.device_entry()) :: Report.t()
  def build_association_report(entry) do
    {:ok, report} =
      AssociationReport.new(
        nodes: [1],
        grouping_identifier: 1,
        max_nodes_supported: 1,
        reports_to_follow: 0
      )

    build_report(entry, report)
  end

  @doc """
  Build a battery report for a battery get command
  """
  @spec build_battery_report(VirtualDevicesRegistry.device_entry()) :: Report.t()
  def build_battery_report(entry) do
    {:ok, report} = BatteryReport.new(level: 100)

    build_report(entry, report)
  end

  @doc """
  Build a version report for a version get command
  """
  @spec build_version_report(VirtualDevicesRegistry.device_entry()) :: Report.t()
  def build_version_report(entry) do
    {:ok, report} =
      VersionReport.new(
        library_type: entry.device_class.library_type,
        protocol_version: "7.16",
        firmware_version: "7.16",
        hardware_version: 1,
        other_firmware_versions: ["7.16"]
      )

    build_report(entry, report)
  end

  def build_manufacturer_specific_device_specific_report(entry, command) do
    case Command.param!(command, :device_id_type) do
      :serial_number ->
        {:ok, report} =
          ManufacturerSpecificDeviceSpecificReport.new(
            device_id_type: :serial_number,
            device_id: "0000"
          )

        build_report(entry, report)

      _other ->
        build_timeout_report(entry.id)
    end
  end

  @doc """
  Build a Grizzly Report for a timeout
  """
  @spec build_timeout_report(VirtualDevices.id()) :: Report.t()
  def build_timeout_report(device_id) do
    Report.new(:complete, :timeout, device_id)
  end

  @doc """
  Build an ack response report
  """
  @spec build_ack_response(VirtualDevicesRegistry.device_entry()) :: Report.t()
  def build_ack_response(entry) do
    Report.new(:complete, :ack_response, entry.id)
  end

  @doc """
  Build a report that contains a command
  """
  @spec build_report(VirtualDevicesRegistry.device_entry(), Command.t()) :: Report.t()
  def build_report(entry, command) do
    Report.new(:complete, :command, entry.id, command: command)
  end

  defp command_classes_for_device(device_class) do
    [
      non_secure_supported: Map.keys(device_class.command_classes.support),
      non_secure_controlled: Map.keys(device_class.command_classes.control)
    ]
  end
end
