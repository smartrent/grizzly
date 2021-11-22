defmodule Grizzly.Commands.Table do
  @moduledoc false

  # look up support for supported command classes and their default Grizzly
  # runtime related options. This where Grizzly and Z-Wave meet in regards to
  # out going commands

  defmodule Generate do
    @moduledoc false
    alias Grizzly.CommandHandlers.{AckResponse, AggregateReport, WaitReport}

    alias Grizzly.ZWave.Commands

    @table [
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
      # Configuration
      {:configuration_set, {Commands.ConfigurationSet, handler: AckResponse}},
      {:configuration_get,
       {Commands.ConfigurationGet, handler: {WaitReport, complete_report: :configuration_report}}},
      {:configuration_bulk_set, {Commands.ConfigurationBulkSet, handler: AckResponse}},
      {:configuration_bulk_get,
       {Commands.ConfigurationBulkGet,
        handler:
          {AggregateReport, complete_report: :configuration_bulk_report, aggregate_param: :values}}},
      {:configuration_properties_get,
       {Commands.ConfigurationPropertiesGet,
        handler: {WaitReport, complete_report: :configuration_properties_report}}},
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
      {:failed_node_list_get,
       {Commands.FailedNodeListGet,
        handler: {WaitReport, complete_report: :failed_node_list_report}}},
      {:node_add, {Commands.NodeAdd, handler: {WaitReport, complete_report: :node_add_status}}},
      {:node_info_cached_get,
       {Commands.NodeInfoCachedGet,
        handler: {WaitReport, complete_report: :node_info_cache_report}}},
      {:node_remove,
       {Commands.NodeRemove, handler: {WaitReport, complete_report: :node_remove_status}}},
      {:failed_node_remove,
       {Commands.FailedNodeRemove,
        handler: {WaitReport, complete_report: :failed_node_remove_status}}},
      {:learn_mode_set,
       {Commands.LearnModeSet, handler: {WaitReport, complete_report: :learn_mode_set_status}}},
      {:network_update_request,
       {Commands.NetworkUpdateRequest,
        handler: {WaitReport, complete_report: :network_update_request_status}}},
      {:network_management_multi_channel_end_point_get,
       {Commands.NetworkManagementMultiChannelEndPointGet,
        handler: {WaitReport, complete_report: :network_management_multi_channel_end_point_report}}},
      {:network_management_multi_channel_capability_get,
       {Commands.NetworkManagementMultiChannelCapabilityGet,
        handler:
          {WaitReport, complete_report: :network_management_multi_channel_capability_report}}},

      # DSKs
      {:node_add_keys_set, {Commands.NodeAddKeysSet, handler: AckResponse}},
      {:node_add_dsk_set, {Commands.NodeAddDSKSet, handler: AckResponse}},
      {:dsk_get, {Commands.DSKGet, handler: {WaitReport, complete_report: :dsk_report}}},
      # Door Lock
      {:door_lock_operation_set, {Commands.DoorLockOperationSet, handler: AckResponse}},
      {:door_lock_operation_get,
       {Commands.DoorLockOperationGet,
        handler: {WaitReport, complete_report: :door_lock_operation_report}}},
      {:door_lock_configuration_set, {Commands.DoorLockConfigurationSet, handler: AckResponse}},
      {:door_lock_configuration_get,
       {Commands.DoorLockConfigurationGet,
        handler: {WaitReport, complete_report: :door_lock_configuration_report}}},
      {:door_lock_capabilities_get,
       {Commands.DoorLockCapabilitiesGet,
        handler: {WaitReport, complete_report: :door_lock_capabilities_report}}},

      # Associations
      {:association_set, {Commands.AssociationSet, handler: AckResponse}},
      {:association_get,
       {Commands.AssociationGet,
        handler: {AggregateReport, complete_report: :association_report, aggregate_param: :nodes}}},
      {:association_remove, {Commands.AssociationRemove, handler: AckResponse}},
      {:association_groupings_get,
       {Commands.AssociationGroupingsGet,
        handler: {WaitReport, complete_report: :association_groupings_report}}},
      {:association_specific_group_get,
       {Commands.AssociationSpecificGroupGet,
        handler: {WaitReport, complete_report: :association_specific_group_report}}},
      # Multi Channel Associations
      {:multi_channel_association_set,
       {Commands.MultiChannelAssociationSet, handler: AckResponse}},
      {:multi_channel_association_get,
       {Commands.MultiChannelAssociationGet,
        handler:
          {AggregateReport,
           complete_report: :multi_channel_association_report, aggregate_param: :nodes}}},
      {:multi_channel_association_remove,
       {Commands.MultiChannelAssociationRemove, handler: AckResponse}},
      {:multi_channel_association_groupings_get,
       {Commands.MultiChannelAssociationGroupingsGet,
        handler: {WaitReport, complete_report: :multi_channel_association_groupings_report}}},
      # Association Group Info
      {:association_group_name_get,
       {Commands.AssociationGroupNameGet,
        handler: {WaitReport, complete_report: :association_group_name_report}}},
      {:association_group_info_get,
       {Commands.AssociationGroupInfoGet,
        handler: {WaitReport, complete_report: :association_group_info_report}}},
      {:association_group_command_list_get,
       {Commands.AssociationGroupCommandListGet,
        handler: {WaitReport, complete_report: :association_group_command_list_report}}},
      # Keep alive
      {:keep_alive, {Commands.ZIPKeepAlive, handler: AckResponse}},
      # Version
      {:version_get,
       {Commands.VersionGet, handler: {WaitReport, complete_report: :version_report}}},
      {:version_command_class_get,
       {Commands.VersionCommandClassGet,
        handler: {WaitReport, complete_report: :version_command_class_report}}},
      # Firmware update metadata
      {:firmware_md_get,
       {Commands.FirmwareMDGet, handler: {WaitReport, complete_report: :firmware_md_report}}},
      {:firmware_update_md_request_get,
       {Commands.FirmwareUpdateMDRequestGet,
        handler: {WaitReport, complete_report: :firmware_update_md_request_report}}},
      {:firmware_update_md_report, {Commands.FirmwareUpdateMDReport, handler: AckResponse}},
      {:firmware_update_activation_set,
       {Commands.FirmwareUpdateActivationSet,
        handler: {WaitReport, complete_report: :firmware_update_activation_report}}},
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
      {:thermostat_mode_supported_get,
       {Commands.ThermostatModeSupportedGet,
        handler: {WaitReport, complete_report: :thermostat_mode_supported_report}}},
      # Thermostat setpoint
      {:thermostat_setpoint_set, {Commands.ThermostatSetpointSet, handler: AckResponse}},
      {:thermostat_setpoint_get,
       {Commands.ThermostatSetpointGet,
        handler: {WaitReport, complete_report: :thermostat_setpoint_report}}},
      {:thermostat_setpoint_supported_get,
       {Commands.ThermostatSetpointSupportedGet,
        handler: {WaitReport, complete_report: :thermostat_setpoint_supported_report}}},
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
       {Commands.SupervisionGet, handler: {WaitReport, complete_report: :supervision_report}}},
      # Sensor binary
      {:sensor_binary_get,
       {Commands.SensorBinaryGet, handler: {WaitReport, complete_report: :sensor_binary_report}}},
      # Multi Channel
      {:multi_channel_endpoint_get,
       {Commands.MultiChannelEndpointGet,
        handler: {WaitReport, complete_report: :multi_channel_endpoint_report}}},
      {:multi_channel_capability_get,
       {Commands.MultiChannelCapabilityGet,
        handler: {WaitReport, complete_report: :multi_channel_capability_report}}},
      {:multi_channel_endpoint_find,
       {Commands.MultiChannelEndpointFind,
        handler:
          {AggregateReport,
           complete_report: :multi_channel_endpoint_find_report, aggregate_param: :end_points}}},
      {:multi_channel_aggregated_members_get,
       {Commands.MultiChannelAggregatedMembersGet,
        handler: {WaitReport, complete_report: :multi_channel_aggregated_members_report}}},
      {:multi_channel_get_command_encapsulation,
       {Commands.MultiChannelCommandEncapsulation, handler: {WaitReport, complete_report: :any}}},
      {:multi_channel_command_encapsulation,
       {Commands.MultiChannelCommandEncapsulation, handler: AckResponse}},
      #
      {:application_node_info_get,
       {Commands.ApplicationNodeInfoGet,
        handler: {WaitReport, complete_report: :application_node_info_report}}},
      # Node Naming and Location
      {:node_name_get,
       {Commands.NodeNameGet, handler: {WaitReport, complete_report: :node_name_report}}},
      {:node_name_set, {Commands.NodeNameSet, handler: AckResponse}},
      {:node_location_get,
       {Commands.NodeLocationGet, handler: {WaitReport, complete_report: :node_location_report}}},
      {:node_location_set, {Commands.NodeLocationSet, handler: AckResponse}},
      # Time parameters
      {:time_parameters_get,
       {Commands.TimeParametersGet,
        handler: {WaitReport, complete_report: :time_parameters_report}}},
      {:time_parameters_set, {Commands.TimeParametersSet, handler: AckResponse}},
      # Alarm
      {:alarm_get, {Commands.AlarmGet, handler: {WaitReport, complete_report: :alarm_report}}},
      {:alarm_set, {Commands.AlarmSet, handler: AckResponse}},
      {:alarm_type_supported_get,
       {Commands.AlarmTypeSupportedGet,
        handler: {WaitReport, complete_report: :alarm_type_supported_report}}},
      {:alarm_event_supported_get,
       {Commands.AlarmEventSupportedGet,
        handler: {WaitReport, complete_report: :alarm_event_supported_report}}},
      # Time
      {:time_get, {Commands.TimeGet, handler: {WaitReport, complete_report: :time_report}}},
      {:date_get, {Commands.DateGet, handler: {WaitReport, complete_report: :date_report}}},
      {:time_offset_get,
       {Commands.TimeOffsetGet, handler: {WaitReport, complete_report: :time_offset_report}}},
      {:time_offset_set, {Commands.TimeOffsetSet, handler: AckResponse}},
      # Indicator
      {:indicator_get,
       {Commands.IndicatorGet, handler: {WaitReport, complete_report: :indicator_report}}},
      {:indicator_set, {Commands.IndicatorSet, handler: AckResponse}},
      {:indicator_supported_get,
       {Commands.IndicatorSupportedGet,
        handler: {WaitReport, complete_report: :indicator_supported_report}}},
      {:indicator_description_get,
       {Commands.IndicatorSupportedGet,
        handler: {WaitReport, complete_report: :indicator_description_report}}},
      # Antitheft
      {:antitheft_get,
       {Commands.AntitheftGet, handler: {WaitReport, complete_report: :antitheft_report}}},
      {:antitheft_set, {Commands.AntitheftSet, handler: AckResponse}},
      # Antitheft unlock
      {:antitheft_unlock_get,
       {Commands.AntitheftUnlockGet,
        handler: {WaitReport, complete_report: :antitheft_unlock_report}}},
      {:antitheft_unlock_set, {Commands.AntitheftUnlockSet, handler: AckResponse}},
      # Central scene
      {:central_scene_supported_get,
       {Commands.CentralSceneSupportedGet,
        handler: {WaitReport, complete_report: :central_scene_supported_report}}},
      {:central_scene_configuration_get,
       {Commands.CentralSceneConfigurationGet,
        handler: {WaitReport, complete_report: :central_scene_configuration_report}}},
      # Scene actuator configuration
      {:scene_actuator_conf_get,
       {Commands.SceneActuatorConfGet,
        handler: {WaitReport, complete_report: :scene_actuator_conf_report}}},
      {:scene_actuator_conf_set, {Commands.SceneActuatorConfSet, handler: AckResponse}},
      # Scene activation
      {:scene_activation_set, {Commands.SceneActivationSet, handler: AckResponse}},
      # Powerlevel
      {:powerlevel_get,
       {Commands.PowerlevelGet, handler: {WaitReport, complete_report: :powerlevel_report}}},
      {:powerlevel_set, {Commands.PowerlevelSet, handler: AckResponse}},
      {:powerlevel_test_node_get,
       {Commands.PowerlevelTestNodeGet,
        handler: {WaitReport, complete_report: :powerlevel_test_node_report}}},
      {:powerlevel_test_node_set, {Commands.PowerlevelTestNodeSet, handler: AckResponse}},
      {:device_reset_locally_notification,
       {Commands.DeviceResetLocallyNotification, handler: AckResponse}},
      # Clock
      {:clock_get, {Commands.ClockGet, handler: {WaitReport, complete_report: :clock_report}}},
      {:clock_set, {Commands.ClockSet, handler: AckResponse}},
      # Network Management Installation Maintenance
      {:priority_route_get,
       {Commands.PriorityRouteGet, handler: {WaitReport, complete_report: :priorityRouteReport}}},
      {:statistics_get,
       {Commands.StatisticsGet, handler: {WaitReport, complete_report: :statistics_report}}},
      {:statistics_clear, {Commands.StatisticsGet, handler: AckResponse}},
      {:rssi_get, {Commands.RssiGet, handler: {WaitReport, complete_report: :rssi_report}}},
      {:zwave_long_range_channel_set, {Commands.ZWaveLongRangeChannelSet, handler: AckResponse}},
      {:zwave_long_range_channel_get,
       {Commands.ZWaveLongRangeChannelGet,
        handler: {WaitReport, complete_report: :zwave_long_range_channel_report}}},
      # Zwaveplus Info
      {:zwaveplus_info_get,
       {Commands.ZwaveplusInfoGet, handler: {WaitReport, complete_report: :zwaveplus_info_report}}},
      # Schedule Entry Lock
      {:schedule_entry_lock_week_day_get,
       {Commands.ScheduleEntryLockWeekDayGet,
        handler: {WaitReport, complete_report: :schedule_entry_lock_week_day_report}}},
      {:schedule_entry_lock_year_day_get,
       {Commands.ScheduleEntryLockYearDayGet,
        handler: {WaitReport, complete_report: :schedule_entry_lock_year_day_report}}},
      {:schedule_entry_type_supported_get,
       {Commands.ScheduleEntryTypeSupportedGet,
        handler: {WaitReport, complete_report: :schedule_entry_type_supported_report}}},
      {:schedule_entry_lock_time_offset_get,
       {Commands.ScheduleEntryLockTimeOffsetGet,
        handler: {WaitReport, complete_report: :schedule_entry_lock_time_offset_report}}},
      {:schedule_entry_lock_daily_repeating_get,
       {Commands.ScheduleEntryLockDailyRepeatingGet,
        handler: {WaitReport, complete_report: :schedule_entry_lock_daily_repeating_report}}},
      {:schedule_entry_lock_enable_set,
       {Commands.ScheduleEntryLockEnableSet, handler: AckResponse}},
      {:schedule_entry_lock_enable_all_set,
       {Commands.ScheduleEntryLockEnableAllSet, handler: AckResponse}},
      {:schedule_entry_lock_week_day_set,
       {Commands.ScheduleEntryLockWeekDaySet, handler: AckResponse}},
      {:schedule_entry_lock_year_day_set,
       {Commands.ScheduleEntryLockYearDaySet, handler: AckResponse}},
      {:schedule_entry_lock_time_offset_set,
       {Commands.ScheduleEntryLockTimeOffsetSet, handler: AckResponse}},
      {:schedule_entry_lock_daily_repeating_set,
       {Commands.ScheduleEntryLockDailyRepeatingSet, handler: AckResponse}}
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

        @doc """
        Dump all the contents of the table
        """
        def dump() do
          unquote(@table)
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
