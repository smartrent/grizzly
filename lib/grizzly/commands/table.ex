defmodule Grizzly.Commands.Table do
  @moduledoc false

  # look up support for supported command classes and their default Grizzly
  # runtime related options. This where Grizzly and Z-Wave meet in regards to
  # out going commands

  defmodule Generate do
    @moduledoc false
    alias Grizzly.CommandHandlers.{AckResponse, WaitReport, AggregateReport}

    alias Grizzly.ZWave.Commands

    @table [
      {:configuration_set, {Commands.ConfigurationSet, handler: AckResponse}},
      {:default_set,
       {Commands.DefaultSet, handler: {WaitReport, complete_report: :default_set_complete}}},
      # Noop
      {:no_operation, {Commands.NoOperation, handler: AckResponse}},
      # Basic
      {:basic_get, {Commands.BasicGet, handler: {WaitReport, complete_report: :basic_report}}},
      {:basic_set, {Commands.BasicSet, handler: AckResponse}},
      # Battery
      {:battery_get,
       {Commands.BatteryGet, handler: {WaitReport, complete_report: :battery_report}}},
      # Binary switches
      {:switch_binary_get,
       {Commands.SwitchBinaryGet, handler: {WaitReport, complete_report: :switch_binary_report}}},
      {:switch_binary_set, {Commands.SwitchBinarySet, handler: AckResponse}},
      # Manufacturer specific
      {:manufacturer_specific_get,
       {Commands.ManufacturerSpecificGet,
        handler: {WaitReport, complete_report: :manufacturer_specific_report}}},
      {:manufacturer_specific_device_specific_get,
       {Commands.ManufacturerSpecificDeviceSpecificGet,
        handler: {WaitReport, complete_report: :manufacturer_specific_device_specific_report}}},
      # Multilevel switches
      {:switch_multilevel_get,
       {Commands.SwitchMultilevelGet,
        handler: {WaitReport, complete_report: :switch_multilevel_report}}},
      {:switch_multilevel_set, {Commands.SwitchMultilevelSet, handler: AckResponse}},
      {:switch_multilevel_start_level_change,
       {Commands.SwitchMultilevelStartLevelChange, handler: AckResponse}},
      {:switch_multilevel_stop_level_change,
       {Commands.SwitchMultilevelStopLevelChange, handler: AckResponse}},
      # Node management
      {:node_list_get,
       {Commands.NodeListGet, handler: {WaitReport, complete_report: :node_list_report}}},
      {:node_add, {Commands.NodeAdd, handler: {WaitReport, complete_report: :node_add_status}}},
      {:node_info_cached_get,
       {Commands.NodeInfoCachedGet,
        handler: {WaitReport, complete_report: :node_info_cache_report}}},
      {:node_remove,
       {Commands.NodeRemove, handler: {WaitReport, complete_report: :node_remove_status}}},
      # DSKs
      {:node_add_keys_set, {Commands.NodeAddKeysSet, handler: AckResponse}},
      {:node_add_dsk_set, {Commands.NodeAddDSKSet, handler: AckResponse}},
      {:dsk_get, {Commands.DSKGet, handler: {WaitReport, complete_report: :dsk_report}}},
      # Door Lock
      {:door_lock_operation_set, {Commands.DoorLockOperationSet, handler: AckResponse}},
      {:door_lock_operation_get,
       {Commands.DoorLockOperationGet,
        handler: {WaitReport, complete_report: :door_lock_operation_report}}},
      # Associations
      {:association_set, {Commands.AssociationSet, handler: AckResponse}},
      {:association_get,
       {Commands.AssociationGet,
        handler: {AggregateReport, complete_report: :association_report, aggregate_param: :nodes}}},
      # Keep alive
      {:keep_alive, {Commands.ZIPKeepAlive, handler: AckResponse}},
      # Version
      {:version_get,
       {Commands.VersionGet, handler: {WaitReport, complete_report: :version_report}}},
      {:version_command_class_get,
       {Commands.CommandClassGet, handler: {WaitReport, complete_report: :command_class_report}}},
      # Firmware update metadata
      {:firmware_update_md_get,
       {Commands.FirmwareUpdateMDGet, handler: {WaitReport, complete_report: :firmware_md_report}}},
      # Wake up
      {:wake_up_interval_get,
       {Commands.WakeUpIntervalGet,
        handler: {WaitReport, complete_report: :wake_up_interval_report}}},
      {:wake_up_interval_set, {Commands.WakeUpIntervalSet, handler: AckResponse}},
      {:wake_up_no_more_information, {Commands.WakeUpNoMoreInformation, handler: AckResponse}},
      {:wake_up_interval_capabilities_get,
       {Commands.WakeUpIntervalCapabilitiesGet,
        handler: {WaitReport, complete_report: :wake_up_interval_capabilities_report}}},
      # Sensor Multilevel
      {:sensor_multilevel_get,
       {Commands.SensorMultilevelGet,
        handler: {WaitReport, complete_report: :sensor_multilevel_report}}},
      {:sensor_multilevel_supported_sensor_get,
       {Commands.SensorMultilevelSupportedSensorGet,
        handler: {WaitReport, complete_report: :sensor_multilevel_supported_sensor_report}}},
      # User code
      {:user_code_set, {Commands.UserCodeSet, handler: AckResponse}},
      {:user_code_get,
       {Commands.UserCodeGet, handler: {WaitReport, complete_report: :user_code_report}}},
      {:user_code_users_number_get,
       {Commands.UserCodeUsersNumberGet,
        handler: {WaitReport, complete_report: :user_code_users_number_report}}},
      # Meter
      {:meter_get, {Commands.MeterGet, handler: {WaitReport, complete_report: :meter_report}}},
      # Thermostat mode
      {:thermostat_mode_set, {Commands.ThermostatModeSet, handler: AckResponse}},
      {:thermostat_mode_get,
       {Commands.ThermostatModeGet,
        handler: {WaitReport, complete_report: :thermostat_mode_report}}},
      # Thermostat setpoint
      {:thermostat_setpoint_set, {Commands.ThermostatSetpointSet, handler: AckResponse}},
      {:thermostat_setpoint_get,
       {Commands.ThermostatSetpointGet,
        handler: {WaitReport, complete_report: :thermostat_setpoint_report}}},
      # Thermostat fan mode
      {:thermostat_fan_mode_set, {Commands.ThermostatFanModeSet, handler: AckResponse}},
      {:thermostat_fan_mode_get,
       {Commands.ThermostatFanModeGet,
        handler: {WaitReport, complete_report: :thermostat_fan_mode_report}}},
      # Thermostat fan state
      {:thermostat_fan_state_get,
       {Commands.ThermostatFanStateGet,
        handler: {WaitReport, complete_report: :thermostat_fan_state_report}}},
      # Thermostat setback
      {:thermostat_setback_set, {Commands.ThermostatSetbackSet, handler: AckResponse}},
      {:thermostat_setback_get,
       {Commands.ThermostatSetbackGet,
        handler: {WaitReport, complete_report: :thermostat_setback_report}}},
      # Thermostat operating state
      {:thermostat_operating_state_get,
       {Commands.ThermostatOperatingStateGet,
        handler: {WaitReport, complete_report: :thermostat_operating_state_report}}},
      # Node provisioning
      {:node_provisioning_set, {Commands.NodeProvisioningSet, handler: AckResponse}},
      {:node_provisioning_get,
       {Commands.NodeProvisioningGet,
        handler: {WaitReport, complete_report: :node_provisioning_report}}},
      {:node_provisioning_delete, {Commands.NodeProvisioningDelete, handler: AckResponse}},
      {:node_provisioning_list_iteration_get,
       {Commands.NodeProvisioningListIterationGet,
        handler: {WaitReport, complete_report: :node_provisioning_list_iteration_report}}},
      # Supervision
      {:supervision_get,
       {Commands.SupervisionGet, handler: {WaitReport, complete_report: :supervision_report}}}
    ]

    defmacro __before_compile__(_) do
      lookup =
        for {command_class, spec} <- @table do
          quote location: :keep do
            def lookup(unquote(command_class)), do: unquote(spec)
          end
        end

      quote location: :keep do
        @doc """
        Look up the Z-Wave command module and default Grizzly command options via the
        command name
        """
        @spec lookup(Grizzly.command()) :: {module(), [Grizzly.command_opt()]}
        unquote(lookup)

        def lookup(command_class) do
          raise ArgumentError, """
          The command #{inspect(command_class)} you are trying to send is not supported
          """
        end
      end
    end
  end

  @before_compile Generate

  @doc """
  Get the handler spec for the command
  """
  @spec handler(Grizzly.command()) :: module() | {module(), args :: list()}
  def handler(command_name) do
    {_, opts} = lookup(command_name)

    Keyword.fetch!(opts, :handler)
  end
end
