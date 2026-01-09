defmodule Grizzly.ZWave.Commands do
  @moduledoc """
  Lookup table for sendable Z-Wave commands.
  """

  use Grizzly.ZWave.Macros

  alias Grizzly.Requests.Handlers.AggregateReport
  alias Grizzly.Requests.Handlers.WaitReport
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.Commands, as: Cmds
  alias Grizzly.ZWave.CommandSpec
  alias Grizzly.ZWave.DecodeError
  alias Grizzly.ZWave.ZWaveError

  @after_verify __MODULE__

  command_class :alarm do
    command :alarm_event_supported_get, 0x01
    command :alarm_event_supported_report, 0x02
    command :alarm_get, 0x04
    command :alarm_report, 0x05
    command :alarm_set, 0x06
    command :alarm_type_supported_get, 0x07, Cmds.GenericNoPayload
    command :alarm_type_supported_report, 0x08
  end

  command_class :antitheft do
    command :antitheft_set, 0x01
    command :antitheft_get, 0x02, Cmds.GenericNoPayload
    command :antitheft_report, 0x03
  end

  command_class :antitheft_unlock do
    command :antitheft_unlock_get, 0x01, Cmds.GenericNoPayload
    command :antitheft_unlock_report, 0x02
    command :antitheft_unlock_set, 0x03
  end

  command_class :application_status do
    command :application_busy, 0x01
    command :application_rejected_request, 0x02
  end

  command_class :association do
    command :association_set, 0x01
    command :association_get, 0x02, handler: {AggregateReport, aggregate_param: :nodes}
    command :association_report, 0x03, default_params: [reports_to_follow: 0]
    command :association_remove, 0x04
    command :association_groupings_get, 0x05, Cmds.GenericNoPayload
    command :association_groupings_report, 0x06
    command :association_specific_group_get, 0x0B, Cmds.GenericNoPayload
    command :association_specific_group_report, 0x0C
  end

  command_class :association_group_info do
    command :association_group_name_get, 0x01
    command :association_group_name_report, 0x02
    command :association_group_info_get, 0x03
    command :association_group_info_report, 0x04
    command :association_group_command_list_get, 0x05
    command :association_group_command_list_report, 0x06
  end

  command_class :barrier_operator do
    command :barrier_operator_set, 0x01
    command :barrier_operator_get, 0x02, Cmds.GenericNoPayload
    command :barrier_operator_report, 0x03
    command :barrier_operator_signal_supported_get, 0x04, Cmds.GenericNoPayload
    command :barrier_operator_signal_supported_report, 0x05
    command :barrier_operator_signal_set, 0x06
    command :barrier_operator_signal_get, 0x07
    command :barrier_operator_signal_report, 0x08
  end

  command_class :basic do
    command :basic_set, 0x01
    command :basic_get, 0x02, Cmds.GenericNoPayload
    command :basic_report, 0x03
  end

  command_class :battery do
    command :battery_get, 0x02, Cmds.GenericNoPayload
    command :battery_report, 0x03
  end

  command_class :central_scene do
    command :central_scene_supported_get, 0x01, Cmds.GenericNoPayload
    command :central_scene_supported_report, 0x02
    command :central_scene_notification, 0x03
    command :central_scene_configuration_set, 0x04
    command :central_scene_configuration_get, 0x05, Cmds.GenericNoPayload
    command :central_scene_configuration_report, 0x06
  end

  command_class :clock do
    command :clock_set, 0x04
    command :clock_get, 0x05, Cmds.GenericNoPayload
    command :clock_report, 0x06
  end

  command_class :configuration do
    command :configuration_default_reset, 0x01, Cmds.GenericNoPayload
    command :configuration_set, 0x04
    command :configuration_get, 0x05, report: :configuration_report
    command :configuration_report, 0x06
    command :configuration_bulk_set, 0x07
    command :configuration_bulk_get, 0x08, handler: {AggregateReport, aggregate_param: :values}
    command :configuration_bulk_report, 0x09
    command :configuration_name_get, 0x0A, handler: {AggregateReport, aggregate_param: :name}
    command :configuration_name_report, 0x0B
    command :configuration_info_get, 0x0C, handler: {AggregateReport, aggregate_param: :info}
    command :configuration_info_report, 0x0D
    command :configuration_properties_get, 0x0E
    command :configuration_properties_report, 0x0F
  end

  command_class :crc_16_encap do
    command :crc_16_encap, 0x01, Cmds.CRC16Encap
  end

  command_class :device_reset_locally do
    command :device_reset_locally_notification, 0x01, Cmds.GenericNoPayload
  end

  command_class :door_lock do
    command :door_lock_operation_set, 0x01
    command :door_lock_operation_get, 0x02, Cmds.GenericNoPayload

    command :door_lock_operation_report, 0x03,
      default_params: [
        inside_handles_mode: %{1 => :disabled, 2 => :disabled, 3 => :disabled, 4 => :disabled},
        outside_handles_mode: %{1 => :disabled, 2 => :disabled, 3 => :disabled, 4 => :disabled},
        latch_position: :open,
        bolt_position: :locked,
        door_state: :open,
        timeout_minutes: 0,
        timeout_seconds: 0
      ]

    command :door_lock_configuration_set, 0x04
    command :door_lock_configuration_get, 0x05, Cmds.GenericNoPayload
    command :door_lock_configuration_report, 0x06
    command :door_lock_capabilities_get, 0x07, Cmds.GenericNoPayload
    command :door_lock_capabilities_report, 0x08
  end

  command_class :firmware_update_md do
    command :firmware_md_get, 0x01, Cmds.GenericNoPayload
    command :firmware_md_report, 0x02, Cmds.FirmwareMDReport
    command :firmware_update_md_request_get, 0x03, Cmds.FirmwareUpdateMDRequestGet
    command :firmware_update_md_request_report, 0x04, Cmds.FirmwareUpdateMDRequestReport
    command :firmware_update_md_get, 0x05, Cmds.FirmwareUpdateMDGet
    command :firmware_update_md_report, 0x06, Cmds.FirmwareUpdateMDReport
    command :firmware_update_md_status_report, 0x07, Cmds.FirmwareUpdateMDStatusReport
    command :firmware_update_activation_set, 0x08, report: :firmware_update_activation_report
    command :firmware_update_activation_report, 0x09
  end

  command_class :hail do
    command :hail, 0x01, Cmds.GenericNoPayload
  end

  command_class :humidity_control_mode do
    command :humidity_control_mode_set, 0x01
    command :humidity_control_mode_get, 0x02, Cmds.GenericNoPayload
    command :humidity_control_mode_report, 0x03
    command :humidity_control_mode_supported_get, 0x04, Cmds.GenericNoPayload
    command :humidity_control_mode_supported_report, 0x05
  end

  command_class :humidity_control_operating_state do
    command :humidity_control_operating_state_get, 0x01, Cmds.GenericNoPayload
    command :humidity_control_operating_state_report, 0x02
  end

  command_class :humidity_control_setpoint do
    command :humidity_control_setpoint_set, 0x01
    command :humidity_control_setpoint_get, 0x02
    command :humidity_control_setpoint_report, 0x03
    command :humidity_control_setpoint_supported_get, 0x04, Cmds.GenericNoPayload
    command :humidity_control_setpoint_supported_report, 0x05
    command :humidity_control_setpoint_scale_supported_get, 0x06
    command :humidity_control_setpoint_scale_supported_report, 0x07
    command :humidity_control_setpoint_capabilities_get, 0x08
    command :humidity_control_setpoint_capabilities_report, 0x09
  end

  command_class :indicator do
    command :indicator_set, 0x01
    command :indicator_get, 0x02
    command :indicator_report, 0x03
    command :indicator_supported_get, 0x04
    command :indicator_supported_report, 0x05
    command :indicator_description_get, 0x06
    command :indicator_description_report, 0x07
  end

  command_class :manufacturer_specific do
    command :manufacturer_specific_get, 0x04, Cmds.GenericNoPayload
    command :manufacturer_specific_report, 0x05
    command :manufacturer_specific_device_specific_get, 0x06
    command :manufacturer_specific_device_specific_report, 0x07
  end

  command_class :meter do
    command :meter_get, 0x01
    command :meter_report, 0x02
    command :meter_supported_get, 0x03, Cmds.GenericNoPayload
    command :meter_supported_report, 0x04
    command :meter_reset, 0x05
  end

  command_class :multi_channel do
    command :multi_channel_endpoint_get, 0x07, Cmds.GenericNoPayload
    command :multi_channel_endpoint_report, 0x08
    command :multi_channel_capability_get, 0x09
    command :multi_channel_capability_report, 0x0A

    command :multi_channel_endpoint_find, 0x0B,
      report: :multi_channel_endpoint_find_report,
      handler: {AggregateReport, aggregate_param: :end_points}

    command :multi_channel_endpoint_find_report, 0x0C

    command :multi_channel_get_command_encapsulation, 0x0D, Cmds.MultiChannelCommandEncapsulation,
      report: :any,
      handler: {WaitReport, complete_report: :any}

    command :multi_channel_command_encapsulation, 0x0D
    command :multi_channel_aggregated_members_get, 0x0E
    command :multi_channel_aggregated_members_report, 0x0F
  end

  command_class :multi_channel_association do
    command :multi_channel_association_set, 0x01

    command :multi_channel_association_get, 0x02,
      report: :multi_channel_association_report,
      handler: {AggregateReport, aggregate_param: :nodes}

    command :multi_channel_association_report, 0x03
    command :multi_channel_association_remove, 0x04
    command :multi_channel_association_groupings_get, 0x05, Cmds.GenericNoPayload
    command :multi_channel_association_groupings_report, 0x06
  end

  command_class :multi_cmd do
    command :multi_command_encapsulated, 0x01, Cmds.MultiCommandEncapsulated
  end

  command_class :network_management_basic_node do
    command :learn_mode_set, 0x01, report: :learn_mode_set_status
    command :learn_mode_set_status, 0x02
    command :network_update_request, 0x03, report: :network_update_request_status
    command :network_update_request_status, 0x04
    command :node_information_send, 0x05
    command :default_set, 0x06, report: :default_set_complete
    command :default_set_complete, 0x07
    command :dsk_get, 0x08, Cmds.DSKGet, default_params: [add_mode: :learn]
    command :dsk_report, 0x09, Cmds.DSKReport
  end

  command_class :network_management_inclusion do
    command :node_add, 0x01, report: :node_add_status
    command :node_add_status, 0x02
    command :node_remove, 0x03, report: :node_remove_status
    command :node_remove_status, 0x04
    command :failed_node_remove, 0x07, report: :failed_node_remove_status
    command :failed_node_remove_status, 0x08
    command :failed_node_replace, 0x09, report: :failed_node_replace_status
    command :failed_node_replace_status, 0x0A
    command :node_neighbor_update_request, 0x0B, report: :node_neighbor_update_status
    command :node_neighbor_update_status, 0x0C
    command :node_add_keys_report, 0x11
    command :node_add_keys_set, 0x12, supports_supervision?: false
    command :node_add_dsk_report, 0x13, Cmds.NodeAddDSKReport
    command :node_add_dsk_set, 0x14, Cmds.NodeAddDSKSet, supports_supervision?: false
    command :smart_start_join_started, 0x15
    command :extended_node_add_status, 0x16
    command :included_nif_report, 0x19, Cmds.IncludedNIFReport
  end

  command_class :network_management_installation_maintenance do
    command :priority_route_set, 0x01
    command :priority_route_get, 0x02
    command :priority_route_report, 0x03
    command :statistics_get, 0x04
    command :statistics_report, 0x05
    command :statistics_clear, 0x06, Cmds.GenericNoPayload
    command :rssi_get, 0x07, Cmds.GenericNoPayload
    command :rssi_report, 0x08
    command :s2_resynchronization_event, 0x09, Cmds.S2ResynchronizationEvent
    command :zwave_long_range_channel_set, 0x0A, Cmds.ZWaveLongRangeChannelSet
    command :zwave_long_range_channel_get, 0x0D, Cmds.GenericNoPayload
    command :zwave_long_range_channel_report, 0x0E, Cmds.ZWaveLongRangeChannelReport
  end

  command_class :network_management_proxy do
    command :node_list_get, 0x01
    command :node_list_report, 0x02
    command :node_info_cached_get, 0x03, default_params: [max_age: 10]
    command :node_info_cached_report, 0x04
    command :network_management_multi_channel_end_point_get, 0x05
    command :network_management_multi_channel_end_point_report, 0x06
    command :network_management_multi_channel_capability_get, 0x07
    command :network_management_multi_channel_capability_report, 0x08
    command :failed_node_list_get, 0x0B
    command :failed_node_list_report, 0x0C
  end

  command_class :no_operation do
    # TODO?
    command :no_operation, 0x00, Cmds.GenericNoPayload
  end

  command_class :node_naming do
    command :node_name_set, 0x01
    command :node_name_get, 0x02, Cmds.GenericNoPayload
    command :node_name_report, 0x03
    command :node_location_set, 0x04
    command :node_location_get, 0x05, Cmds.GenericNoPayload
    command :node_location_report, 0x06
  end

  command_class :node_provisioning do
    command :node_provisioning_set, 0x01, default_params: [meta_extensions: []]
    command :node_provisioning_delete, 0x02
    command :node_provisioning_list_iteration_get, 0x03, default_params: [remaining_counter: 0xFF]

    command :node_provisioning_list_iteration_report, 0x04,
      default_params: [meta_extensions: [], dsk: ""]

    command :node_provisioning_get, 0x05, default_params: [meta_extensions: []]
    command :node_provisioning_report, 0x06, default_params: [meta_extensions: [], dsk: nil]
  end

  command_class :powerlevel do
    command :powerlevel_set, 0x01
    command :powerlevel_get, 0x02, Cmds.GenericNoPayload
    command :powerlevel_report, 0x03
    command :powerlevel_test_node_set, 0x04
    command :powerlevel_test_node_get, 0x05, Cmds.GenericNoPayload
    command :powerlevel_test_node_report, 0x06
  end

  command_class :scene_activation do
    command :scene_activation_set, 0x01
  end

  command_class :scene_actuator_conf do
    command :scene_actuator_conf_set, 0x01
    command :scene_actuator_conf_get, 0x02
    command :scene_actuator_conf_report, 0x03
  end

  command_class :schedule_entry_lock do
    command :schedule_entry_lock_enable_set, 0x01
    command :schedule_entry_lock_enable_all_set, 0x02
    command :schedule_entry_lock_week_day_set, 0x03
    command :schedule_entry_lock_week_day_get, 0x04
    command :schedule_entry_lock_week_day_report, 0x05
    command :schedule_entry_lock_year_day_set, 0x06
    command :schedule_entry_lock_year_day_get, 0x07
    command :schedule_entry_lock_year_day_report, 0x08
    command :schedule_entry_type_supported_get, 0x09, Cmds.GenericNoPayload
    command :schedule_entry_type_supported_report, 0x0A
    command :schedule_entry_lock_time_offset_get, 0x0B, Cmds.GenericNoPayload
    command :schedule_entry_lock_time_offset_report, 0x0C
    command :schedule_entry_lock_time_offset_set, 0x0D
    command :schedule_entry_lock_daily_repeating_get, 0x0E
    command :schedule_entry_lock_daily_repeating_report, 0x0F
    command :schedule_entry_lock_daily_repeating_set, 0x10
  end

  command_class :security do
    command :s0_commands_supported_get, 0x02, Cmds.GenericNoPayload

    command :s0_commands_supported_report, 0x03, Cmds.S0CommandsSupportedReport,
      default_params: [supported: [], controlled: [], reports_to_follow: 0]

    command :s0_security_scheme_get, 0x04, Cmds.S0SecuritySchemeGet
    command :s0_security_scheme_report, 0x05, Cmds.S0SecuritySchemeReport
    command :s0_network_key_set, 0x06, Cmds.S0NetworkKeySet, report: :s0_network_key_verify
    command :s0_network_key_verify, 0x07, Cmds.GenericNoPayload

    command :s0_security_scheme_inherit, 0x08, Cmds.S0SecuritySchemeInherit,
      report: :s0_security_scheme_report

    command :s0_nonce_get, 0x40, Cmds.GenericNoPayload
    command :s0_nonce_report, 0x80, Cmds.S0NonceReport
    command :s0_message_encapsulation, 0x81, Cmds.S0MessageEncapsulation
  end

  command_class :security_2 do
    command :s2_nonce_get, 0x01, Cmds.GenericNoPayload
    command :s2_nonce_report, 0x02, Cmds.S2NonceReport
    command :s2_message_encapsulation, 0x03, Cmds.S2MessageEncapsulation
    command :s2_kex_get, 0x04, Cmds.GenericNoPayload, supports_supervision?: false
    command :s2_kex_report, 0x05, Cmds.S2KexReport, supports_supervision?: false
    command :s2_kex_set, 0x06, Cmds.S2KexSet, supports_supervision?: false
    command :s2_kex_fail, 0x07, Cmds.S2KexFail, supports_supervision?: false
    command :s2_public_key_report, 0x08, Cmds.S2PublicKeyReport, supports_supervision?: false
    command :s2_network_key_get, 0x09, Cmds.S2NetworkKeyGet, supports_supervision?: false
    command :s2_network_key_report, 0x0A, Cmds.S2NetworkKeyReport, supports_supervision?: false
    command :s2_network_key_verify, 0x0B, Cmds.GenericNoPayload, supports_supervision?: false
    command :s2_transfer_end, 0x0C, Cmds.S2TransferEnd, supports_supervision?: false
    command :s2_commands_supported_get, 0x0D, Cmds.GenericNoPayload

    command :s2_commands_supported_report, 0x0E, Cmds.S2CommandsSupportedReport,
      default_params: [command_classes: []]
  end

  command_class :sensor_binary do
    command :sensor_binary_supported_sensor_get, 0x01, Cmds.GenericNoPayload
    command :sensor_binary_get, 0x02
    command :sensor_binary_report, 0x03
    command :sensor_binary_supported_sensor_report, 0x04
  end

  command_class :sensor_multilevel do
    command :sensor_multilevel_supported_sensor_get, 0x01, Cmds.GenericNoPayload
    command :sensor_multilevel_supported_sensor_report, 0x02
    command :sensor_multilevel_supported_scale_get, 0x03
    command :sensor_multilevel_get, 0x04
    command :sensor_multilevel_report, 0x05
    command :sensor_multilevel_supported_scale_report, 0x06
  end

  command_class :sound_switch do
    command :sound_switch_tones_number_get, 0x01, Cmds.GenericNoPayload
    command :sound_switch_tones_number_report, 0x02
    command :sound_switch_tone_info_get, 0x03
    command :sound_switch_tone_info_report, 0x04
    command :sound_switch_configuration_set, 0x05
    command :sound_switch_configuration_get, 0x06, Cmds.GenericNoPayload
    command :sound_switch_configuration_report, 0x07
    command :sound_switch_tone_play_set, 0x08
    command :sound_switch_tone_play_get, 0x09, Cmds.GenericNoPayload
    command :sound_switch_tone_play_report, 0x0A
  end

  command_class :supervision do
    command :supervision_get, 0x01
    command :supervision_report, 0x02
  end

  command_class :switch_binary do
    command :switch_binary_set, 0x01
    command :switch_binary_get, 0x02, Cmds.GenericNoPayload
    command :switch_binary_report, 0x03
  end

  command_class :switch_multilevel do
    command :switch_multilevel_set, 0x01
    command :switch_multilevel_get, 0x02, Cmds.GenericNoPayload
    command :switch_multilevel_report, 0x03
    command :switch_multilevel_start_level_change, 0x04
    command :switch_multilevel_stop_level_change, 0x05, Cmds.GenericNoPayload
  end

  command_class :thermostat_fan_mode do
    command :thermostat_fan_mode_set, 0x01
    command :thermostat_fan_mode_get, 0x02, Cmds.GenericNoPayload
    command :thermostat_fan_mode_report, 0x03
    command :thermostat_fan_mode_supported_get, 0x04, Cmds.GenericNoPayload
    command :thermostat_fan_mode_supported_report, 0x05
  end

  command_class :thermostat_fan_state do
    command :thermostat_fan_state_get, 0x02, Cmds.GenericNoPayload
    command :thermostat_fan_state_report, 0x03
  end

  command_class :thermostat_mode do
    command :thermostat_mode_set, 0x01
    command :thermostat_mode_get, 0x02, Cmds.GenericNoPayload
    command :thermostat_mode_report, 0x03
    command :thermostat_mode_supported_get, 0x04, Cmds.GenericNoPayload
    command :thermostat_mode_supported_report, 0x05
  end

  command_class :thermostat_operating_state do
    command :thermostat_operating_state_get, 0x02, Cmds.GenericNoPayload
    command :thermostat_operating_state_report, 0x03
  end

  command_class :thermostat_setback do
    command :thermostat_setback_set, 0x01
    command :thermostat_setback_get, 0x02, Cmds.GenericNoPayload
    command :thermostat_setback_report, 0x03
  end

  command_class :thermostat_setpoint do
    command :thermostat_setpoint_set, 0x01
    command :thermostat_setpoint_get, 0x02
    command :thermostat_setpoint_report, 0x03
    command :thermostat_setpoint_supported_get, 0x04, Cmds.GenericNoPayload
    command :thermostat_setpoint_supported_report, 0x05
    command :thermostat_setpoint_capabilities_get, 0x09
    command :thermostat_setpoint_capabilities_report, 0x0A
  end

  command_class :time do
    command :time_get, 0x01, Cmds.GenericNoPayload
    command :time_report, 0x02
    command :date_get, 0x03, Cmds.GenericNoPayload
    command :date_report, 0x04
    command :time_offset_set, 0x05
    command :time_offset_get, 0x06, Cmds.GenericNoPayload
    command :time_offset_report, 0x07
  end

  command_class :time_parameters do
    command :time_parameters_set, 0x01
    command :time_parameters_get, 0x02, Cmds.GenericNoPayload
    command :time_parameters_report, 0x03
  end

  command_class :user_code do
    command :user_code_set, 0x01
    command :user_code_get, 0x02
    command :user_code_report, 0x03
    command :user_code_users_number_get, 0x04, Cmds.GenericNoPayload
    command :user_code_users_number_report, 0x05
    command :user_code_capabilities_get, 0x06, Cmds.GenericNoPayload
    command :user_code_capabilities_report, 0x07
    command :user_code_keypad_mode_set, 0x08
    command :user_code_keypad_mode_get, 0x09, Cmds.GenericNoPayload
    command :user_code_keypad_mode_report, 0x0A
    command :extended_user_code_set, 0x0B
    command :extended_user_code_get, 0x0C
    command :extended_user_code_report, 0x0D
    command :admin_code_set, 0x0E
    command :admin_code_get, 0x0F, Cmds.GenericNoPayload
    command :admin_code_report, 0x10
    command :user_code_checksum_get, 0x11, Cmds.GenericNoPayload
    command :user_code_checksum_report, 0x12
  end

  command_class :user_credential do
    command :user_capabilities_get, 0x01, Cmds.GenericNoPayload
    command :user_capabilities_report, 0x02
    command :credential_capabilities_get, 0x03, Cmds.GenericNoPayload
    command :credential_capabilities_report, 0x04
    command :user_set, 0x05
    command :user_get, 0x06
    command :user_report, 0x07
    command :credential_set, 0x0A
    command :credential_get, 0x0B
    command :credential_report, 0x0C
    command :credential_learn_start, 0x0F
    command :credential_learn_cancel, 0x10, Cmds.GenericNoPayload
    command :credential_learn_status_report, 0x11
    command :user_credential_association_set, 0x12
    command :user_credential_association_report, 0x13
    command :all_users_checksum_get, 0x14, Cmds.GenericNoPayload
    command :all_users_checksum_report, 0x15
    command :user_checksum_get, 0x16
    command :user_checksum_report, 0x17
    command :credential_checksum_get, 0x18
    command :credential_checksum_report, 0x19
    command :admin_pin_code_set, 0x1A
    command :admin_pin_code_get, 0x1B, Cmds.GenericNoPayload
    command :admin_pin_code_report, 0x1C
  end

  command_class :version do
    command :version_get, 0x11, Cmds.GenericNoPayload
    command :version_report, 0x12

    command :version_command_class_get, 0x13,
      report_matcher_fun: {Cmds.VersionCommandClassGet, :report_matches_get?}

    command :version_command_class_report, 0x14
    command :version_capabilities_get, 0x15, Cmds.GenericNoPayload
    command :version_capabilities_report, 0x16
    command :version_zwave_software_get, 0x17, Cmds.GenericNoPayload
    command :version_zwave_software_report, 0x18, Cmds.VersionZWaveSoftwareReport
  end

  command_class :wake_up do
    command :wake_up_interval_set, 0x04
    command :wake_up_interval_get, 0x05, Cmds.GenericNoPayload
    command :wake_up_interval_report, 0x06
    command :wake_up_notification, 0x07, Cmds.GenericNoPayload
    command :wake_up_no_more_information, 0x08, Cmds.GenericNoPayload
    command :wake_up_interval_capabilities_get, 0x09, Cmds.GenericNoPayload
    command :wake_up_interval_capabilities_report, 0x0A
  end

  command_class :window_covering do
    command :window_covering_supported_get, 0x01, Cmds.GenericNoPayload
    command :window_covering_supported_report, 0x02
    command :window_covering_get, 0x03
    command :window_covering_report, 0x04
    command :window_covering_set, 0x05
    command :window_covering_start_level_change, 0x06
    command :window_covering_stop_level_change, 0x07
  end

  command_class :zip do
    command :zip_packet, 0x02, Cmds.ZIPPacket,
      default_params: [
        source: 0x00,
        dest: 0x00,
        secure: true,
        header_extensions: [],
        flag: nil,
        command: nil,
        more_info: false
      ]

    command :keep_alive, 0x03, Cmds.ZIPKeepAlive
  end

  command_class :zip_gateway do
    command :application_node_info_get, 0x0C, Cmds.GenericNoPayload
    command :application_node_info_report, 0x0D
  end

  command_class :zwaveplus_info do
    command :zwaveplus_info_get, 0x01, Cmds.GenericNoPayload
    command :zwaveplus_info_report, 0x02
  end

  @doc """
  Get the command spec for a given command name.

  ## Examples

      iex> Grizzly.ZWave.Commands.spec_for(:thermostat_setpoint_get)
      {:ok, %Grizzly.ZWave.CommandSpec{
        name: :thermostat_setpoint_get,
        command_byte: 0x02,
        command_class: :thermostat_setpoint,
        default_params: [],
        module: Grizzly.ZWave.Commands.ThermostatSetpointGet,
        encode_fun: {Grizzly.ZWave.Commands.ThermostatSetpointGet, :encode_params},
        decode_fun: {Grizzly.ZWave.Commands.ThermostatSetpointGet, :decode_params},
        handler: {Grizzly.Requests.Handlers.WaitReport, complete_report: :thermostat_setpoint_report},
        report: :thermostat_setpoint_report,
        report_matcher_fun: nil,
        supports_supervision?: false
      }}
  """
  @spec spec_for(Grizzly.command()) :: {:ok, CommandSpec.t()} | {:error, :unknown_command}
  def spec_for(command_name) do
    case Map.fetch(builtin_commands(), command_name) do
      {:ok, spec} -> {:ok, spec}
      :error -> {:error, :unknown_command}
    end
  end

  @doc """
  Get the command spec for a given command class byte and command byte.
  """
  @spec spec_for(byte(), byte()) :: {:ok, CommandSpec.t()} | {:error, :unknown_command}
  def spec_for(cc_byte, command_byte) do
    Enum.find_value(builtin_commands(), {:error, :unknown_command}, fn {_command_name, spec} ->
      cc = spec.command_class
      cmd = spec.command_byte

      if CommandClasses.to_byte(cc) == cc_byte and cmd == command_byte do
        {:ok, spec}
      end
    end)
  end

  @doc "See `spec_for/1`."
  @spec spec_for!(Grizzly.command()) :: CommandSpec.t()
  def spec_for!(command_name) do
    case spec_for(command_name) do
      {:ok, spec} ->
        spec

      {:error, :unknown_command} ->
        raise ArgumentError, "Command #{inspect(command_name)} does not exist"
    end
  end

  @doc "See `spec_for/2`."
  @spec spec_for!(byte(), byte()) :: CommandSpec.t()
  def spec_for!(cc_byte, command_byte) do
    case spec_for(cc_byte, command_byte) do
      {:ok, spec} ->
        spec

      {:error, :unknown_command} ->
        raise ArgumentError,
              "Command with command class byte #{inspect(cc_byte)} and command byte #{inspect(command_byte)} does not exist"
    end
  end

  @doc """
  Look up the command module and handler options for a given command, either by
  name or from its binary representation.
  """
  @spec lookup(Grizzly.command() | binary()) :: {module(), [Grizzly.command_opt()]}
  def lookup(<<cc_byte, command_byte, _rest::binary>>) do
    lookup(cc_byte, command_byte)
  end

  def lookup(command_name) do
    case spec_for(command_name) do
      {:ok, spec} ->
        {spec.module, handler: CommandSpec.handler_spec(spec)}

      {:error, :unknown_command} ->
        raise ArgumentError, "Command #{inspect(command_name)} does not exist"
    end
  end

  @doc """
  Look up the command module and handler options for a given command class byte
  and command byte.
  """
  @spec lookup(byte(), byte()) :: {module(), [Grizzly.command_opt()]}
  def lookup(cc_byte, command_byte) do
    case spec_for(cc_byte, command_byte) do
      {:ok, spec} ->
        {spec.module, handler: CommandSpec.handler_spec(spec)}

      {:error, :unknown_command} ->
        raise ArgumentError,
              "Command with command class byte #{inspect(cc_byte)} and command byte #{inspect(command_byte)} does not exist"
    end
  end

  @spec create(atom(), keyword()) :: {:error, :unknown_command} | {:ok, Grizzly.ZWave.Command.t()}
  def create(command_name, params \\ []) do
    with {:ok, spec} <- spec_for(command_name) do
      CommandSpec.create_command(spec, params)
    end
  end

  @spec decode(binary()) ::
          {:ok, Command.t()} | {:error, DecodeError.t() | ZWaveError.t()}
  def decode(<<0x00>>) do
    create(:no_operation, [])
  end

  def decode(<<cc_byte, command_byte, params::binary>> = binary) do
    if !Keyword.has_key?(Logger.metadata(), :zwave_command) do
      Logger.metadata(zwave_command: inspect(binary, base: :hex, limit: 100))
    end

    with {:ok, spec} <- spec_for(cc_byte, command_byte),
         {mod, fun} = spec.decode_fun,
         {:ok, decoded_params} <- apply(mod, fun, [params]) do
      CommandSpec.create_command(spec, decoded_params)
    else
      {:error, :unknown_command} -> {:error, %ZWaveError{binary: binary}}
      {:error, %DecodeError{}} = err -> err
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
    case Map.fetch(builtin_commands(), command_name) do
      {:ok, %CommandSpec{supports_supervision?: v}} -> v
      :error -> false
    end
  end

  @spec format_handler_spec(module() | Grizzly.handler_spec()) :: Grizzly.handler_spec()
  def format_handler_spec({_handler, _args} = spec), do: spec
  def format_handler_spec(handler), do: {handler, []}

  @doc false
  def __after_verify__(module) do
    commands = Enum.reverse(module.builtin_commands())

    Enum.each(commands, fn {_name, command_spec} ->
      {file, line} = Keyword.get(@command_spec_def_locations, command_spec.name)

      case CommandSpec.validate(command_spec) do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          IO.warn(
            Exception.format(:error, reason),
            module: __MODULE__,
            function: {:command, 3},
            file: file,
            line: line
          )
      end
    end)
  end
end
