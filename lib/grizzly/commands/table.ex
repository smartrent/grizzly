defmodule Grizzly.Commands.Table do
  @moduledoc """
  Lookup table for sendable Z-Wave commands.
  """

  alias Grizzly.CommandHandlers.{AckResponse, AggregateReport, WaitReport}
  alias Grizzly.ZWave.Commands

  @table %{
    default_set:
      {Commands.DefaultSet, handler: {WaitReport, complete_report: :default_set_complete}},

    # Noop
    no_operation: {Commands.NoOperation, handler: AckResponse},

    # Basic
    basic_get: {Commands.BasicGet, handler: {WaitReport, complete_report: :basic_report}},
    basic_set: {Commands.BasicSet, handler: AckResponse},

    # Battery
    battery_get: {Commands.BatteryGet, handler: {WaitReport, complete_report: :battery_report}},

    # Binary switches
    switch_binary_get:
      {Commands.SwitchBinaryGet, handler: {WaitReport, complete_report: :switch_binary_report}},
    switch_binary_set: {Commands.SwitchBinarySet, handler: AckResponse},

    # Configuration
    configuration_set: {Commands.ConfigurationSet, handler: AckResponse},
    configuration_get:
      {Commands.ConfigurationGet, handler: {WaitReport, complete_report: :configuration_report}},
    configuration_bulk_set: {Commands.ConfigurationBulkSet, handler: AckResponse},
    configuration_bulk_get:
      {Commands.ConfigurationBulkGet,
       handler:
         {AggregateReport, complete_report: :configuration_bulk_report, aggregate_param: :values}},
    configuration_properties_get:
      {Commands.ConfigurationPropertiesGet,
       handler: {WaitReport, complete_report: :configuration_properties_report}},
    configuration_name_get:
      {Commands.ConfigurationNameGet,
       handler:
         {AggregateReport, complete_report: :configuration_name_report, aggregate_param: :name}},
    configuration_info_get:
      {Commands.ConfigurationInfoGet,
       handler:
         {AggregateReport, complete_report: :configuration_info_report, aggregate_param: :info}},
    configuration_default_reset: {Commands.ConfigurationDefaultReset, handler: AckResponse},

    # Manufacturer specific
    manufacturer_specific_get:
      {Commands.ManufacturerSpecificGet,
       handler: {WaitReport, complete_report: :manufacturer_specific_report}},
    manufacturer_specific_device_specific_get:
      {Commands.ManufacturerSpecificDeviceSpecificGet,
       handler: {WaitReport, complete_report: :manufacturer_specific_device_specific_report}},

    # Multilevel switches
    switch_multilevel_get:
      {Commands.SwitchMultilevelGet,
       handler: {WaitReport, complete_report: :switch_multilevel_report}},
    switch_multilevel_set: {Commands.SwitchMultilevelSet, handler: AckResponse},
    switch_multilevel_start_level_change:
      {Commands.SwitchMultilevelStartLevelChange, handler: AckResponse},
    switch_multilevel_stop_level_change:
      {Commands.SwitchMultilevelStopLevelChange, handler: AckResponse},

    # Node management
    node_list_get:
      {Commands.NodeListGet, handler: {WaitReport, complete_report: :node_list_report}},
    failed_node_list_get:
      {Commands.FailedNodeListGet,
       handler: {WaitReport, complete_report: :failed_node_list_report}},
    node_add: {Commands.NodeAdd, handler: {WaitReport, complete_report: :node_add_status}},
    failed_node_replace:
      {Commands.FailedNodeReplace,
       handler: {WaitReport, complete_report: :failed_node_replace_status}},
    node_info_cached_get:
      {Commands.NodeInfoCachedGet,
       handler: {WaitReport, complete_report: :node_info_cached_report}},
    node_remove:
      {Commands.NodeRemove, handler: {WaitReport, complete_report: :node_remove_status}},
    failed_node_remove:
      {Commands.FailedNodeRemove,
       handler: {WaitReport, complete_report: :failed_node_remove_status}},
    learn_mode_set:
      {Commands.LearnModeSet, handler: {WaitReport, complete_report: :learn_mode_set_status}},
    network_update_request:
      {Commands.NetworkUpdateRequest,
       handler: {WaitReport, complete_report: :network_update_request_status}},
    network_management_multi_channel_end_point_get:
      {Commands.NetworkManagementMultiChannelEndPointGet,
       handler: {WaitReport, complete_report: :network_management_multi_channel_end_point_report}},
    network_management_multi_channel_capability_get:
      {Commands.NetworkManagementMultiChannelCapabilityGet,
       handler: {WaitReport, complete_report: :network_management_multi_channel_capability_report}},
    node_neighbor_update_request:
      {Commands.NodeNeighborUpdateRequest,
       handler: {WaitReport, complete_report: :node_neighbor_update_status}},
    node_information_send: {Commands.NodeInformationSend, handler: AckResponse},

    # S0
    # s0_commands_supported_get should technically use AggregateReport, but it would
    # require changes to AggregateReport. Few devices support so many CCs that they
    # don't all fit into one frame.
    s0_nonce_get: {Commands.S0NonceGet, handler: {WaitReport, complete_report: :s0_nonce_report}},
    s0_network_key_set:
      {Commands.S0NetworkKeySet, handler: {WaitReport, complete_report: :s0_network_key_verify}},
    s0_security_scheme_get:
      {Commands.S0SecuritySchemeGet,
       handler: {WaitReport, complete_report: :s0_security_scheme_report}},
    s0_security_scheme_inherit:
      {Commands.S0SecuritySchemeInherit,
       handler: {WaitReport, complete_report: :s0_security_scheme_report}},
    s0_commands_supported_get:
      {Commands.S0CommandsSupportedGet,
       handler: {WaitReport, complete_report: :s0_commands_supported_report}},
    s0_message_encapsulation: {Commands.S0MessageEncapsulation, handler: AckResponse},

    # S2
    s2_kex_get:
      {Commands.S2KexGet,
       handler: {WaitReport, complete_report: :s2_kex_report, supports_supervision?: false}},
    s2_kex_set:
      {Commands.S2KexSet,
       handler: {WaitReport, complete_report: :s2_kex_report, supports_supervision?: false}},
    s2_kex_fail: {Commands.S2KexFail, handler: {AckResponse, supports_supervision?: false}},
    s2_kex_report: {Commands.S2KexReport, handler: {AckResponse, supports_supervision?: false}},
    s2_public_key_report:
      {Commands.S2PublicKeyReport, handler: {AckResponse, supports_supervision?: false}},
    s2_network_key_get:
      {Commands.S2NetworkKeyGet,
       handler:
         {WaitReport, complete_report: :s2_network_key_report, supports_supervision?: false}},
    s2_network_key_report:
      {Commands.S2NetworkKeyReport, handler: {AckResponse, supports_supervision?: false}},
    s2_network_key_verify:
      {Commands.S2NetworkKeyVerify, handler: {AckResponse, supports_supervision?: false}},
    s2_transfer_end:
      {Commands.S2TransferEnd, handler: {AckResponse, supports_supervision?: false}},
    s2_commands_supported_get:
      {Commands.S2CommandsSupportedGet,
       handler: {WaitReport, complete_report: :s2_commands_supported_report}},

    # DSKs
    node_add_keys_set:
      {Commands.NodeAddKeysSet, handler: {AckResponse, [supports_supervision?: false]}},
    node_add_dsk_set:
      {Commands.NodeAddDSKSet, handler: {AckResponse, [supports_supervision?: false]}},
    dsk_get: {Commands.DSKGet, handler: {WaitReport, complete_report: :dsk_report}},

    # Door Lock
    door_lock_operation_set: {Commands.DoorLockOperationSet, handler: AckResponse},
    door_lock_operation_get:
      {Commands.DoorLockOperationGet,
       handler: {WaitReport, complete_report: :door_lock_operation_report}},
    door_lock_configuration_set: {Commands.DoorLockConfigurationSet, handler: AckResponse},
    door_lock_configuration_get:
      {Commands.DoorLockConfigurationGet,
       handler: {WaitReport, complete_report: :door_lock_configuration_report}},
    door_lock_capabilities_get:
      {Commands.DoorLockCapabilitiesGet,
       handler: {WaitReport, complete_report: :door_lock_capabilities_report}},

    # Associations
    association_set: {Commands.AssociationSet, handler: AckResponse},
    association_get:
      {Commands.AssociationGet,
       handler: {AggregateReport, complete_report: :association_report, aggregate_param: :nodes}},
    association_remove: {Commands.AssociationRemove, handler: AckResponse},
    association_groupings_get:
      {Commands.AssociationGroupingsGet,
       handler: {WaitReport, complete_report: :association_groupings_report}},
    association_specific_group_get:
      {Commands.AssociationSpecificGroupGet,
       handler: {WaitReport, complete_report: :association_specific_group_report}},

    # Multi Channel Associations
    multi_channel_association_set: {Commands.MultiChannelAssociationSet, handler: AckResponse},
    multi_channel_association_get:
      {Commands.MultiChannelAssociationGet,
       handler:
         {AggregateReport,
          complete_report: :multi_channel_association_report, aggregate_param: :nodes}},
    multi_channel_association_remove:
      {Commands.MultiChannelAssociationRemove, handler: AckResponse},
    multi_channel_association_groupings_get:
      {Commands.MultiChannelAssociationGroupingsGet,
       handler: {WaitReport, complete_report: :multi_channel_association_groupings_report}},

    # Association Group Info
    association_group_name_get:
      {Commands.AssociationGroupNameGet,
       handler: {WaitReport, complete_report: :association_group_name_report}},
    association_group_info_get:
      {Commands.AssociationGroupInfoGet,
       handler: {WaitReport, complete_report: :association_group_info_report}},
    association_group_command_list_get:
      {Commands.AssociationGroupCommandListGet,
       handler: {WaitReport, complete_report: :association_group_command_list_report}},

    # Keep alive
    keep_alive: {Commands.ZIPKeepAlive, handler: AckResponse},

    # Version
    version_get: {Commands.VersionGet, handler: {WaitReport, complete_report: :version_report}},
    version_capabilities_get:
      {Commands.VersionCapabilitiesGet,
       handler: {WaitReport, complete_report: :version_capabilities_report}},
    version_zwave_software_get:
      {Commands.VersionZWaveSoftwareGet,
       handler: {WaitReport, complete_report: :version_zwave_software_report}},
    version_command_class_get:
      {Commands.VersionCommandClassGet,
       handler: {WaitReport, complete_report: :version_command_class_report}},
    # Firmware update metadata
    firmware_md_get:
      {Commands.FirmwareMDGet, handler: {WaitReport, complete_report: :firmware_md_report}},
    firmware_update_md_request_get:
      {Commands.FirmwareUpdateMDRequestGet,
       handler: {WaitReport, complete_report: :firmware_update_md_request_report}},
    firmware_update_md_report: {Commands.FirmwareUpdateMDReport, handler: AckResponse},
    firmware_update_activation_set:
      {Commands.FirmwareUpdateActivationSet,
       handler: {WaitReport, complete_report: :firmware_update_activation_report}},

    # Wake up
    wake_up_interval_get:
      {Commands.WakeUpIntervalGet,
       handler: {WaitReport, complete_report: :wake_up_interval_report}},
    wake_up_interval_set: {Commands.WakeUpIntervalSet, handler: AckResponse},
    wake_up_no_more_information: {Commands.WakeUpNoMoreInformation, handler: AckResponse},
    wake_up_interval_capabilities_get:
      {Commands.WakeUpIntervalCapabilitiesGet,
       handler: {WaitReport, complete_report: :wake_up_interval_capabilities_report}},

    # Sensor Multilevel
    sensor_multilevel_get:
      {Commands.SensorMultilevelGet,
       handler: {WaitReport, complete_report: :sensor_multilevel_report}},
    sensor_multilevel_supported_sensor_get:
      {Commands.SensorMultilevelSupportedSensorGet,
       handler: {WaitReport, complete_report: :sensor_multilevel_supported_sensor_report}},
    sensor_multilevel_supported_scale_get:
      {Commands.SensorMultilevelSupportedScaleGet,
       handler: {WaitReport, complete_report: :sensor_multilevel_supported_scale_report}},

    # User code
    user_code_set: {Commands.UserCodeSet, handler: AckResponse},
    user_code_get:
      {Commands.UserCodeGet, handler: {WaitReport, complete_report: :user_code_report}},
    user_code_users_number_get:
      {Commands.UserCodeUsersNumberGet,
       handler: {WaitReport, complete_report: :user_code_users_number_report}},
    user_code_capabilities_get:
      {Commands.UserCodeCapabilitiesGet,
       handler: {WaitReport, complete_report: :user_code_capabilities_report}},
    user_code_checksum_get:
      {Commands.UserCodeChecksumGet,
       handler: {WaitReport, complete_report: :user_code_checksum_report}},
    extended_user_code_set: {Commands.ExtendedUserCodeSet, handler: AckResponse},
    extended_user_code_get:
      {Commands.ExtendedUserCodeGet,
       handler: {WaitReport, complete_report: :extended_user_code_report}},
    user_code_keypad_mode_set: {Commands.UserCodeKeypadModeSet, handler: AckResponse},
    user_code_keypad_mode_get:
      {Commands.UserCodeKeypadModeGet,
       handler: {WaitReport, complete_report: :user_code_keypad_mode_report}},
    admin_code_set: {Commands.AdminCodeSet, handler: AckResponse},
    admin_code_get:
      {Commands.AdminCodeGet, handler: {WaitReport, complete_report: :admin_code_report}},

    # Meter
    meter_get: {Commands.MeterGet, handler: {WaitReport, complete_report: :meter_report}},
    meter_supported_get:
      {Commands.MeterSupportedGet,
       handler: {WaitReport, complete_report: :meter_supported_report}},
    meter_reset: {Commands.MeterReset, handler: AckResponse},

    # Thermostat mode
    thermostat_mode_set: {Commands.ThermostatModeSet, handler: AckResponse},
    thermostat_mode_get:
      {Commands.ThermostatModeGet,
       handler: {WaitReport, complete_report: :thermostat_mode_report}},
    thermostat_mode_supported_get:
      {Commands.ThermostatModeSupportedGet,
       handler: {WaitReport, complete_report: :thermostat_mode_supported_report}},

    # Thermostat setpoint
    thermostat_setpoint_set: {Commands.ThermostatSetpointSet, handler: AckResponse},
    thermostat_setpoint_get:
      {Commands.ThermostatSetpointGet,
       handler: {WaitReport, complete_report: :thermostat_setpoint_report}},
    thermostat_setpoint_supported_get:
      {Commands.ThermostatSetpointSupportedGet,
       handler: {WaitReport, complete_report: :thermostat_setpoint_supported_report}},
    thermostat_setpoint_capabilities_get:
      {Commands.ThermostatSetpointCapabilitiesGet,
       handler: {WaitReport, complete_report: :thermostat_setpoint_capabilities_report}},

    # Thermostat fan mode
    thermostat_fan_mode_set: {Commands.ThermostatFanModeSet, handler: AckResponse},
    thermostat_fan_mode_get:
      {Commands.ThermostatFanModeGet,
       handler: {WaitReport, complete_report: :thermostat_fan_mode_report}},
    thermostat_fan_mode_supported_get:
      {Commands.ThermostatFanModeSupportedGet,
       handler: {WaitReport, complete_report: :thermostat_fan_mode_supported_report}},

    # Thermostat fan state
    thermostat_fan_state_get:
      {Commands.ThermostatFanStateGet,
       handler: {WaitReport, complete_report: :thermostat_fan_state_report}},

    # Thermostat setback
    thermostat_setback_set: {Commands.ThermostatSetbackSet, handler: AckResponse},
    thermostat_setback_get:
      {Commands.ThermostatSetbackGet,
       handler: {WaitReport, complete_report: :thermostat_setback_report}},

    # Thermostat operating state
    thermostat_operating_state_get:
      {Commands.ThermostatOperatingStateGet,
       handler: {WaitReport, complete_report: :thermostat_operating_state_report}},

    # Node provisioning
    node_provisioning_set: {Commands.NodeProvisioningSet, handler: AckResponse},
    node_provisioning_get:
      {Commands.NodeProvisioningGet,
       handler: {WaitReport, complete_report: :node_provisioning_report}},
    node_provisioning_delete: {Commands.NodeProvisioningDelete, handler: AckResponse},
    node_provisioning_list_iteration_get:
      {Commands.NodeProvisioningListIterationGet,
       handler: {WaitReport, complete_report: :node_provisioning_list_iteration_report}},

    # Supervision
    supervision_get:
      {Commands.SupervisionGet, handler: {WaitReport, complete_report: :supervision_report}},

    # Sensor binary
    sensor_binary_get:
      {Commands.SensorBinaryGet, handler: {WaitReport, complete_report: :sensor_binary_report}},
    sensor_binary_supported_sensor_get:
      {Commands.SensorBinarySupportedSensorGet,
       handler: {WaitReport, complete_report: :sensor_binary_supported_sensor_report}},

    # Multi Channel
    multi_channel_endpoint_get:
      {Commands.MultiChannelEndpointGet,
       handler: {WaitReport, complete_report: :multi_channel_endpoint_report}},
    multi_channel_capability_get:
      {Commands.MultiChannelCapabilityGet,
       handler: {WaitReport, complete_report: :multi_channel_capability_report}},
    multi_channel_endpoint_find:
      {Commands.MultiChannelEndpointFind,
       handler:
         {AggregateReport,
          complete_report: :multi_channel_endpoint_find_report, aggregate_param: :end_points}},
    multi_channel_aggregated_members_get:
      {Commands.MultiChannelAggregatedMembersGet,
       handler: {WaitReport, complete_report: :multi_channel_aggregated_members_report}},
    multi_channel_get_command_encapsulation:
      {Commands.MultiChannelCommandEncapsulation, handler: {WaitReport, complete_report: :any}},
    multi_channel_command_encapsulation:
      {Commands.MultiChannelCommandEncapsulation, handler: AckResponse},

    # Application
    application_node_info_get:
      {Commands.ApplicationNodeInfoGet,
       handler: {WaitReport, complete_report: :application_node_info_report}},

    # Node Naming and Location
    node_name_get:
      {Commands.NodeNameGet, handler: {WaitReport, complete_report: :node_name_report}},
    node_name_set: {Commands.NodeNameSet, handler: AckResponse},
    node_location_get:
      {Commands.NodeLocationGet, handler: {WaitReport, complete_report: :node_location_report}},
    node_location_set: {Commands.NodeLocationSet, handler: AckResponse},

    # Time parameters
    time_parameters_get:
      {Commands.TimeParametersGet,
       handler: {WaitReport, complete_report: :time_parameters_report}},
    time_parameters_set: {Commands.TimeParametersSet, handler: AckResponse},

    # Alarm
    alarm_get: {Commands.AlarmGet, handler: {WaitReport, complete_report: :alarm_report}},
    alarm_set: {Commands.AlarmSet, handler: AckResponse},
    alarm_type_supported_get:
      {Commands.AlarmTypeSupportedGet,
       handler: {WaitReport, complete_report: :alarm_type_supported_report}},
    alarm_event_supported_get:
      {Commands.AlarmEventSupportedGet,
       handler: {WaitReport, complete_report: :alarm_event_supported_report}},

    # Time
    time_get: {Commands.TimeGet, handler: {WaitReport, complete_report: :time_report}},
    date_get: {Commands.DateGet, handler: {WaitReport, complete_report: :date_report}},
    time_offset_get:
      {Commands.TimeOffsetGet, handler: {WaitReport, complete_report: :time_offset_report}},
    time_offset_set: {Commands.TimeOffsetSet, handler: AckResponse},

    # Indicator
    indicator_get:
      {Commands.IndicatorGet, handler: {WaitReport, complete_report: :indicator_report}},
    indicator_set: {Commands.IndicatorSet, handler: AckResponse},
    indicator_supported_get:
      {Commands.IndicatorSupportedGet,
       handler: {WaitReport, complete_report: :indicator_supported_report}},
    indicator_description_get:
      {Commands.IndicatorDescriptionGet,
       handler: {WaitReport, complete_report: :indicator_description_report}},

    # Antitheft
    antitheft_get:
      {Commands.AntitheftGet, handler: {WaitReport, complete_report: :antitheft_report}},
    antitheft_set: {Commands.AntitheftSet, handler: AckResponse},

    # Antitheft unlock
    antitheft_unlock_get:
      {Commands.AntitheftUnlockGet,
       handler: {WaitReport, complete_report: :antitheft_unlock_report}},
    antitheft_unlock_set: {Commands.AntitheftUnlockSet, handler: AckResponse},

    # Central scene
    central_scene_supported_get:
      {Commands.CentralSceneSupportedGet,
       handler: {WaitReport, complete_report: :central_scene_supported_report}},
    central_scene_configuration_get:
      {Commands.CentralSceneConfigurationGet,
       handler: {WaitReport, complete_report: :central_scene_configuration_report}},
    central_scene_configuration_set:
      {Commands.CentralSceneConfigurationSet, handler: AckResponse},

    # Scene actuator configuration
    scene_actuator_conf_get:
      {Commands.SceneActuatorConfGet,
       handler: {WaitReport, complete_report: :scene_actuator_conf_report}},
    scene_actuator_conf_set: {Commands.SceneActuatorConfSet, handler: AckResponse},

    # Scene activation
    scene_activation_set: {Commands.SceneActivationSet, handler: AckResponse},

    # Powerlevel
    powerlevel_get:
      {Commands.PowerlevelGet, handler: {WaitReport, complete_report: :powerlevel_report}},
    powerlevel_set: {Commands.PowerlevelSet, handler: AckResponse},
    powerlevel_test_node_get:
      {Commands.PowerlevelTestNodeGet,
       handler: {WaitReport, complete_report: :powerlevel_test_node_report}},
    powerlevel_test_node_set: {Commands.PowerlevelTestNodeSet, handler: AckResponse},
    device_reset_locally_notification:
      {Commands.DeviceResetLocallyNotification, handler: AckResponse},

    # Clock
    clock_get: {Commands.ClockGet, handler: {WaitReport, complete_report: :clock_report}},
    clock_set: {Commands.ClockSet, handler: AckResponse},

    # Network Management Installation Maintenance
    priority_route_set: {Commands.PriorityRouteSet, handler: AckResponse},
    priority_route_get:
      {Commands.PriorityRouteGet, handler: {WaitReport, complete_report: :priority_route_report}},
    statistics_get:
      {Commands.StatisticsGet, handler: {WaitReport, complete_report: :statistics_report}},
    statistics_clear: {Commands.StatisticsClear, handler: AckResponse},
    rssi_get: {Commands.RssiGet, handler: {WaitReport, complete_report: :rssi_report}},
    zwave_long_range_channel_set: {Commands.ZWaveLongRangeChannelSet, handler: AckResponse},
    zwave_long_range_channel_get:
      {Commands.ZWaveLongRangeChannelGet,
       handler: {WaitReport, complete_report: :zwave_long_range_channel_report}},

    # Zwaveplus Info
    zwaveplus_info_get:
      {Commands.ZwaveplusInfoGet, handler: {WaitReport, complete_report: :zwaveplus_info_report}},

    # Schedule Entry Lock
    schedule_entry_lock_week_day_get:
      {Commands.ScheduleEntryLockWeekDayGet,
       handler: {WaitReport, complete_report: :schedule_entry_lock_week_day_report}},
    schedule_entry_lock_year_day_get:
      {Commands.ScheduleEntryLockYearDayGet,
       handler: {WaitReport, complete_report: :schedule_entry_lock_year_day_report}},
    schedule_entry_type_supported_get:
      {Commands.ScheduleEntryTypeSupportedGet,
       handler: {WaitReport, complete_report: :schedule_entry_type_supported_report}},
    schedule_entry_lock_time_offset_get:
      {Commands.ScheduleEntryLockTimeOffsetGet,
       handler: {WaitReport, complete_report: :schedule_entry_lock_time_offset_report}},
    schedule_entry_lock_daily_repeating_get:
      {Commands.ScheduleEntryLockDailyRepeatingGet,
       handler: {WaitReport, complete_report: :schedule_entry_lock_daily_repeating_report}},
    schedule_entry_lock_enable_set: {Commands.ScheduleEntryLockEnableSet, handler: AckResponse},
    schedule_entry_lock_enable_all_set:
      {Commands.ScheduleEntryLockEnableAllSet, handler: AckResponse},
    schedule_entry_lock_week_day_set:
      {Commands.ScheduleEntryLockWeekDaySet, handler: AckResponse},
    schedule_entry_lock_year_day_set:
      {Commands.ScheduleEntryLockYearDaySet, handler: AckResponse},
    schedule_entry_lock_time_offset_set:
      {Commands.ScheduleEntryLockTimeOffsetSet, handler: AckResponse},
    schedule_entry_lock_daily_repeating_set:
      {Commands.ScheduleEntryLockDailyRepeatingSet, handler: AckResponse},

    # Barrier Operator
    barrier_operator_get:
      {Commands.BarrierOperatorGet,
       handler: {WaitReport, complete_report: :barrier_operator_report}},
    barrier_operator_set: {Commands.BarrierOperatorSet, handler: AckResponse},
    barrier_operator_signal_supported_get:
      {Commands.BarrierOperatorSignalSupportedGet,
       handler: {WaitReport, complete_report: :barrier_operator_signal_supported_report}},
    barrier_operator_signal_get:
      {Commands.BarrierOperatorSignalGet,
       handler: {WaitReport, complete_report: :barrier_operator_signal_report}},
    barrier_operator_signal_set: {Commands.BarrierOperatorSignalSet, handler: AckResponse},

    # Window Covering
    window_covering_supported_get:
      {Commands.WindowCoveringSupportedGet,
       handler: {WaitReport, complete_report: :window_covering_supported_report}},
    window_covering_get:
      {Commands.WindowCoveringGet,
       handler: {WaitReport, complete_report: :window_covering_report}},
    window_covering_set: {Commands.WindowCoveringSet, handler: AckResponse},
    window_covering_start_level_change:
      {Commands.WindowCoveringStartLevelChange, handler: AckResponse},
    window_covering_stop_level_change:
      {Commands.WindowCoveringStopLevelChange, handler: AckResponse},

    # Mailbox
    mailbox_configuration_get:
      {Commands.MailboxConfigurationGet,
       handler: {WaitReport, complete_report: :mailbox_configuration_report}},
    mailbox_configuration_set: {Commands.MailboxConfigurationSet, handler: AckResponse},
    mailbox_configuration_report: {Commands.MailboxConfigurationReport, handler: AckResponse},
    # Mailbox Queue will sometimes require the `WaitReport` handler (such as with
    # the pop operation). It is up to the caller to use the correct handler.
    mailbox_queue: {Commands.MailboxQueue, handler: AckResponse},

    # Sound Switch
    sound_switch_tones_number_get:
      {Commands.SoundSwitchTonesNumberGet,
       handler: {WaitReport, complete_report: :sound_switch_tones_number_report}},
    sound_switch_tone_info_get:
      {Commands.SoundSwitchToneInfoGet,
       handler: {WaitReport, complete_report: :sound_switch_tone_info_report}},
    sound_switch_configuration_set: {Commands.SoundSwitchConfigurationSet, handler: AckResponse},
    sound_switch_configuration_get:
      {Commands.SoundSwitchConfigurationGet,
       handler: {WaitReport, complete_report: :sound_switch_configuration_report}},
    sound_switch_tone_play_set: {Commands.SoundSwitchTonePlaySet, handler: AckResponse},
    sound_switch_tone_play_get:
      {Commands.SoundSwitchTonePlayGet,
       handler: {WaitReport, complete_report: :sound_switch_tone_play_report}},

    # Humidity Control Setpoint
    humidity_control_setpoint_set: {Commands.HumidityControlSetpointSet, handler: AckResponse},
    humidity_control_setpoint_get:
      {Commands.HumidityControlSetpointGet,
       handler: {WaitReport, complete_report: :humidity_control_setpoint_report}},
    humidity_control_setpoint_supported_get:
      {Commands.HumidityControlSetpointSupportedGet,
       handler: {WaitReport, complete_report: :humidity_control_setpoint_supported_report}},
    humidity_control_setpoint_scale_supported_get:
      {Commands.HumidityControlSetpointScaleSupportedGet,
       handler: {WaitReport, complete_report: :humidity_control_setpoint_scale_supported_report}},
    humidity_control_setpoint_capabilities_get:
      {Commands.HumidityControlSetpointCapabilitiesGet,
       handler: {WaitReport, complete_report: :humidity_control_setpoint_capabilities_report}},

    # Humidity Control Mode
    humidity_control_mode_set: {Commands.HumidityControlModeSet, handler: AckResponse},
    humidity_control_mode_get:
      {Commands.HumidityControlModeGet,
       handler: {WaitReport, complete_report: :humidity_control_mode_report}},
    humidity_control_mode_supported_get:
      {Commands.HumidityControlModeSupportedGet,
       handler: {WaitReport, complete_report: :humidity_control_mode_supported_report}},

    # Humidity Control Operating State
    humidity_control_operating_state_get:
      {Commands.HumidityControlOperatingStateGet,
       handler: {WaitReport, complete_report: :humidity_control_operating_state_report}},

    # User Credential
    user_capabilities_get:
      {Commands.UserCapabilitiesGet,
       handler: {WaitReport, complete_report: :user_capabilities_report}},
    credential_capabilities_get:
      {Commands.CredentialCapabilitiesGet,
       handler: {WaitReport, complete_report: :credential_capabilities_report}},
    user_set: {Commands.UserSet, handler: AckResponse},
    user_get: {Commands.UserGet, handler: {WaitReport, complete_report: :user_report}},
    credential_set: {Commands.CredentialSet, handler: AckResponse},
    credential_get:
      {Commands.CredentialGet, handler: {WaitReport, complete_report: :credential_report}},
    credential_learn_start: {Commands.CredentialLearnStart, handler: AckResponse},
    credential_learn_cancel: {Commands.CredentialLearnCancel, handler: AckResponse},
    user_credential_association_set:
      {Commands.UserCredentialAssociationSet, handler: AckResponse},
    all_users_checksum_get:
      {Commands.AllUsersChecksumGet,
       handler: {WaitReport, complete_report: :all_users_checksum_report}},
    user_checksum_get:
      {Commands.UserChecksumGet, handler: {WaitReport, complete_report: :user_checksum_report}},
    credential_checksum_get:
      {Commands.CredentialChecksumGet,
       handler: {WaitReport, complete_report: :credential_checksum_report}},
    admin_pin_code_set: {Commands.AdminPinCodeSet, handler: AckResponse},
    admin_pin_code_get:
      {Commands.AdminPinCodeGet, handler: {WaitReport, complete_report: :admin_pin_code_report}}
  }

  @spec lookup(Grizzly.command()) :: {module(), [Grizzly.command_opt()]}
  def lookup(command_name) do
    case Map.fetch(@table, command_name) do
      {:ok, handler_spec} ->
        handler_spec

      :error ->
        raise ArgumentError, """
        The command #{inspect(command_name)} you are trying to send is not supported
        """
    end
  end

  @doc """
  Get the handler spec for the command
  """
  @spec handler(Grizzly.command()) :: Grizzly.handler_spec()
  def handler(command_name) do
    {_, opts} = lookup(command_name)

    opts
    |> Keyword.fetch!(:handler)
    |> format_handler_spec()
  end

  @doc """
  Whether the command can be supervised (only commands that use the AckResponse
  handler can be supervised).
  """
  @spec supports_supervision?(Grizzly.command()) :: boolean()
  def supports_supervision?(command_name) do
    {module, default_opts} = handler(command_name)
    module == AckResponse && default_opts[:supports_supervision?] != false
  end

  @spec format_handler_spec(module() | Grizzly.handler_spec()) :: Grizzly.handler_spec()
  def format_handler_spec({_handler, _args} = spec), do: spec
  def format_handler_spec(handler), do: {handler, []}

  def dump(), do: @table
end
