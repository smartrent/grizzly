# !! THIS FILE IS GENERATED BY `mix zwave.gen.xml`
# !! DO NOT EDIT DIRECTLY

defmodule Grizzly.ZWave.GeneratedMappings do
  @moduledoc false
  def command_class_mappings() do
    [
      {0, :no_operation},
      {2, :zensor_net},
      {32, :basic},
      {33, :controller_replication},
      {34, :application_status},
      {35, :zip},
      {36, :security_panel_mode},
      {37, :switch_binary},
      {38, :switch_multilevel},
      {39, :switch_all},
      {40, :switch_toggle_binary},
      {41, :switch_toggle_multilevel},
      {42, :chimney_fan},
      {43, :scene_activation},
      {44, :scene_actuator_conf},
      {45, :scene_controller_conf},
      {46, :security_panel_zone},
      {47, :security_panel_zone_sensor},
      {48, :sensor_binary},
      {49, :sensor_multilevel},
      {50, :meter},
      {51, :switch_color},
      {52, :network_management_inclusion},
      {53, :meter_pulse},
      {54, :basic_tariff_info},
      {55, :hrv_status},
      {56, :thermostat_heating},
      {57, :hrv_control},
      {58, :dcp_config},
      {59, :dcp_monitor},
      {60, :meter_tbl_config},
      {61, :meter_tbl_monitor},
      {62, :meter_tbl_push},
      {63, :prepayment},
      {64, :thermostat_mode},
      {65, :prepayment_encapsulation},
      {66, :thermostat_operating_state},
      {67, :thermostat_setpoint},
      {68, :thermostat_fan_mode},
      {69, :thermostat_fan_state},
      {70, :climate_control_schedule},
      {71, :thermostat_setback},
      {72, :rate_tbl_config},
      {73, :rate_tbl_monitor},
      {74, :tariff_config},
      {75, :tariff_tbl_monitor},
      {76, :door_lock_logging},
      {77, :network_management_basic},
      {78, :schedule_entry_lock},
      {79, :zip_6lowpan},
      {80, :basic_window_covering},
      {81, :mtp_window_covering},
      {82, :network_management_proxy},
      {83, :schedule},
      {84, :network_management_primary},
      {85, :transport_service},
      {86, :crc_16_encap},
      {87, :application_capability},
      {88, :zip_nd},
      {89, :association_group_info},
      {90, :device_reset_locally},
      {91, :central_scene},
      {92, :ip_association},
      {93, :antitheft},
      {94, :zwaveplus_info},
      {95, :zip_gateway},
      {96, :multi_channel},
      {97, :zip_portal},
      {98, :door_lock},
      {99, :user_code},
      {100, :humidity_control_setpoint},
      {101, :dmx},
      {102, :barrier_operator},
      {103, :network_management_installation_maintenance},
      {104, :zip_naming},
      {105, :mailbox},
      {106, :window_covering},
      {107, :irrigation},
      {108, :supervision},
      {109, :humidity_control_mode},
      {110, :humidity_control_operating_state},
      {111, :entry_control},
      {112, :configuration},
      {113, :alarm},
      {114, :manufacturer_specific},
      {115, :powerlevel},
      {116, :inclusion_controller},
      {117, :protection},
      {118, :lock},
      {119, :node_naming},
      {120, :node_provisioning},
      {121, :sound_switch},
      {122, :firmware_update_md},
      {123, :grouping_name},
      {124, :remote_association_activate},
      {125, :remote_association},
      {126, :antitheft_unlock},
      {128, :battery},
      {129, :clock},
      {130, :hail},
      {131, :user_credential},
      {132, :wake_up},
      {133, :association},
      {134, :version},
      {135, :indicator},
      {136, :proprietary},
      {137, :language},
      {138, :time},
      {139, :time_parameters},
      {140, :geographic_location},
      {142, :multi_channel_association},
      {143, :multi_cmd},
      {144, :energy_production},
      {145, :manufacturer_proprietary},
      {146, :screen_md},
      {147, :screen_attributes},
      {148, :simple_av_control},
      {149, :av_content_directory_md},
      {150, :av_content_renderer_status},
      {151, :av_content_search_md},
      {152, :security},
      {153, :av_tagging_md},
      {154, :ip_configuration},
      {155, :association_command_configuration},
      {156, :sensor_alarm},
      {157, :silence_alarm},
      {158, :sensor_configuration},
      {159, :security_2},
      {160, :ir_repeater},
      {161, :authentication},
      {162, :authentication_media_write},
      {163, :generic_schedule},
      {239, :mark},
      {240, :non_interoperable}
    ]
  end

  def basic_device_class_mappings() do
    [{1, :controller}, {2, :static_controller}, {3, :end_node}, {4, :routing_end_node}]
  end

  def generic_device_class_mappings() do
    [
      {1, :generic_controller},
      {2, :static_controller},
      {3, :av_control_point},
      {4, :display},
      {5, :network_extender},
      {6, :appliance},
      {7, :sensor_notification},
      {8, :thermostat},
      {9, :window_covering},
      {15, :repeater_end_node},
      {16, :switch_binary},
      {17, :switch_multilevel},
      {18, :switch_remote},
      {19, :switch_toggle},
      {21, :zip_node},
      {22, :ventilation},
      {23, :security_panel},
      {24, :wall_controller},
      {32, :sensor_binary},
      {33, :sensor_multilevel},
      {48, :meter_pulse},
      {49, :meter},
      {64, :entry_control},
      {80, :semi_interoperable},
      {161, :sensor_alarm},
      {255, :non_interoperable}
    ]
  end

  def specific_device_class_mappings() do
    [
      {:appliance, 0, :not_used},
      {:appliance, 1, :general_appliance},
      {:appliance, 2, :kitchen_appliance},
      {:appliance, 3, :laundry_appliance},
      {:av_control_point, 0, :not_used},
      {:av_control_point, 1, :sound_switch},
      {:av_control_point, 4, :satellite_receiver},
      {:av_control_point, 17, :satellite_receiver_v2},
      {:av_control_point, 18, :doorbell},
      {:display, 0, :not_used},
      {:display, 1, :simple_display},
      {:entry_control, 0, :not_used},
      {:entry_control, 1, :door_lock},
      {:entry_control, 2, :advanced_door_lock},
      {:entry_control, 3, :secure_keypad_door_lock},
      {:entry_control, 4, :secure_keypad_door_lock_deadbolt},
      {:entry_control, 5, :secure_door},
      {:entry_control, 6, :secure_gate},
      {:entry_control, 7, :secure_barrier_addon},
      {:entry_control, 8, :secure_barrier_open_only},
      {:entry_control, 9, :secure_barrier_close_only},
      {:entry_control, 10, :secure_lockbox},
      {:entry_control, 11, :secure_keypad},
      {:generic_controller, 0, :not_used},
      {:generic_controller, 1, :portable_remote_controller},
      {:generic_controller, 2, :portable_scene_controller},
      {:generic_controller, 3, :portable_installer_tool},
      {:generic_controller, 4, :remote_control_av},
      {:generic_controller, 6, :remote_control_simple},
      {:meter, 0, :not_used},
      {:meter, 1, :simple_meter},
      {:meter, 2, :adv_energy_control},
      {:meter, 3, :whole_home_meter_simple},
      {:meter_pulse, 0, :not_used},
      {:network_extender, 0, :not_used},
      {:network_extender, 1, :secure_extender},
      {:non_interoperable, 0, :not_used},
      {:repeater_end_node, 0, :not_used},
      {:repeater_end_node, 1, :repeater_end_node},
      {:repeater_end_node, 2, :virtual_node},
      {:repeater_end_node, 3, :ir_repeater},
      {:security_panel, 0, :not_used},
      {:security_panel, 1, :zoned_security_panel},
      {:semi_interoperable, 0, :not_used},
      {:semi_interoperable, 1, :energy_production},
      {:sensor_alarm, 0, :not_used},
      {:sensor_alarm, 1, :basic_routing_alarm_sensor},
      {:sensor_alarm, 2, :routing_alarm_sensor},
      {:sensor_alarm, 3, :basic_zensor_net_alarm_sensor},
      {:sensor_alarm, 4, :zensor_net_alarm_sensor},
      {:sensor_alarm, 5, :adv_zensor_net_alarm_sensor},
      {:sensor_alarm, 6, :basic_routing_smoke_sensor},
      {:sensor_alarm, 7, :routing_smoke_sensor},
      {:sensor_alarm, 8, :basic_zensor_net_smoke_sensor},
      {:sensor_alarm, 9, :zensor_net_smoke_sensor},
      {:sensor_alarm, 10, :adv_zensor_net_smoke_sensor},
      {:sensor_alarm, 11, :alarm_sensor},
      {:sensor_binary, 0, :not_used},
      {:sensor_binary, 1, :routing_sensor_binary},
      {:sensor_multilevel, 0, :not_used},
      {:sensor_multilevel, 1, :routing_sensor_multilevel},
      {:sensor_multilevel, 2, :chimney_fan},
      {:sensor_notification, 0, :not_used},
      {:sensor_notification, 1, :notification_sensor},
      {:static_controller, 0, :not_used},
      {:static_controller, 1, :pc_controller},
      {:static_controller, 2, :scene_controller},
      {:static_controller, 3, :static_installer_tool},
      {:static_controller, 4, :set_top_box},
      {:static_controller, 5, :sub_system_controller},
      {:static_controller, 6, :tv},
      {:static_controller, 7, :gateway},
      {:switch_binary, 0, :not_used},
      {:switch_binary, 1, :power_switch_binary},
      {:switch_binary, 2, :color_tunable_binary},
      {:switch_binary, 3, :scene_switch_binary},
      {:switch_binary, 4, :power_strip},
      {:switch_binary, 5, :siren},
      {:switch_binary, 6, :valve_open_close},
      {:switch_binary, 7, :irrigation_controller},
      {:switch_multilevel, 0, :not_used},
      {:switch_multilevel, 1, :power_switch_multilevel},
      {:switch_multilevel, 2, :color_tunable_multilevel},
      {:switch_multilevel, 3, :motor_multiposition},
      {:switch_multilevel, 4, :scene_switch_multilevel},
      {:switch_multilevel, 5, :class_a_motor_control},
      {:switch_multilevel, 6, :class_b_motor_control},
      {:switch_multilevel, 7, :class_c_motor_control},
      {:switch_multilevel, 8, :fan_switch},
      {:switch_remote, 0, :not_used},
      {:switch_remote, 1, :switch_remote_binary},
      {:switch_remote, 2, :switch_remote_multilevel},
      {:switch_remote, 3, :switch_remote_toggle_binary},
      {:switch_remote, 4, :switch_remote_toggle_multilevel},
      {:switch_toggle, 0, :not_used},
      {:switch_toggle, 1, :switch_toggle_binary},
      {:switch_toggle, 2, :switch_toggle_multilevel},
      {:thermostat, 0, :not_used},
      {:thermostat, 1, :thermostat_heating},
      {:thermostat, 2, :thermostat_general},
      {:thermostat, 3, :setback_schedule_thermostat},
      {:thermostat, 4, :setpoint_thermostat},
      {:thermostat, 5, :setback_thermostat},
      {:thermostat, 6, :thermostat_general_v2},
      {:ventilation, 0, :not_used},
      {:ventilation, 1, :residential_hrv},
      {:wall_controller, 0, :not_used},
      {:wall_controller, 1, :basic_wall_controller},
      {:window_covering, 0, :not_used},
      {:window_covering, 1, :simple_window_covering},
      {:zip_node, 0, :not_used},
      {:zip_node, 1, :zip_tun_node},
      {:zip_node, 2, :zip_adv_node}
    ]
  end
end
