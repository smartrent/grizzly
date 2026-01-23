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
  alias Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.Notifications
  alias Grizzly.ZWave.ZWaveError
  alias Grizzly.ZWave.ZWEnum

  @after_verify __MODULE__

  command_class :alarm, 0x71 do
    command :alarm_event_supported_get, 0x01, Cmds.Generic,
      params: [
        enum(:type, Notifications.types(), size: 8)
      ]

    command :alarm_event_supported_report, 0x02
    command :alarm_get, 0x04
    command :alarm_report, 0x05

    command :alarm_set, 0x06, Cmds.Generic,
      params: [
        enum(:zwave_type, Notifications.types(), size: 8),
        enum(:status, ZWEnum.new(enabled: 0xFF, disabled: 0x00), size: 8)
      ]

    command :alarm_type_supported_get, 0x07, Cmds.Generic, params: []
    command :alarm_type_supported_report, 0x08
  end

  command_class :antitheft, 0x5D do
    command :antitheft_set, 0x01
    command :antitheft_get, 0x02, Cmds.Generic, params: []
    command :antitheft_report, 0x03
  end

  command_class :antitheft_unlock, 0x7E do
    command :antitheft_unlock_get, 0x01, Cmds.Generic, params: []
    command :antitheft_unlock_report, 0x02
    command :antitheft_unlock_set, 0x03
  end

  command_class :application_status, 0x22 do
    command :application_busy, 0x01, Cmds.Generic,
      params: [
        enum(:status, ZWEnum.new(try_again_later: 0, try_again_after_wait: 1, request_queued: 2),
          size: 8
        ),
        param(:wait_time, :uint, size: 8)
      ]

    command :application_rejected_request, 0x02, Cmds.Generic,
      params: [
        param(:status, :constant, size: 8, opts: [value: 0, hidden: true])
      ]
  end

  command_class :association, 0x85 do
    command :association_set, 0x01

    command :association_get, 0x02, Cmds.Generic,
      handler: {AggregateReport, aggregate_param: :nodes},
      params: [
        param(:grouping_identifier, :uint, size: 8)
      ]

    command :association_report, 0x03, default_params: [reports_to_follow: 0]
    command :association_remove, 0x04, supports_supervision?: true
    command :association_groupings_get, 0x05, Cmds.Generic, params: []

    command :association_groupings_report, 0x06, Cmds.Generic,
      params: [
        param(:supported_groupings, :uint, size: 8)
      ]

    command :association_specific_group_get, 0x0B, Cmds.Generic, params: []

    command :association_specific_group_report, 0x0C, Cmds.Generic,
      params: [
        param(:group, :uint, size: 8)
      ]
  end

  command_class :association_group_info, 0x59 do
    command :association_group_name_get, 0x01, Cmds.Generic,
      params: [
        param(:group_id, :uint, size: 8)
      ]

    command :association_group_name_report, 0x02, Cmds.Generic,
      params: [
        param(:group_id, :uint, size: 8),
        param(:length, {:length, :name}, size: 8),
        param(:name, :binary, size: {:variable, :length})
      ]

    command :association_group_info_get, 0x03, Cmds.Generic,
      params: [
        param(:refresh_cache, :boolean, size: 1),
        param(:all, :boolean, size: 1),
        reserved(size: 6),
        param(:group_id, :uint, size: 8, default: 0)
      ]

    command :association_group_info_report, 0x04

    command :association_group_command_list_get, 0x05, Cmds.Generic,
      params: [
        param(:allow_cache, :boolean, size: 1),
        reserved(size: 7),
        param(:group_id, :uint, size: 8)
      ]

    command :association_group_command_list_report, 0x06
  end

  command_class :barrier_operator, 0x66 do
    command :barrier_operator_set, 0x01, Cmds.Generic,
      params: [
        enum(:target_value, ZWEnum.new(close: 0, open: 0xFF), size: 8)
      ]

    command :barrier_operator_get, 0x02, Cmds.Generic, params: []

    command :barrier_operator_report, 0x03, Cmds.Generic,
      params: [
        param(:state, :any,
          size: 8,
          opts: [
            encode: &CommandClasses.BarrierOperator.state_to_byte/1,
            decode: &CommandClasses.BarrierOperator.state_from_byte/1
          ]
        )
      ]

    command :barrier_operator_signal_supported_get, 0x04, Cmds.Generic, params: []
    command :barrier_operator_signal_supported_report, 0x05

    subsystem_type =
      enum(:subsystem_type, ZWEnum.new(audible_notification: 1, visual_notification: 2), size: 8)

    subsystem_state = enum(:subsystem_state, ZWEnum.new(off: 0, on: 0xFF), size: 8)

    command :barrier_operator_signal_set, 0x06, Cmds.Generic,
      params: [subsystem_type, subsystem_state]

    command :barrier_operator_signal_get, 0x07, Cmds.Generic, params: [subsystem_type]

    command :barrier_operator_signal_report, 0x08, Cmds.Generic,
      params: [subsystem_type, subsystem_state]
  end

  command_class :basic, 0x20 do
    command :basic_set, 0x01
    command :basic_get, 0x02, Cmds.Generic, params: []
    command :basic_report, 0x03
  end

  command_class :battery, 0x80 do
    command :battery_get, 0x02, Cmds.Generic, params: []
    command :battery_report, 0x03
  end

  command_class :central_scene, 0x5B do
    command :central_scene_supported_get, 0x01, Cmds.Generic, params: []
    command :central_scene_supported_report, 0x02
    command :central_scene_notification, 0x03

    central_scene_config_params = [
      param(:slow_refresh, :boolean, size: 1),
      reserved(size: 7)
    ]

    command :central_scene_configuration_set, 0x04, Cmds.Generic,
      params: central_scene_config_params

    command :central_scene_configuration_get, 0x05, Cmds.Generic, params: []

    command :central_scene_configuration_report, 0x06, Cmds.Generic,
      params: central_scene_config_params
  end

  command_class :clock, 0x81 do
    clock_weekdays =
      ZWEnum.new(%{
        unknown: 0x00,
        monday: 0x01,
        tuesday: 0x02,
        wednesday: 0x03,
        thursday: 0x04,
        friday: 0x05,
        saturday: 0x06,
        sunday: 0x07
      })

    clock_params = [
      enum(:weekday, clock_weekdays, size: 3),
      param(:hour, :uint, size: 5),
      param(:minute, :uint, size: 8)
    ]

    command :clock_set, 0x04, Cmds.Generic, params: clock_params
    command :clock_get, 0x05, Cmds.Generic, params: []
    command :clock_report, 0x06, Cmds.Generic, params: clock_params
  end

  command_class :configuration, 0x70 do
    param_num_8 = param(:param_number, :uint, size: 8)
    param_num_16 = param(:param_number, :uint, size: 16)
    reports_to_follow = param(:reports_to_follow, :uint, size: 8, default: 0)

    command :configuration_default_reset, 0x01, Cmds.Generic, params: []
    command :configuration_set, 0x04

    command :configuration_get, 0x05, Cmds.Generic,
      report: :configuration_report,
      params: [param_num_8]

    command :configuration_report, 0x06, Cmds.Generic,
      params: [
        param_num_8,
        reserved(size: 5),
        param(:size, :uint, size: 3),
        param(:value, :int, size: {:variable, :size})
      ]

    command :configuration_bulk_set, 0x07

    command :configuration_bulk_get, 0x08, Cmds.Generic,
      handler: {AggregateReport, aggregate_param: :values},
      params: [
        param(:offset, :uint, size: 16, default: 0),
        param(:number_of_parameters, :uint, size: 8)
      ]

    command :configuration_bulk_report, 0x09

    command :configuration_name_get, 0x0A, Cmds.Generic,
      handler: {AggregateReport, aggregate_param: :name},
      params: [param_num_16]

    command :configuration_name_report, 0x0B, Cmds.Generic,
      params: [
        param_num_16,
        reports_to_follow,
        param(:name, :binary, size: :variable)
      ]

    command :configuration_info_get, 0x0C, Cmds.Generic,
      handler: {AggregateReport, aggregate_param: :info},
      params: [param_num_16]

    command :configuration_info_report, 0x0D, Cmds.Generic,
      params: [
        param_num_16,
        reports_to_follow,
        param(:info, :binary, size: :variable)
      ]

    command :configuration_properties_get, 0x0E, Cmds.Generic, params: [param_num_16]

    command :configuration_properties_report, 0x0F
  end

  command_class :crc_16_encap, 0x56 do
    command :crc_16_encap, 0x01, Cmds.CRC16Encap
  end

  command_class :device_reset_locally, 0x5A do
    command :device_reset_locally_notification, 0x01, Cmds.Generic, params: []
  end

  command_class :door_lock, 0x62 do
    command :door_lock_operation_set, 0x01, Cmds.Generic,
      params: [
        enum(:mode, Encoding.door_lock_modes(), size: 8)
      ]

    command :door_lock_operation_get, 0x02, Cmds.Generic, params: []

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

    command :door_lock_configuration_set, 0x04, Cmds.DoorLockConfigurationSetReport
    command :door_lock_configuration_get, 0x05, Cmds.Generic, params: []
    command :door_lock_configuration_report, 0x06, Cmds.DoorLockConfigurationSetReport
    command :door_lock_capabilities_get, 0x07, Cmds.Generic, params: []
    command :door_lock_capabilities_report, 0x08
  end

  command_class :firmware_update_md, 0x7A do
    command :firmware_md_get, 0x01, Cmds.Generic, params: []
    command :firmware_md_report, 0x02, Cmds.FirmwareMDReport
    command :firmware_update_md_request_get, 0x03, Cmds.FirmwareUpdateMDRequestGet
    command :firmware_update_md_request_report, 0x04, Cmds.FirmwareUpdateMDRequestReport

    command :firmware_update_md_get, 0x05, Cmds.Generic,
      params: [
        param(:number_of_reports, :uint, size: 8),
        reserved(size: 1),
        param(:report_number, :uint, size: 15)
      ]

    command :firmware_update_md_report, 0x06, Cmds.FirmwareUpdateMDReport
    command :firmware_update_md_status_report, 0x07, Cmds.FirmwareUpdateMDStatusReport
    command :firmware_update_activation_set, 0x08, report: :firmware_update_activation_report
    command :firmware_update_activation_report, 0x09
  end

  command_class :hail, 0x82 do
    command :hail, 0x01, Cmds.Generic, params: []
  end

  command_class :humidity_control_mode, 0x6D do
    set_report_params = [
      reserved(size: 4),
      enum(:mode, Encoding.humidity_control_modes(), size: 4)
    ]

    command :humidity_control_mode_set, 0x01, Cmds.Generic, params: set_report_params
    command :humidity_control_mode_get, 0x02, Cmds.Generic, params: []
    command :humidity_control_mode_report, 0x03, Cmds.Generic, params: set_report_params
    command :humidity_control_mode_supported_get, 0x04, Cmds.Generic, params: []

    command :humidity_control_mode_supported_report, 0x05, Cmds.Generic,
      params: [
        bitmask(:modes, Encoding.humidity_control_modes(), size: :variable)
      ]
  end

  command_class :humidity_control_operating_state, 0x6E do
    command :humidity_control_operating_state_get, 0x01, Cmds.Generic, params: []

    command :humidity_control_operating_state_report, 0x02, Cmds.Generic,
      params: [
        reserved(size: 4),
        enum(:state, Encoding.humidity_control_operating_states(), size: 4)
      ]
  end

  command_class :humidity_control_setpoint, 0x64 do
    setpoint_type_params = [
      reserved(size: 4),
      enum(:setpoint_type, Encoding.humidity_control_setpoint_types(), size: 4)
    ]

    command :humidity_control_setpoint_set, 0x01, Cmds.HumidityControlSetpointSetReport
    command :humidity_control_setpoint_get, 0x02, Cmds.Generic, params: setpoint_type_params
    command :humidity_control_setpoint_report, 0x03, Cmds.HumidityControlSetpointSetReport
    command :humidity_control_setpoint_supported_get, 0x04, Cmds.Generic, params: []

    command :humidity_control_setpoint_supported_report, 0x05, Cmds.Generic,
      params: [
        bitmask(:setpoint_types, Encoding.humidity_control_setpoint_types(), size: :variable)
      ]

    command :humidity_control_setpoint_scale_supported_get, 0x06, Cmds.Generic,
      params: setpoint_type_params

    command :humidity_control_setpoint_scale_supported_report, 0x07, Cmds.Generic,
      params: [
        reserved(size: 4),
        bitmask(:scales, Encoding.humidity_control_setpoint_scales(), size: 4)
      ]

    command :humidity_control_setpoint_capabilities_get, 0x08, Cmds.Generic,
      params: setpoint_type_params

    command :humidity_control_setpoint_capabilities_report, 0x09
  end

  command_class :indicator, 0x87 do
    command :indicator_set, 0x01
    command :indicator_get, 0x02
    command :indicator_report, 0x03
    command :indicator_supported_get, 0x04
    command :indicator_supported_report, 0x05
    command :indicator_description_get, 0x06
    command :indicator_description_report, 0x07
  end

  command_class :manufacturer_specific, 0x72 do
    command :manufacturer_specific_get, 0x04, Cmds.Generic, params: []

    command :manufacturer_specific_report, 0x05, Cmds.Generic,
      params: [
        param(:manufacturer_id, :uint, size: 16),
        param(:product_type_id, :uint, size: 16),
        param(:product_id, :uint, size: 16)
      ]

    command :manufacturer_specific_device_specific_get, 0x06
    command :manufacturer_specific_device_specific_report, 0x07
  end

  command_class :meter, 0x32 do
    command :meter_get, 0x01
    command :meter_report, 0x02
    command :meter_supported_get, 0x03, Cmds.Generic, params: []
    command :meter_supported_report, 0x04
    command :meter_reset, 0x05
  end

  command_class :multi_channel, 0x60 do
    command :multi_channel_endpoint_get, 0x07, Cmds.Generic, params: []
    command :multi_channel_endpoint_report, 0x08

    command :multi_channel_capability_get, 0x09, Cmds.Generic,
      params: [
        reserved(size: 1),
        param(:end_point, :uint, size: 7)
      ]

    command :multi_channel_capability_report, 0x0A

    command :multi_channel_endpoint_find, 0x0B,
      report: :multi_channel_endpoint_find_report,
      handler: {AggregateReport, aggregate_param: :end_points}

    command :multi_channel_endpoint_find_report, 0x0C

    command :multi_channel_get_command_encapsulation, 0x0D, Cmds.MultiChannelCommandEncapsulation,
      report: :any,
      handler: {WaitReport, complete_report: :any}

    command :multi_channel_command_encapsulation, 0x0D

    command :multi_channel_aggregated_members_get, 0x0E, Cmds.Generic,
      params: [
        reserved(size: 1),
        param(:aggregated_end_point, :uint, size: 7)
      ]

    command :multi_channel_aggregated_members_report, 0x0F
  end

  command_class :multi_channel_association, 0x8E do
    command :multi_channel_association_set, 0x01, Cmds.MultiChannelAssociationSetRemove

    command :multi_channel_association_get, 0x02, Cmds.Generic,
      report: :multi_channel_association_report,
      handler: {AggregateReport, aggregate_param: :nodes},
      params: [
        param(:grouping_identifier, :uint, size: 8)
      ]

    command :multi_channel_association_report, 0x03

    command :multi_channel_association_remove, 0x04, Cmds.MultiChannelAssociationSetRemove,
      supports_supervision?: true

    command :multi_channel_association_groupings_get, 0x05, Cmds.Generic, params: []
    command :multi_channel_association_groupings_report, 0x06
  end

  command_class :multi_cmd, 0x8F do
    command :multi_command_encapsulated, 0x01, Cmds.MultiCommandEncapsulated
  end

  command_class :network_management_basic_node, 0x4D do
    command :learn_mode_set, 0x01, report: :learn_mode_set_status
    command :learn_mode_set_status, 0x02

    command :network_update_request, 0x03, Cmds.Generic,
      report: :network_update_request_status,
      params: [
        param(:seq_number, :uint, size: 8)
      ]

    command :network_update_request_status, 0x04, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        enum(:status, Encoding.network_update_request_statuses(), size: 8)
      ]

    command :node_information_send, 0x05

    command :default_set, 0x06, Cmds.Generic,
      report: :default_set_complete,
      params: [
        param(:seq_number, :uint, size: 8)
      ]

    command :default_set_complete, 0x07

    dsk_add_mode = enum(:add_mode, ZWEnum.new(%{learn: 0, add: 1}), size: 1)

    command :dsk_get, 0x08, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        reserved(size: 7),
        dsk_add_mode
      ]

    command :dsk_report, 0x09, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        reserved(size: 7),
        dsk_add_mode,
        param(:dsk, :dsk, size: 16 * 8)
      ]
  end

  command_class :network_management_inclusion, 0x34 do
    command :node_add, 0x01, report: :node_add_status
    command :node_add_status, 0x02
    command :node_remove, 0x03, report: :node_remove_status
    command :node_remove_status, 0x04
    command :failed_node_remove, 0x07, report: :failed_node_remove_status
    command :failed_node_remove_status, 0x08
    command :failed_node_replace, 0x09, report: :failed_node_replace_status
    command :failed_node_replace_status, 0x0A

    command :node_neighbor_update_request, 0x0B, Cmds.Generic,
      report: :node_neighbor_update_status,
      params: [
        param(:seq_number, :uint, size: 8),
        param(:node_id, :uint, size: 8)
      ]

    command :node_neighbor_update_status, 0x0C, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        enum(:status, ZWEnum.new(done: 0x22, failed: 0x23), size: 8)
      ]

    command :node_add_keys_report, 0x11
    command :node_add_keys_set, 0x12, supports_supervision?: false
    command :node_add_dsk_report, 0x13, Cmds.NodeAddDSKReport
    command :node_add_dsk_set, 0x14, Cmds.NodeAddDSKSet, supports_supervision?: false
    command :smart_start_join_started, 0x15
    command :extended_node_add_status, 0x16
    command :included_nif_report, 0x19, Cmds.IncludedNIFReport
  end

  command_class :network_management_installation_maintenance, 0x67 do
    command :priority_route_set, 0x01
    command :priority_route_get, 0x02, Cmds.Generic, params: [param(:node_id, :uint, size: 8)]
    command :priority_route_report, 0x03
    command :statistics_get, 0x04, Cmds.Generic, params: [param(:node_id, :uint, size: 8)]
    command :statistics_report, 0x05
    command :statistics_clear, 0x06, Cmds.Generic, params: []
    command :rssi_get, 0x07, Cmds.Generic, params: []
    command :rssi_report, 0x08
    command :s2_resynchronization_event, 0x09, Cmds.S2ResynchronizationEvent
    command :zwave_long_range_channel_set, 0x0A, Cmds.ZWaveLongRangeChannelSet
    command :zwave_long_range_channel_get, 0x0D, Cmds.Generic, params: []
    command :zwave_long_range_channel_report, 0x0E, Cmds.ZWaveLongRangeChannelReport
  end

  command_class :network_management_proxy, 0x52 do
    command :node_list_get, 0x01, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8)
      ]

    command :node_list_report, 0x02
    command :node_info_cached_get, 0x03, default_params: [max_age: 10]
    command :node_info_cached_report, 0x04
    command :network_management_multi_channel_end_point_get, 0x05
    command :network_management_multi_channel_end_point_report, 0x06
    command :network_management_multi_channel_capability_get, 0x07
    command :network_management_multi_channel_capability_report, 0x08

    command :failed_node_list_get, 0x0B, Cmds.Generic,
      params: [param(:seq_number, :uint, size: 8)]

    command :failed_node_list_report, 0x0C
  end

  command_class :no_operation, 0x00 do
    command :no_operation, 0x00, Cmds.Generic, params: []
  end

  command_class :node_naming, 0x77 do
    res5 = reserved(size: 5)
    encoding = enum(:encoding, Encoding.string_encodings(), size: 3)
    name = param(:name, :binary, size: :variable)
    location = param(:location, :binary, size: :variable)
    command :node_name_set, 0x01, Cmds.Generic, params: [res5, encoding, name]
    command :node_name_get, 0x02, Cmds.Generic, params: []
    command :node_name_report, 0x03, Cmds.Generic, params: [res5, encoding, name]
    command :node_location_set, 0x04, Cmds.Generic, params: [res5, encoding, location]
    command :node_location_get, 0x05, Cmds.Generic, params: []
    command :node_location_report, 0x06, Cmds.Generic, params: [res5, encoding, location]
  end

  command_class :node_provisioning, 0x78 do
    command :node_provisioning_set, 0x01, default_params: [meta_extensions: []]
    command :node_provisioning_delete, 0x02

    command :node_provisioning_list_iteration_get, 0x03, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        param(:remaining_counter, :uint, size: 8, required: false, default: 0xFF)
      ]

    command :node_provisioning_list_iteration_report, 0x04,
      default_params: [meta_extensions: [], dsk: ""]

    command :node_provisioning_get, 0x05, default_params: [meta_extensions: []]
    command :node_provisioning_report, 0x06, default_params: [meta_extensions: [], dsk: nil]
  end

  command_class :powerlevel, 0x73 do
    power_level = enum(:power_level, Encoding.power_levels(), size: 8)

    power_level_params = [
      power_level,
      param(:timeout, :uint, size: 8)
    ]

    command :powerlevel_set, 0x01, Cmds.Generic, params: power_level_params
    command :powerlevel_get, 0x02, Cmds.Generic, params: []
    command :powerlevel_report, 0x03, Cmds.Generic, params: power_level_params

    command :powerlevel_test_node_set, 0x04, Cmds.Generic,
      params: [
        param(:test_node_id, :uint, size: 8),
        power_level,
        param(:test_frame_count, :uint, size: 16)
      ]

    command :powerlevel_test_node_get, 0x05, Cmds.Generic, params: []

    command :powerlevel_test_node_report, 0x06, Cmds.Generic,
      params: [
        param(:test_node_id, :uint, size: 8),
        enum(
          :status_of_operation,
          ZWEnum.new(%{test_failed: 0, test_success: 1, test_in_progress: 2}),
          size: 8
        ),
        param(:test_frame_count, :uint, size: 16)
      ]
  end

  command_class :scene_activation, 0x2B do
    command :scene_activation_set, 0x01
  end

  command_class :scene_actuator_conf, 0x2C do
    command :scene_actuator_conf_set, 0x01
    command :scene_actuator_conf_get, 0x02
    command :scene_actuator_conf_report, 0x03
  end

  command_class :schedule_entry_lock, 0x4E do
    sel_weekdays =
      ZWEnum.new(
        sunday: 0,
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6
      )

    sel_weekdays_bitmask = bitmask(:week_days, sel_weekdays, size: 8)

    sel_user_id = param(:user_identifier, :uint, size: 8)
    sel_slot_id = param(:schedule_slot_id, :uint, size: 8)

    sel_set_action =
      enum(:set_action, ZWEnum.new(%{erase: 0, modify: 1}),
        size: 8,
        opts: [if_unknown: {:value, :unknown}]
      )

    sel_week_day_params = [
      sel_user_id,
      sel_slot_id,
      param(:day_of_week, :uint, size: 8),
      param(:start_hour, :uint, size: 8),
      param(:start_minute, :uint, size: 8),
      param(:stop_hour, :uint, size: 8),
      param(:stop_minute, :uint, size: 8)
    ]

    sel_year_day_params = [
      sel_user_id,
      sel_slot_id,
      param(:start_year, :uint, size: 8),
      param(:start_month, :uint, size: 8),
      param(:start_day, :uint, size: 8),
      param(:start_hour, :uint, size: 8),
      param(:start_minute, :uint, size: 8),
      param(:stop_year, :uint, size: 8),
      param(:stop_month, :uint, size: 8),
      param(:stop_day, :uint, size: 8),
      param(:stop_hour, :uint, size: 8),
      param(:stop_minute, :uint, size: 8)
    ]

    sel_tzo_params = [
      enum(:sign_tzo, Encoding.tz_offset_signs(), size: 1),
      param(:hour_tzo, :uint, size: 7),
      param(:minute_tzo, :uint, size: 8),
      enum(:sign_offset_dst, Encoding.tz_offset_signs(), size: 1),
      param(:minute_offset_dst, :uint, size: 7)
    ]

    command :schedule_entry_lock_enable_set, 0x01, Cmds.Generic,
      params: [
        sel_user_id,
        param(:enabled, :boolean, size: 8, opts: [true: 1, false: 0])
      ]

    command :schedule_entry_lock_enable_all_set, 0x02, Cmds.Generic,
      params: [
        param(:enabled, :boolean, size: 8, opts: [true: 1, false: 0])
      ]

    command :schedule_entry_lock_week_day_set, 0x03, Cmds.Generic,
      params: [sel_set_action | sel_week_day_params]

    command :schedule_entry_lock_week_day_get, 0x04, Cmds.Generic,
      params: [sel_user_id, sel_slot_id]

    command :schedule_entry_lock_week_day_report, 0x05, Cmds.Generic, params: sel_week_day_params

    command :schedule_entry_lock_year_day_set, 0x06, Cmds.Generic,
      params: [sel_set_action | sel_year_day_params]

    command :schedule_entry_lock_year_day_get, 0x07, Cmds.Generic,
      params: [sel_user_id, sel_slot_id]

    command :schedule_entry_lock_year_day_report, 0x08, Cmds.Generic, params: sel_year_day_params
    command :schedule_entry_type_supported_get, 0x09, Cmds.Generic, params: []

    command :schedule_entry_type_supported_report, 0x0A, Cmds.Generic,
      params: [
        param(:number_of_slots_week_day, :uint, size: 8),
        param(:number_of_slots_year_day, :uint, size: 8),
        param(:number_of_slots_daily_repeating, :uint, size: 8, required: false)
      ]

    command :schedule_entry_lock_time_offset_get, 0x0B, Cmds.Generic, params: []
    command :schedule_entry_lock_time_offset_report, 0x0C, Cmds.Generic, params: sel_tzo_params
    command :schedule_entry_lock_time_offset_set, 0x0D, Cmds.Generic, params: sel_tzo_params

    command :schedule_entry_lock_daily_repeating_get, 0x0E, Cmds.Generic,
      params: [sel_user_id, sel_slot_id]

    command :schedule_entry_lock_daily_repeating_report, 0x0F, Cmds.Generic,
      params: [
        sel_user_id,
        sel_slot_id,
        sel_weekdays_bitmask,
        param(:start_hour, :uint, size: 8),
        param(:start_minute, :uint, size: 8),
        param(:duration_hour, :uint, size: 8),
        param(:duration_minute, :uint, size: 8)
      ]

    command :schedule_entry_lock_daily_repeating_set, 0x10, Cmds.Generic,
      params: [
        sel_set_action,
        sel_user_id,
        sel_slot_id,
        sel_weekdays_bitmask,
        param(:start_hour, :uint, size: 8),
        param(:start_minute, :uint, size: 8),
        param(:duration_hour, :uint, size: 8),
        param(:duration_minute, :uint, size: 8)
      ]
  end

  command_class :security, 0x98 do
    command :s0_commands_supported_get, 0x02, Cmds.Generic, params: []

    command :s0_commands_supported_report, 0x03, Cmds.S0CommandsSupportedReport,
      default_params: [supported: [], controlled: [], reports_to_follow: 0]

    s0_security_schemes_params = [
      param(:supported_security_schemes, :constant,
        size: 8,
        required: false,
        opts: [value: [supported_security_schemes: [:s0]]]
      )
    ]

    command :s0_security_scheme_get, 0x04, Cmds.Generic, params: s0_security_schemes_params
    command :s0_security_scheme_report, 0x05, Cmds.Generic, params: s0_security_schemes_params

    command :s0_network_key_set, 0x06, Cmds.Generic,
      report: :s0_network_key_verify,
      params: [
        param(:network_key, :binary, size: :variable)
      ]

    command :s0_network_key_verify, 0x07, Cmds.Generic, params: []

    command :s0_security_scheme_inherit, 0x08, Cmds.Generic,
      report: :s0_security_scheme_report,
      params: s0_security_schemes_params

    command :s0_nonce_get, 0x40, Cmds.Generic, params: []
    command :s0_nonce_report, 0x80, Cmds.Generic, params: [param(:nonce, :binary, size: 8 * 8)]
    command :s0_message_encapsulation, 0x81, Cmds.S0MessageEncapsulation
  end

  command_class :security_2, 0x9F do
    command :s2_nonce_get, 0x01, Cmds.Generic, params: []

    command :s2_nonce_report, 0x02, Cmds.Generic,
      params: [
        param(:seq_number, :uint, size: 8),
        reserved(size: 6),
        param(:mpan_out_of_sync?, :boolean, size: 1),
        param(:span_out_of_sync?, :boolean, size: 1),
        param(:receivers_entropy_input, :binary, size: 16 * 8)
      ]

    command :s2_message_encapsulation, 0x03, Cmds.S2MessageEncapsulation
    command :s2_kex_get, 0x04, Cmds.Generic, params: [], supports_supervision?: false
    command :s2_kex_report, 0x05, Cmds.S2KexReport, supports_supervision?: false
    command :s2_kex_set, 0x06, Cmds.S2KexSet, supports_supervision?: false

    command :s2_kex_fail, 0x07, Cmds.Generic,
      supports_supervision?: false,
      params: [
        enum(:kex_fail_type, Encoding.kex_fail_types(), size: 8)
      ]

    command :s2_public_key_report, 0x08, Cmds.Generic,
      supports_supervision?: false,
      params: [
        reserved(size: 7),
        param(:including_node, :boolean, size: 1),
        param(:ecdh_public_key, :binary, size: :variable)
      ]

    command :s2_network_key_get, 0x09, Cmds.Generic,
      supports_supervision?: false,
      params: [
        enum(:requested_key, Encoding.security_key_types(), size: 8)
      ]

    command :s2_network_key_report, 0x0A, Cmds.Generic,
      supports_supervision?: false,
      params: [
        enum(:granted_key, Encoding.security_key_types(), size: 8),
        param(:network_key, :binary, size: 16 * 8)
      ]

    command :s2_network_key_verify, 0x0B, Cmds.Generic, params: [], supports_supervision?: false

    command :s2_transfer_end, 0x0C, Cmds.Generic,
      supports_supervision?: false,
      params: [
        reserved(size: 6),
        param(:key_verified, :boolean, size: 1),
        param(:key_request_complete, :boolean, size: 1)
      ]

    command :s2_commands_supported_get, 0x0D, Cmds.Generic, params: []

    command :s2_commands_supported_report, 0x0E, Cmds.S2CommandsSupportedReport,
      default_params: [command_classes: []]
  end

  command_class :sensor_binary, 0x30 do
    command :sensor_binary_supported_sensor_get, 0x01, Cmds.Generic, params: []

    command :sensor_binary_get, 0x02, Cmds.Generic,
      params: [
        enum(:sensor_type, Encoding.binary_sensor_types(), size: 8)
      ]

    command :sensor_binary_report, 0x03

    command :sensor_binary_supported_sensor_report, 0x04, Cmds.Generic,
      params: [
        bitmask(:sensor_types, Encoding.binary_sensor_types(), size: 16)
      ]
  end

  command_class :sensor_multilevel, 0x31 do
    command :sensor_multilevel_supported_sensor_get, 0x01, Cmds.Generic, params: []
    command :sensor_multilevel_supported_sensor_report, 0x02

    command :sensor_multilevel_supported_scale_get, 0x03, Cmds.Generic,
      params: [
        param(:sensor_type, :any,
          size: 8,
          opts: [
            encode: &CommandClasses.SensorMultilevel.encode_sensor_type/1,
            decode: &CommandClasses.SensorMultilevel.decode_sensor_type/1
          ]
        )
      ]

    command :sensor_multilevel_get, 0x04
    command :sensor_multilevel_report, 0x05
    command :sensor_multilevel_supported_scale_report, 0x06
  end

  command_class :sound_switch, 0x79 do
    tone_identifier = param(:tone_identifier, :uint, size: 8)

    play_params = [tone_identifier, param(:volume, :uint, size: 8, required: false)]

    config_params = [
      param(:volume, :uint, size: 8),
      param(:default_tone_identifier, :uint, size: 8)
    ]

    command :sound_switch_tones_number_get, 0x01, Cmds.Generic, params: []

    command :sound_switch_tones_number_report, 0x02, Cmds.Generic,
      params: [
        param(:supported_tones, :uint, size: 8)
      ]

    command :sound_switch_tone_info_get, 0x03, Cmds.Generic, params: [tone_identifier]
    command :sound_switch_tone_info_report, 0x04
    command :sound_switch_configuration_set, 0x05, Cmds.Generic, params: config_params
    command :sound_switch_configuration_get, 0x06, Cmds.Generic, params: []
    command :sound_switch_configuration_report, 0x07, Cmds.Generic, params: config_params
    command :sound_switch_tone_play_set, 0x08, Cmds.Generic, params: play_params
    command :sound_switch_tone_play_get, 0x09, Cmds.Generic, params: []
    command :sound_switch_tone_play_report, 0x0A, Cmds.Generic, params: play_params
  end

  command_class :supervision, 0x6C do
    command :supervision_get, 0x01
    command :supervision_report, 0x02
  end

  command_class :switch_binary, 0x25 do
    command :switch_binary_set, 0x01
    command :switch_binary_get, 0x02, Cmds.Generic, params: []
    command :switch_binary_report, 0x03
  end

  command_class :switch_multilevel, 0x26 do
    command :switch_multilevel_set, 0x01
    command :switch_multilevel_get, 0x02, Cmds.Generic, params: []
    command :switch_multilevel_report, 0x03
    command :switch_multilevel_start_level_change, 0x04
    command :switch_multilevel_stop_level_change, 0x05, Cmds.Generic, params: []
  end

  command_class :thermostat_fan_mode, 0x44 do
    mode = enum(:mode, Encoding.thermostat_fan_modes(), size: 4)

    command :thermostat_fan_mode_set, 0x01, Cmds.Generic, params: [reserved(size: 4), mode]
    command :thermostat_fan_mode_get, 0x02, Cmds.Generic, params: []
    command :thermostat_fan_mode_report, 0x03, Cmds.Generic, params: [reserved(size: 4), mode]
    command :thermostat_fan_mode_supported_get, 0x04, Cmds.Generic, params: []

    command :thermostat_fan_mode_supported_report, 0x05, Cmds.Generic,
      params: [bitmask(:modes, Encoding.thermostat_fan_modes(), size: :variable)]
  end

  command_class :thermostat_fan_state, 0x45 do
    command :thermostat_fan_state_get, 0x02, Cmds.Generic, params: []

    command :thermostat_fan_state_report, 0x03, Cmds.Generic,
      params: [
        reserved(size: 4),
        enum(:state, Encoding.thermostat_fan_states(), size: 4)
      ]
  end

  command_class :thermostat_mode, 0x40 do
    command :thermostat_mode_set, 0x01, Cmds.ThermostatModeSetReport
    command :thermostat_mode_get, 0x02, Cmds.Generic, params: []
    command :thermostat_mode_report, 0x03, Cmds.ThermostatModeSetReport
    command :thermostat_mode_supported_get, 0x04, Cmds.Generic, params: []
    command :thermostat_mode_supported_report, 0x05
  end

  command_class :thermostat_operating_state, 0x42 do
    command :thermostat_operating_state_get, 0x02, Cmds.Generic, params: []

    command :thermostat_operating_state_report, 0x03, Cmds.Generic,
      params: [
        enum(:state, Encoding.thermostat_operating_states(), size: 8)
      ]
  end

  command_class :thermostat_setback, 0x47 do
    setback_params = [
      reserved(size: 6),
      param(:type, :any,
        size: 2,
        opts: [
          encode: &CommandClasses.ThermostatSetback.encode_type/1,
          decode: &CommandClasses.ThermostatSetback.decode_type/1
        ]
      ),
      param(:state, :any,
        size: 8,
        opts: [
          encode: &CommandClasses.ThermostatSetback.encode_state/1,
          decode: &CommandClasses.ThermostatSetback.decode_state/1
        ]
      )
    ]

    command :thermostat_setback_set, 0x01, Cmds.Generic, params: setback_params
    command :thermostat_setback_get, 0x02, Cmds.Generic, params: []
    command :thermostat_setback_report, 0x03, Cmds.Generic, params: setback_params
  end

  command_class :thermostat_setpoint, 0x43 do
    command :thermostat_setpoint_set, 0x01

    command :thermostat_setpoint_get, 0x02, Cmds.Generic,
      params: [
        reserved(size: 4),
        param(:type, :any,
          size: 4,
          opts: [
            encode: &CommandClasses.ThermostatSetpoint.encode_type/1,
            decode: &CommandClasses.ThermostatSetpoint.decode_type/1
          ]
        )
      ]

    command :thermostat_setpoint_report, 0x03
    command :thermostat_setpoint_supported_get, 0x04, Cmds.Generic, params: []
    command :thermostat_setpoint_supported_report, 0x05
    command :thermostat_setpoint_capabilities_get, 0x09
    command :thermostat_setpoint_capabilities_report, 0x0A
  end

  command_class :time, 0x8A do
    command :time_get, 0x01, Cmds.Generic, params: []

    command :time_report, 0x02, Cmds.Generic,
      params: [
        param(:rtc_failure?, :boolean, size: 1, default: false),
        reserved(size: 2),
        param(:hour, :uint, size: 5),
        param(:minute, :uint, size: 8),
        param(:second, :uint, size: 8)
      ]

    command :date_get, 0x03, Cmds.Generic, params: []

    command :date_report, 0x04, Cmds.Generic,
      params: [
        param(:year, :uint, size: 16),
        param(:month, :uint, size: 8),
        param(:day, :uint, size: 8)
      ]

    time_offset_params = [
      enum(:sign_tzo, Encoding.tz_offset_signs(), size: 1),
      param(:hour_tzo, :uint, size: 7),
      param(:minute_tzo, :uint, size: 8),
      enum(:sign_offset_dst, Encoding.tz_offset_signs(), size: 1),
      param(:minute_offset_dst, :uint, size: 7),
      param(:month_start_dst, :uint, size: 8),
      param(:day_start_dst, :uint, size: 8),
      param(:hour_start_dst, :uint, size: 8),
      param(:month_end_dst, :uint, size: 8),
      param(:day_end_dst, :uint, size: 8),
      param(:hour_end_dst, :uint, size: 8)
    ]

    command :time_offset_set, 0x05, Cmds.Generic, params: time_offset_params
    command :time_offset_get, 0x06, Cmds.Generic, params: []
    command :time_offset_report, 0x07, Cmds.Generic, params: time_offset_params
  end

  command_class :time_parameters, 0x8B do
    time_param_params = [
      param(:year, :uint, size: 16),
      param(:month, :uint, size: 8),
      param(:day, :uint, size: 8),
      param(:hour_utc, :uint, size: 8),
      param(:minute_utc, :uint, size: 8),
      param(:second_utc, :uint, size: 8)
    ]

    command :time_parameters_set, 0x01, Cmds.Generic, params: time_param_params
    command :time_parameters_get, 0x02, Cmds.Generic, params: []
    command :time_parameters_report, 0x03, Cmds.Generic, params: time_param_params
  end

  command_class :user_code, 0x63 do
    keypad_mode = enum(:mode, Encoding.user_code_keypad_modes(), size: 8)

    admin_code_params = [
      reserved(size: 4),
      param(:length, {:length, :code}, size: 4),
      param(:code, :binary, size: {:variable, :length})
    ]

    command :user_code_set, 0x01

    command :user_code_get, 0x02, Cmds.Generic,
      params: [
        param(:user_id, :uint, size: 8)
      ]

    command :user_code_report, 0x03
    command :user_code_users_number_get, 0x04, Cmds.Generic, params: []

    command :user_code_users_number_report, 0x05, Cmds.Generic,
      params: [
        param(:supported_users, :uint, size: 8),
        param(:extended_supported_users, :uint, size: 16, required: false)
      ]

    command :user_code_capabilities_get, 0x06, Cmds.Generic, params: []
    command :user_code_capabilities_report, 0x07
    command :user_code_keypad_mode_set, 0x08, Cmds.Generic, params: [keypad_mode]
    command :user_code_keypad_mode_get, 0x09, Cmds.Generic, params: []
    command :user_code_keypad_mode_report, 0x0A, Cmds.Generic, params: [keypad_mode]
    command :extended_user_code_set, 0x0B

    command :extended_user_code_get, 0x0C, Cmds.Generic,
      params: [
        param(:user_id, :uint, size: 16),
        reserved(size: 7),
        param(:report_more?, :boolean, size: 1)
      ]

    command :extended_user_code_report, 0x0D
    command :admin_code_set, 0x0E, Cmds.Generic, params: admin_code_params
    command :admin_code_get, 0x0F, Cmds.Generic, params: []
    command :admin_code_report, 0x10, Cmds.Generic, params: admin_code_params
    command :user_code_checksum_get, 0x11, Cmds.Generic, params: []

    command :user_code_checksum_report, 0x12, Cmds.Generic,
      params: [
        param(:checksum, :uint, size: 16)
      ]
  end

  command_class :user_credential, 0x83 do
    user_id = param(:user_id, :uint, size: 16)
    credential_slot = param(:credential_slot, :uint, size: 16)
    credential_type = enum(:credential_type, Encoding.uc_credential_types(), size: 8)
    checksum = param(:checksum, :uint, size: 16)

    admin_pin_code_common_params = [
      param(:length, {:length, :code}, size: 4),
      param(:code, :binary, size: {:variable, :length})
    ]

    credential_learn_operation = enum(:operation_type, ZWEnum.new(%{add: 0, modify: 1}), size: 8)

    command :user_capabilities_get, 0x01, Cmds.Generic, params: []
    command :user_capabilities_report, 0x02
    command :credential_capabilities_get, 0x03, Cmds.Generic, params: []
    command :credential_capabilities_report, 0x04
    command :user_set, 0x05
    command :user_get, 0x06, Cmds.Generic, params: [user_id]
    command :user_report, 0x07
    command :credential_set, 0x0A

    command :credential_get, 0x0B, Cmds.Generic,
      params: [user_id, credential_type, credential_slot]

    command :credential_report, 0x0C

    command :credential_learn_start, 0x0F, Cmds.Generic,
      params: [
        user_id,
        credential_type,
        credential_slot,
        credential_learn_operation,
        param(:learn_timeout, :uint, size: 8)
      ]

    command :credential_learn_cancel, 0x10, Cmds.Generic, params: []

    command :credential_learn_status_report, 0x11, Cmds.Generic,
      params: [
        enum(:status, Encoding.credential_learn_statuses(), size: 8),
        user_id,
        credential_type,
        credential_slot,
        param(:steps_remaining, :uint, size: 8)
      ]

    command :user_credential_association_set, 0x12, Cmds.Generic,
      params: [
        credential_type,
        credential_slot,
        param(:destination_user_id, :uint, size: 16)
      ]

    command :user_credential_association_report, 0x13, Cmds.Generic,
      params: [
        credential_type,
        credential_slot,
        param(:destination_user_id, :uint, size: 16),
        enum(:status, Encoding.uc_association_set_statuses(), size: 8)
      ]

    command :all_users_checksum_get, 0x14, Cmds.Generic, params: []
    command :all_users_checksum_report, 0x15, Cmds.Generic, params: [checksum]
    command :user_checksum_get, 0x16, Cmds.Generic, params: [user_id]
    command :user_checksum_report, 0x17, Cmds.Generic, params: [user_id, checksum]
    command :credential_checksum_get, 0x18, Cmds.Generic, params: [credential_type]
    command :credential_checksum_report, 0x19, Cmds.Generic, params: [credential_type, checksum]

    command :admin_pin_code_set, 0x1A, Cmds.Generic,
      params: [reserved(size: 4) | admin_pin_code_common_params]

    command :admin_pin_code_get, 0x1B, Cmds.Generic, params: []

    command :admin_pin_code_report, 0x1C, Cmds.Generic,
      params: [
        enum(:result, Encoding.uc_admin_pin_code_set_statuses(), size: 4)
        | admin_pin_code_common_params
      ]
  end

  command_class :version, 0x86 do
    command :version_get, 0x11, Cmds.Generic, params: []
    command :version_report, 0x12

    command :version_command_class_get, 0x13,
      report_matcher_fun: {Cmds.VersionCommandClassGet, :report_matches_get?}

    command :version_command_class_report, 0x14
    command :version_capabilities_get, 0x15, Cmds.Generic, params: []

    command :version_capabilities_report, 0x16, Cmds.Generic,
      params: [
        reserved(size: 5),
        param(:zwave_software, :boolean, size: 1),
        param(:command_class, :boolean, size: 1),
        param(:version, :boolean, size: 1)
      ]

    command :version_zwave_software_get, 0x17, Cmds.Generic, params: []
    command :version_zwave_software_report, 0x18, Cmds.VersionZWaveSoftwareReport
  end

  command_class :wake_up, 0x84 do
    set_report_params = [
      param(:seconds, :uint, size: 24),
      param(:node_id, :uint, size: 8)
    ]

    command :wake_up_interval_set, 0x04, Cmds.Generic, params: set_report_params
    command :wake_up_interval_get, 0x05, Cmds.Generic, params: []
    command :wake_up_interval_report, 0x06, Cmds.Generic, params: set_report_params
    command :wake_up_notification, 0x07, Cmds.Generic, params: []
    command :wake_up_no_more_information, 0x08, Cmds.Generic, params: []
    command :wake_up_interval_capabilities_get, 0x09, Cmds.Generic, params: []
    command :wake_up_interval_capabilities_report, 0x0A
  end

  command_class :window_covering, 0x6A do
    command :window_covering_supported_get, 0x01, Cmds.Generic, params: []
    command :window_covering_supported_report, 0x02
    command :window_covering_get, 0x03
    command :window_covering_report, 0x04
    command :window_covering_set, 0x05
    command :window_covering_start_level_change, 0x06
    command :window_covering_stop_level_change, 0x07
  end

  command_class :zip, 0x23 do
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

  command_class :zip_gateway, 0x5F do
    command :application_node_info_get, 0x0C, Cmds.Generic, params: []
    command :application_node_info_report, 0x0D
  end

  command_class :zwaveplus_info, 0x5E do
    command :zwaveplus_info_get, 0x01, Cmds.Generic, params: []
    command :zwaveplus_info_report, 0x02
  end

  @doc """
  Get the command spec for a given command name.

  ## Examples

      iex> Grizzly.ZWave.Commands.spec_for(:user_set)
      {:ok, %Grizzly.ZWave.CommandSpec{
        name: :user_set,
        command_byte: 0x05,
        command_class: :user_credential,
        default_params: [],
        module: Grizzly.ZWave.Commands.UserSet,
        encode_fun: {Grizzly.ZWave.Commands.UserSet, :encode_params},
        decode_fun: {Grizzly.ZWave.Commands.UserSet, :decode_params},
        handler: {Grizzly.Requests.Handlers.AckResponse, []},
        supports_supervision?: true
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
      Command.new(spec, params)
    end
  end

  @spec create!(atom(), keyword()) :: Grizzly.ZWave.Command.t()
  def create!(command_name, params \\ []) do
    command_name
    |> spec_for!()
    |> Command.new(params)
    |> then(fn {:ok, cmd} -> cmd end)
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
         {:ok, decoded_params} <- apply(mod, fun, [spec, params]) do
      Command.new(spec, decoded_params)
    else
      {:error, :unknown_command} ->
        {:error, %ZWaveError{binary: binary}}

      {:error, %DecodeError{command: nil} = err} ->
        err =
          case spec_for(cc_byte, command_byte) do
            {:ok, spec} -> %DecodeError{err | command: spec.name}
            _ -> err
          end

        {:error, err}

      other ->
        other
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
