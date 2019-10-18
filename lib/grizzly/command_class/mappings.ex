defmodule Grizzly.CommandClass.Mappings do
  @type command_class_name :: atom
  @type command_class_type :: :raw | :network | :application | :management

  @type command_class_byte :: byte()

  @type command_class_unk :: {:unk, byte}
  @type specific_cmd_class_unk :: {:unk, byte, byte}

  @known_network_command_classes [0x34]

  require Logger

  @spec from_byte(byte) :: command_class_name | command_class_unk
  def from_byte(0x02), do: :zensor_net
  def from_byte(0x20), do: :basic
  def from_byte(0x21), do: :controller_replication
  def from_byte(0x22), do: :application_status
  def from_byte(0x23), do: :zip
  def from_byte(0x24), do: :security_panel_mode
  def from_byte(0x25), do: :switch_binary
  def from_byte(0x26), do: :switch_multilevel
  def from_byte(0x27), do: :switch_all
  def from_byte(0x28), do: :switch_toggle_binary
  def from_byte(0x2A), do: :chimney_fan
  def from_byte(0x2B), do: :scene_activation
  def from_byte(0x2C), do: :scene_actuator_conf
  def from_byte(0x2D), do: :scene_controller_conf
  def from_byte(0x2E), do: :security_panel_zone
  def from_byte(0x2F), do: :security_panel_zone_sensor
  def from_byte(0x30), do: :sensor_binary
  def from_byte(0x31), do: :sensor_multilevel
  def from_byte(0x32), do: :meter
  def from_byte(0x33), do: :switch_color
  def from_byte(0x34), do: :network_management_inclusion
  def from_byte(0x35), do: :meter_pulse
  def from_byte(0x36), do: :basic_tariff_info
  def from_byte(0x37), do: :hrv_status
  def from_byte(0x38), do: :thermostat_heating
  def from_byte(0x39), do: :hrv_control
  def from_byte(0x3A), do: :dcp_config
  def from_byte(0x3B), do: :dcp_monitor
  def from_byte(0x3C), do: :meter_tbl_config
  def from_byte(0x3D), do: :meter_tbl_monitor
  def from_byte(0x3E), do: :meter_tbl_push
  def from_byte(0x3F), do: :prepayment
  def from_byte(0x40), do: :thermostat_mode
  def from_byte(0x41), do: :prepayment_encapsulation
  def from_byte(0x42), do: :operating_state
  def from_byte(0x43), do: :thermostat_setpoint
  def from_byte(0x44), do: :thermostat_fan_mode
  def from_byte(0x45), do: :thermostat_fan_state
  def from_byte(0x46), do: :climate_control_schedule
  def from_byte(0x47), do: :thermostat_setback
  def from_byte(0x48), do: :rate_tbl_config
  def from_byte(0x49), do: :rate_tbl_monitor
  def from_byte(0x4A), do: :tariff_config
  def from_byte(0x4B), do: :tariff_tbl_monitor
  def from_byte(0x4C), do: :door_lock_logging
  def from_byte(0x4D), do: :network_management_basic
  def from_byte(0x4E), do: :schedule_entry_lock
  def from_byte(0x4F), do: :zip_6lowpan
  def from_byte(0x50), do: :basic_window_covering
  def from_byte(0x51), do: :mtp_window_covering
  def from_byte(0x52), do: :network_management_proxy
  def from_byte(0x53), do: :schedule
  def from_byte(0x54), do: :network_management_primary
  def from_byte(0x55), do: :transport_service
  def from_byte(0x56), do: :crc_16_encap
  def from_byte(0x57), do: :application_capability
  def from_byte(0x58), do: :zip_nd
  def from_byte(0x59), do: :association_group_info
  def from_byte(0x5A), do: :device_rest_locally
  def from_byte(0x5B), do: :central_scene
  def from_byte(0x5C), do: :ip_association
  def from_byte(0x5D), do: :antitheft
  def from_byte(0x5E), do: :zwaveplus_info
  def from_byte(0x5F), do: :zip_gateway
  def from_byte(0x61), do: :zip_portal
  def from_byte(0x62), do: :door_lock
  def from_byte(0x63), do: :user_code
  def from_byte(0x64), do: :humidity_control_setpoint
  def from_byte(0x65), do: :dmx
  def from_byte(0x66), do: :barrier_operator
  def from_byte(0x67), do: :network_management_installation_maintenance
  def from_byte(0x68), do: :zip_naming
  def from_byte(0x69), do: :mailbox
  def from_byte(0x6A), do: :window_covering
  def from_byte(0x6B), do: :irrigation
  def from_byte(0x6C), do: :supervision
  def from_byte(0x6D), do: :humidity_control_mode
  def from_byte(0x6E), do: :humidity_control_operating_state
  def from_byte(0x6F), do: :entry_control
  def from_byte(0x70), do: :configuration
  def from_byte(0x71), do: :alarm
  def from_byte(0x72), do: :manufacturer_specific
  def from_byte(0x73), do: :powerlevel
  def from_byte(0x74), do: :inclusion_controller
  def from_byte(0x75), do: :protection
  def from_byte(0x76), do: :lock
  def from_byte(0x77), do: :node_naming
  def from_byte(0x78), do: :node_provisioning
  def from_byte(0x7A), do: :firmware_update_md
  def from_byte(0x7B), do: :grouping_name
  def from_byte(0x7C), do: :remote_association_activate
  def from_byte(0x7D), do: :remote_association
  def from_byte(0x80), do: :battery
  def from_byte(0x81), do: :clock
  def from_byte(0x82), do: :hail
  def from_byte(0x84), do: :wake_up
  def from_byte(0x85), do: :association
  def from_byte(0x86), do: :command_class_version
  def from_byte(0x87), do: :indicator
  def from_byte(0x88), do: :proprietary
  def from_byte(0x89), do: :language
  def from_byte(0x8A), do: :time
  def from_byte(0x8B), do: :time_parameters
  def from_byte(0x8C), do: :geographic_location
  def from_byte(0x8E), do: :multi_channel_association
  def from_byte(0x8F), do: :multi_cmd
  def from_byte(0x90), do: :energy_production
  def from_byte(0x91), do: :manufacturer_proprietary
  def from_byte(0x92), do: :screen_md
  def from_byte(0x93), do: :screen_attributes
  def from_byte(0x94), do: :simple_av_control
  def from_byte(0x95), do: :av_content_directory_md
  def from_byte(0x96), do: :av_content_renderer_status
  def from_byte(0x97), do: :av_content_search_md
  def from_byte(0x98), do: :security
  def from_byte(0x99), do: :av_tagging_md
  def from_byte(0x9A), do: :ip_configuration
  def from_byte(0x9B), do: :association_command_configuration
  def from_byte(0x9C), do: :sensor_alarm
  def from_byte(0x9D), do: :silence_alarm
  def from_byte(0x9E), do: :sensor_configuration
  def from_byte(0x9F), do: :security_2
  def from_byte(0xEF), do: :mark
  def from_byte(0xF0), do: :non_interoperable

  def from_byte(byte) do
    _ = Logger.warn("Unknown command class byte #{Integer.to_string(byte, 16)}")
    {:unk, byte}
  end

  @spec to_byte(command_class_name) :: command_class_byte() | command_class_unk()
  def to_byte(:zensor_net), do: 0x02
  def to_byte(:basic), do: 0x20
  def to_byte(:controller_replication), do: 0x21
  def to_byte(:application_status), do: 0x22
  def to_byte(:zip), do: 0x23
  def to_byte(:security_panel_mode), do: 0x24
  def to_byte(:switch_binary), do: 0x25
  def to_byte(:switch_multilevel), do: 0x26
  def to_byte(:switch_all), do: 0x27
  def to_byte(:switch_toggle_binary), do: 0x28
  def to_byte(:chimney_fan), do: 0x2A
  def to_byte(:scene_activation), do: 0x2B
  def to_byte(:scene_actuator_conf), do: 0x2C
  def to_byte(:scene_controller_conf), do: 0x2D
  def to_byte(:security_panel_zone), do: 0x2E
  def to_byte(:security_panel_zone_sensor), do: 0x2F
  def to_byte(:sensor_binary), do: 0x30
  def to_byte(:sensor_multilevel), do: 0x31
  def to_byte(:meter), do: 0x32
  def to_byte(:switch_color), do: 0x33
  def to_byte(:network_management_inclusion), do: 0x34
  def to_byte(:meter_pulse), do: 0x35
  def to_byte(:basic_tariff_info), do: 0x36
  def to_byte(:hrv_status), do: 0x37
  def to_byte(:thermostat_heating), do: 0x38
  def to_byte(:hrv_control), do: 0x39
  def to_byte(:dcp_config), do: 0x3A
  def to_byte(:dcp_monitor), do: 0x3B
  def to_byte(:meter_tbl_config), do: 0x3C
  def to_byte(:meter_tbl_monitor), do: 0x3D
  def to_byte(:meter_tbl_push), do: 0x3E
  def to_byte(:prepayment), do: 0x3F
  def to_byte(:thermostat_mode), do: 0x40
  def to_byte(:prepayment_encapsulation), do: 0x41
  def to_byte(:operating_state), do: 0x42
  def to_byte(:thermostat_setpoint), do: 0x43
  def to_byte(:thermostat_fan_mode), do: 0x44
  def to_byte(:thermostat_fan_state), do: 0x45
  def to_byte(:climate_control_schedule), do: 0x46
  def to_byte(:thermostat_setback), do: 0x47
  def to_byte(:rate_tbl_config), do: 0x48
  def to_byte(:rate_tbl_monitor), do: 0x49
  def to_byte(:tariff_config), do: 0x4A
  def to_byte(:tariff_tbl_monitor), do: 0x4B
  def to_byte(:door_lock_logging), do: 0x4C
  def to_byte(:network_management_basic), do: 0x4D
  def to_byte(:schedule_entry_lock), do: 0x4E
  def to_byte(:zip_6lowpan), do: 0x4F
  def to_byte(:basic_window_covering), do: 0x50
  def to_byte(:mtp_window_covering), do: 0x51
  def to_byte(:network_management_proxy), do: 0x52
  def to_byte(:schedule), do: 0x53
  def to_byte(:network_management_primary), do: 0x54
  def to_byte(:transport_service), do: 0x55
  def to_byte(:crc_16_encap), do: 0x56
  def to_byte(:application_capability), do: 0x57
  def to_byte(:zip_nd), do: 0x58
  def to_byte(:association_group_info), do: 0x59
  def to_byte(:device_rest_locally), do: 0x5A
  def to_byte(:central_scene), do: 0x5B
  def to_byte(:ip_association), do: 0x5C
  def to_byte(:antitheft), do: 0x5D
  def to_byte(:zwaveplus_info), do: 0x5E
  def to_byte(:zip_gateway), do: 0x5F
  def to_byte(:zip_portal), do: 0x61
  def to_byte(:door_lock), do: 0x62
  def to_byte(:user_code), do: 0x63
  def to_byte(:humidity_control_setpoint), do: 0x64
  def to_byte(:dmx), do: 0x65
  def to_byte(:barrier_operator), do: 0x66
  def to_byte(:network_management_installation_maintenance), do: 0x67
  def to_byte(:zip_naming), do: 0x68
  def to_byte(:mailbox), do: 0x69
  def to_byte(:window_covering), do: 0x6A
  def to_byte(:irrigation), do: 0x6B
  def to_byte(:supervision), do: 0x6C
  def to_byte(:humidity_control_mode), do: 0x6D
  def to_byte(:humidity_control_operating_state), do: 0x6E
  def to_byte(:entry_control), do: 0x6F
  def to_byte(:configuration), do: 0x70
  def to_byte(:alarm), do: 0x71
  def to_byte(:manufacturer_specific), do: 0x72
  def to_byte(:powerlevel), do: 0x73
  def to_byte(:inclusion_controller), do: 0x74
  def to_byte(:protection), do: 0x75
  def to_byte(:lock), do: 0x76
  def to_byte(:node_naming), do: 0x77
  def to_byte(:node_provisioning), do: 0x78
  def to_byte(:firmware_update_md), do: 0x7A
  def to_byte(:grouping_name), do: 0x7B
  def to_byte(:remote_association_activate), do: 0x7C
  def to_byte(:remote_association), do: 0x7D
  def to_byte(:battery), do: 0x80
  def to_byte(:clock), do: 0x81
  def to_byte(:hail), do: 0x82
  def to_byte(:wake_up), do: 0x84
  def to_byte(:association), do: 0x85
  def to_byte(:command_class_version), do: 0x86
  def to_byte(:indicator), do: 0x87
  def to_byte(:proprietary), do: 0x88
  def to_byte(:language), do: 0x89
  def to_byte(:time), do: 0x8A
  def to_byte(:time_parameters), do: 0x8B
  def to_byte(:geographic_location), do: 0x8C
  def to_byte(:multi_channel_association), do: 0x8E
  def to_byte(:multi_cmd), do: 0x8F
  def to_byte(:energy_production), do: 0x90
  def to_byte(:manufacturer_proprietary), do: 0x91
  def to_byte(:screen_md), do: 0x92
  def to_byte(:screen_attributes), do: 0x93
  def to_byte(:simple_av_control), do: 0x94
  def to_byte(:av_content_directory_md), do: 0x95
  def to_byte(:av_content_renderer_status), do: 0x96
  def to_byte(:av_content_search_md), do: 0x97
  def to_byte(:security), do: 0x98
  def to_byte(:av_tagging_md), do: 0x99
  def to_byte(:ip_configuration), do: 0x9A
  def to_byte(:association_command_configuration), do: 0x9B
  def to_byte(:sensor_alarm), do: 0x9C
  def to_byte(:silence_alarm), do: 0x9D
  def to_byte(:sensor_configuration), do: 0x9E
  def to_byte(:security_2), do: 0x9F
  def to_byte(:mark), do: 0xEF
  def to_byte(:non_interoperable), do: 0xF0

  def to_byte(command_class) do
    _ = Logger.warn("Unknown command class name #{inspect(command_class)}")
    {:unk, command_class}
  end

  @spec command_from_byte(command_class :: byte, command :: byte) ::
          command_class_name() | command_class_unk()
  def command_from_byte(0x25, 0x01), do: :set
  def command_from_byte(0x25, 0x02), do: :get
  def command_from_byte(0x25, 0x03), do: :switch_binary_report
  def command_from_byte(0x31, 0x05), do: :sensor_multilevel_report
  def command_from_byte(0x32, 0x02), do: :meter_report
  def command_from_byte(0x34, 0x02), do: :node_add_status
  def command_from_byte(0x34, 0x04), do: :node_remove_status
  def command_from_byte(0x43, 0x03), do: :thermostat_setpoint_report
  def command_from_byte(0x52, 0x01), do: :node_list_get
  def command_from_byte(0x52, 0x03), do: :node_info_cache
  def command_from_byte(0x5A, 0x01), do: :device_rest_locally_notification
  def command_from_byte(0x69, 0x03), do: :mailbox_configuration_report
  def command_from_byte(0x71, 0x05), do: :zwave_alarm_event
  def command_from_byte(0x72, 0x04), do: :manufacturer_specific_get
  def command_from_byte(0x72, 0x05), do: :manufacturer_specific_report
  def command_from_byte(0x80, 0x02), do: :get
  def command_from_byte(0x84, 0x05), do: :interval_get
  def command_from_byte(0x84, 0x06), do: :interval_report
  def command_from_byte(0x84, 0x0A), do: :interval_capabilities_report
  def command_from_byte(0x85, 0x01), do: :set
  def command_from_byte(0x85, 0x03), do: :report

  def command_from_byte(command_class_byte, byte) do
    _ =
      Logger.warn(
        "Unknown command from byte #{Integer.to_string(byte, 16)} for command class byte #{
          Integer.to_string(command_class_byte, 16)
        }"
      )

    {:unk, byte}
  end

  @spec byte_to_basic_class(byte) :: command_class_name() | command_class_unk()
  def byte_to_basic_class(0x01), do: :controller
  def byte_to_basic_class(0x02), do: :static_controller
  def byte_to_basic_class(0x03), do: :slave
  def byte_to_basic_class(0x04), do: :routing_slave

  def byte_to_basic_class(byte) do
    _ = Logger.warn("Unknown basic class #{Integer.to_string(byte, 16)}")
    {:unk, byte}
  end

  @spec byte_to_generic_class(byte) :: command_class_name() | command_class_unk()
  def byte_to_generic_class(0x01), do: :generic_controller
  def byte_to_generic_class(0x02), do: :static_controller
  def byte_to_generic_class(0x03), do: :av_control_point
  def byte_to_generic_class(0x04), do: :display
  def byte_to_generic_class(0x05), do: :network_extender
  def byte_to_generic_class(0x06), do: :appliance
  def byte_to_generic_class(0x07), do: :sensor_notification
  def byte_to_generic_class(0x08), do: :thermostat
  def byte_to_generic_class(0x09), do: :window_covering
  def byte_to_generic_class(0x0F), do: :repeater_slave
  def byte_to_generic_class(0x10), do: :switch_binary
  def byte_to_generic_class(0x11), do: :switch_multilevel
  def byte_to_generic_class(0x12), do: :switch_remote
  def byte_to_generic_class(0x13), do: :switch_toggle
  def byte_to_generic_class(0x15), do: :zip_node
  def byte_to_generic_class(0x16), do: :ventilation
  def byte_to_generic_class(0x17), do: :security_panel
  def byte_to_generic_class(0x18), do: :wall_controller
  def byte_to_generic_class(0x20), do: :sensor_binary
  def byte_to_generic_class(0x21), do: :sensor_multilevel
  def byte_to_generic_class(0x30), do: :meter_pulse
  def byte_to_generic_class(0x31), do: :meter
  def byte_to_generic_class(0x40), do: :entry_control
  def byte_to_generic_class(0x50), do: :semi_interoperable
  def byte_to_generic_class(0xA1), do: :sensor_alarm
  def byte_to_generic_class(0xFF), do: :non_interoperable

  def byte_to_generic_class(byte) do
    _ = Logger.warn("Unknown generic class #{Integer.to_string(byte, 16)}")
    {:unk, byte}
  end

  @spec byte_to_specific_class(byte, byte) :: command_class_name() | specific_cmd_class_unk()
  def byte_to_specific_class(0x01, 0x00), do: :not_used
  def byte_to_specific_class(0x01, 0x01), do: :portable_remote_controller
  def byte_to_specific_class(0x01, 0x02), do: :portable_scene_controller
  def byte_to_specific_class(0x01, 0x03), do: :installer_tool
  def byte_to_specific_class(0x01, 0x04), do: :remote_control_av
  def byte_to_specific_class(0x01, 0x06), do: :remote_control_simple

  def byte_to_specific_class(0x02, 0x00), do: :not_used
  def byte_to_specific_class(0x02, 0x01), do: :pc_controller
  def byte_to_specific_class(0x02, 0x02), do: :scene_controller
  def byte_to_specific_class(0x02, 0x03), do: :static_installer_tool
  def byte_to_specific_class(0x02, 0x04), do: :set_top_box
  def byte_to_specific_class(0x02, 0x05), do: :sub_system_controller
  def byte_to_specific_class(0x02, 0x06), do: :tv
  def byte_to_specific_class(0x02, 0x07), do: :gateway

  def byte_to_specific_class(0x03, 0x00), do: :not_used
  def byte_to_specific_class(0x03, 0x04), do: :satellite_receiver
  def byte_to_specific_class(0x03, 0x11), do: :satellite_receiver_v2
  def byte_to_specific_class(0x03, 0x12), do: :doorbell

  def byte_to_specific_class(0x04, 0x00), do: :not_used
  def byte_to_specific_class(0x04, 0x01), do: :simple_display

  def byte_to_specific_class(0x05, 0x00), do: :not_used
  def byte_to_specific_class(0x05, 0x01), do: :secure_extender

  def byte_to_specific_class(0x06, 0x00), do: :not_used
  def byte_to_specific_class(0x06, 0x01), do: :general_appliance
  def byte_to_specific_class(0x06, 0x02), do: :kitchen_appliance
  def byte_to_specific_class(0x06, 0x03), do: :laundry_appliance

  def byte_to_specific_class(0x07, 0x00), do: :not_used
  def byte_to_specific_class(0x07, 0x01), do: :notification_sensor

  def byte_to_specific_class(0x08, 0x00), do: :not_used
  def byte_to_specific_class(0x08, 0x01), do: :thermostat_heating
  def byte_to_specific_class(0x08, 0x02), do: :thermostat_general
  def byte_to_specific_class(0x08, 0x03), do: :setback_schedule_thermostat
  def byte_to_specific_class(0x08, 0x04), do: :setpoint_thermostat
  def byte_to_specific_class(0x08, 0x05), do: :setback_thermostat
  def byte_to_specific_class(0x08, 0x06), do: :thermostat_general_v2

  def byte_to_specific_class(0x09, 0x00), do: :not_used
  def byte_to_specific_class(0x09, 0x01), do: :simple_window_covering

  def byte_to_specific_class(0x10, 0x00), do: :not_used
  def byte_to_specific_class(0x10, 0x01), do: :power_switch_binary
  def byte_to_specific_class(0x10, 0x02), do: :color_tunable_binary
  def byte_to_specific_class(0x10, 0x03), do: :scene_switch_binary
  def byte_to_specific_class(0x10, 0x04), do: :power_strip
  def byte_to_specific_class(0x10, 0x05), do: :siren
  def byte_to_specific_class(0x10, 0x06), do: :valve_open_close
  def byte_to_specific_class(0x10, 0x07), do: :irrigation_controller

  def byte_to_specific_class(0x11, 0x00), do: :not_used
  def byte_to_specific_class(0x11, 0x01), do: :power_switch_multilevel
  def byte_to_specific_class(0x11, 0x02), do: :color_tunable_multilevel
  def byte_to_specific_class(0x11, 0x03), do: :motor_multipositions
  def byte_to_specific_class(0x11, 0x04), do: :scene_switch_multilevel
  def byte_to_specific_class(0x11, 0x05), do: :class_a_motor_control
  def byte_to_specific_class(0x11, 0x06), do: :class_b_motor_control
  def byte_to_specific_class(0x11, 0x07), do: :class_c_motor_control
  def byte_to_specific_class(0x11, 0x08), do: :fan_switch

  def byte_to_specific_class(0x12, 0x00), do: :not_used
  def byte_to_specific_class(0x12, 0x01), do: :switch_remote_binary
  def byte_to_specific_class(0x12, 0x02), do: :switch_remote_multilevel
  def byte_to_specific_class(0x12, 0x03), do: :switch_remote_toggle_binary
  def byte_to_specific_class(0x12, 0x04), do: :switch_remote_toggle_multilevel

  def byte_to_specific_class(0x13, 0x00), do: :not_used
  def byte_to_specific_class(0x13, 0x01), do: :switch_toggle_binary
  def byte_to_specific_class(0x13, 0x02), do: :switch_toggle_multilevel

  def byte_to_specific_class(0x15, 0x00), do: :not_used
  def byte_to_specific_class(0x15, 0x01), do: :zip_adv_node
  def byte_to_specific_class(0x15, 0x02), do: :zip_tun_node

  def byte_to_specific_class(0x17, 0x00), do: :not_used
  def byte_to_specific_class(0x17, 0x01), do: :zoned_security_panel

  def byte_to_specific_class(0x18, 0x00), do: :not_used
  def byte_to_specific_class(0x18, 0x01), do: :basic_wall_controller

  def byte_to_specific_class(0x20, 0x00), do: :not_used
  def byte_to_specific_class(0x20, 0x01), do: :routing_sensor_binary

  def byte_to_specific_class(0x21, 0x00), do: :not_used
  def byte_to_specific_class(0x21, 0x01), do: :routing_sensor_multilevel
  def byte_to_specific_class(0x21, 0x02), do: :chimney_fan

  def byte_to_specific_class(0x30, 0x00), do: :not_used

  def byte_to_specific_class(0x31, 0x00), do: :not_used
  def byte_to_specific_class(0x31, 0x01), do: :simple_meter
  def byte_to_specific_class(0x31, 0x02), do: :adv_energy_control
  def byte_to_specific_class(0x31, 0x03), do: :whole_home_meter_simple

  def byte_to_specific_class(0x40, 0x00), do: :not_used
  def byte_to_specific_class(0x40, 0x01), do: :door_lock
  def byte_to_specific_class(0x40, 0x02), do: :advanced_door_lock
  def byte_to_specific_class(0x40, 0x03), do: :secure_keypad_door_lock
  def byte_to_specific_class(0x40, 0x04), do: :secure_keypad_door_lock_deadbolt
  def byte_to_specific_class(0x40, 0x05), do: :secure_door
  def byte_to_specific_class(0x40, 0x06), do: :secure_gate
  def byte_to_specific_class(0x40, 0x07), do: :secure_barrier_addon
  def byte_to_specific_class(0x40, 0x08), do: :secure_barrier_open_only
  def byte_to_specific_class(0x40, 0x09), do: :secure_barrier_close_only
  def byte_to_specific_class(0x40, 0x0A), do: :secure_lockbox
  def byte_to_specific_class(0x40, 0x0B), do: :secure_keypad

  def byte_to_specific_class(0x50, 0x00), do: :not_used
  def byte_to_specific_class(0x50, 0x01), do: :energy_production

  def byte_to_specific_class(0xA1, 0x00), do: :not_used
  def byte_to_specific_class(0xA1, 0x01), do: :basic_routing_alarm_sensor
  def byte_to_specific_class(0xA1, 0x02), do: :routing_alarm_sensor
  def byte_to_specific_class(0xA1, 0x03), do: :basic_zensor_net_alarm_sensor
  def byte_to_specific_class(0xA1, 0x04), do: :zensor_net_alarm_sensor
  def byte_to_specific_class(0xA1, 0x05), do: :adv_zensor_net_alarm_sensor
  def byte_to_specific_class(0xA1, 0x06), do: :basic_routing_smoke_sensor
  def byte_to_specific_class(0xA1, 0x07), do: :routing_smoke_sensor
  def byte_to_specific_class(0xA1, 0x08), do: :basic_zensor_net_smoke_sensor
  def byte_to_specific_class(0xA1, 0x09), do: :zensor_net_smoke_sensor
  def byte_to_specific_class(0xA1, 0x0A), do: :adv_zensor_net_smoke_sensor
  def byte_to_specific_class(0xA1, 0x0B), do: :alarm_sensor

  def byte_to_specific_class(0xFF, 0x00), do: :not_used

  def byte_to_specific_class(gen_byte, spec_byte) do
    _ =
      Logger.warn(
        "Unknown specific class #{Integer.to_string(spec_byte, 16)} for generic class #{
          Integer.to_string(gen_byte, 16)
        }"
      )

    {:unk, gen_byte, spec_byte}
  end

  @spec is_network_command_class(byte) :: boolean
  def is_network_command_class(byte) when byte in @known_network_command_classes, do: true
  def is_network_command_class(_), do: false
end
